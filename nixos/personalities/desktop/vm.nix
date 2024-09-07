{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.quickemu ];
  services.spice-vdagentd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  boot.kernelParams = [
    "kvm.ignore_msrs=1"
  ];
}
