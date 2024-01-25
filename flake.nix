{
  description = "anthr76 Flakes";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: Add any other flake you might need
    hardware = {
     url = "github:nixos/nixos-hardware";
    };

    sops-nix.url = "github:mic92/sops-nix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # SSH Agent
    nixpkgs-pr-169155.url = "github:nixos/nixpkgs?ref=2f0d2186cf8c98279625db83b527b1091107c61c";
    nixpkgs-pr-269415.url = "github:nixos/nixpkgs?ref=f4e7e4a19bb2ec8738caf0154ca2943776fca32b";
    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kde2nix = {
      url = "github:nix-community/kde2nix";
    };
    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, disko, nixpkgs, home-manager, hyprland, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
    in
    {
      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
      overlays = import ./overlays { inherit inputs outputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # FIXME replace with your hostname
        "bkp1.nwk2.rabbito.tech" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main nixos configuration file <
            ./nixos/hosts/bkp1.nwk2.rabbito.tech
          ];
        };
        "lga-test1.tenant-29c7a3-baggie.coreweave.cloud" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main nixos configuration file <
            ./nixos/hosts/lga-test1.tenant-29c7a3-baggie.coreweave.cloud
          ];
        };
        "e39.nwk3.rabbito.tech" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main nixos configuration file <
            ./nixos/hosts/e39.nwk3.rabbito.tech
          ];
        };
        # TODO: error: getting status of '/nix/store/hosts/iso': No such file or director
        # Nix can be so weird..
        # iso = nixpkgs.lib.nixosSystem {
        #   specialArgs = { inherit inputs outputs; };
        #   modules = [
        #     # > Our main nixos configuration file <
        #     ./nixos/image-generators
        #   ];
        # };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # FIXME replace with your username@hostname
        "anthony@bkp1.nwk2.rabbito.tech" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./home-manager/hosts/bkp1.nwk2.rabbito.tech.nix
          ];
        };
        "anthony@lga-test1.tenant-29c7a3-baggie.coreweave.cloud" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./home-manager/hosts/lga-test1.tenant-29c7a3-baggie.coreweave.cloud.nix
          ];
        };
        "anthony@e39.nwk3.rabbito.tech" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./home-manager/hosts/e39.nwk3.rabbito.tech.nix
          ];
        };
        "anthony@nicoles-mbp.nwk3.rabbito.tech" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-darwin;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./home-manager/hosts/nicoles-mbp.nwk3.rabbito.tech.nix
          ];
        };
      };
    };
}
