{ pkgs, inputs, ... }:
{
  home.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
    # Ensure VA-API picks the AMD/Mesa driver.
    LIBVA_DRIVER_NAME = "radeonsi";
  };
  programs.chromium = {
    enable = true;
    package = pkgs.chromium.override {
      enableWideVine = true;
    };
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "ckhlfagjncfmdieecfekjbpnnaekhlhd"; } # No Mouse Wheel Zoom
      {
        # adnauseam
        id = "ilkggpgmkemaniponkfgnkonpajankkm";
        crxPath = builtins.fetchurl {
          name = "chromium-web-store.crx";
          url = "https://github.com/dhowe/AdNauseam/releases/download/v3.24.0/adnauseam-3.24.0.chromium.crx";
          sha256 = "sha256:0hy5x1q84q4alg412ic23fq39afn75kmfnmb475sd8bwvmr4v8q6";
        };
        version = "3.24.0";
      }
    ];
    commandLineArgs = [
      # Wayland-stable path: ANGLE with GL backend (not Vulkan).
      "--use-gl=angle"
      "--use-angle=gl"
      # Enable VA-API decode/encode; keep NVIDIA hints harmlessly present.
      "--enable-features=VaapiVideoDecoder,AcceleratedVideoEncoder,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks"
      # Disable Vulkan/ANGLE Vulkan and zero-copy paths that commonly cause artifacts on AMD.
      "--disable-features=Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,AcceleratedVideoDecodeLinuxZeroCopyGL,UseMultiPlaneFormatForHardwareVideo"
      # Zero-copy can still be toggled independently; force it off.
      "--disable-zero-copy"
      # WebGPU (Dawn) can try Vulkan/EGL paths and spam errors; not needed for video playback.
      "--disable-webgpu"
      # Prefer Wayland; remove x11 hint to avoid mismatched compositor paths.
      "--ozone-platform=wayland"
      # Allow software fallback if GL context init fails (prevents blank content); remove after validation.
      # "--disable-software-rasterizer"
      # Useful logging when testing.
      "--enable-logging=stderr"
    ];
  };
  catppuccin.chromium.enable = true;
}
