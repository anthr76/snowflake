# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };
  imports = [
    ./serial.nix
  ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
  };
  services.openssh.banner = ''
    WARNING:  Unauthorized access to this system is forbidden and will be
    prosecuted by law. By accessing this system, you agree that your actions
    may be monitored if unauthorized usage is suspected.
  '';
  boot.kernelPackages = pkgs.linuxPackages_cachyos-server;
  services.scx.enable = true;
  services.scx.scheduler = "scx_bpfland";
  systemd = {
    enableEmergencyMode = false;
    settings = {
      Manager = {
        RebootWatchdogSec = "30s";
        RuntimeWatchdogSec = "20s";
      };
    };
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };
  # use TCP BBR has significantly increased throughput and reduced latency for connections
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # Show failed systemd units on login
  programs.bash.interactiveShellInit = ''
    # Show failed systemd units if any
    if systemctl --failed --quiet --no-legend | grep -q .; then
      echo -e "\n\033[1;31mFailed systemd units:\033[0m"
      systemctl --failed --no-legend
      echo ""
    fi
  '';
  programs.fish.interactiveShellInit = ''
    # Show failed systemd units if any
    if systemctl --failed --quiet --no-legend | string length -q
      echo -e "\n\033[1;31mFailed systemd units:\033[0m"
      systemctl --failed --no-legend
      echo ""
    end
  '';
  programs.zsh.interactiveShellInit = ''
    # Show failed systemd units if any
    if systemctl --failed --quiet --no-legend | grep -q .; then
      echo -e "\n\033[1;31mFailed systemd units:\033[0m"
      systemctl --failed --no-legend
      echo ""
    fi
  '';
}
