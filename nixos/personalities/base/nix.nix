{ inputs, lib, pkgs, config, ... }: {
  systemd.services.nix-daemon.serviceConfig.LimitNOFILE =
    lib.mkForce 4096000000;
  nix = {
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    gc = {
      automatic = true;
      dates = "weekly";
      # Keep the last 3 generations
      options = "--delete-older-than +3";
    };
    settings = {
      substituters = [
        "https://hyprland.cachix.org"
        # KDE2Nix
        "https://nix-community.cachix.org"
        # Chaotic Nyx
        "https://nyx.chaotic.cx/"
        # Snowflake
        "https://snowflake.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "snowflake.cachix.org-1:p9pP30w7PFDuzkJ2v4TQ446cXLUglrnBUhN6tUzp2sA="
      ];
      trusted-users = [ "root" "@wheel" ];
      builders-use-substitutes = true;
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
      flake-registry = ""; # Disable global flake registry
    };
    distributedBuilds = true;
    buildMachines = [{
      hostName = "eu.nixbuild.net";
      system = "x86_64-linux";
      maxJobs = 100;
      supportedFeatures = [ "benchmark" "big-parallel" ];
    }];
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
      hostNames = [ "eu.nixbuild.net" ];
      publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };
  sops.secrets.nixbuild-ssh-key = {
    sopsFile = ../../../secrets/users.yaml;
    mode = "0600";
  };
  system = {
    # Enable printing changes on nix build etc with nvd
    activationScripts.report-changes = ''
      ${pkgs.nvd}/bin/nvd ${pkgs.diffutils}/bin/diff $(${pkgs.coreutils}/bin/ls -dv /nix/var/nix/profiles/system-*-link | ${pkgs.coreutils}/bin/tail -2)
    '';
  };
}
