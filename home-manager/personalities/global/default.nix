{ outputs, pkgs, lib, ... }: {
  imports = [ ../cli ] ++ (builtins.attrValues outputs.homeManagerModules);
  home.activation = {
   reportChanges  = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.home-manager}/bin/home-manager generations | ${pkgs.coreutils}/bin/head -n 2 | ${pkgs.coreutils}/bin/bin/cut -d' ' -f 7 | ${pkgs.coreutils}/bin/tac | ${pkgs.findutils}/bin/xargs ${pkgs.nvd}/bin/nvd diff
    '';
  };
}
