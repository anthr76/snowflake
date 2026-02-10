{
  description = "anthr76 Flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-master.url = "github:nixos/nixpkgs?ref=master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    gomod2nix.url = "github:nix-community/gomod2nix";
    gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
    hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs-pr-169155.url = "github:nixos/nixpkgs?ref=2f0d2186cf8c98279625db83b527b1091107c61c";
    nixpkgs-pr-269415.url = "github:nixos/nixpkgs?ref=f4e7e4a19bb2ec8738caf0154ca2943776fca32b";
    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";
    nix-cachyos-kernel.inputs.nixpkgs.follows = "nixpkgs";
    proton-cachyos.url = "github:powerofthe69/proton-cachyos-nix";
    proton-cachyos.inputs.nixpkgs.follows = "nixpkgs";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixified-ai = {
      url = "github:nixified-ai/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";
    apple-color-emoji.url = "github:samuelngs/apple-emoji-linux";
    apple-color-emoji.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nix-reshade.url = "github:LovingMelody/nix-reshade";
    nix-reshade.inputs.nixpkgs.follows = "nixpkgs";
    attic.url = "github:zhaofengli/attic";
  };

  outputs = {
    self,
    disko,
    gomod2nix,
    nix4vscode,
    nix-darwin,
    nixpkgs,
    home-manager,
    hardware,
    jovian-nixos,
    nix-github-actions,
    nix-flatpak,
    catppuccin,
    nixified-ai,
    nixos-generators,
    zen-browser,
    impermanence,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    systems = ["x86_64-linux" "aarch64-linux"];
    allSystems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs allSystems (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            gomod2nix.overlays.default
            nix4vscode.overlays.forVscode
          ];
        }
    );
    withPrefix = prefix:
      lib.mapAttrs' (name: value: {
        name = lib.replaceStrings ["." "@"] ["_" "_"] "${prefix}${name}";
        inherit value;
      });
  in {
    githubActions = nix-github-actions.lib.mkGithubMatrix {
      checks = nixpkgs.lib.getAttrs ["x86_64-linux"] self.checks;
      attrPrefix = "";
    };

    packages = forEachSystem (pkgs:
      import ./pkgs {inherit pkgs;}
      // {
        # Installer ISO built with nixos-generators
        installer-iso = nixos-generators.nixosGenerate {
          system = pkgs.system;
          modules = [./nixos/iso];
          format = "install-iso";
        };

        # VM image for testing the ISO
        installer-vm = nixos-generators.nixosGenerate {
          system = pkgs.system;
          modules = [./nixos/iso];
          format = "vm";
        };
      });
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});
    overlays = import ./overlays {inherit inputs outputs;};
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    darwinConfigurations = let
      mac-studio-config = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nix-darwin/hosts/mac-studio.nwk3.rabbito.tech
        ];
      };
    in {
      "mac-studio.nwk3.rabbito.tech" = mac-studio-config;
      "mac-studio" = mac-studio-config;
      "Mac-Studio" = mac-studio-config;
    };

    nixosConfigurations = {
      "bkp1" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/bkp1
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "octo" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/octo
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "cdgc" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/cdgc
        ];
      };
      "f80" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/f80
          nix-flatpak.nixosModules.nix-flatpak
          nixified-ai.nixosModules.comfyui
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "lattice" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          hardware.nixosModules.framework-16-7040-amd
          inputs.nixos-facter-modules.nixosModules.facter
          ./nixos/hosts/lattice
        ];
      };
      "fw1-nwk3" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/fw1-nwk3
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "fw1-nwk2" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/fw1-nwk2
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "fw1-qgr1" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/fw1-qgr1
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "worker-1" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/worker-1
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "worker-2" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/worker-2
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "worker-3" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/worker-3
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "worker-4" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/worker-4
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
      "worker-5" = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/worker-5
          inputs.nixos-facter-modules.nixosModules.facter
        ];
      };
    };

    homeConfigurations = {
      "anthony@bkp1" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/hosts/bkp1.nix
          catppuccin.homeModules.catppuccin
        ];
      };
      "steam@octo" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/hosts/octo.nix
          catppuccin.homeModules.catppuccin
        ];
      };
      "anthony@f80" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          catppuccin.homeModules.catppuccin
          ./home-manager/hosts/f80.nix
        ];
      };
      "anthony@lattice" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/hosts/lattice.nix
          catppuccin.homeModules.catppuccin
        ];
      };
      "anthony@generic" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/hosts/generic.nix
          catppuccin.homeModules.catppuccin
        ];
      };
      "anthony@mac-studio" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.aarch64-darwin;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/hosts/mac-studio.nix
          catppuccin.homeModules.catppuccin
        ];
      };
    };

    checks = forEachSystem (
      pkgs: let
        pkgsSet = withPrefix "pkgs-" (
          lib.filterAttrs (
            name: x:
              x.meta?platforms
              && lib.elem pkgs.system x.meta.platforms
          )
          self.packages.${pkgs.system}
        );

        nixosSet = withPrefix "nixos-" (
          lib.mapAttrs (name: x: x.config.system.build.toplevel)
          (lib.filterAttrs (name: x: x.pkgs.system == pkgs.system)
            self.nixosConfigurations)
        );

        # Explicitly list Linux home configs to avoid evaluating darwin configs
        linuxHomeConfigs = {
          "anthony@bkp1" = self.homeConfigurations."anthony@bkp1";
          "steam@octo" = self.homeConfigurations."steam@octo";
          "anthony@f80" = self.homeConfigurations."anthony@f80";
          "anthony@lattice" = self.homeConfigurations."anthony@lattice";
          "anthony@generic" = self.homeConfigurations."anthony@generic";
        };
        homeSet = withPrefix "home-" (
          lib.mapAttrs (name: x: x.activation-script)
          (lib.filterAttrs (name: x: x.pkgs.system == pkgs.system)
            linuxHomeConfigs)
        );
      in
        pkgsSet // nixosSet // homeSet
    );
  };
}
