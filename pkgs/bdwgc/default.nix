{
  stdenv,
  fetchpatch,
  autoconf,
  automake,
  libtool,
  src,
  version,
}:
stdenv.mkDerivation rec {
  pname = "boehm-gc";

  inherit version src;

  nativeBuildInputs = [automake autoconf libtool];

  preConfigure = "./autogen.sh";

  configureFlags = [
    "--disable-debug"
    "--disable-dependency-tracking"
    "--disable-shared"
    "--enable-large-config"
  ];

  enableParallelBuilding = true;
}
