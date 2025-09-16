{ pkgs, inputs, ... }:
{
  home.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };
  programs.chromium = {
    enable = true;
    package =
      let
        stablePkgs = import inputs.nixpkgs-stable {
          system = pkgs.system;
          config.allowUnfree = true;
        };
      in
      stablePkgs.chromium.override {
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
      "--enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,AcceleratedVideoDecodeLinuxZeroCopyGL,AcceleratedVideoEncoder,VaapiIgnoreDriverChecks,UseMultiPlaneFormatForHardwareVideo"
      "--use-gl=angle"
      "--use-angle=vulkan"
      "--ozone-platform-hint=x11"
    ];
  };
  catppuccin.chromium.enable = true;
}
