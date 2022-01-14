{
  description = "Flake for Crystal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    utils.url = "github:kreisys/flake-utils";

    crystal-source = {
      url = "github:crystal-lang/crystal/1.3.1";
      flake = false;
    };

    crystal-i686-linux = {
      url =
        "https://github.com/crystal-lang/crystal/releases/download/1.3.1/crystal-1.3.1-1-linux-x86_64.tar.gz";
      flake = false;
    };

    crystal-x86_64-darwin = {
      url =
        "https://github.com/crystal-lang/crystal/releases/download/1.3.1/crystal-1.3.1-1-linux-x86_64.tar.gz";
      flake = false;
    };

    crystal-x86_64-linux = {
      url =
        "https://github.com/crystal-lang/crystal/releases/download/1.3.1/crystal-1.3.1-1-linux-x86_64.tar.gz";
      flake = false;
    };

    libatomic_ops-src = {
      url =
        "https://github.com/ivmai/libatomic_ops/releases/download/v7.6.10/libatomic_ops-7.6.10.tar.gz";
      flake = false;
    };

    bdwgc-src = {
      url =
        "https://github.com/ivmai/bdwgc/releases/download/v8.0.4/gc-8.0.4.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, ... }@inputs:
    utils.lib.simpleFlake {
      inherit nixpkgs;
      name = "crystal";

      overlay = final: prev:
        let version = "1.2.2";
        in {
          bdwgc = prev.callPackage ./bdwgc.nix {
            src = inputs.bdwgc-src;
            libatomic_ops = inputs.libatomic_ops-src;
          };

          crystal-bin = prev.callPackage ./package-bin.nix {
            inherit version;
            src = inputs."crystal-${prev.system}";
          };

          crystal = final.callPackage ./package.nix {
            inherit version;
            src = inputs.crystal-source;
          };

          crystal-specs = final.callPackage ./package.nix {
            inherit version;
            src = inputs.crystal-source;
            doCheck = true;
          };
        };

      packages = { crystal, crystal-bin }@pkgs:
        pkgs // {
          defaultPackage = crystal;
        };

      shell = ./shell.nix;
    };
}
