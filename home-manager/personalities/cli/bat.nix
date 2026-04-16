{
  pkgs,
  inputs,
  ...
}: {
  programs.bat = {
    enable = true;
    # TODO: unstable nushell (transitive dep via bat-extras) fails its test
    # suite on darwin; pin batman to stable until fixed upstream.
    extraPackages = [inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.bat-extras.batman];
  };
  home.shellAliases = {
    "cat" = "bat -pp";
  };
  catppuccin.bat.enable = true;
}
