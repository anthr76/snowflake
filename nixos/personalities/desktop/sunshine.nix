{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = [pkgs.xvfb-run pkgs.xwayland-run];
  users.users = {
    sunshine = {
      isNormalUser = true;
      initialPassword = "suneshine";
      linger = true;
      extraGroups = ["wheel" "networkmanager" "input" "video" "sound"];
    };
  };
  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${pkgs.sunshine}/bin/sunshine";
  };
  services.avahi.publish.userServices = true;
  boot.kernelModules = ["uinput"];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
  '';

  # systemd.user.services.sunshine = {
  #   description = "A self-hosted game stream server for Moonlight(Client)";
  #   after = ["graphical-session-pre.target"];
  #   wants = ["graphical-session-pre.target"];
  #   wantedBy = ["graphical-session.target"];
  #   startLimitIntervalSec = 500;
  #   startLimitBurst = 5;

  #   serviceConfig = {
  #     ExecStart = "${config.security.wrapperDir}/sunshine";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #   };
  # };

  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 47984;
        to = 48010;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48010;
      }
    ];
  };
}
