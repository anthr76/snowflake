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
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
      flake-registry = ""; # Disable global flake registry
    };
  };
}
