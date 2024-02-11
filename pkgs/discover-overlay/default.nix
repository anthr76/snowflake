{
  buildPythonPackage,
  fetchPypi,
  gobject-introspection,
  gtk-layer-shell,
  gtk3,
  lib,
  wrapGAppsHook,
  pillow,
  pygobject3,
  pyxdg,
  requests,
  setuptools,
  websocket-client,
  xlib,
}:
  buildPythonPackage rec {
    pname = "discover-overlay";
    version = "0.6.9";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-14UmxAF4X0GnPokZeXAqeZYdSDUPrE3ZpNDUdk64Bik=";
    };
    nativeBuildInputs = [
      wrapGAppsHook
      gobject-introspection
    ];
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
    ];

    doCheck = false;

    meta = with lib; {
      description = "Yet another discord overlay for linux";
      homepage = "https://github.com/trigg/Discover";
      license = licenses.gpl3;
      platforms = platforms.linux;
    };
  }
