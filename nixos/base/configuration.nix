
{ inputs, outputs, lib, config, pkgs, ... }: {
  users.users = {
    anthony = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLhz2vRJ9Jaonksg5hQME2MWSQf8zriDMkPVuylZiF1eq+WTnqYMOiUABhJcG5sI45cfqmpeY3l/GarIV8tRd/Q= hello@anthonyrabbito.com'
      ];
      extraGroups = [ "wheel" ];
    };
  };
}
