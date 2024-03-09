# This file defines overlays
{ outputs, inputs }:
{
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}'
  flake-inputs = final: _: {
    inputs = builtins.mapAttrs
      (_: flake: let
        legacyPackages = ((flake.legacyPackages or {}).${final.system} or {});
        packages = ((flake.packages or {}).${final.system} or {});
      in
        if legacyPackages != {} then legacyPackages else packages
      )
      inputs;
  };
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    lunarvim = prev.lunarvim.overrideAttrs (oldAttrs: {
      src = final.fetchFromGitHub {
        owner = "LunarVim";
        repo = "LunarVim";
        rev = "9ee3b7b8846d7ed2fa79f03d67083f8b95c897f2";
        sha256 = "sha256-grCEaLJrcPMdM9ODWSExcNsc+G+QmEmZ7EBfBeEVeGU";
        fetchSubmodules = true;
      };
      runtimeDeps = oldAttrs.runtimeDeps ++ [
        final.gopls
        final.clang-tools
        final.wget
        final.libgcc
        final.vimPlugins.nvim-treesitter.withAllGrammars
        final.lazygit
        final.clang
      ];
    });
    xwayland-run = prev.xwayland-run.overrideAttrs (oldAttrs: {
      version = "0.0.2-c5846bed";
      src = final.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "ofourdan";
        repo = "xwayland-run";
        rev = "c5846bed1d01497c75f8347e4d5dd1077cf171e9";
        hash = "sha256-/i5+S/UPoNZk3pUVXf6F4NY32Gy70U6A8bOX8PJiCRo=";
      };
    });
    gamescope = prev.gamescope.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [ ./gamescope-native-res.patch ];
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
          --replace "/usr/share/dbus-1/system.d" "${placeholder "out"}/share/dbus-1/system.d" \
      '';
      buildInputs = oldAttrs.buildInputs ++ [final.glib];
    });
    sunshine = prev.sunshine.overrideAttrs (oldAttrs: {
      cmakeFlags = oldAttrs.cmakeFlags ++ [
        "-DSUNSHINE_ENABLE_TRAY=OFF"
        "-DSUNSHINE_REQUIRE_TRAY=OFF"
      ];
    });
    discord = prev.discord.overrideAttrs (oldAttrs: {
      withOpenASAR = true;
      withVencord = true;
      postFixup =
        oldAttrs.postFixup
        or ""
        + ''
          wrapProgram $out/bin/discord \
          --add-flags "--ignore-gpu-blocklist " \
          --add-flags "--disable-features=UseOzonePlatform " \
          --add-flags "--enable-features=VaapiVideoDecoder " \
          --add-flags "--use-gl=desktop " \
          --add-flags "--enable-gpu-rasterization " \
          --add-flags "--enable-zero-copy"
        '';
    });
    moonlight-qt = prev.moonlight-qt.overrideAttrs (oldAttrs: {
      version = "v0.3.3-89a628a";
      patches = [];
      src = final.fetchFromGitHub {
        owner = "moonlight-stream";
        repo = "moonlight-qt";
        rev = "89a628a0dde50264fd2170125588c15d8dd80a2c";
        sha256 = "sha256-6KJTYYbrIPt3zNaK63fcFBb9W8reItpeqylugj0CwjU=";
        fetchSubmodules = true;
      };
      buildInputs = oldAttrs.buildInputs ++ [final.libplacebo final.vulkan-headers];
    });
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
