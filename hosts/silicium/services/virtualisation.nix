{
  virtualisation.incus = {
    enable = true;
  };
  networking = {
    firewall.trustedInterfaces = [ "incusbr0" ];
    nftables.enable = true;
  };
}
