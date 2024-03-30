{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, libevdev
, xdotool
, xorg
}:

with lib;

stdenv.mkDerivation {
  name = "wayland-push-to-talk-fix";
  src = fetchFromGitHub {
    owner = "Rush";
    repo = "wayland-push-to-talk-fix";
    rev = "490f43054453871fe18e7d7e9041cfbd0f1d9b7d";
    sha256 = "ZRSgrQHnNdEF2PyaflmI5sUoKCxtZ0mQY/bb/9PH64c=";
  };

  nativeBuildInputs = [
    pkg-config
    libevdev
    xdotool
    xorg.libX11.dev
  ];


  installPhase = ''
    mkdir -p $out/bin
    cp push-to-talk $out/bin/
  '';

  meta = {
    description = "This fixes the inability to use push to talk in Discord when running Wayland";
    homepage = "https://github.com/Rush/wayland-push-to-talk-fix";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
