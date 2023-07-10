{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    ./sops.nix
    ./fish.nix
    ./nix.nix
    ./users.nix
    ./openssh.nix
    ./podman.nix
    ./systemd-initrd.nix
    ./zram.nix
    ./polkit.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

}
