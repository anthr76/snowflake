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

   # TODO: may be redundant
   # ./networking.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
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


  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.


  hardware.opengl = {
    enable = true;
  };
  hardware.opengl.driSupport = true;
  services.hardware.bolt.enable = true;
}
