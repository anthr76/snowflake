{
  config,
  lib,
  pkgs,
  ...
}: let
  scratch = "/var/lib/scratch";
  kopiaHome = "${scratch}/kopia";
  ownerFile = "${scratch}/.owner-id";

  sftpUser = "fm2322";
  sftpHost = "fm2322.rsync.net";
  repoPath = "/data1/home/fm2322/kopia-rabbito";
  leaseName = "kopia-rabbito.owner";
  # A lease older than this is treated as abandoned so a replacement host can
  # take over. Must comfortably exceed the renew timer below.
  leaseTtl = 1800;

  keyFile = config.sops.secrets.rsync-net-ssh-key.path;
  pwFile = config.sops.secrets.kopia-password.path;

  kopia = lib.getExe pkgs.kopia;
  jq = lib.getExe pkgs.jq;
  sftp = "${pkgs.openssh}/bin/sftp";
  coreutils = pkgs.coreutils;

  # Snapshots are attributed to the world, not to the machine via
  # --override-source. Hosts here get
  # replaced constantly and kopia keys sources on user@host:/path, so without
  # pinning, every replacement starts a fresh lineage that retention never
  # matches -- which is how the old tarball directory reached 270G.
  snapshotHost = "rabbito";
  snapshotUser = "root";

  # Everything ignored below is regenerated or re-downloaded. The Distant
  # Horizons LOD databases alone are ~4.5G and churn constantly; clients
  # rebuild them after a restore.
  minecraftIgnore = [
    "DistantHorizons.sqlite"
    "DistantHorizons.sqlite-shm"
    "DistantHorizons.sqlite-wal"
    "/mods"
    "/libraries"
    "/versions"
    "/cache"
    "/crash-reports"
    "/logs"
    "/lost+found"
    "/.cache"
    "/.local"
    "/.fabric"
    "/fabricloader.log"
  ];

  sets = [
    {
      name = "minecraft";
      path = "${scratch}/minecraft";
      user = "minecraft";
      group = "minecraft";
      unit = "minecraft-server.service";
      # Presence of this proves real data. services.minecraft-server sets
      # createHome, so dataDir always exists on a fresh host -- "directory is
      # non-empty" is NOT evidence of a world.
      marker = "world";
      schedule = "hourly";
      ignore = minecraftIgnore;
      quiesce = true;
    }
    {
      name = "palworld";
      path = "${scratch}/palworld/server/Pal/Saved";
      user = "anthony";
      group = "users";
      unit = "palworld.service";
      marker = "SaveGames";
      schedule = "daily";
      ignore = [];
      quiesce = false;
    }
    {
      name = "satisfactory";
      path = "${scratch}/satisfactory/.config/Epic/FactoryGame/Saved";
      user = "anthony";
      group = "users";
      unit = "satisfactory.service";
      marker = "SaveGames";
      schedule = "daily";
      ignore = [];
      quiesce = false;
    }
  ];

  sshOpts = "-i ${keyFile} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes";

  common = ''
    set -euo pipefail
    export HOME=${kopiaHome}
    export KOPIA_CONFIG_PATH=${kopiaHome}/repository.config
    export KOPIA_CACHE_DIRECTORY=${kopiaHome}/cache
    export KOPIA_PASSWORD="$(cat ${pwFile})"
    export KOPIA_CHECK_FOR_UPDATES=false

    # Identity is tied to the scratch disk rather than the hostname: two guests
    # accidentally running this same config have different disks, so they get
    # different ids and the lease below can tell them apart.
    owner_id() {
      if [ ! -s ${ownerFile} ]; then
        ${coreutils}/bin/head -c16 /dev/urandom \
          | ${coreutils}/bin/od -An -tx1 \
          | ${coreutils}/bin/tr -d ' \n' > ${ownerFile}
      fi
      cat ${ownerFile}
    }

    lease_read() {
      local tmp
      tmp=$(mktemp)
      if echo "get ${leaseName} $tmp" \
        | ${sftp} ${sshOpts} -b - ${sftpUser}@${sftpHost} >/dev/null 2>&1; then
        cat "$tmp"
      fi
      rm -f "$tmp"
    }

    # Fails if a *different* owner holds a lease that has not yet expired.
    lease_guard() {
      local me line other age now
      me=$(owner_id)
      line=$(lease_read || true)
      if [ -z "$line" ]; then return 0; fi
      other=$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $1}')
      now=$(date +%s)
      age=$(( now - $(echo "$line" | ${pkgs.gawk}/bin/awk '{print $2}') ))
      if [ "$other" = "$me" ]; then return 0; fi
      if [ "$age" -lt ${toString leaseTtl} ]; then
        echo "REFUSING: ${repoPath} is claimed by $other ($age s ago); this guest is $me." >&2
        echo "Two guests appear to be live against one repository. Stop one of them." >&2
        return 1
      fi
      echo "note: taking over lease from $other (stale by $age s)" >&2
      return 0
    }

    lease_claim() {
      local tmp
      tmp=$(mktemp)
      echo "$(owner_id) $(date +%s)" > "$tmp"
      echo "put $tmp ${leaseName}" \
        | ${sftp} ${sshOpts} -b - ${sftpUser}@${sftpHost} >/dev/null
      rm -f "$tmp"
    }
  '';

  connectScript = pkgs.writeShellScript "kopia-connect" ''
    ${common}
    ${coreutils}/bin/mkdir -p ${kopiaHome}/cache
    if ${kopia} repository status >/dev/null 2>&1; then
      exit 0
    fi
    if ! ${kopia} repository connect sftp \
      --host=${sftpHost} --username=${sftpUser} --path=${repoPath} \
      --keyfile=${keyFile} --known-hosts=/etc/ssh/ssh_known_hosts; then
      echo "no repository at ${repoPath}; creating one" >&2
      ${kopia} repository create sftp \
        --host=${sftpHost} --username=${sftpUser} --path=${repoPath} \
        --keyfile=${keyFile} --known-hosts=/etc/ssh/ssh_known_hosts
    fi
    # Maintenance is owned by the pinned identity rather than whichever host
    # happened to create the repository, or it stops running after a rebuild.
    ${kopia} maintenance set --owner=${snapshotUser}@${snapshotHost} || true
    ${kopia} policy set --global \
      --keep-latest=10 --keep-hourly=24 --keep-daily=7 \
      --keep-weekly=4 --keep-monthly=6 --keep-annual=0 || true
  '';

  backupScript = set:
    pkgs.writeShellScript "kopia-backup-${set.name}" ''
      ${common}
      if [ ! -d "${set.path}" ]; then
        echo "${set.path} does not exist yet; nothing to back up"
        exit 0
      fi
      # Never snapshot a half-restored set: doing so makes the newest snapshot
      # the broken one, which is what a later restore would pick.
      if [ ! -e "${set.path}/${set.marker}" ]; then
        echo "${set.path} has no ${set.marker}; refusing to back up an incomplete set" >&2
        exit 1
      fi
      lease_guard
      lease_claim
      ${lib.optionalString (set.ignore != []) ''
        ${coreutils}/bin/install -m 0644 ${
          pkgs.writeText "kopiaignore-${set.name}" (lib.concatStringsSep "\n" set.ignore + "\n")
        } "${set.path}/.kopiaignore"
      ''}
      ${kopia} snapshot create "${set.path}" \
        --override-source="${snapshotUser}@${snapshotHost}:${set.path}" \
        --description=${set.name}
    '';

  restoreScript = pkgs.writeShellScript "kopia-restore" ''
    ${common}

    restore_set() {
      local name="$1" path="$2" user="$3" group="$4" marker="$5" snap tmp
      # Restore only when the set has no real data. Checking for the marker
      # rather than an empty directory matters because activation pre-creates
      # some of these paths before this ever runs.
      if [ -e "$path/$marker" ]; then
        echo "$name: $path/$marker present, leaving it alone"
        return 0
      fi
      # Only consult the repository when a restore is actually needed, so an
      # rsync.net outage cannot block startup on a host that has its data.
      lease_guard
      snap=$(${kopia} snapshot list "${snapshotUser}@${snapshotHost}:$path" --json 2>/dev/null \
        | ${jq} -r 'if length > 0 then .[-1].rootEntry.obj else empty end')
      if [ -z "$snap" ]; then
        echo "$name: no snapshot in repository, starting fresh"
        return 0
      fi
      # Stage then swap, so an interrupted restore never leaves a partial set
      # in place -- which would both look "restored" and get backed up.
      tmp="$path.restoring"
      echo "$name: restoring $snap into $path"
      ${coreutils}/bin/rm -rf "$tmp"
      ${coreutils}/bin/mkdir -p "$tmp"
      ${kopia} snapshot restore "$snap" "$tmp"
      if [ ! -e "$tmp/$marker" ]; then
        echo "$name: restored data has no $marker; refusing to install it" >&2
        return 1
      fi
      # Restored as root; the services run as their own users and the uids in
      # the snapshot do not match this host's.
      ${coreutils}/bin/chown -R "$user:$group" "$tmp"
      ${coreutils}/bin/rm -rf "$path"
      # install -d, not mkdir -p: the parents matter. These paths are nested
      # (server/Pal/Saved), and root-owned intermediates leave the service
      # unable to write beside its own save dir -- steamcmd fails with 0x602.
      ${coreutils}/bin/install -d -o "$user" -g "$group" "$(dirname "$path")"
      ${coreutils}/bin/mv "$tmp" "$path"
      echo "$name: restore complete"
    }

    ${lib.concatMapStringsSep "\n" (s: ''restore_set "${s.name}" "${s.path}" "${s.user}" "${s.group}" "${s.marker}"'') sets}
  '';

  renewScript = pkgs.writeShellScript "kopia-lease-renew" ''
    ${common}
    lease_guard
    lease_claim
  '';

  backupServices = lib.listToAttrs (map (s:
    lib.nameValuePair "kopia-backup-${s.name}" {
      description = "Back up ${s.name} saves to rsync.net";
      after = ["kopia-connect.service"];
      requires = ["kopia-connect.service"];
      serviceConfig =
        {
          Type = "oneshot";
          ExecStart = backupScript s;
        }
        // lib.optionalAttrs s.quiesce {
          # Flush the world first or the snapshot catches a half-written region.
          ExecStartPre = pkgs.writeShellScript "minecraft-quiesce" ''
            if [ -p /run/minecraft-server.stdin ]; then
              echo "save-off" > /run/minecraft-server.stdin
              echo "save-all flush" > /run/minecraft-server.stdin
              sleep 10
            fi
          '';
          ExecStopPost = pkgs.writeShellScript "minecraft-unquiesce" ''
            if [ -p /run/minecraft-server.stdin ]; then
              echo "save-on" > /run/minecraft-server.stdin || true
            fi
          '';
        };
    })
  sets);

  backupTimers = lib.listToAttrs (map (s:
    lib.nameValuePair "kopia-backup-${s.name}" {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = s.schedule;
        RandomizedDelaySec = "5m";
        Persistent = true;
      };
    })
  sets);
in {
  sops.secrets.kopia-password = {
    sopsFile = ../../../secrets/rabbito.yaml;
    mode = "0400";
  };
  sops.secrets.rsync-net-ssh-key = {
    sopsFile = ../../../secrets/rabbito.yaml;
    mode = "0400";
  };

  programs.ssh.knownHosts = {
    rsync-net-ed25519 = {
      hostNames = [sftpHost];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdUkGe6kKn5ssz4WRZKjcws0InbQqZayenzk9obmP1z";
    };
    rsync-net-ecdsa = {
      hostNames = [sftpHost];
      publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNKxjzXzYdLwYoXcT/lRlxNzfHdGkr0pZDLk1tiPvLnbec1st3UjYq8HgYE1c/ko0VqINCR1uarlObpKpmazVHc=";
    };
  };

  environment.systemPackages = [pkgs.kopia];

  systemd.services =
    {
      kopia-connect = {
        description = "Connect to the rabbito kopia repository";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target" "var-lib-scratch.mount"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = connectScript;
        };
      };

      game-restore = {
        description = "Restore game saves from kopia if this host has none";
        # Ordering only, deliberately not `requires`: a host that already has
        # its data must still start when rsync.net is unreachable. The script
        # only touches the repository when a restore is actually needed, and
        # fails closed in that case rather than generating a fresh world.
        after = ["kopia-connect.service"];
        before = map (s: s.unit) sets;
        requiredBy = map (s: s.unit) sets;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = restoreScript;
        };
      };

      kopia-lease-renew = {
        description = "Refresh this guest's claim on the kopia repository";
        after = ["kopia-connect.service"];
        requires = ["kopia-connect.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = renewScript;
        };
      };
    }
    // backupServices;

  systemd.timers =
    {
      kopia-lease-renew = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "10min";
        };
      };
    }
    // backupTimers;
}
