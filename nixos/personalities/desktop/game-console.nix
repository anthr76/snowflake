# This is a steamOS steam console like setup.
# Lots of duplication here between we defined things, but since this is a console things need to be insecure and different.
{pkgs, outputs, inputs, ...}:
{
  imports = [
    inputs.jovian-nixos.nixosModules.jovian
    ../../personalities/base/zram.nix
    ../../personalities/base/bootloader.nix
    ../../personalities/base/sops.nix
    ../../personalities/base/openssh.nix
    ../../personalities/base/nix.nix
    ../../personalities/base/podman.nix
    # ./sunshine.nix
    # ./wolf.nix
    # ./audio.nix
  ];
  services.xserver.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };
  environment.systemPackages = [
    inputs.jovian-nixos.legacyPackages.${pkgs.system}.steam
    pkgs.mangohud
    pkgs.vim
    pkgs.vulkan-tools
  ];
  boot = {
    plymouth = {
      enable = true;
      theme = "steamos";
      themePackages = [
        inputs.jovian-nixos.legacyPackages.${pkgs.system}.steamdeck-hw-theme
      ];
    };
    loader.timeout = 0;
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "udev.log_level=3"
      "rd.udev.log_level=3"
      "vt.global_cursor_default=0"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
  users.users = {
      steam = {
      isNormalUser = true;
      initialPassword = "steam";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../../../home-manager/users/anthony/yubi.pub)
        (builtins.readFile ../../../home-manager/users/anthony/e39_tpm2.pub)
      ];
    };
  };
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    wireless = {
      iwd = {
        enable = true;
      };
    };
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };
  hardware.bluetooth.enable = true;
  jovian = {
    hardware.has.amd.gpu = true;
    hardware.amd.gpu.enableBacklightControl = false;
    decky-loader.enable = true;
    devices.steamdeck.enableKernelPatches = true;
    devices.steamdeck.enableSoundSupport = true;
    steam = {
      enable = true;
      autoStart = true;
      user = "steam";
      desktopSession = "plasma";
    };
    steamos = {
      useSteamOSConfig = true;
    };
  };
}
