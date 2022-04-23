{ pkgs, lib, ... }: {
  home.packages = with pkgs; [ kubectl kubecolor kubelogin-oidc ];
  programs.fish.functions = {
    k = "kubecolor $argv";
  };
}
