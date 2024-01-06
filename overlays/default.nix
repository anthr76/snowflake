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
  wezterm = prev.wezterm.override {
    rustPlatform = prev.rustPlatform // {
      buildRustPackage = args:
        prev.rustPlatform.buildRustPackage (args // rec {
          src = final.fetchFromGitHub {
            owner = "wez";
            repo = "wezterm";
            rev = "4921f139d35590ab35415021221a2a6f5cf10ab3";
            fetchSubmodules = true;
            hash = "sha256-WXOsP2rjbT4unc7lXbxbRbCcrc89SfyVdErzFndBF9o=";
          };
          cargoLock = {
            lockFile = "${src}/Cargo.lock";
            outputHashes = {
              "xcb-1.2.1" =
                "sha256-zkuW5ATix3WXBAj2hzum1MJ5JTX3+uVQ01R1vL6F1rY=";
              "xcb-imdkit-0.2.0" =
                "sha256-L+NKD0rsCk9bFABQF4FZi9YoqBHr4VAZeKAWgsaAegw=";
            };
          };
        });
    };
  };
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
        rev = "c3e886fbcc4664b7afb5f0062c1558eda02b9001";
        sha256 = "sha256-G2cu3wrfayN9g2UidHzrufCQk1jyX5CmJx1+969Zi40=";
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
