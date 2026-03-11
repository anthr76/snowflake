{
  outputs,
  lib,
  pkgs,
  ...
}: let
  hostnames = builtins.attrNames outputs.nixosConfigurations;
in {
  # TODO: Enable in new release.
  # services.ssh-agent.enable = true;
  home.packages = with pkgs; [
    openssh
  ];
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = lib.hm.dag.entryAfter ["net"] {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      net = {
        host = builtins.concatStringsSep " " hostnames;
        forwardAgent = true;
      };
      trusted = lib.hm.dag.entryBefore ["net"] {
        host = "rabbito.tech *.nwk3.rabbito.tech *.nwk2.rabbito.tech *.qgr1.rabbito.tech";
        forwardAgent = true;
      };
    };
  };
}
