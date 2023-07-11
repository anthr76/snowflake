{ pkgs, ... }: {
  home.packages = with pkgs; [ kubectl kubecolor kubelogin-oidc ];
  programs.fish.functions = {
    k = {
      wraps = "kubectl";
      body = "kubecolor $argv";
    };
  };
}
