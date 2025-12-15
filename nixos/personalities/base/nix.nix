{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: {
  nix = {
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = ["nixpkgs=${inputs.nixpkgs.outPath}"];
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    settings = {
      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://snowflake.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://ai.cachix.org"
        "https://catppuccin.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "snowflake.cachix.org-1:p9pP30w7PFDuzkJ2v4TQ446cXLUglrnBUhN6tUzp2sA="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
        "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      ];
      trusted-users = ["root" "@wheel"];
      builders-use-substitutes = true;
      auto-optimise-store = lib.mkDefault true;
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
      flake-registry = ""; # Disable global flake registry
    };
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "x86_64-linux";
        maxJobs = 100;
        supportedFeatures = ["benchmark" "big-parallel"];
      }
    ];
  };
  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      ServerAliveInterval 60
      IPQoS throughput
      IdentityFile ${config.sops.secrets.nixbuild-ssh-key.path}
  '';

  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = ["eu.nixbuild.net"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };
  sops.secrets.nixbuild-ssh-key = {
    sopsFile = ../../../secrets/users.yaml;
    mode = "0600";
  };
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      if [[ -e /run/current-system ]]; then
        echo "--- diff to current-system"
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig"
        echo "---"
      fi
    '';
  };
  # For nixos-rebuild build-vm
  virtualisation.vmVariant = {
    virtualisation.sharedDirectories = {
      keys = {
        source = "/etc/ssh";
        target = "/etc/ssh";
      };
    };
  };
  programs.nh = {
    enable = true;
    flake = "github:anthr76/snowflake";
    clean = {
      enable = true;
      extraArgs = "--keep 5";
    };
  };
}
