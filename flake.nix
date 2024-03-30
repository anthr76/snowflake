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
    nixpkgs-pr-299036.url = "github:Shawn8901/nixpkgs?ref=fix-extest-extraenv";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, disko, nixpkgs, nixpkgs-unstable, home-manager, chaotic, jovian-nixos, nix-github-actions, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
      withPrefix = prefix: lib.mapAttrs' (name: value: { name = "${prefix}${name}"; inherit value; });
    in
    {
      githubActions = nix-github-actions.lib.mkGithubMatrix { inherit (self) checks; };
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
        # FIXME: eval issue
        # "lga-test1.tenant-29c7a3-baggie.coreweave.cloud" = lib.nixosSystem {
        #   specialArgs = { inherit inputs outputs; };
        #   modules = [
        #     ./nixos/hosts/lga-test1.tenant-29c7a3-baggie.coreweave.cloud
        #   ];
        # };
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
            jovian-nixos.nixosModules.jovian
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
        # FIXME: depends on packages that don't build on that system
        # "anthony@nicoles-mbp.nwk3.rabbito.tech" = lib.homeManagerConfiguration {
        #   pkgs = pkgsFor.x86_64-darwin;
        #   extraSpecialArgs = { inherit inputs outputs; };
        #   modules = [
        #     ./home-manager/hosts/nicoles-mbp.nwk3.rabbito.tech.nix
        #   ];
        # };
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

      # Run `nix flake check`
      checks = forEachSystem (pkgs:
        # add all the packages to checks
        (withPrefix "pkgs-" self.packages.${pkgs.system})
        # add the NixOS configurations with the same system
        //
        (withPrefix "nixos-"
          (lib.mapAttrs (_: x: x.config.system.build.toplevel)
            (lib.filterAttrs (_: x: x.pkgs.system == pkgs.system)
              self.nixosConfigurations)))
        # add the Home Manager configurations with the same system
        //
        (withPrefix "home-"
          (lib.mapAttrs (_: x: x.activation-script)
            (lib.filterAttrs (_: x: x.pkgs.system == pkgs.system)
              self.homeConfigurations)))
      );

    };
}
