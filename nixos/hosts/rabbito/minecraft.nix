{
  lib,
  pkgs,
  ...
}: let
  dataDir = "/var/lib/scratch/minecraft";

  mcVersion = "1.21.11";
  loaderVersion = "0.19.5";
  launcherVersion = "1.1.2";

  fabricServerJar = pkgs.fetchurl {
    name = "fabric-server-mc.${mcVersion}-loader.${loaderVersion}-launcher.${launcherVersion}.jar";
    url = "https://meta.fabricmc.net/v2/versions/loader/${mcVersion}/${loaderVersion}/${launcherVersion}/server/jar";
    hash = "sha256-K2PSk75UyPVISiQoWcq4QdzuOFEeEbL4LpIhHxmHLQg=";
  };
  modSpecs = [
    {
      name = "fabric-api-0.141.6+1.21.11.jar";
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/6qAuTtLR/fabric-api-0.141.6%2B1.21.11.jar";
      hash = "sha512-hS02gsTzU/0MqGVGr4V4UT6Lz2KDd/qdScVWvFnFAkxpq1bJL8bfuhH+0Z5DFqP1Y25+B/09lvcEO1Ma71m2Nw==";
    }
    {
      name = "fabric-language-kotlin-1.14.1+kotlin.2.4.20.jar";
      url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/eRRZzGMc/fabric-language-kotlin-1.14.1%2Bkotlin.2.4.20.jar";
      hash = "sha512-kUBPh3dEZs6GBKr+p5HYzJe2A7wxDc4XyBiPlPd4PMptwU/HJs6HHKMXv+kDPBmdjYWNUShBBqAHVOlSFHcDuA==";
    }
    {
      name = "lithium-fabric-0.21.4+mc1.21.11.jar";
      url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/Ow7wA0kG/lithium-fabric-0.21.4%2Bmc1.21.11.jar";
      hash = "sha512-8UpcPS+teGNHyiUIP5AhOWlPYYt8EDlH8v0Genxe6Ipj4e+JJvfWk+p57X0A9XMXuud++cLWML9e0BrJenUrlA==";
    }
    {
      name = "ferritecore-8.2.0-fabric.jar";
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/Ii0gP3D8/ferritecore-8.2.0-fabric.jar";
      hash = "sha512-MhCSaoLrMu/ZvOur4vbAU9r1xDN+68bVusupbSg1EK+95kbn4ZV1HeeV7HCi6kT+93y1S/Isjle7gy1iF0GIaQ==";
    }
    {
      name = "c2me-fabric-mc1.21.11-0.4.0-alpha.0.26.jar";
      url = "https://cdn.modrinth.com/data/VSNURh3q/versions/879vA5z6/c2me-fabric-mc1.21.11-0.4.0-alpha.0.26.jar";
      hash = "sha512-vbbOBJrnx3n5r92Ash0mbe7OLvdqKvgDP1VU0qUONzSp0ERDPAyW8Msn7nChiBuX6+14Zz7iHDqr/crVgoJT5Q==";
    }
    {
      name = "vmp-fabric-mc1.21.11-0.2.0+beta.7.227-all.jar";
      url = "https://cdn.modrinth.com/data/wnEe9KBa/versions/7Cxc2cAR/vmp-fabric-mc1.21.11-0.2.0%2Bbeta.7.227-all.jar";
      hash = "sha512-VTSlsOyItY8aOVdT5IEN3pqPD5eoiJj0th6WC9IZ7CjqYMZnbX7iTVtGWTmk/5RwUg2QFbuc2xDZNX/4LDb9qw==";
    }
    {
      name = "servercore-fabric-1.5.15+1.21.11.jar";
      url = "https://cdn.modrinth.com/data/4WWQxlQP/versions/zg8VIycZ/servercore-fabric-1.5.15%2B1.21.11.jar";
      hash = "sha512-lkOSdp5T+XZEZuJgRFUvYOkRN/SHtJ2YqFvU3AOrjpZfDGm8GkPpbvVzfNjxqbt1zAoMCd0wurZ4bYq0u+puAQ==";
    }
    {
      name = "krypton-0.2.10.jar";
      url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/O9LmWYR7/krypton-0.2.10.jar";
      hash = "sha512-Tc1yKNGJDd/HjJn/KEtF+c9Aqud+9jWTCOJtBvoNk4NlJVaWr0zBLVJMRsSIbNzRkmjBZaK/Cig1IC/oV9pcqw==";
    }
    {
      name = "threadtweak-fabric-0.1.8+mc1.21.11.jar";
      url = "https://cdn.modrinth.com/data/vSEH1ERy/versions/9t60vZ1h/threadtweak-fabric-0.1.8%2Bmc1.21.11.jar";
      hash = "sha512-yrRE6uyqEIsNAO6pqilBXE4mZLpk3j7tuj9jIoaGvC0zT33ga9oiNnJEz6Cksht3iOkkEI7vBL/gd7zv8cSzTg==";
    }
    {
      name = "DistantHorizons-3.2.0-b-1.21.11-fabric-neoforge.jar";
      url = "https://cdn.modrinth.com/data/uCdwusMi/versions/bCTilxSz/DistantHorizons-3.2.0-b-1.21.11-fabric-neoforge.jar";
      hash = "sha512-FBkOviAElWlRyalyMrdML9i/vtZJbwRKVYgufUvhh8GmwmiNYv64lVG0o+0xUzcOX5AG+YGRtvhwm4kdjzubYg==";
    }
    {
      name = "Jade-1.21.11-Fabric-21.1.6.jar";
      url = "https://cdn.modrinth.com/data/nvQzSEkH/versions/swJhAyak/Jade-1.21.11-Fabric-21.1.6.jar";
      hash = "sha512-be4Q7/ptaMgixZt3BPVQb+Z0xQ1hldolFxZB3s+mhNxPFNkZZW92j+j8OQA8YZMSbLBbtZ7tihor01TcU4debQ==";
    }
    {
      name = "yet_another_config_lib_v3-3.8.2+1.21.11-fabric.jar";
      url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/pHWDw3Vc/yet_another_config_lib_v3-3.8.2%2B1.21.11-fabric.jar";
      hash = "sha512-OS231HEDDMonSD7PWMYmoUzXPXGhiv5tQXPGsDCUi4qSWzbnCNTMLIl9+j8gp/I7mZ/BiqbTbBVtopA3YBFTrA==";
    }
    {
      name = "controlify-3.0.1+lts+1.21.11-fabric.jar";
      url = "https://cdn.modrinth.com/data/DOUdJVEm/versions/qZW7FPjm/controlify-3.0.1%2Blts%2B1.21.11-fabric.jar";
      hash = "sha512-Gnu8untyGyjtXkb6XpS/eVJRyUdpOfNASag9ZKFs5WzbKmhBx2j0OT+hsbpnIVxn/n/dFKKdF3DwPUyBKxD83g==";
    }
  ];

  mods = pkgs.linkFarm "rabbito-minecraft-mods" (
    map (m: {
      inherit (m) name;
      path = pkgs.fetchurl {inherit (m) name url hash;};
    })
    modSpecs
  );

  fabricServer = pkgs.writeShellScriptBin "minecraft-server" ''
    exec ${pkgs.jdk21_headless}/bin/java "$@" -jar ${fabricServerJar} nogui
  '';
in {
  services.minecraft-server = {
    enable = true;
    eula = true;
    inherit dataDir;
    openFirewall = true;
    package = fabricServer;
    declarative = false;
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
    ];
  };
  systemd.services.minecraft-server.preStart = lib.mkAfter ''
    rm -rf ${dataDir}/mods
    ln -sfn ${mods} ${dataDir}/mods
  '';
}
