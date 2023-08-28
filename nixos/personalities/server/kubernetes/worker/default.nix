{
  imports = [
    ../default.nix
  ];
  services.kubernetes.roles = ["node"];
}
