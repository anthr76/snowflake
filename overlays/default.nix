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
    # libplacebo =  prev.libplacebo.overrideAttrs (oldAttrs: {
    #   inherit (inputs.nixpkgs-pr-269415.legacyPackages.${prev.system})
    #     libplacebo;
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
    sunshine = prev.sunshine.overrideAttrs (oldAttrs: {
      version = "0.21.0-69a3edd";
      src = final.fetchFromGitHub {
        owner = "LizardByte";
        repo = "Sunshine";
        rev = "69a3edd9b01c76aa44fd5c2a29de1c3b3722cb41";
        sha256 = "sha256-4W+/mIRSkNj7hl3m5b2DJHt2euwAGcr753RHRBM5a9A=";
        fetchSubmodules = true;
      };
      buildInputs = oldAttrs.buildInputs ++ [
        final.miniupnpc
        # TODO: Figure out if these are needed.
        # Appeasing Cmake a bit here but may not be needed
        final.libgudev
        final.systemdLibs
        final.nodejs
      ];
    });
    # gamescope-nvidia = prev.gamescope.overrideAttrs (oldAttrs: {
    #   version = "4.8-nvidia";
    #   src = final.fetchFromGitHub {
    #     owner = "sharkautarch";
    #     repo = "gamescope";
    #     rev = "1a5a707cd3efbf5372ef46ab4c96dcc0696eab63";
    #     fetchSubmodules = true;
    #     hash = "sha256-Kf6Wq4pTUkt4VITMWApzEQ5Mh6mdXFL1jv7JOAseMMg=";
    #   };
    # });
    # nixpkgs-pr-269415
    # libplacebo = prev.libplacebo.overrideAttrs (oldAttrs: {
    #   version = "6.338.1";
    #   src = final.fetchFromGitLab {
    #     domain = "code.videolan.org";
    #     owner = "videolan";
    #     repo = "libplacebo";
    #     rev = "v6.338.1";
    #     hash = "sha256-NZmwR3+lIC2PF+k+kqCjoMYkMM/PKOJmDwAq7t6YONY=";
    #   };
    #   nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [final.xxHash];
    #   patches = [ ./libplacebo-0001-Vulkan-Don-t-try-to-reuse-old-swapchain.patch ];
    # });
    # moonlight-qt = prev.moonlight-qt.overrideAttrs (oldAttrs: {
    #   version = "v0.3.3-e20d560";
    #   src = final.fetchFromGitHub {
    #     owner = "moonlight-stream";
    #     repo = "moonlight-qt";
    #     rev = "b01a83ff3949c9ae42d75a1ad5c80c4fb9a529f8";
    #     sha256 = "GgZQoPA9Cgu8zKBgy7zTXVbumS0esBttPFVgNyI84Fc=";
    #     fetchSubmodules = true;
    #   };
    #   buildInputs = oldAttrs.buildInputs ++ [final.libplacebo final.vulkan-headers];
    # });
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
