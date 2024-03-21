{
  description = "anthr76 Flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:mic92/sops-nix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # SSH Agent
    nixpkgs-pr-169155.url = "github:nixos/nixpkgs?ref=2f0d2186cf8c98279625db83b527b1091107c61c";
    # TODO: Document this PR
    nixpkgs-pr-269415.url = "github:nixos/nixpkgs?ref=f4e7e4a19bb2ec8738caf0154ca2943776fca32b";
    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    # proton-ge-custom: init at 9-1
    nixpkgs-pr-294532.url = "github:NotAShelf/nixpkgs?ref=proton-ge";
  };

  outputs = { self, disko, nixpkgs, nixpkgs-unstable, home-manager, chaotic, ... }@inputs:
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
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
      nixosConfigurations = {
        "bkp1.nwk2.rabbito.tech" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/bkp1.nwk2.rabbito.tech
          ];
        };
        "lga-test1.tenant-29c7a3-baggie.coreweave.cloud" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/lga-test1.tenant-29c7a3-baggie.coreweave.cloud
          ];
        };
        "e39.nwk3.rabbito.tech" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/hosts/e39.nwk3.rabbito.tech
          ];
        };
        "octo.nwk3.rabbito.tech" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            chaotic.nixosModules.default
            ./nixos/hosts/octo.nwk3.rabbito.tech
          ];
        };
        "f80.nwk3.rabbito.tech" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            chaotic.nixosModules.default
            ./nixos/hosts/f80.nwk3.rabbito.tech
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
      homeConfigurations = {
        "anthony@bkp1.nwk2.rabbito.tech" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/hosts/bkp1.nwk2.rabbito.tech.nix
          ];
        };
        "anthony@lga-test1.tenant-29c7a3-baggie.coreweave.cloud" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/hosts/lga-test1.tenant-29c7a3-baggie.coreweave.cloud.nix
          ];
        };
        "anthony@e39.nwk3.rabbito.tech" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/hosts/e39.nwk3.rabbito.tech.nix
          ];
        };
        "anthony@nicoles-mbp.nwk3.rabbito.tech" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-darwin;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/hosts/nicoles-mbp.nwk3.rabbito.tech.nix
          ];
        };
        "steam@octo.nwk3.rabbito.tech" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/hosts/octo.nwk3.rabbito.tech.nix
          ];
        };
        "anthony@f80.nwk3.rabbito.tech" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/hosts/f80.nwk3.rabbito.tech.nix
          ];
        };
      };
    };
}
