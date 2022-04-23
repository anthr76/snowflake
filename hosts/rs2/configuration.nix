{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "rs2";
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "America/New_York";
  #  environment.etc = {
  #    "sway/config.d/config-mon.conf".text = ''
  #      output "eDP-2" {
  #      scale 1.6
  #      }
  #    '';
  #  };
  networking.useDHCP = false;
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    # TODO: Clean the tech debt
    pinentry-curses
    pcsclite
    pcsctools
    sops
    age
  ];
  system.stateVersion = "21.11";
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}

