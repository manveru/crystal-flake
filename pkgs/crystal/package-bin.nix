{
  lib,
  stdenv,
  callPackage,
  src,
  version,
}:
lib.fix (compiler:
    stdenv.mkDerivation rec {
      pname = "crystal-bin";
      inherit version src;

      passthru.buildCrystalPackage =
        callPackage ./build-crystal-package.nix {crystal = compiler;};

      installPhase = if stdenv.isDarwin then
      ''
        mkdir -p $out/bin/
        cp embedded/bin/crystal $out/bin/
      ''      
      else
      ''
        mkdir -p $out
        cp -r bin lib share $out
      '';
    })
