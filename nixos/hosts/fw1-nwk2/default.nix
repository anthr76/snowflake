{
  inputs,
  ...
}:
{
  imports = [
    ./disks.nix
    ../../personalities/server/default.nix
    ../../personalities/server/tailscale.nix
    ../../personalities/base
    inputs.disko.nixosModules.disko
  ];

  networking.hostName = "fw1";
  networking.domain = "nwk2.rabbito.tech";

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";
  services.router = {
    enable = true;
    domain = "nwk2.rabbito.tech";

    udevRules = ''
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:27:82:e9", NAME="lan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:27:82:e8", NAME="wan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:27:82:ea", NAME="oob"
    '';
    enableOob = true;
    oobInterface = "oob";
    oobSubnet = "10.10.10.0/24";
    oobAddress = "10.10.10.1";
    enableLan = true;
    lanInterface = "lan";
    lanSubnet = "192.168.1.0/24";
    lanAddress = "192.168.1.1";

    cloudflaredomains = [
      "fw1.nwk2.rabbito.tech"
      "nwk2.rabbito.tech"
    ];

    tailscaleRoutes = [
      "192.168.11.0/24"
      "10.30.99.0/24"
      "192.168.7.0/24"
    ];

    forwardZones = {
      "nwk3.rabbito.tech" = {
        forwarders = [ "10.40.99.1" ];
      };
    };

    vlans = [
      {
        id = 8;
        name = "kubernetes";
        subnet = "192.168.15.0/24";
        router = "192.168.15.1";
      }
      {
        id = 10;
        name = "servers";
        subnet = "192.168.7.0/24";
        router = "192.168.7.1";
      }
      {
        id = 99;
        name = "management";
        subnet = "10.30.99.0/24";
        router = "10.30.99.1";
      }
      {
        id = 100;
        name = "endusers";
        subnet = "192.168.11.0/24";
        router = "192.168.11.1";
      }
      {
        id = 101;
        name = "guests";
        subnet = "192.168.5.0/24";
        router = "192.168.5.1";
      }
    ];
  };
}
