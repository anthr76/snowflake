{ hmUsers, pkgs, config, ... }:
{
  home-manager.users = { inherit (hmUsers) anthonyjrabbito; };
  users.defaultUserShell = pkgs.fish;
  users.users.anthonyjrabbito = {
    description = "default";
    isNormalUser = true;
    group = "anthonyjrabbito";
    extraGroups = [ "wheel" "networkmanager"];
  };
}

