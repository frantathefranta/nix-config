{ pkgs, ... }:

{
  programs.k9s = {
    enable = true;
    package = pkgs.unstable.k9s;
    plugin = {
      reconcile-git = {
        shortCut = "Shift-R";
        confirm = false;
        description = "Flux reconcile";
        scopes = [ "gitrepositories" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          ">-"
          "flux"
          "--context $CONTEXT"
          "reconcile source git"
          "-n $NAMESPACE $NAME"
          "| less -K"
        ];
      };
      reconcile-hr = {
        shortCut = "Shift-R";
        confirm = false;
        description = "Flux reconcile";
        scopes = [ "helmreleases" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          ">-"
          "flux"
          "--context $CONTEXT"
          "reconcile helmrelease"
          "-n $NAMESPACE $NAME"
          "| less -K"
        ];
      };
      stern = {
        shortCut = "Ctrl-Y";
        confirm = false;
        description = "Logs <stern>";
        scopes = [ "pods" ];
        command = "${pkgs.stern}/bin/stern";
        background = false;
        args = [
          "--tail"
          "50"
          "$FILTER"
          "-n $NAMESPACE"
          "--context $CONTEXT"
        ];
      };
    };
  };
  home.packages = with pkgs; [
    unstable.fluxcd
    unstable.talosctl
    stern # Logs
    go-task
    jq
    kubectl
    kubernetes-helm
    kubecolor
    kustomize
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
