{inputs, pkgs, ...}: {
  home.packages = [inputs.attic.packages.${pkgs.system}.attic-client];
  programs.fish.functions = {
    nix-build-push = {
      description = "Build a nix package and push its full closure (including build deps) to an attic cache";
      body = ''
        if test (count $argv) -lt 2
          echo "Usage: nix-build-push <package> <cache>"
          echo "Example: nix-build-push .#cwctl attic-prod:cache"
          return 1
        end
        set -l package $argv[1]
        set -l cache $argv[2]

        echo "Building $package..."
        nix build -L $package; or return 1

        echo "Pushing build closure to $cache..."
        set -l drv (nix path-info --derivation $package)
        nix-store -qR --include-outputs "$drv" \
          | grep -v '\.drv$' \
          | while read -l p; test -e "$p" && echo "$p"; end \
          | xargs attic push $cache
      '';
    };
    devenv-build-push = {
      description = "Build devenv shell and push its closure to an attic cache";
      body = ''
        if test (count $argv) -lt 1
          echo "Usage: devenv-build-push <cache>"
          echo "Example: devenv-build-push attic-prod:cache"
          return 1
        end
        set -l cache $argv[1]

        echo "Building devenv shell..."
        devenv build; or return 1

        echo "Pushing shell closure to $cache..."
        attic push $cache .devenv/gc/shell
      '';
    };
  };
}
