{
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Memory management tuning for gaming
  # Reduces swap pressure and keeps more in RAM
  boot.kernel.sysctl = {
    # Only swap when absolutely necessary (default: 60)
    "vm.swappiness" = 10;
    # Keep file cache longer, important for game asset loading (default: 100)
    "vm.vfs_cache_pressure" = 50;
    # Start async writeback earlier to avoid I/O spikes (default: 10)
    "vm.dirty_background_ratio" = 5;
    # Force sync writeback threshold (default: 20)
    "vm.dirty_ratio" = 10;
    # Read single pages from swap, better for random access (default: 3)
    "vm.page-cluster" = 0;
    # Disable watermark boosting to reduce reclaim overhead
    "vm.watermark_boost_factor" = 0;
    # More aggressive page reclaim before hitting memory limits
    "vm.watermark_scale_factor" = 125;
    # Prefer reclaiming page cache over anonymous memory
    "vm.zone_reclaim_mode" = 0;
    # Compact memory more aggressively for huge pages
    "vm.compaction_proactiveness" = 20;
  };
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    fontPackages = with pkgs; [
      liberation_ttf
      wqy_zenhei
      source-han-sans
    ];
    package = pkgs.steam.override {
      extraEnv = {
        STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
        # Preload gamemode for pressure-vessel compatibility
        LD_PRELOAD = "${pkgs.gamemode.lib}/lib/libgamemode.so:${pkgs.pkgsi686Linux.gamemode.lib}/lib/libgamemode.so";
      };
      extraLibraries = p:
        with p; [
          xorg.libxcb
          gamemode.lib
          freetype
        ];
    };
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      proton-cachyos
    ];
  };
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = ["--autopower"];
  };
  programs.gamescope = {
    enable = true;
    capSysNice = false;
    package = pkgs.gamescope;
  };
  hardware.graphics = {
    enable32Bit = true;
    extraPackages = [pkgs.gamescope-wsi];
    extraPackages32 = [pkgs.pkgsi686Linux.gamescope-wsi];
  };
  services.pulseaudio.support32Bit = true;
  environment.systemPackages = [pkgs.vulkan-tools pkgs.amdgpu_top pkgs.lsfg-vk-ui pkgs.lsfg-vk];
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        softrealtime = "off";
        igpu_desiredgov = "performance";
        igpu_power_threshold = "-1";
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = "0";
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.rpc-bridge}/bin/bridge.sh";
      };
    };
  };
  gaming-kernel.enable = true;
}
