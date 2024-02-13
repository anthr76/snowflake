{ inputs, lib, ... }:
{
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
        ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      ];
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
      flake-registry = ""; # Disable global flake registry
    };
  };
}
