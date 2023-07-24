{ pkgs, ... }: {
  home.packages = with pkgs; [ kubectl kubecolor kubelogin-oidc kubernetes-helm ];
  programs.fish.functions = {
    k = {
      wraps = "kubectl";
      body = "kubecolor $argv";
    };
  };
}
