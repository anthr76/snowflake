{ outputs, ... }: {
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

  hardware.enableRedistributableFirmware = true;
  environment.enableAllTerminfo = true;
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];

}
