{
  lib,
  stdenv,
  fetchFromGitHub,
}:
with lib;
  stdenv.mkDerivation {
    name = "udpbroadcastrelay";
    src = fetchFromGitHub {
      owner = "marjohn56";
      repo = "udpbroadcastrelay";
      rev = "8ebaa9b2690eb61a236184f6f6bf7eb773da4fd9";
      sha256 = "sha256-sZ4K0W608enGmugFVebt2HRpY7eUPItFVwjMLVjRnRs=";
    };

    installPhase = ''
      mkdir -p $out/bin
      cp udpbroadcastrelay $out/bin/
    '';

    meta = {
      description = "UDP multicast/unicast relayer";
      homepage = "https://github.com/marjohn56/udpbroadcastrelay";
      license = licenses.gpl2;
      platforms = platforms.linux;
    };
  }
