{ outputs, lib, ... }:
let
  hostnames = builtins.attrNames outputs.nixosConfigurations;
in
{
  # TODO: Enable in new release.
  # services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    matchBlocks = {
      net = {
        host = builtins.concatStringsSep " " hostnames;
        forwardAgent = true;
      };
      trusted = lib.hm.dag.entryBefore [ "net" ] {
        host = "rabbito.tech *.nwk3.rabbito.tech *.nwk2.rabbito.tech *.scr1.rabbito.tech";
        forwardAgent = true;
      };
    };
  };
}
