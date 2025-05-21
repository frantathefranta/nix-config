{pkgs, ...}: {
  imports = [
    ./global
    ./features/kubectl
  ];
}
