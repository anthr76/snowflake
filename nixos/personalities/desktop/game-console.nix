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
    # inputs.jovian-nixos.nixosModules.default
  ];
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.enable = true;
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
    inputs.jovian-nixos.legacyPackages.${pkgs.system}.mangohud
  ];
  boot.plymouth = {
    enable = true;
    theme = "steamos";
    themePackages = [
      inputs.jovian-nixos.legacyPackages.${pkgs.system}.steamdeck-hw-theme
    ];
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
  jovian = {
    decky-loader.enable = true;
    devices.steamdeck.enableKernelPatches = true;
    steam = {
      enable = true;
      autoStart = true;
      user = "steam";
      desktopSession = "plasmawayland";
    };
    steamos = {
      enableBluetoothConfig = true;
      enableProductSerialAccess = true;
      enableSysctlConfig = true;
      enableMesaPatches = true;
    };
  };
}
