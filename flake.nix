{
  description = "Flake for Crystal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";

    crystal-src = {
      url = "github:crystal-lang/crystal/1.15.1";
      flake = false;
    };

    crystal-x86_64-darwin = {
      url = "https://github.com/crystal-lang/crystal/releases/download/1.15.1/crystal-1.15.1-1-darwin-universal.tar.gz";
      flake = false;
    };

    crystal-x86_64-linux = {
      url = "https://github.com/crystal-lang/crystal/releases/download/1.15.1/crystal-1.15.1-1-linux-x86_64.tar.gz";
      flake = false;
    };

    crystal-aarch64-darwin = {
      url = "https://github.com/crystal-lang/crystal/releases/download/1.15.1/crystal-1.15.1-1-darwin-universal.tar.gz";
      flake = false;
    };

    bdwgc-src = {
      url = "github:ivmai/bdwgc/v8.2.8";
      flake = false;
    };

    crystalline-src = {
      url = "github:elbywan/crystalline/v0.16.0";
      flake = false;
    };

    ameba-src = {
      url = "github:crystal-ameba/ameba/v1.6.4";
      flake = false;
    };
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [flake-parts.flakeModules.easyOverlay];

      systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"];

      perSystem = {
        final,
        pkgs,
        ...
      }: {
        overlayAttrs = let
          crystalVersion = "1.15.1";
          crystallineVersion = "0.16.0";
          bdwgcVersion = "8.2.8";
          amebaVersion = "1.6.4";
          llvmPackages = pkgs.llvmPackages_16;
          clangStdenv = pkgs.clang16Stdenv;
          llvm = pkgs.llvm_16;
        in {
          bdwgc = pkgs.callPackage ./pkgs/bdwgc {
            src = inputs.bdwgc-src;
            version = bdwgcVersion;
          };

          crystal-bin = pkgs.callPackage ./pkgs/crystal/package-bin.nix {
            version = crystalVersion;
            src = inputs."crystal-${pkgs.system}";
          };

          crystal = final.callPackage ./pkgs/crystal {
            inherit llvm llvmPackages clangStdenv;
            version = crystalVersion;
            src = inputs.crystal-src;
          };

          crystal-specs = final.callPackage ./pkgs/crystal {
            inherit llvmPackages;
            version = crystalVersion;
            src = inputs.crystal-src;
            doCheck = true;
          };

          crystalline = final.callPackage ./pkgs/crystalline {
            inherit llvmPackages;
            version = crystallineVersion;
            src = inputs.crystalline-src;
          };

          ameba = final.callPackage ./pkgs/ameba {
            version = amebaVersion;
            src = inputs.ameba-src;
          };

          treefmt-crystal = final.callPackage ./pkgs/treefmt-crystal {
            writeShellApplication = pkgs.writeShellApplication;
          };
        };

        packages = {
          inherit (final) ameba crystal crystal-bin crystalline bdwgc treefmt-crystal;
          defaultPackage = final.crystal;
          default = final.crystal;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            final.crystal
            pkgs.pkg-config
            pkgs.openssl
            pkgs.zlib
            pkgs.pcre
            pkgs.libevent
            pkgs.treefmt
            pkgs.crystal2nix
            final.treefmt-crystal
          ];
        };
      };
    };
}
