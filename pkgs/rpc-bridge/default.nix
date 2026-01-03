{
  stdenv,
  lib,
  fetchFromGitHub,
  wine,
  pkgsCross,
}:
stdenv.mkDerivation rec {
  pname = "rpc-bridge";
  version = "1.4.0.1";

  src = fetchFromGitHub {
    owner = "EnderIce2";
    repo = "rpc-bridge";
    rev = "v${version}";
    sha256 = "sha256-NB3GqwlJ1dkI+MmbjDEDhiAvvAtRHOdC/PEEyIP2i28=";
  };

  nativeBuildInputs = [pkgsCross.mingwW64.stdenv.cc wine];

  installPhase = ''
    mkdir -p $out/bin
    cp build/bridge.exe $out/bin
    cp build/bridge.sh $out/bin
  '';

  meta = with lib; {
    description = "Enable Rich Presence between your Wine applications and the native Discord client on Linux and macOS.";
    license = licenses.mit;
    platforms = platforms.all;
    homepage = "https://github.com/EnderIce2/rpc-bridge";
  };
}
