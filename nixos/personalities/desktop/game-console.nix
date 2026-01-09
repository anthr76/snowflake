# This is a steamOS steam console like setup.
# Lots of duplication here between we defined things, but since this is a console things need to be insecure and different.
{
  pkgs,
  outputs,
  inputs,
  config,
  lib,
  ...
}: {
  imports =
    [
      ../../personalities/base/bootloader.nix
      ../../personalities/base/sops.nix
      ../../personalities/base/openssh.nix
      ../../personalities/base/nix.nix
      ../../personalities/base/tmpfs.nix
      # ./sunshine.nix
      ./audio.nix
      inputs.jovian-nixos.nixosModules.default
    ]
    ++ (builtins.attrValues outputs.nixosModules);
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.flake-inputs
      # https://github.com/Jovian-Experiments/Jovian-NixOS/issues/303
      (final: prev: {
        steam = prev.steam.override {platformArgs = "";};
      })
    ];
    config = {allowUnfree = true;};
  };
  gaming-kernel.enable = false;
  # services.scx.enable = true;
  # services.scx.scheduler = "scx_lavd";
  services.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  services.packagekit.enable = true;
  fonts.enableDefaultPackages = true;
  hardware.xpadneo.enable = false;
  services.fwupd.enable = true;
  environment.systemPackages = with pkgs; [
    lsfg-vk-ui
    lsfg-vk
    mangohud
    vim
    vulkan-tools
    kdePackages.discover
    amdgpu_top
    steam-rom-manager
    prismlauncher
    # Gamecube / Wii
    dolphin-emu
    # PSX
    # TODO: Find replacement for PS1
    # duckstation
    # Dreamcast
    inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.flycast
    # Saturn
    # Currently Broken
    #yabause
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
      extraPkgs = pkgs: with pkgs; [liberation_ttf wqy_zenhei];
      extraLibraries = pkgs: [pkgs.xorg.libxcb];
    };
    extest.enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };

  services.xserver.displayManager.startx.enable = lib.mkForce false;
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
      allowedTCPPorts = [22];
    };
    wireless = {iwd = {enable = true;};};
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };
  # hardware = {
  #     graphics = {
  #         enable = true;
  #         enable32Bit = true;
  #     };
  #     amdgpu.amdvlk = {
  #         enable = true;
  #         support32Bit.enable = true;
  #     };
  # };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.input = {
    General = {
      UserspaceHID = true;
      ClassicBondedOnly = false;
      LEAutoSecurity = false;
    };
  };
  boot.kernelModules = [
    "hid_microsoft" # Xbox One Elite 2 controller driver preferred by Steam
    "uinput"
  ];
  # TODO: This is a hack. Check on this
  # https://github.com/ValveSoftware/steam-for-linux/issues/9310#issuecomment-2166248312
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "xbox-one-elite-2-udev-rules";
      text = ''KERNEL=="hidraw*", TAG+="uaccess"'';
      destination = "/etc/udev/rules.d/60-xbox-elite-2-hid.rules";
    })
  ];
  hardware.steam-hardware.enable = true;
  # jovian = {
  #   steamos.useSteamOSConfig = true;
  #   hardware.has.amd.gpu = true;
  # };
  jovian = {
    devices.steamdeck.enableKernelPatches = true;
    steamos.useSteamOSConfig = true;
    hardware.has.amd.gpu = true;
    decky-loader = {
      enable = true;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "steam";
      desktopSession = "plasma";
    };
  };
  jovian.steam.environment = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}";
    # We don't support adopting a drive, yet.
    STEAM_ALLOW_DRIVE_ADOPT = "0";
    # Ejecting doesn't work, either.
    STEAM_ALLOW_DRIVE_UNMOUNT = "1";
  };
  # Low-latency audio for HDMI output to soundbar
  # Reduces PipeWire buffer sizes to minimize audio delay
  services.pipewire.extraConfig.pipewire = {
    "10-game-console-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 1024;
      };
    };
  };
  services.pipewire.extraConfig.pipewire-pulse = {
    "10-game-console-low-latency" = {
      "pulse.properties" = {
        "pulse.min.req" = "512/48000";
        "pulse.default.req" = "512/48000";
        "pulse.min.quantum" = "512/48000";
      };
    };
  };
  services.pipewire.wireplumber.extraConfig = {
    "10-game-console-low-latency" = {
      "monitor.alsa.rules" = [
        {
          matches = [{"node.name" = "~alsa_output.*";}];
          actions = {
            update-props = {
              "api.alsa.period-size" = 512;
              "api.alsa.headroom" = 1024;
              # Prevent device from suspending (avoids re-sync delays)
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };
  # environment.etc."xdg/gamescope-session/environment".text = ''
  #   STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}"
  #   # We don't support adopting a drive, yet.
  #   STEAM_ALLOW_DRIVE_ADOPT = "0"
  #   # Ejecting doesn't work, either.
  #   STEAM_ALLOW_DRIVE_UNMOUNT = "1"
  #   steamargs = ("-steamos3" "-steampal" "-gamepadui")
  # '';
  # services.udev.extraRules = ''
  #   # If a GPU crash is caused by a specific process, kill the PID
  #   ACTION=="change", ENV{DEVNAME}=="/dev/dri/card0", ENV{RESET}=="1", ENV{PID}!="0", RUN+="${pkgs.util-linux}/bin/kill -9 %E{PID}"

  #   # Kill greetd and Gamescope if the GPU crashes and VRAM is lost
  #   ACTION=="change", ENV{DEVNAME}=="/dev/dri/card0", ENV{RESET}=="1", ENV{FLAGS}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart greetd"
  # '';
  # GameCube controller 8BitDo GameCube NGC Mod Kit over D-Input
  # environment.sessionVariables.SDL_GAMECONTROLLERCONFIG = "05000000c82d00006a28000000010000,8BitDo GameCube,a:b0,b:b3,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftstick:b13,lefttrigger:a5,leftx:a0,lefty:a1,paddle1:b9,paddle2:b8,rightshoulder:b10,rightstick:b14,righttrigger:a4,rightx:a2,righty:a3,start:b11,x:b1,y:b4,platform:Linux,";
}
