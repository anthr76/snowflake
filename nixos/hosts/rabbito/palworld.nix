{pkgs, ...}: let
  dataDir = "/var/lib/scratch/palworld";
  serverDir = "${dataDir}/server";
  # Palworld Dedicated Server on Steam.
  appId = "2394010";
in {
  users.users.palworld = {
    description = "Palworld dedicated server service user";
    isSystemUser = true;
    group = "palworld";
    home = dataDir;
    createHome = true;
  };
  users.groups.palworld = {};

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 palworld palworld -"
    "d ${serverDir} 0750 palworld palworld -"
  ];

  # Not packaged in nixpkgs: the server is a proprietary Unreal build fetched
  # from Steam at runtime and executed under the Steam FHS environment.
  systemd.services.palworld = {
    description = "Palworld Dedicated Server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];

    environment = {
      HOME = dataDir;
      # PalServer-Linux-Shipping dlopen()s the shipped Steam libs by bare name.
      LD_LIBRARY_PATH = "${serverDir}/linux64:${serverDir}/Pal/Binaries/Linux";
    };

    serviceConfig = {
      User = "palworld";
      Group = "palworld";
      WorkingDirectory = serverDir;
      Restart = "on-failure";
      RestartSec = 30;
      # The first install pulls ~8G from Steam.
      TimeoutStartSec = "60min";
      # Unreal flushes saves on SIGINT; SIGTERM loses the last autosave window.
      KillSignal = "SIGINT";
      TimeoutStopSec = "90s";
    };

    preStart = ''
      ${pkgs.steamcmd}/bin/steamcmd \
        +force_install_dir ${serverDir} \
        +login anonymous \
        +app_update ${appId} validate \
        +quit

      # The binary looks for the Steam SDK at this fixed path under $HOME.
      sdk="$(find ${dataDir}/.local/share/Steam ${serverDir} \
        -name steamclient.so -path '*linux64*' 2>/dev/null | head -n1)"
      if [ -n "$sdk" ]; then
        mkdir -p ${dataDir}/.steam/sdk64
        ln -sf "$sdk" ${dataDir}/.steam/sdk64/steamclient.so
      fi

      # Steam ships an empty PalWorldSettings.ini; seeding it from the defaults
      # is the documented first-run step. Edits made afterwards are preserved.
      cfgDir="${serverDir}/Pal/Saved/Config/LinuxServer"
      if [ -f "$cfgDir/PalWorldSettings.ini" ] && [ ! -s "$cfgDir/PalWorldSettings.ini" ] \
        && [ -f "${serverDir}/DefaultPalWorldSettings.ini" ]; then
        cp "${serverDir}/DefaultPalWorldSettings.ini" "$cfgDir/PalWorldSettings.ini"
      fi
    '';

    script = ''
      exec ${pkgs.steam-run}/bin/steam-run ${serverDir}/PalServer.sh \
        -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS
    '';
  };

  networking.firewall = {
    # 8211 is the game port; 27015 is the Steam query port.
    allowedUDPPorts = [8211 27015];
  };
}
