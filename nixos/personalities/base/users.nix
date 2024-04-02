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
      extraGroups = [ "wheel" ]
        ++ ifTheyExist [ "tss" "networkmanager" "scanner" "lp" "gamemode" ];
      hashedPasswordFile = config.sops.secrets.anthony-password.path;
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../../../home-manager/users/anthony/yubi.pub)
        (builtins.readFile ../../../home-manager/users/anthony/e39_tpm2.pub)
      ];
    };
  };
  sops.secrets.anthony-password = {
    sopsFile = ../../../secrets/users.yaml;
    neededForUsers = true;
  };
}
