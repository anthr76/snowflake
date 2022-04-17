{ self, config, lib, pkgs, ... }:
let inherit (lib) fileContents;
in
{
  # Sets nrdxp.cachix.org binary cache which just speeds up some builds
  imports = [ ../cachix ];

  # For rage encryption, all hosts need a ssh key pair
  services.openssh = {
    enable = true;
    openFirewall = lib.mkDefault false;
  };


  # This is just a representation of the nix default
  nix.systemFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];

  environment = {

    # Selection of sysadmin tools that can come in handy
    systemPackages = with pkgs; [
      binutils
      coreutils
      curl
      direnv
      dnsutils
      dosfstools
      fd
      git
      bottom
      gptfdisk
      iputils
      jq
      manix
      moreutils
      nix-index
      nmap
      ripgrep
      skim
      tealdeer
      usbutils
      utillinux
      whois
    ];
  };

  nix = {

    # Improve nix store disk usage
    autoOptimiseStore = true;
    gc.automatic = true;
    optimise.automatic = true;

    # Prevents impurities in builds
    useSandbox = true;

    # give root and @wheel special privileges with nix
    trustedUsers = [ "root" "@wheel" ];

    # Generally useful nix option defaults
    extraOptions = ''
      min-free = 536870912
      keep-outputs = true
      keep-derivations = true
      fallback = true
    '';

  };

  # Service that makes Out of Memory Killer more effective
  services.earlyoom.enable = true;

}
