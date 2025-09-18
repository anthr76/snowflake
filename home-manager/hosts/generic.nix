{ ... }:
{
  imports = [ ../users/anthony ../users/anthony/linux.nix ];

  services.home.autoUpgrade = {
    enable = true;
    serviceName = "auto-home-update";
    description = "Automatic Home Manager upgrade";
    flake = "github:anthr76/snowflake/stable";
    configuration = "anthony@generic";
    timer = {
      onCalendar = "Sun *-*-* 03:00:00";
      randomizedDelaySec = "1800";
      persistent = true;
    };
  };
}
