{ outputs, ... }: {
  imports = [ ../cli ] ++ (builtins.attrValues outputs.homeManagerModules);
}
