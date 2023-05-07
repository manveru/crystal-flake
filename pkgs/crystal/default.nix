{
  lib,
  stdenv,
  llvmPackages,
  clang11Stdenv,
  llvm_11,
  removeReferencesTo,
  makeWrapper,
  tzdata,
  pkg-config,
  which,
  readline,
  openssl,
  libxml2,
  git,
  bdwgc,
  libevent,
  zlib,
  libyaml,
  gmp,
  pcre2,
  libiconv,
  libffi,
  hostname,
  coreutils,
  callPackage,
  crystal-bin,
  src,
  version,
  doCheck ? false,
}:
lib.fix (compiler:
    clang11Stdenv.mkDerivation rec {
      pname = "crystal";
      inherit version src;

      passthru = {
        buildCrystalPackage =
          callPackage ./build-crystal-package.nix {crystal = compiler;};
      };

      nativeBuildInputs = [makeWrapper removeReferencesTo llvm_11 pkg-config crystal-bin];

      buildInputs = [bdwgc gmp libevent libxml2 libyaml openssl pcre2 readline zlib libffi] ++ lib.optionals stdenv.isDarwin [ libiconv ];

      checkInputs = [which git gmp openssl readline libxml2 libyaml] ++ lib.optionals stdenv.isDarwin [ libiconv ];

      disallowedReferences = [crystal-bin];

      enableParallelBuilding = true;
      dontStrip = true;
      inherit doCheck;

      outputs = ["out" "lib" "bin"];

      buildFlags = ["all" "docs" "interpreter=1" "release=1"];

      LLVM_CONFIG = "${llvm_11.dev}/bin/llvm-config";
      CRYSTAL_LIBRARY_PATH = "${placeholder "lib"}/crystal";
      CRYSTAL_CONFIG_TARGET = stdenv.targetPlatform.config;
      FLAGS = ["--threads=\${NIX_BUILD_CORES}"];

      postPatch = ''
        substituteInPlace Makefile \
          --replace \
          'docs: ## Generate standard library documentation' \
          'docs: crystal ## Generate standard library documentation'

        substituteInPlace src/crystal/system/unix/time.cr \
          --replace /usr/share/zoneinfo/ ${tzdata}/share/zoneinfo/

        substituteInPlace spec/std/process_spec.cr \
          --replace '/bin/cat' '${coreutils}/bin/cat' \
          --replace '/bin/ls' '${coreutils}/bin/ls' \
          --replace '/usr/bin/env' '${coreutils}/bin/env' \
          --replace '"env"' '"${coreutils}/bin/env"'

        substituteInPlace spec/std/system_spec.cr \
          --replace '`hostname`' '`${hostname}/bin/hostname`'

        # See https://github.com/crystal-lang/crystal/issues/8629
        substituteInPlace spec/std/socket/udp_socket_spec.cr \
          --replace \
          'it "joins and transmits to multicast groups"' \
          'pending "joins and transmits to multicast groups"'

        ln -sf spec/compiler spec/std

        # Dirty fix for when no sandboxing is enabled
        rm -rf /tmp/crystal
        mkdir -p /tmp/crystal
      '';

      checkPhase = ''
        runHook preCheck

        export HOME=/tmp
        mkdir -p $HOME/test

        export CRYSTAL_LIBRARY_PATH="$PWD/lib"
        export LIBRARY_PATH=${
          lib.makeLibraryPath [gmp openssl readline libxml2 libyaml]
        }:$LIBRARY_PATH
        export PATH=${lib.makeBinPath [which git]}:$PATH

        make deps

        ./bin/crystal spec -- --verbose ./spec/compiler_spec.cr

        runHook postCheck
      '';

      installPhase = ''
        runHook preInstall

        install -Dm755 .build/crystal $bin/bin/crystal

        # Due to the crazy way CRYSTAL_LIBRARY_PATH is retrieved from the
        # previous Crystal, we have to make the path to it invalid in the
        # resulting binary.
        remove-references-to -t ${crystal-bin} $bin/bin/crystal

        wrapProgram $bin/bin/crystal \
          --suffix PATH : ${
          lib.makeBinPath [pkg-config llvmPackages.clang which]
        } \
          --suffix CRYSTAL_PATH : lib:$lib/crystal \
          --suffix LLVM_CONFIG : "${llvm_11.dev}/bin/llvm-config" \
          --suffix PKG_CONFIG_PATH : ${
          lib.makeSearchPathOutput "dev" "lib/pkgconfig" buildInputs
        } \
          --suffix CRYSTAL_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

        install -dm755 $lib/crystal
        cp -r src/* $lib/crystal/

        install -dm755 $out/share/doc/crystal/api
        cp -r docs/* $out/share/doc/crystal/api/
        cp -r samples $out/share/doc/crystal/

        install -Dm644 etc/completion.bash $out/share/bash-completion/completions/crystal
        install -Dm644 etc/completion.zsh $out/share/zsh/site-functions/_crystal

        install -Dm644 man/crystal.1 $out/share/man/man1/crystal.1

        install -Dm644 -t $out/share/licenses/crystal LICENSE README.md

        mkdir -p $out
        ln -s $bin/bin $out/bin
        ln -s $lib $out/lib

        runHook postInstall
      '';

      meta = with lib; {
        description = "A compiled language with Ruby like syntax and type inference";
        homepage = "https://crystal-lang.org/";
        license = licenses.asl20;
        maintainers = with maintainers; [manveru];
        platforms = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];
      };
    })
