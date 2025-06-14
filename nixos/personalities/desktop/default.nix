# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ pkgs, outputs, inputs, ... }: {
  # You can import other NixOS modules here
  imports = [
    ../base
    ./audio.nix
    ./networking.nix
    ./print.nix
    ../physical
    ./gaming.nix
    ./geoclue.nix
    ./vm.nix

    # TODO: may be redundant
    # ./networking.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.flake-inputs

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

  hardware.graphics = { enable = true; };
  hardware.amdgpu.opencl.enable = true;
  hardware.graphics.extraPackages = [
    pkgs.mesa.opencl
    pkgs.rocmPackages.clr.icd
  ];
  services.hardware.bolt.enable = true;
  services.flatpak.enable = true;
}
