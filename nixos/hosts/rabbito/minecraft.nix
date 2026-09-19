{
  lib,
  pkgs,
  ...
}: let
  dataDir = "/var/lib/scratch/minecraft";

  # Held at 26.2 because the Additive client pack has no 26.3 build yet. The
  # server must match the client exactly, and Distant Horizons 3.3.0 now ships
  # for 26.2, so staying here costs nothing -- krypton and controlify are also
  # native again, with no dependency override needed.
  mcVersion = "26.2";
  loaderVersion = "0.19.5";
  launcherVersion = "1.1.2";

  fabricServerJar = pkgs.fetchurl {
    name = "fabric-server-mc.${mcVersion}-loader.${loaderVersion}-launcher.${launcherVersion}.jar";
    url = "https://meta.fabricmc.net/v2/versions/loader/${mcVersion}/${loaderVersion}/${launcherVersion}/server/jar";
    hash = "sha256-8dK6/Qs7l2MLDN2OiQzRAts9vmCHejilyBOqkp5pESc=";
  };

  modSpecs = [
    {
      name = "fabric-api-0.161.0+26.2.jar";
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/ewUK83HI/fabric-api-0.161.0%2B26.2.jar";
      hash = "sha512-JQL6Wt546aEgs3R7wamiFn1mcXQ76kW/EV0xdMlBIa7ah8VJRG0aYEqcEfuCjeF6VR41FM5C8+kwad0Uva7lWw==";
    }
    {
      name = "fabric-language-kotlin-1.14.1+kotlin.2.4.20.jar";
      url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/eRRZzGMc/fabric-language-kotlin-1.14.1%2Bkotlin.2.4.20.jar";
      hash = "sha512-kUBPh3dEZs6GBKr+p5HYzJe2A7wxDc4XyBiPlPd4PMptwU/HJs6HHKMXv+kDPBmdjYWNUShBBqAHVOlSFHcDuA==";
    }
    {
      name = "lithium-fabric-0.25.3+mc26.2.jar";
      url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/f7vZ0VWU/lithium-fabric-0.25.3%2Bmc26.2.jar";
      hash = "sha512-FItjjzxiKfuvSHEgojRKCvXkEaWqZTPV25112gqMDYME9j60zKE/TQOyybTCPVWd10wdgyQi74owh70AXmKovQ==";
    }
    {
      name = "ferritecore-9.0.0-fabric.jar";
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/d5ddUdiB/ferritecore-9.0.0-fabric.jar";
      hash = "sha512-2B+pfhF4TBnUL4nC9DODHQB2A91xk87kX6F35KapxSs4SxmFhuBKD39jzZlv7XEzIleL3pqNtX4RiIVK5cvlhA==";
    }
    {
      name = "c2me-fabric-mc26.2-0.4.2-alpha.0.52.jar";
      url = "https://cdn.modrinth.com/data/VSNURh3q/versions/LmKTn6Yc/c2me-fabric-mc26.2-0.4.2-alpha.0.52.jar";
      hash = "sha512-dqfFLqmyIpXBXQK+fxykto/Gc2hGXxvTz/tHzTa/O/a53ZJbygLMssfLLCbfEjVTjZjdusQ/hZhcOf0YPJ80aA==";
    }
    {
      name = "vmp-fabric-mc26.2-0.2.0+beta.7.236-all.jar";
      url = "https://cdn.modrinth.com/data/wnEe9KBa/versions/d6FfpWFI/vmp-fabric-mc26.2-0.2.0%2Bbeta.7.236-all.jar";
      hash = "sha512-Lg/YfmbzXwD2NBdtQHKmxtHu6WXRgXgzcJrT6nPk8nGfoVLV6VtauCFrBkx9sSS38Tg46+qH2S96ct+Cg56b1Q==";
    }
    {
      name = "servercore-fabric-1.5.19+26.2.jar";
      url = "https://cdn.modrinth.com/data/4WWQxlQP/versions/edrtnY9v/servercore-fabric-1.5.19%2B26.2.jar";
      hash = "sha512-qkz8k/jgIXKRAwJEQzDjdxPfzyBH0o5V63Mjo81dUUkzdKCVmqPmJuwr9D/HB6dVUIuDRUuzS21X1lwGmSkHSw==";
    }
    {
      name = "krypton-0.3.1.jar";
      url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/5WeL0Nkz/krypton-0.3.1.jar";
      hash = "sha512-uNmvNM0AUEk6+4piMsuPeF2qnYiHtwRfbmpTxrubX/xDGP2bA0epQOrP66R3PxDLgK4L4eec5MGIj5btoh5WTg==";
    }
    {
      name = "DistantHorizons-3.3.0-26.2-fabric-neoforge.jar";
      url = "https://cdn.modrinth.com/data/uCdwusMi/versions/3CtFgbnO/DistantHorizons-3.3.0-26.2-fabric-neoforge.jar";
      hash = "sha512-D2/BtxUPfbwg/CtrbB3F9eOubp5r5kGQvre1ddH/5r1uERL0ynELw7pE7BgC1hoxzGdGm4H3uV6WxJlAQx5EpQ==";
    }
    {
      name = "Jade-mc26.2-Fabric-26.2.11.jar";
      url = "https://cdn.modrinth.com/data/nvQzSEkH/versions/ue8CO97w/Jade-mc26.2-Fabric-26.2.11.jar";
      hash = "sha512-cw4H3Vy7+FC6Dn/UhStSiGfT4vwt5jsVbInu6e5t2S2IK3RPl/5yTyqgr8W0aFd0htlVj4DT5GzF+hM7okG5yQ==";
    }
    {
      name = "yet_another_config_lib_v3-3.9.6+26.2-fabric.jar";
      url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/cnfPzuFU/yet_another_config_lib_v3-3.9.6%2B26.2-fabric.jar";
      hash = "sha512-s6WOSl71RkdWkoK4suljA4mzVo8KvsucFo2qqBVHfL+WHnneKAgcrFUbabgQ9WHwQ9Zp0QNK7IDxIVOlPf9T7w==";
    }
    {
      name = "controlify-3.5.0+mc26.2-universal.jar";
      url = "https://cdn.modrinth.com/data/DOUdJVEm/versions/9ePC9FQ4/controlify-3.5.0%2Bmc26.2-universal.jar";
      hash = "sha512-3ULAo+zSphwSac0U1Xib3N5IDMK1dJWztSF/2uD799xLMFwNSAAR1306S24M0MOsN0lePjZezhV2VMkNkFM/rA==";
    }
  ];

  mods = pkgs.linkFarm "rabbito-minecraft-mods" (
    map (m: {
      inherit (m) name;
      path = pkgs.fetchurl {inherit (m) name url hash;};
    })
    modSpecs
  );

  # The module calls ${package}/bin/minecraft-server with jvmOpts as argv, so
  # the JVM flags have to land before -jar. Minecraft 26.x ships class file
  # version 69, so this needs JDK 25 -- JDK 21 only reads up to 65.
  fabricServer = pkgs.writeShellScriptBin "minecraft-server" ''
    exec ${pkgs.jdk25_headless}/bin/java "$@" -jar ${fabricServerJar} nogui
  '';
in {
  # Activation runs `chmod $homeMode` on the dataDir every switch (default
  # 700), so a manual chmod never survives. 750 + anthony in the minecraft
  # group keeps the world browsable without sudo.
  users.users.minecraft.homeMode = "750";

  services.minecraft-server = {
    enable = true;
    eula = true;
    inherit dataDir;
    openFirewall = true;
    package = fabricServer;

    # Left stateful on purpose: server.properties, whitelist.json and ops.json
    # carry the world seed, player list and the tuning applied on the host.
    declarative = false;

    # Aikar's G1GC tuning. Deliberately not raised despite 128G on the guest:
    # a larger G1 heap means longer pauses, not better TPS, and staying under
    # 32G keeps compressed oops enabled.
    jvmOpts = lib.concatStringsSep " " [
      "-Xms12G"
      "-Xmx12G"
      "-XX:+UseG1GC"
      "-XX:+ParallelRefProcEnabled"
      "-XX:MaxGCPauseMillis=200"
      "-XX:+UnlockExperimentalVMOptions"
      "-XX:+DisableExplicitGC"
      "-XX:+AlwaysPreTouch"
      "-XX:G1NewSizePercent=30"
      "-XX:G1MaxNewSizePercent=40"
      "-XX:G1HeapRegionSize=8M"
      "-XX:G1ReservePercent=20"
      "-XX:G1HeapWastePercent=5"
      "-XX:G1MixedGCCountTarget=4"
      "-XX:InitiatingHeapOccupancyPercent=15"
      "-XX:G1MixedGCLiveThresholdPercent=90"
      "-XX:G1RSetUpdatingPauseTimePercent=5"
      "-XX:SurvivorRatio=32"
      "-XX:+PerfDisableSharedMem"
      "-XX:MaxTenuringThreshold=1"
      # G1 sizes its pools from the CPU count, which on 64 vCPUs gives ~43
      # refinement + ~43 parallel + 11 concurrent threads for a 12G heap --
      # oversubscribed against C2ME's 34 workers and DH's 32. Cap them to
      # what the heap actually needs.
      "-XX:ParallelGCThreads=10"
      "-XX:ConcGCThreads=3"
      "-XX:G1ConcRefinementThreads=10"
      # The guest reports THP as madvise, so the JVM can back a pre-touched
      # 12G heap with huge pages and cut TLB pressure.
      "-XX:+UseTransparentHugePages"
      # JDK 24+ warns on every sun.misc.Unsafe memory access; joml triggers it
      # dozens of times per start. Silence rather than drown real warnings.
      "--sun-misc-unsafe-memory-access=allow"
    ];
  };

  # Point mods/ at the Nix-built pack. Anything dropped in by hand is discarded
  # on restart, which is the trade for the pack being reproducible.
  systemd.services.minecraft-server.preStart = lib.mkAfter ''
    rm -rf ${dataDir}/mods
    ln -sfn ${mods} ${dataDir}/mods
    # No longer needed at ${mcVersion}: controlify is native here, so a stale
    # override would silently drop its real minecraft dependency check.
    rm -f ${dataDir}/config/fabric_loader_dependencies.json
  '';
}
