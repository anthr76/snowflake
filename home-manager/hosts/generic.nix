{ pkgs, ... }:
{
  imports = [ ../users/anthony ../users/anthony/linux.nix ];

  systemd.user.services.auto-home-update = {
    Unit = {
      Description = "Automatic Home Manager update via nh";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.nh}/bin/nh home switch --no-nom -c anthony@generic github:anthr76/snowflake/stable";
      Restart = "on-failure";
      RestartSec = "300";
    };
  };

  systemd.user.timers.auto-home-update = {
    Unit = {
      Description = "Weekly Home Manager auto-update timer";
      Requires = [ "auto-home-update.service" ];
    };
    Timer = {
      OnCalendar = "Sun *-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "1800";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
