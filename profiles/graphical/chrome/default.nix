{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ google-chrome ];
  # This is broke? 
  nixpkgs.config.google-chrome.commandLineArgs =
    "--use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";

}
