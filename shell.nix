{
  mkShell,
  crystal,
  pkg-config,
  openssl,
  zlib,
  pcre,
  libevent,
  treefmt,
  treefmt-crystal,
}:
mkShell {
  nativeBuildInputs = [
    crystal
    pkg-config
    openssl
    zlib
    pcre
    libevent
    treefmt
    treefmt-crystal
  ];
}
