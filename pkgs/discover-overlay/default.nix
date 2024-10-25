{ buildPythonPackage, fetchFromGitHub, gobject-introspection, gtk-layer-shell, gtk3
, lib, wrapGAppsHook, pillow, pygobject3, pyxdg, requests, setuptools
, websocket-client, xlib, pulsectl-asyncio }:
buildPythonPackage rec {
  pname = "discover-overlay";
  version = "0.7.8";

  src = fetchFromGitHub {
    owner = "trigg";
    repo = "Discover";
    rev = "v0.7.8";
    sha256 = "sha256-0b0uZDa9Q3pQ6X65C+E31dMpdTPt4vvHDEqFEtRoedg=";
  };
  nativeBuildInputs = [ wrapGAppsHook gobject-introspection ];
  propagatedBuildInputs = [
    gobject-introspection
    gtk-layer-shell
    gtk3
    pillow
    pygobject3
    pyxdg
    requests
    setuptools
    websocket-client
    xlib
    pulsectl-asyncio
  ];

  doCheck = false;

  meta = with lib; {
    description = "Yet another discord overlay for linux";
    homepage = "https://github.com/trigg/Discover";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
