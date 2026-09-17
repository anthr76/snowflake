{lib, ...}: {
  imports = [
    ../../personalities/base
    ../../personalities/server
    ../../personalities/server/tailscale.nix
    ./minecraft.nix
    ./palworld.nix
    ./satisfactory.nix
    ./backup.nix
  ];

  networking.hostName = "rabbito";
  networking.domain = "vms.rabbito.tech";
  system.stateVersion = "26.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # microvm.nix disables grub but not systemd-boot, which base enables;
  # without this an in-guest nixos-rebuild fails installing to a missing /boot.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  microvm = {
    hypervisor = "cloud-hypervisor";
    vcpu = 64;
    mem = 131072;

    machineId = "e7855a0f-3cd7-479f-bbe8-6a096a258ac0";

    vsock = {
      cid = 3;
      ssh.enable = true;
    };

    writableStoreOverlay = "/nix/.rw-store";

    volumes = [
      {
        image = "root.img";
        mountPoint = "/";
        size = 512000;
      }
      {
        image = "scratch.img";
        mountPoint = "/var/lib/scratch";
        size = 512000;
      }
      {
        image = "nix-store-overlay.img";
        mountPoint = "/nix/.rw-store";
        size = 32768;
      }
    ];

    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];

    interfaces = [
      {
        type = "tap";
        id = "vm-rabbito";
        mac = "02:00:00:00:00:01";
      }
    ];
  };

  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = false;
  systemd.network.networks."10-mgmt" = {
    matchConfig.MACAddress = "02:00:00:00:00:01";
    address = ["10.100.0.2/24"];
    gateway = ["10.100.0.1"];
    dns = ["10.100.0.1"];
    networkConfig.DHCP = "no";
  };

  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../../../home-manager/users/anthony/yubi.pub)
    (builtins.readFile ../../../home-manager/users/anthony/lattice_tpm2.pub)
    (builtins.readFile ../../../home-manager/users/anthony/f80_tpm2.pub)
    (builtins.readFile ../../../home-manager/users/anthony/studio.pub)
    (builtins.readFile ../../../home-manager/users/anthony/mbp.pub)
  ];

  nix.settings.auto-optimise-store = false;
  nix.optimise.automatic = false;
  services.scx.enable = lib.mkForce false;

  networking.firewall.trustedInterfaces = ["tailscale0"];
}
