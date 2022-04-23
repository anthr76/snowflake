{pkgs, lib, ...}: {
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome-dev;
    commandLineArgs = "--use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end"
}