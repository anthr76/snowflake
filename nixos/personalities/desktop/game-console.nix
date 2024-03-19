# This is a steamOS steam console like setup.
# Lots of duplication here between we defined things, but since this is a console things need to be insecure and different.
{pkgs, outputs, inputs, ...}:
{
  imports = [
    inputs.jovian-nixos.nixosModules.jovian
    ../../personalities/base/bootloader.nix
    ../../personalities/base/sops.nix
    ../../personalities/base/openssh.nix
    ../../personalities/base/nix.nix
    # ./no-rgb.nix
    ./sunshine.nix
    # ./wolf.nix
    # ./audio.nix
  ];
  services.xserver.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  services.packagekit.enable = true;
  fonts.enableDefaultPackages = true;
  hardware.xpadneo.enable = true;
  services.fwupd.enable = true;
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
    pkgs.kdePackages.discover
    pkgs.amdgpu_top
  ];
  programs.steam.extraCompatPackages = [
    inputs.nixpkgs-pr-294532.legacyPackages.${pkgs.system}.proton-ge-custom
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
  boot.kernelModules = ["uinput"];
  users.users = {
      steam = {
      isNormalUser = true;
      initialPassword = "steam";
      extraGroups = [
        "wheel"
        "networkmanager"
        "input"
        "wheel"
        # test
        "video"
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
  hardware.bluetooth.input = {
    General = {
      UserspaceHID = true;
      ClassicBondedOnly = false;
      LEAutoSecurity = false;
    };
  };
  hardware.steam-hardware.enable = true;
  jovian = {
    hardware.has.amd.gpu = true;
    # hardware.amd.gpu.enableBacklightControl = true;
    decky-loader.enable = false;
    devices.steamdeck.enableKernelPatches = true;
    devices.steamdeck.enableSoundSupport = true;
    devices.steamdeck.enableControllerUdevRules = true;
    steam = {
      enable = true;
      autoStart = true;
      user = "steam";
      desktopSession = "plasma";
    };
    steamos = {
      useSteamOSConfig = true;
      enableBluetoothConfig = false;
    };
  };
  services.udev.extraRules = ''
    # If a GPU crash is caused by a specific process, kill the PID
    ACTION=="change", ENV{DEVNAME}=="/dev/dri/card0", ENV{RESET}=="1", ENV{PID}!="0", RUN+="${pkgs.util-linux}/bin/kill -9 %E{PID}"

    # Kill greetd and Gamescope if the GPU crashes and VRAM is lost
    ACTION=="change", ENV{DEVNAME}=="/dev/dri/card0", ENV{RESET}=="1", ENV{FLAGS}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart greetd"
  '';
}
