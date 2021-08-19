inputs: final: prev: {
  crystal =
    prev.callPackage ./package.nix { src = inputs."crystal-${prev.system}"; };
}
