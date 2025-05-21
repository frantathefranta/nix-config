{ pkgs, ... }:

{
  programs.k9s.enable = true;
  home.packages = with pkgs; [
    fluxcd
    go-task
    jq
    kubectl
    kubernetes-helm
    kubecolor
    kustomize
    talosctl
  ];
  programs.fish.shellAbbrs = {
    k = {
      position = "anywhere";
      expansion = "kubectl";
    };
    kubectl = {
      position = "anywhere";
      expansion = "kubecolor";
    };
    kd = {
      position = "anywhere";
      expansion = "kubectl describe";
    };
    kg = {
      position = "anywhere";
      expansion = "kubectl get";
    };
  };
}
