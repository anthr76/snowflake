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
    xpadneo = prev.xpadneo.overrideAttrs (oldAttrs: {
      version = "git.74dd867";
      src = final.fetchFromGitHub {
        owner = "atar-axis";
        repo = "xpadneo";
        rev = "ed569629dbf0ef0033386a54826aff6da2af2a9f";
        sha256 = "";
        fetchSubmodules = true;
      };
    });
    gamescope = prev.gamescope.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        ./gamescope-native-res.patch
      ];
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
            sha256 = "sha256-8QP9Y8V9s8xrc+MIUlB7iHVNHbntGkw0O/N510gQ+bE=";
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
