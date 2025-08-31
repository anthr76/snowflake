{
  lib,
  inputs,
  config,
  ...
}: {
  imports = [
    ../../personalities/server/default.nix
    ../../personalities/server/tailscale.nix
    ../../personalities/base
    ./disks.nix
    inputs.disko.nixosModules.disko
  ];
  networking.hostName = "fw1";
  networking.domain = "scr1.rabbito.tech";
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.router = {
    enable = true;
    domain = "scr1.rabbito.tech";
    udevRules = ''
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="20:7c:14:f8:4a:d5", NAME="lan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="20:7c:14:f8:4a:d0", NAME="wan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="20:7c:14:f8:4a:d1", NAME="oob"
    '';
    enableLan = true;
    lanInterface = "lan";
    lanSubnet = "192.168.1.0/24";
    lanAddress = "192.168.1.1";
    enableOob = true;
    oobInterface = "oob";
    oobSubnet = "10.10.10.0/24";
    oobAddress = "10.10.10.1";

    cloudflaredomains = [
      "fw1.scr1.rabbito.tech"
      "scr1.rabbito.tech"
    ];
    # TODO: Fixup
    tailscaleRoutes = [
      "192.168.8.0/24" # K8s
      "192.168.4.0/24" # Servers
      "10.20.99.0/24" # Management
      "192.168.6.0/24" # End users
    ];

    forwardZones = {
      "nwk3.rabbito.tech" = {
        forwarders = ["10.40.99.1"];
      };
      "nwk2.rabbito.tech" = {
        forwarders = ["10.30.99.1"];
      };
    };

    # Standard VLAN configuration
    vlans = [
      {
        id = 8;
        name = "kubernetes";
        subnet = "192.168.8.0/24";
        router = "192.168.8.1";
        enabled = true;
      }
      {
        id = 10;
        name = "servers";
        subnet = "192.168.4.0/24";
        router = "192.168.4.1";
      }
      {
        id = 99;
        name = "management";
        subnet = "10.20.99.0/24";
        router = "10.20.99.1";
      }
      {
        id = 100;
        name = "endusers";
        subnet = "192.168.6.0/24";
        router = "192.168.6.1";
      }
      {
        id = 101;
        name = "guests";
        subnet = "192.168.12.0/24";
        router = "192.168.12.1";
      }
    ];
  };
}
