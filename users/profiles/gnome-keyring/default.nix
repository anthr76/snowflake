{ pkgs, lib, ... }: {
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };
}
