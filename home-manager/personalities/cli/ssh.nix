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
    settings = {
      "*" = lib.hm.dag.entryAfter ["net"] {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      net = {
        header = "Host ${builtins.concatStringsSep " " hostnames}";
        ForwardAgent = true;
      };
      trusted = lib.hm.dag.entryBefore ["net"] {
        header = "Host rabbito.tech *.nwk3.rabbito.tech *.nwk2.rabbito.tech *.qgr1.rabbito.tech";
        ForwardAgent = true;
      };
    };
  };
}
