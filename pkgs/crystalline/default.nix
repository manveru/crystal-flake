{
  src,
  version,
  crystal,
  llvmPackages,
  openssl,
  shards,
  lib,
  makeWrapper,
}:
crystal.buildCrystalPackage rec {
  pname = "crystalline";
  inherit version src;

  shardsFile = ./shards.nix;

  passthru.shards = ''
    #!/usr/bin/env bash

    set -exuo pipefail

    cur="$PWD"
    dir="$(mktemp -d)"
    cp -r "${src}/." "$dir"
    chmod u+w -R "$dir"
    cd "$dir"
    crystal2nix
    cp shards.nix "$cur/pkgs/crystalline/shards.nix"
    rm -rf "$dir"
  '';

  format = "crystal";

  nativeBuildInputs = [llvmPackages.llvm openssl makeWrapper shards];

  doCheck = false;
  doInstallCheck = false;

  crystalBinaries.crystalline = {
    src = "src/crystalline.cr";
    options = ["--release" "--no-debug" "--progress" "-Dpreview_mt"];
  };

  postInstall = ''
    wrapProgram "$out/bin/crystalline" --prefix PATH : '${
      lib.makeBinPath [llvmPackages.llvm.dev]
    }'
  '';
}
