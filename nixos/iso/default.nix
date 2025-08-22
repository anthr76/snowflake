{
  pkgs,
  lib,
  ...
}: {
  systemd.services.sshd.wantedBy = lib.mkForce ["multi-user.target"];

  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../../home-manager/users/anthony/yubi.pub)
    (builtins.readFile ../../home-manager/users/anthony/lattice_tpm2.pub)
    (builtins.readFile ../../home-manager/users/anthony/f80_tpm2.pub)
  ];

  users.users.root.initialHashedPassword = lib.mkForce null;
  users.users.root.password = lib.mkForce "root";

  services.getty.autologinUser = lib.mkForce "root";

  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    accept-flake-config = true;
  };

  system.stateVersion = "25.11";

  boot.kernelParams = ["console=ttyS0,115200" "console=tty1"];
  services.getty.extraArgs = ["--keep-baud" "115200,38400,9600"];
  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = ["getty.target"];
    serviceConfig.Restart = "always";
  };

  systemd = {
    enableEmergencyMode = false;
    settings = {
      Manager = {
        RebootWatchdogSec = "30s";
        RuntimeWatchdogSec = "20s";
      };
    };
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    rsync
    lsof
    pciutils
    usbutils
    disko
    ethtool
    nh
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = lib.mkForce true; # Enable password auth too
    };
  };

  programs.bash.loginShellInit = ''
    # Only show banner for interactive sessions
    if [[ $- == *i* ]]; then
      echo ""
      echo "======================================="
      echo "        NixOS Installation ISO"
      echo "======================================="
      echo "Hostname: $(hostname)"
      echo "Kernel: $(uname -r)"
      echo ""

      # Wait for network interfaces to get IP addresses (max 30 seconds)
      echo "Waiting for network configuration..."
      for i in {1..30}; do
        if ip addr show | grep -q "inet.*scope global"; then
          break
        fi
        sleep 1
        echo -n "."
      done
      echo ""

      echo "Network Interfaces:"
      ip addr show | grep -E "^[0-9]+:|inet " | sed 's/^/  /'
      echo ""
      echo "SSH is enabled on port 22"
      echo "Root password: root"
      echo "======================================="
      echo ""
    fi
  '';
}
