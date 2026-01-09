{ config, lib, pkgs, ... }:

{
  
  systemd.network.enable = true;
  systemd.network.netdevs."20-vrf_dn42" = {
    netdevConfig = {
      Name = "dn42";
      Kind = "vrf";
    };
    vrfConfig = {
      Table = 4242;
    };
  };
  systemd.network.netdevs."30-dummy42" = {
    netdevConfig = {
      Name = "dummy42";
      Kind = "dummy";
    };
  };
  systemd.network.networks."30-dummy42" = {
    matchConfig.Name = "dummy42";
    address = [
      "fdb7:c21f:f30f:2::1/128"
    ];
    networkConfig = {
      LinkLocalAddressing = false;
      IPv6LinkLocalAddressGenerationMode = "none";
      VRF = "dn42";
    };
  };
}
