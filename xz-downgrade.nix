{ pkgs, config, inputs, ... }:
{
    system.replaceRuntimeDependencies = [
        {
            original = pkgs.xz;
            replacement = inputs.nixpkgs-staging-next.legacyPackages.${pkgs.system}.xz;
        }
    ];
}