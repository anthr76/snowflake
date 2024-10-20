{ pkgs, inputs, lib, outputs, ... }:
{
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
    nix = {
      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well, awesome!
      nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      package = pkgs.nix;
      gc = {
        automatic = true;
        interval = {
          Day = 7;
        };
        # Keep the last 3 generations
        # TODO: Figure out how to GC generations instead of time frame this is broken
        # https://github.com/NixOS/nixpkgs/issues/282884
        # options = "--delete-older-than +3";
      };
      settings = {
        trusted-users = [ "root" "@admin" ];
        builders-use-substitutes = true;
        auto-optimise-store = lib.mkDefault true;
        experimental-features = [ "nix-command" "flakes" ];
        warn-dirty = false;
        flake-registry = ""; # Disable global flake registry
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
      };
    };
    services.nix-daemon.enable = true;
}
