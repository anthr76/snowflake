{ hmUsers, pkgs, config, ... }: {
  home-manager.users = { inherit (hmUsers) anthonyjrabbito; };
  users.defaultUserShell = pkgs.fish;
  users.users.anthonyjrabbito = {
    description = "default";
    isNormalUser = true;
    group = "anthonyjrabbito";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = (builtins.filter builtins.isString
      (builtins.split "\n" (builtins.readFile (builtins.fetchurl {
        url = "https://github.com/anthr76.keys";
        sha256 = "ac89c011ed2105c9437c8ab055c1eb5796b842d6b04869d150fb6ef26b3e2bfd";
      }))));
  };
}

