# Wrapper for `crystal tool format` that adheres to the treefmt spec.
{
  lib,
  crystal,
  writeShellApplication,
  gitMinimal,
}:
writeShellApplication {
  name = "treefmt-crystal";
  text = ''
    set -euo pipefail

    PATH="$PATH:"${lib.makeBinPath [
      gitMinimal
      crystal
    ]}

    trap 'rm -rf "$tmp"' EXIT
    tmp="$(mktemp -d)"

    root="$(git rev-parse --show-toplevel)"

    for f in "$@"; do
      fdir="$tmp"/"$(dirname "''${f#"$root"/}")"
      mkdir -p "$fdir"
      cp -a "$f" "$fdir"/
    done
    cp -ar "$root"/.git "$tmp"/

    cd "$tmp"
    crystal tool format "''${@#"$root"/}"

    for f in "''${@#"$root"/}"; do
      if [ -n "$(git status --porcelain --untracked-files=no -- "$f")" ]; then
        cp "$f" "$root"/"$f"
      fi
    done
  '';
}
