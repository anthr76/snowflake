{ pkgs, ... }: {
  home.packages = with pkgs; [ kubectl kubecolor kubelogin-oidc helm ];
  programs.fish.functions = {
    k = {
      wraps = "kubectl";
      body = "kubecolor $argv";
    };
  };
}
