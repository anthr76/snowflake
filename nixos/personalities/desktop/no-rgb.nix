{ pkgs, ... }: {
  config = {
    services.udev.packages = [ pkgs.openrgb ];
    boot.kernelModules = [ "i2c-dev" ];
    hardware.i2c.enable = true;

    # systemd.services.no-rgb = {
    #   description = "no-rgb";
    #   serviceConfig = {
    #     ExecStart = "${no-rgb}/bin/no-rgb";
    #     Type = "oneshot";
    #   };
    #   wantedBy = [ "multi-user.target" ];
    # };
  };
}

