{ lib, modulesPath, ... }:
{
  imports = [
    ../personalities/base/nix.nix
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

  ];
  # TODO: Make multi-arch
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  users.users.nixos.initialHashedPassword = lib.mkForce "$y$j9T$xZjggTS7XleoEC5btC4zE1$CilddAoe5u/kUX9moORH9SKGNN.jzXmR9dfx8zBk6GD";
}
