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
    akeyless
    unstable.fluxcd
    unstable.talosctl
    go-task
    jq
    krew
    kubecolor
    kubectl
    kubernetes-helm
    kustomize
    stern # Logs
  ];
  programs.fish = {
    interactiveShellInit = # fish
      ''
        set -q KREW_ROOT; and set -gx PATH $PATH $KREW_ROOT/.krew/bin; or set -gx PATH $PATH $HOME/.krew/bin
      '';
    shellAbbrs = {
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
  };
}
