{ pkgs, inputs, lib, ... }: {
  home.packages = with pkgs.channels.latest; [
    helix
    # This should be in a wrapper of some kind.
    # https://matrix.to/#/!zMuVRxoqjyxyjSEBXc:matrix.org/$f9HORMP9NMcg5k3U4Lz94Q7HM3vg8zCwpLRoVyl4puo?via=matrix.org&via=mozilla.org&via=tchncs.de
    # https://github.com/nix-community/home-manager/issues/2923
    # https://github.com/nix-community/home-manager/issues/2921
    terraform-ls
    rnix-lsp
    gopls
    nodePackages.dockerfile-language-server-nodejs
    nodePackages.bash-language-server    
  ];

  # TODO: https://github.com/nix-community/home-manager/issues/2921 
  # programs.helix = {
  #   enable = true;
  # };
}
