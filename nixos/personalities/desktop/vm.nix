{pkgs, ...}: {
  # FIXME: https://github.com/NixOS/nixpkgs/issues/359723
  environment.systemPackages = [pkgs.quickemu];
  services.spice-vdagentd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  boot.kernelParams = [
    "kvm.ignore_msrs=1"
  ];
}
