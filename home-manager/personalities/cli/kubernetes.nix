{ pkgs, ... }: {
  home.packages = with pkgs; [ kubectl kubecolor kubelogin-oidc kubernetes-helm stern fluxcd kubevirt ];
  programs.fish.functions = {
    k = {
      wraps = "kubectl";
      body = "kubecolor $argv";
    };
  };
}
