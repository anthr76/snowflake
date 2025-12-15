{...}: {
  home.file = {
    ".steam/steam/steam_dev.cfg".text = ''
      @nClientDownloadEnableHTTP2PlatformLinux 0
      @fDownloadRateImprovementToAddAnotherConnection 1.0
      unShaderBackgroundProcessingThreads 8
    '';
  };
}
