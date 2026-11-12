# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  config,
  outputs,
  lib,
  inputs,
  ...
}: {
  imports = [../../personalities/global inputs.sops-nix.homeManagerModules.sops];
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
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home.file.".ssh/lattice_tpm2.pub".text = builtins.readFile ./lattice_tpm2.pub;
  home.file.".ssh/f80_tpm2.pub".text = builtins.readFile ./f80_tpm2.pub;
  home.file.".ssh/yubi.pub".text = builtins.readFile ./yubi.pub;

  # Trust every key we sign with so `git log --show-signature` can verify locally.
  home.file.".ssh/allowed_signers".text = let
    signer = pub: let
      parts = lib.splitString " " (lib.trim (builtins.readFile pub));
    in "${config.programs.git.settings.user.email} namespaces=\"git\" ${builtins.elemAt parts 0} ${builtins.elemAt parts 1}";
  in
    lib.concatMapStrings (pub: signer pub + "\n") [
      ./yubi.pub
      ./lattice_tpm2.pub
      ./f80_tpm2.pub
      ./mbp.pub
      ./studio.pub
    ];
  programs.git.settings.gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";

  # Add stuff for your user as you see fit:
  # home.packages = with pkgs; [ steam ];

  home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

  # Enable home-manager and git
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = lib.mkDefault "23.05";
}
