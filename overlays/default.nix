# This file defines overlays
{ inputs, ... }:
{
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
      runtimeDeps = oldAttrs.runtimeDeps ++ [
        final.gopls
        final.clang-tools
      ];
    });
    libplacebo = prev.libplacebo.overrideAttrs (oldAttrs: {
      version = "6.338.1";
      src = final.fetchFromGitLab {
        domain = "code.videolan.org";
        owner = "videolan";
        repo = "libplacebo";
        rev = "v6.338.1";
        hash = "sha256-NZmwR3+lIC2PF+k+kqCjoMYkMM/PKOJmDwAq7t6YONY=";
      };
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [final.xxHash];
    });
    moonlight-qt = prev.moonlight-qt.overrideAttrs (oldAttrs: {
      version = "v0.3.3-e20d560";
      src = final.fetchFromGitHub {
        owner = "moonlight-stream";
        repo = "moonlight-qt";
        rev = "e20d56041ea73a543511385583c580f4c09b21f3";
        sha256 = "GgZQoPA9Cgu8zKBgy7zTXVbumS0esBttPFVGNyI84Fc=";
        fetchSubmodules = true;
      };
      buildInputs = oldAttrs.buildInputs ++ [final.libplacebo final.vulkan-headers];
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
    discord = prev.discord.overrideAttrs (oldAttrs: {
      withOpenASAR = true;
      withVencord = true;
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
