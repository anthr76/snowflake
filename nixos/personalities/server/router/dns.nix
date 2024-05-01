{ pkgs, ... }:{
  services.coredns = {
    enable = true;
    # https://github.com/NixOS/nixpkgs/issues/307750
    package = pkgs.coredns-snowflake;
  };
}
