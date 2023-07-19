{ inputs, lib, pkgs, config, outputs, ... }:
{
  imports = [
    ../cli
  ] ++ (builtins.attrValues outputs.homeManagerModules);
}
