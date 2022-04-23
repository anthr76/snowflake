{
  description = "anthr76 structured configuration database.";

  nixConfig.extra-experimental-features = "nix-command flakes";
  nixConfig.extra-substituters =
    "https://nrdxp.cachix.org https://nix-community.cachix.org";
  nixConfig.extra-trusted-public-keys =
    "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";

  inputs = {
    # Track channels with commits tested and built by hydra
    nixos.url = "github:nixos/nixpkgs/nixos-21.11";
    latest.url = "github:nixos/nixpkgs/nixos-unstable";
    yubico-piv-tool-pr-161198.url =
      "github:nixos/nixpkgs?ref=62eb5417e440201e434a23f05e2e485017d79d94";

    digga.url = "github:divnix/digga";
    digga.inputs.nixpkgs.follows = "nixos";
    digga.inputs.nixlib.follows = "nixos";
    digga.inputs.home-manager.follows = "home";
    digga.inputs.deploy.follows = "deploy";

    bud.url = "github:divnix/bud";
    bud.inputs.nixpkgs.follows = "nixos";
    bud.inputs.devshell.follows = "digga/devshell";

    home.url = "github:nix-community/home-manager/release-21.11";
    home.inputs.nixpkgs.follows = "nixos";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixos";

    deploy.url = "github:serokell/deploy-rs";
    deploy.inputs.nixpkgs.follows = "nixos";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixos";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixos";

    naersk.url = "github:nmattia/naersk";
    naersk.inputs.nixpkgs.follows = "nixos";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-generators.url = "github:nix-community/nixos-generators";

    work.url = "path:/home/anthonyjrabbito/dev/work-flake";
  };

  outputs = { self, digga, bud, nixos, home, nixos-hardware, work, nur, agenix
    , nvfetcher, deploy, ... }@inputs:
    digga.lib.mkFlake {
      inherit self inputs;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      channelsConfig = { allowUnfree = true; };

      channels = {
        nixos = {
          imports = [ (digga.lib.importOverlays ./overlays) ];
          overlays =
            [ nur.overlay agenix.overlay nvfetcher.overlay ./pkgs/default.nix ];
        };
        latest = { };
      };

      lib = import ./lib { lib = digga.lib // nixos.lib; };

      sharedOverlays = [
        (final: prev: {
          __dontExport = true;
          lib = prev.lib.extend (lfinal: lprev: { our = self.lib; });
        })
      ];

      nixos = {
        hostDefaults = {
          system = "x86_64-linux";
          channelName = "nixos";
          imports = [ (digga.lib.importExportableModules ./modules) ];
          modules = [
            { lib.our = self.lib; }
            digga.nixosModules.bootstrapIso
            digga.nixosModules.nixConfig
            home.nixosModules.home-manager
            agenix.nixosModules.age
            bud.nixosModules.bud
          ];
        };

        imports = [ (digga.lib.importHosts ./hosts) ];
        hosts = {
          rs2 = {
            channelName = "nixos";
            modules = [
              nixos-hardware.nixosModules.common-pc-laptop
              nixos-hardware.nixosModules.common-cpu-amd
              nixos-hardware.nixosModules.common-gpu-amd
              work.nixosModules.vpn
              work.nixosModules.private-ca
            ];
          };
        };
        importables = rec {
          profiles = digga.lib.rakeLeaves ./profiles // {
            users = digga.lib.rakeLeaves ./users;
          };
          suites = with profiles; rec {
            base = [
              core
              yubikey
              ssh
              misc.gnupg
              graphical.greetd
              graphical.sway
              graphical.chromium
              graphical.chrome
              graphical.audio
              podman
              users.anthonyjrabbito
              users.root
            ];
          };
        };
      };

      home = {
        imports = [ (digga.lib.importExportableModules ./users/modules) ];
        modules = [ ];
        importables = rec {
          profiles = digga.lib.rakeLeaves ./users/profiles;
          suites = with profiles; rec {
            base = [
              alacritty
              fish
              lsd
              nvim
              gnupg
              direnv
              starship
              git-work
	      kubernetes
              gh
              teams
              xdg
              kanshi
            ];
          };
        };
        users = {
          anthonyjrabbito = { suites, ... }: { imports = suites.base; };
        }; # digga.lib.importers.rakeLeaves ./users/hm;
      };

      devshell = ./shell;

      homeConfigurations =
        digga.lib.mkHomeConfigurations self.nixosConfigurations;

      deploy.nodes = digga.lib.mkDeployNodes self.nixosConfigurations { };

    };
}
