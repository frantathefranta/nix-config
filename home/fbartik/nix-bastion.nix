{pkgs, ...}: {
  imports = [
    ./global
    ./features/kubectl
    ./features/productivity
  ];
}
