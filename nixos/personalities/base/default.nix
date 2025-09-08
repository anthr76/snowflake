{
  outputs,
  ...
}: {
  imports =
    [
      ./sops.nix
      ./fish.nix
      ./nix.nix
      ./users.nix
      ./openssh.nix
      ./docker.nix
      ./zram.nix
      ./polkit.nix
      ./bootloader.nix
      ./networking.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);
}
