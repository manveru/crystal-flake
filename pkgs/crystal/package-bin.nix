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

      installPhase = ''
        mkdir -p $out
        cp -r bin lib share $out
      '';
    })
