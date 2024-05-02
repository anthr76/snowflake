{
  description = "anthr76 Flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    gomod2nix.url = "github:nix-community/gomod2nix";
    gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
    hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:mic92/sops-nix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # SSH Agent
    nixpkgs-pr-169155.url =
      "github:nixos/nixpkgs?ref=2f0d2186cf8c98279625db83b527b1091107c61c";
    # TODO: Document this PR
    nixpkgs-pr-269415.url =
      "github:nixos/nixpkgs?ref=f4e7e4a19bb2ec8738caf0154ca2943776fca32b";
    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, disko, gomod2nix, nix-darwin, nixpkgs, nixpkgs-unstable, home-manager, chaotic
    , jovian-nixos, nix-github-actions, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            gomod2nix.overlays.default
          ];
        });
      withPrefix = prefix:
        lib.mapAttrs' (name: value: {
          # Also remove special characters
          name = lib.replaceStrings [ "." "@" ] [ "_" "_" ] "${prefix}${name}";
          inherit value;
        });
    in {
      githubActions = nix-github-actions.lib.mkGithubMatrix {
        # aarch64-linux is not supported by GitHub
        checks = nixpkgs.lib.getAttrs [ "x86_64-linux" ] self.checks;
        attrPrefix = "";
      };
      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
      overlays = import ./overlays { inherit inputs outputs; };
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
      nixosConfigurations = {
        "bkp1" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/bkp1
            chaotic.nixosModules.default
          ];
        };
        "octo" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            chaotic.nixosModules.default
            ./nixos/hosts/octo
          ];
        };
        "f80" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            chaotic.nixosModules.default
            ./nixos/hosts/f80
          ];
        };
        "fw1-nwk3" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/fw1-nwk3
            chaotic.nixosModules.default
          ];
        };
        "fw1-nwk2" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/fw1-nwk2
            chaotic.nixosModules.default
          ];
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
        "anthony@nicoles-mbp" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-darwin;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/hosts/nicoles-mbp.nix ];
        };
        "anthony@generic" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/hosts/generic.nix ];
        };
      };
      darwinConfigurations = {
        "nicoles-mbp" = nix-darwin.lib.darwinSystem {
          modules = [
            nix-darwin/hosts/nicoles-mbp
          ];
          pkgs = pkgsFor.x86_64-darwin;
          specialArgs = { inherit inputs outputs; };
       };
      };

      # Run `nix flake check`
      checks = forEachSystem (pkgs:
        # add all the supported packages to checks
        (withPrefix "pkgs-"
          (lib.filterAttrs (_: x: lib.elem pkgs.system x.meta.platforms)
            self.packages.${pkgs.system}))
        # add the NixOS configurations with the same system
        // (withPrefix "nixos-"
          (lib.mapAttrs (_: x: x.config.system.build.toplevel)
            (lib.filterAttrs (_: x: x.pkgs.system == pkgs.system)
              self.nixosConfigurations)))
        # add the Home Manager configurations with the same system
        // (withPrefix "home-" (lib.mapAttrs (_: x: x.activation-script)
          (lib.filterAttrs (_: x: x.pkgs.system == pkgs.system)
            self.homeConfigurations))));

    };
}
