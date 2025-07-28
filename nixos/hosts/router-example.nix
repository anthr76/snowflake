# Router Module Usage Example
#
# This example shows how to use the new router module to configure
# a standardized router setup with the 4 required VLANs plus optional Kubernetes VLAN.

{
  inputs,
  ...
}:
{
  imports = [
    ./disks.nix
    inputs.disko.nixosModules.disko
  ];

  networking.hostName = "fw1";
  networking.domain = "example.rabbito.tech";

  # Hardware configuration (customize for your hardware)
  boot.initrd.availableKernelModules = [
    "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";

  # Enable the router module
  services.router = {
    enable = true;
    domain = "example.rabbito.tech";

    # Interface naming rules (customize MAC addresses for your hardware)
    udevRules = ''
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:ff", NAME="lan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:fe", NAME="wan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:fd", NAME="oob"
    '';

    # Enable LAN interface (trunk port for VLANs + base network)
    enableLan = true;
    lanInterface = "lan";
    lanSubnet = "192.168.1.0/24";
    lanAddress = "192.168.1.1";

    # Enable OOB management interface (emergency access)
    enableOob = true;
    oobInterface = "oob";
    oobSubnet = "10.10.10.0/24";
    oobAddress = "10.10.10.1";

    # Cloudflare domains to update
    cloudflaredomains = [
      "fw-1.example.rabbito.tech"
      "example.rabbito.tech"
    ];

    # Routes to advertise via Tailscale
    tailscaleRoutes = [
      "192.168.20.0/24"  # End users
      "192.168.21.0/24"  # Servers
      "10.50.99.0/24"    # Management
    ];

    # DNS forward zones for other networks
    forwardZones = {
      "other-network.rabbito.tech" = {
        forwarders = [ "10.60.99.1" ];
      };
    };

    # Standard VLAN configuration
    vlans = [
      {
        id = 8;
        name = "kubernetes";
        subnet = "192.168.22.0/24";
        router = "192.168.22.1";
        enabled = true;  # Set to false if Kubernetes VLAN not needed
      }
      {
        id = 10;
        name = "servers";
        subnet = "192.168.21.0/24";
        router = "192.168.21.1";
      }
      {
        id = 99;
        name = "management";
        subnet = "10.50.99.0/24";
        router = "10.50.99.1";
      }
      {
        id = 100;
        name = "endusers";
        subnet = "192.168.20.0/24";
        router = "192.168.20.1";
      }
      {
        id = 101;
        name = "guests";
        subnet = "192.168.23.0/24";
        router = "192.168.23.1";
      }
    ];
  };
}
