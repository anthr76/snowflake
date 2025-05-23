{
  description = "anthr76 Flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
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
    nixpkgs-pr-169155.url = "github:nixos/nixpkgs?ref=2f0d2186cf8c98279625db83b527b1091107c61c";
    nixpkgs-pr-269415.url = "github:nixos/nixpkgs?ref=f4e7e4a19bb2ec8738caf0154ca2943776fca32b";
    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
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
  };

  outputs = { self, disko, gomod2nix, nix4vscode, nix-darwin, nixpkgs
           , home-manager, chaotic, hardware, jovian-nixos
           , nix-github-actions, nix-flatpak, nixified-ai, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (system:
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
          name = lib.replaceStrings [ "." "@" ] [ "_" "_" ] "${prefix}${name}";
          inherit value;
        });
    in {
      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = nixpkgs.lib.getAttrs [ "x86_64-linux" ] self.checks;
        attrPrefix = "";
      };

      packages    = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      devShells   = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
      overlays    = import ./overlays { inherit inputs outputs; };
      nixosModules        = import ./modules/nixos;
      homeManagerModules  = import ./modules/home-manager;

      nixosConfigurations = {
        "bkp1" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./nixos/hosts/bkp1 chaotic.nixosModules.default ];
        };
        "octo" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ chaotic.nixosModules.default ./nixos/hosts/octo ];
        };
        "cdgc" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            chaotic.nixosModules.default
            ./nixos/hosts/cdgc
          ];
        };
        "f80" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            chaotic.nixosModules.default
            nix-flatpak.nixosModules.nix-flatpak
            nixified-ai.nixosModules.comfyui
            ./nixos/hosts/f80
          ];
        };
        "lattice" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            chaotic.nixosModules.default
            hardware.nixosModules.framework-16-7040-amd
            ./nixos/hosts/lattice
          ];
        };
        "fw1-nwk3" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./nixos/hosts/fw1-nwk3 chaotic.nixosModules.default ];
        };
        "fw1-nwk2" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./nixos/hosts/fw1-nwk2 chaotic.nixosModules.default ];
        };
      };

      homeConfigurations = {
        "anthony@bkp1" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/hosts/bkp1.nix ];
        };
        "steam@octo" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/hosts/octo.nix ];
        };
        "anthony@f80" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/hosts/f80.nix ];
        };
        "anthony@lattice" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/hosts/lattice.nix ];
        };
        "anthony@generic" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/hosts/generic.nix ];
        };
      };

      checks = forEachSystem (pkgs:
        let
          pkgsSet = withPrefix "pkgs-" (
            lib.filterAttrs (name: x:
              x.meta?platforms
              && lib.elem pkgs.system x.meta.platforms
            ) self.packages.${pkgs.system}
          );

          nixosSet = withPrefix "nixos-" (
            lib.mapAttrs (name: x: x.config.system.build.toplevel)
              (lib.filterAttrs (name: x: x.pkgs.system == pkgs.system)
                self.nixosConfigurations)
          );

          homeSet = withPrefix "home-" (
            lib.mapAttrs (name: x: x.activation-script)
              (lib.filterAttrs (name: x: x.pkgs.system == pkgs.system)
                self.homeConfigurations)
          );
        in
          pkgsSet // nixosSet // homeSet
      );
    };
}
