# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  system-tarball-extlinux = import ./system-tarball-extlinux.nix;
  custom-wireguard = import ./custom-wireguard.nix;
  vep14xx-fan-curve = import ./vep14xx-fan-curve.nix;
  # conman = import ./conman.nix;
}
