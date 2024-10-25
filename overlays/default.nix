# This file defines overlays
{ outputs, inputs }: {
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}'
  flake-inputs = final: _: {
    inputs =
      builtins.mapAttrs (
        _: flake: let
          legacyPackages = (flake.legacyPackages or {}).${final.system} or {};
          packages = (flake.packages or {}).${final.system} or {};
        in
          if legacyPackages != {}
          then legacyPackages
          else packages
      )
      inputs;
  };
  # Adds pkgs.stable == inputs.nixpkgs-stable.legacyPackages.${pkgs.system}
  # TODO: This doesn't work?
  stable = final: _: {
    stable = inputs.nixpkgs-stable.legacyPackages.${final.system};
  };

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # ffmpeg = prev.ffmpeg.override {
    #   withDebug = false;
    #   buildFfplay = false;
    #   withHeadlessDeps = true;
    #   withCuda = true;
    #   withNvdec = true;
    #   withFontconfig = true;
    #   withGPL = true;
    #   withAom = true;
    #   withAss = true;
    #   withBluray = true;
    #   withFdkAac =true;
    #   withFreetype = true;
    #   withMp3lame = true;
    #   withOpencoreAmrnb = true;
    #   withOpenjpeg = true;
    #   withOpus = true;
    #   withSrt = true;
    #   withTheora = true;
    #   withVidStab = true;
    #   withVorbis = true;
    #   withVpx = true;
    #   withWebp = true;
    #   withX264 = true;
    #   withX265 = true;
    #   withXvid = true;
    #   withZmq = true;
    #   withUnfree = true;
    #   withNvenc = true;
    #   buildPostproc = true;
    #   withSmallDeps = true;
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    # kdePackages = prev.kdePackages // {
    #   kwin = prev.kdePackages.kwin.overrideAttrs (old: {
    #     src = final.fetchFromGitLab {
    #       domain = "invent.kde.org";
    #       owner = "plasma";
    #       repo = "kwin";
    #       rev = "0fef229587d642e6175f39abc45fc839baffe1f1";
    #       hash = "sha256-obRUX6D00SNneHxqBmxIEdNA+VG9EFZn4c2mqybX14M=";
    #     };
    #     patches = (old.patches or []) ++ [
    #       (final.fetchpatch {
    #         url =
    #           "https://invent.kde.org/plasma/kwin/-/merge_requests/4800.patch";
    #         sha256 = "sha256-O7i2j2aElv5tUZSyMXGrPs3A0PYdYzfXHgrjIgKvVgE=";
    #       })
    #     ];
    #   });
    # };
    xpadneo = prev.xpadneo.overrideAttrs (oldAttrs: {
      version = "git.74dd867";
      src = final.fetchFromGitHub {
        owner = "atar-axis";
        repo = "xpadneo";
        rev = "74dd867e9e4fa4f6b2bb73df5434d8c8972152e8";
        sha256 = "sha256-fi5+S/UPoNZk3pUVXf6F4NY32Gy70U6A8bOX8PJizRo=";
        fetchSubmodules = true;
      };
    });
    gamescope = prev.gamescope.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        ./gamescope-native-res.patch
      ];
    });
    logiops = prev.logiops.overrideAttrs (oldAttrs: {
      version = "v0.3.3";
      src = final.fetchgit {
        url = "https://github.com/PixlOne/logiops.git";
        fetchSubmodules = true;
        rev = "94f6dbab5390c1c7375836dd9314c0c2488e48a3";
        sha256 = "9nFTud5szQN8jpG0e/Bkp+I9ELldfo66SdfVCUTuekg=";
      };
      preConfigure = ''
        substituteInPlace src/logid/CMakeLists.txt \
          --replace "/usr/share/dbus-1/system.d" "${
            placeholder "out"
          }/share/dbus-1/system.d" \
      '';
      buildInputs = oldAttrs.buildInputs ++ [ final.glib ];
    });
    discord = prev.discord.overrideAttrs (oldAttrs: {
      withOpenASAR = true;
      withVencord = true;
      postFixup = oldAttrs.postFixup or "" + ''
        wrapProgram $out/bin/discord \
        --add-flags "--ignore-gpu-blocklist " \
        --add-flags "--disable-features=UseOzonePlatform " \
        --add-flags "--enable-features=VaapiVideoDecoder " \
        --add-flags "--use-gl=desktop " \
        --add-flags "--enable-gpu-rasterization " \
        --add-flags "--enable-zero-copy"
      '';
    });

    kdePackages = prev.kdePackages // {
      sddm = prev.kdePackages.sddm.overrideAttrs (old: {
        patches = (old.patches or []) ++ [
          (final.fetchpatch {
            url =
              "https://patch-diff.githubusercontent.com/raw/sddm/sddm/pull/1779.patch";
            sha256 = "";
          })
        ];
      });
    };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
