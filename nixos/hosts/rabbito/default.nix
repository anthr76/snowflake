{lib, ...}: {
  imports = [
    ../../personalities/base
    ../../personalities/server
    ./minecraft.nix
    ./palworld.nix
  ];

  networking.hostName = "rabbito";
  networking.domain = "vms.rabbito.tech";
  system.stateVersion = "26.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # Mirrors the layout microvm.nix builds for us. Only /nix/.rw-store (vdb) and
  # /var/lib/scratch (vda) survive a reboot -- / is a tmpfs.
  fileSystems = {
    "/" = {
      device = "rootfs";
      fsType = "tmpfs";
      options = ["x-initrd.mount" "size=50%" "mode=0755"];
    };
    "/nix/.ro-store" = {
      device = "ro-store";
      fsType = "virtiofs";
      options = [
        "x-initrd.mount"
        "defaults"
        "x-systemd.after=systemd-modules-load.service"
      ];
      neededForBoot = true;
    };
    "/nix/.rw-store" = {
      device = "/dev/vdb";
      fsType = "ext4";
      options = ["x-initrd.mount"];
      neededForBoot = true;
    };
    "/nix/store" = {
      device = "overlay";
      fsType = "overlay";
      options = [
        "lowerdir=/sysroot/nix/.ro-store"
        "upperdir=/sysroot/nix/.rw-store/store"
        "workdir=/sysroot/nix/.rw-store/work"
        "x-initrd.mount"
        "x-systemd.requires-mounts-for=/sysroot/nix/.ro-store"
        "x-systemd.requires-mounts-for=/sysroot/nix/.rw-store/store"
        "x-systemd.requires-mounts-for=/sysroot/nix/.rw-store/work"
      ];
    };
    "/var/lib/scratch" = {
      device = "/dev/vda";
      fsType = "ext4";
    };
  };

  networking.networkmanager.enable = lib.mkForce false;
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-mgmt" = {
      matchConfig.MACAddress = "02:00:00:00:00:01";
      address = ["10.100.0.2/24"];
      gateway = ["10.100.0.1"];
      dns = ["10.100.0.1"];
      networkConfig.DHCP = "no";
    };
  };

  # / is a tmpfs, so the host keys sops derives its age identity from have to
  # live on the one disk that persists.
  services.openssh.hostKeys = lib.mkForce [
    {
      path = "/var/lib/scratch/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/var/lib/scratch/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../../../home-manager/users/anthony/yubi.pub)
    (builtins.readFile ../../../home-manager/users/anthony/lattice_tpm2.pub)
    (builtins.readFile ../../../home-manager/users/anthony/f80_tpm2.pub)
    (builtins.readFile ../../../home-manager/users/anthony/studio.pub)
    (builtins.readFile ../../../home-manager/users/anthony/mbp.pub)
  ];

  services.scx.enable = lib.mkForce false;

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.trustedInterfaces = ["tailscale0"];
}
