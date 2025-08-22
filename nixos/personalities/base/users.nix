{ pkgs, config, ... }:
let
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users = {
    anthony = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [ "wheel" "dialout" ]
        ++ ifTheyExist [ "tss" "networkmanager" "scanner" "lp" "gamemode" ];
      hashedPasswordFile = config.sops.secrets.anthony-password.path;
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../../../home-manager/users/anthony/yubi.pub)
        (builtins.readFile ../../../home-manager/users/anthony/lattice_tpm2.pub)
        (builtins.readFile ../../../home-manager/users/anthony/f80_tpm2.pub)
      ];
    };
  };
  sops.secrets.anthony-password = {
    sopsFile = ../../../secrets/users.yaml;
    neededForUsers = true;
  };
}
