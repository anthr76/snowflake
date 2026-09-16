{pkgs, ...}: let
  dataDir = "/var/lib/scratch/satisfactory";
  serverDir = "${dataDir}/server";
  # Satisfactory Dedicated Server on Steam.
  appId = "1690800";

  prepare = pkgs.writeShellScript "satisfactory-prepare" ''
    set -euo pipefail

    # +login must precede +force_install_dir: the other order makes steamcmd
    # fail a fresh install with "Missing configuration".
    ${pkgs.steamcmd}/bin/steamcmd \
      +login anonymous \
      +force_install_dir ${serverDir} \
      +app_update ${appId} validate \
      +quit

    # The binary looks for the Steam SDK at this fixed path under $HOME.
    sdk="$(find ${dataDir}/.local/share/Steam ${serverDir} \
      -name steamclient.so -path '*linux64*' 2>/dev/null | head -n1)"
    if [ -n "$sdk" ]; then
      mkdir -p ${dataDir}/.steam/sdk64
      ln -sf "$sdk" ${dataDir}/.steam/sdk64/steamclient.so
    fi
  '';

  start = pkgs.writeShellScript "satisfactory-start" ''
    exec ${pkgs.steam-run}/bin/steam-run ${serverDir}/FactoryServer.sh -log -unattended
  '';
in {
  # Not packaged in nixpkgs: the server is a proprietary Unreal build fetched
  # from Steam at runtime and executed under the Steam FHS environment.
  systemd.services.satisfactory = {
    description = "Satisfactory Dedicated Server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];

    environment = {
      # Saves and server config live under $HOME/.config/Epic/FactoryGame, so
      # this has to be the scratch disk rather than anthony's real home.
      HOME = dataDir;
      LD_LIBRARY_PATH = "${serverDir}/linux64:${serverDir}/Engine/Binaries/Linux";
    };

    serviceConfig = {
      User = "anthony";
      Group = "users";
      # '-' so a missing directory is not fatal: systemd chdirs here before
      # every Exec* line, including the one below that creates it.
      WorkingDirectory = "-${serverDir}";
      ExecStartPre = [
        # '+' runs this as root -- /var/lib/scratch is root-owned.
        "+${pkgs.coreutils}/bin/install -d -o anthony -g users -m 0750 ${dataDir} ${serverDir}"
        prepare
      ];
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 30;
      # The first install pulls ~15G from Steam.
      TimeoutStartSec = "60min";
      # Unreal flushes saves on SIGINT; SIGTERM loses the last autosave window.
      KillSignal = "SIGINT";
      TimeoutStopSec = "90s";
    };
  };

  networking.firewall = {
    # 1.0 dropped the old 15000/15777 pair: 7777 now carries both the game
    # traffic and the HTTPS API, and 8888 is reliable messaging.
    allowedTCPPorts = [7777 8888];
    allowedUDPPorts = [7777];
  };
}
