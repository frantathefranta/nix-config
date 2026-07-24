{ ... }:
{
  imports = [
    ./global
  ];
  sops.age.keyFile = null;
  home.stateVersion = "26.05";
}
