# This is a steamOS steam console like setup.
# Lots of duplication here between we defined things, but since this is a console things need to be insecure and different.
{ pkgs, outputs, inputs, config, lib, ... }: {
  imports = [
    ../../personalities/base/bootloader.nix
    ../../personalities/base/sops.nix
    ../../personalities/base/openssh.nix
    ../../personalities/base/nix.nix
    ../../personalities/base/tmpfs.nix
    ./sunshine.nix
    ./audio.nix
    inputs.jovian-nixos.nixosModules.default
  ] ++ (builtins.attrValues outputs.nixosModules);
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      outputs.overlays.flake-inputs
    ];
    config = { allowUnfree = true; };
  };
  gaming-kernel.enable = false;
  # chaotic.hdr.enable = true;
  # chaotic.hdr.specialisation.enable	= false;
  # chaotic.mesa-git.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  services.packagekit.enable = true;
  fonts.enableDefaultPackages = true;
  hardware.xpadneo.enable = true;
  services.fwupd.enable = true;
  environment.systemPackages = with pkgs; [
    mangohud
    vim
    vulkan-tools
    kdePackages.discover
    amdgpu_top
    steam-rom-manager
    # Gamecube / Wii
    dolphin-emu
    # PSX
    duckstation
    # Dreamcast
    flycast
    # Saturn
    yabause
    # N64
    mupen64plus
    # SNES
    bsnes-hd
    # TODO: Changed format
    # (retroarch.override {
    #   cores = with libretro; [
    #     # 32X
    #     picodrive
    #     # PCE
    #     beetle-supergrafx
    #     # ColecoVision
    #     bluemsx
    #     # NES
    #     mesen
    #   ];
    # })
  ];
  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [ liberation_ttf wqy_zenhei ];
    };
    extest.enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

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
  boot.kernelModules = [ "uinput" ];
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
        (builtins.readFile ../../../home-manager/users/anthony/lattice_tpm2.pub)
        (builtins.readFile ../../../home-manager/users/anthony/f80_tpm2.pub)
      ];
    };
  };
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    wireless = { iwd = { enable = true; }; };
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
  # jovian = {
  #   steamos.useSteamOSConfig = true;
  #   hardware.has.amd.gpu = true;
  # };
  jovian = {
    devices.steamdeck.enableKernelPatches = true;
    steamos.useSteamOSConfig = true;
    hardware.has.amd.gpu = true;
    steam = {
      enable = true;
      autoStart = true;
      user = "steam";
      desktopSession = "plasma";
    };
  };
  services.udev.extraRules = ''
    # If a GPU crash is caused by a specific process, kill the PID
    ACTION=="change", ENV{DEVNAME}=="/dev/dri/card0", ENV{RESET}=="1", ENV{PID}!="0", RUN+="${pkgs.util-linux}/bin/kill -9 %E{PID}"

    # Kill greetd and Gamescope if the GPU crashes and VRAM is lost
    ACTION=="change", ENV{DEVNAME}=="/dev/dri/card0", ENV{RESET}=="1", ENV{FLAGS}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart greetd"
  '';
  # GameCube controller 8BitDo GameCube NGC Mod Kit over D-Input
  # environment.sessionVariables.SDL_GAMECONTROLLERCONFIG = "05000000c82d00006a28000000010000,8BitDo GameCube,a:b0,b:b3,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftstick:b13,lefttrigger:a5,leftx:a0,lefty:a1,paddle1:b9,paddle2:b8,rightshoulder:b10,rightstick:b14,righttrigger:a4,rightx:a2,righty:a3,start:b11,x:b1,y:b4,platform:Linux,";
}
