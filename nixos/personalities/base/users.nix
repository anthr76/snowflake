{ pkgs, config, ... }:
{
  users.mutableUsers = false;
  users.users = {
    anthony = {
      isNormalUser = true;
      shell = pkgs.fish;
      passwordFile = config.sops.secrets.anthony-password.path;
      openssh.authorizedKeys.keys = (builtins.filter builtins.isString
        (builtins.split "\n" (builtins.readFile (builtins.fetchurl {
          url = "https://github.com/anthr76.keys";
          sha256 = "1hflxw0a11sq8p7bnmp8rhzixhh8rdigk9531z99f5i0izkf9a5a";
        }))));
      extraGroups = [ "wheel" ];
    };
  };
  sops.secrets.anthony-password = {
    sopsFile = ../../../secrets/users.yaml;
    neededForUsers = true;
  };
}
