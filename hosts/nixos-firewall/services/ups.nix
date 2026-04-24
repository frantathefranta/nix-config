{ config, ... }:

{
  power.ups = {
    enable = true;
    mode = "netserver";
    /*
      APC Smart UPS with NMC2 card (AP9631).
      Had to run "snmp -c1 public -n1 0.0.0.0" to allow access for SNMPv1
      No need to set privProtocol=AES as claimed in https://networkupstools.org/stable-hcl.html 
    */
    ups."apc-rack-pdu01" = {
      driver = "snmp-ups";
      summary = ''
        mibs=apcc
        snmp_version=v1
      '';
      port = "apc-rack-pdu01.infra.franta.us";
    };
    users."nut-admin" = {
      passwordFile = config.sops.secrets."ups/apcPassword".path;
      upsmon = "primary";
    };
    upsmon.monitor."apc-rack-pdu01" = {
      system = "apc-rack-pdu01@localhost";
      user = "nut-admin";
      powerValue = 1; # Number of power supplies that the UPS feeds on this system
      passwordFile = config.sops.secrets."ups/apcPassword".path;
    };
  };
  services.prometheus.exporters.nut = {
    enable = true;
  };
  networking.nftables.firewall.rules.allow_nut_access = {
    from = [ "lab_space" ];
    to = [ "fw" ];
    allowedTCPPorts = [ config.services.prometheus.exporters.nut.port ];
  };
  sops.secrets."ups/apcPassword" = {
    sopsFile = ../secrets.yaml;
  };
}
