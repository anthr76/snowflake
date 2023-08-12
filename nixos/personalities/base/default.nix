{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    ./sops.nix
    ./fish.nix
    ./nix.nix
    ./users.nix
    ./openssh.nix
    ./podman.nix
    ./zram.nix
    ./polkit.nix
    ./bootloader.nix
    ./networking.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

}
