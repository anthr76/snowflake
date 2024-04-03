{ lib, stdenv, fetchFromGitHub, meson, pkg-config, vulkan-loader, ninja
, writeText, vulkan-headers, vulkan-utility-libraries, jq, libX11, libXrandr
, libxcb, wayland }:

stdenv.mkDerivation rec {
  pname = "vulkan-hdr-layer";
  version = "f5f13b7";

  src = (fetchFromGitHub {
    owner = "Zamundaaa";
    repo = "VK_hdr_layer";
    rev = "f5f13b7ae44135a4d79a60bd4cd4efe7e1534ba6";
    fetchSubmodules = true;
    hash = "sha256-l7L/PadW5h3IIZ95vldHdEd8oHkpA/QB91wwpIgidm8=";
  }).overrideAttrs (_: {
    GIT_CONFIG_COUNT = 1;
    GIT_CONFIG_KEY_0 = "url.https://github.com/.insteadOf";
    GIT_CONFIG_VALUE_0 = "git@github.com:";
  });

  nativeBuildInputs = [ vulkan-headers meson ninja pkg-config jq ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    vulkan-utility-libraries
    libX11
    libXrandr
    libxcb
    wayland
  ];

  # Help vulkan-loader find the validation layers
  setupHook = writeText "setup-hook" ''
    addToSearchPath XDG_DATA_DIRS @out@/share
  '';

  meta = with lib; {
    description = "Layers providing Vulkan HDR";
    homepage = "https://github.com/Drakulix/VK_hdr_layer";
    platforms = platforms.linux;
    license = licenses.mit;
  };
}
