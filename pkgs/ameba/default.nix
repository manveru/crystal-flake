{
  src,
  version,
  crystal,
  shards,
  coreutils,
}:
crystal.buildCrystalPackage {
  pname = "ameba";
  inherit version src;

  preBuild = ''
    mkdir -p lib
    ln -s $src lib/ameba
  '';

  INSTALL_BIN = "${coreutils}/bin/install";

  buildInputs = [shards];

  crystalBinaries.ameba.src = "bin/ameba.cr";
}
