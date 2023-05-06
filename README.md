# Crystal Nix Flake

An opinionated distribution of Crystal, with following packages:

* [Crystal](https://crystal-lang.org)
* [crystalline](https://github.com/elbywan/crystalline)
* [ameba](https://crystal-ameba.github.io)

This is just enough to get my usual development environment going, and
relatively painless to update thanks to the `./update.cr` script.

Updates aren't automated yet, but feel free to ping me when I happen to miss a
release.

The crystal package comes in two flavours, `crystal` and `crystal-bin`. The
`crystal` package is built from source using the `crystal-bin` one, so if you
want to avoid compilation times, you might want to cache them or use the binary
version.

## Nix Shell Usage

    nix shell github:manveru/crystal-flake#crystal
    nix shell github:manveru/crystal-flake#ameba
    nix shell github:manveru/crystal-flake#crystalline

## Nix Flake Usage

```nix
{
  description = "Usage example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    crystal-flake.url = "github:manveru/crystal-flake";
  };

  outputs = {
    nixpkgs,
    crystal-flake,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (crystal-flake.legacyPackages.${system}) ameba crystal crystalline;
  in {
    devShells.${system}.default = pkgs.mkShell {
      nativeBuildInputs = [
        ameba
        crystal
        crystalline
      ];
    };
  };
}
```

## Note

The `darwin` version isn't tested, since I only have an `x86_64-linux` machine,
but in theory the `crystal-bin` packages should work as well as the official
release.


