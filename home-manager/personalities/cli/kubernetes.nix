{ pkgs, ... }: {
  home.packages = with pkgs; [
    kubectl
    cilium-cli
    kubecolor
    kubelogin-oidc
    kubernetes-helm
    stern
    unstable.fluxcd
    kubevirt
  ];
  programs.fish.functions = {
    k = {
      wraps = "kubectl";
      body = "kubecolor $argv";
    };
  };
}
