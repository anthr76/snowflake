{ lib, stdenv, fetchFromGitHub }:

with lib;

stdenv.mkDerivation {
  name = "udpbroadcastrelay";
  src = fetchFromGitHub {
    owner = "marjohn56";
    repo = "udpbroadcastrelay";
    rev = "07d747947047f4c01a3b7dd26bb15beafffeadff";
    sha256 = "sha256-tFkn4hWky77UdXzgZWCf5aaiFKeQl3E/71EVh8kXO/I=";
  };


  installPhase = ''
    mkdir -p $out/bin
    cp udpbroadcastrelay $out/bin/
  '';

  meta = {
    description =
      "UDP multicast/unicast relayer";
    homepage = "https://github.com/marjohn56/udpbroadcastrelay";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
