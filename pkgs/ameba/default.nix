{
  src,
  version,
  crystal,
  shards,
  fetchFromGitHub,
}:
crystal.buildCrystalPackage rec {
  pname = "ameba";
  inherit version src;

  preBuild = ''
    mkdir -p lib
    ln -s $src lib/ameba
  '';

  buildInputs = [shards];

  crystalBinaries.ameba.src = "bin/ameba.cr";
}
