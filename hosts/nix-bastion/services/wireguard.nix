{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.wireguard-tools ];
  networking.firewall.interfaces = {
    ens18 = {
      allowedUDPPorts = [ 41000 ];
    };
    wg_mikrotik = {
      allowedTCPPorts = [ 179 ];
    };
  };
  services.custom-wireguard.interfaces = {
    "50-wg_mikrotik" = {
      listenPort = 41000;
      peerEndpoint = "mikrotik.eu.franta.us:41000";
      peerPublicKey = "BkpNRSaQbXazDzVSfyLGnV6WKdVfiRdyTx9YSPWsNwk=";
      peerAddressV6 = "fe80::1/64";
      localAddressV6 = "fe80::2";
    };
  };
}
