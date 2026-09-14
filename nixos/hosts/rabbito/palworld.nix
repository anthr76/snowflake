{pkgs, ...}: let
  dataDir = "/var/lib/scratch/palworld";
  serverDir = "${dataDir}/server";
  # Palworld Dedicated Server on Steam.
  appId = "2394010";

  prepare = pkgs.writeShellScript "palworld-prepare" ''
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

    # Steam ships an empty PalWorldSettings.ini; seeding it from the defaults
    # is the documented first-run step. Edits made afterwards are preserved.
    cfgDir="${serverDir}/Pal/Saved/Config/LinuxServer"
    if [ -f "$cfgDir/PalWorldSettings.ini" ] && [ ! -s "$cfgDir/PalWorldSettings.ini" ] \
      && [ -f "${serverDir}/DefaultPalWorldSettings.ini" ]; then
      cp "${serverDir}/DefaultPalWorldSettings.ini" "$cfgDir/PalWorldSettings.ini"
    fi
  '';

  start = pkgs.writeShellScript "palworld-start" ''
    exec ${pkgs.steam-run}/bin/steam-run ${serverDir}/PalServer.sh \
      -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS
  '';
in {
  # Not packaged in nixpkgs: the server is a proprietary Unreal build fetched
  # from Steam at runtime and executed under the Steam FHS environment.
  systemd.services.palworld = {
    description = "Palworld Dedicated Server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];

    environment = {
      # Not anthony's real home: /home is on the tmpfs, so steamcmd would
      # re-download the ~8G depot on every reboot.
      HOME = dataDir;
      # PalServer-Linux-Shipping dlopen()s the shipped Steam libs by bare name.
      LD_LIBRARY_PATH = "${serverDir}/linux64:${serverDir}/Pal/Binaries/Linux";
    };

    serviceConfig = {
      User = "anthony";
      Group = "users";
      # '-' so a missing directory is not fatal: systemd chdirs here before
      # every Exec* line, including the one below that creates it.
      WorkingDirectory = "-${serverDir}";
      ExecStartPre = [
        # '+' runs this as root -- /var/lib/scratch is root-owned, and
        # systemd-tmpfiles only runs at boot, never on a switch.
        "+${pkgs.coreutils}/bin/install -d -o anthony -g users -m 0750 ${dataDir} ${serverDir}"
        prepare
      ];
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 30;
      # The first install pulls ~8G from Steam.
      TimeoutStartSec = "60min";
      # Unreal flushes saves on SIGINT; SIGTERM loses the last autosave window.
      KillSignal = "SIGINT";
      TimeoutStopSec = "90s";
    };
  };

  networking.firewall = {
    # 8211 is the game port; 27015 is the Steam query port.
    allowedUDPPorts = [8211 27015];
  };
}
