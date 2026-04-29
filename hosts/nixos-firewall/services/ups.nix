{ config, ... }:

{
  power.ups = {
    enable = true;
    mode = "netserver";
    ups = {
      /*
        APC Smart UPS with NMC2 card (AP9631).
        Had to run "snmp -c1 public -n1 0.0.0.0" to allow access for SNMPv1
        No need to set privProtocol=AES as claimed in https://networkupstools.org/stable-hcl.html
      */
      "apc-rack-pdu01" = {
        driver = "snmp-ups";
        summary = ''
          mibs=apcc
          snmp_version=v1
        '';
        port = "apc-rack-pdu01.infra.franta.us";
      };
      "apc-usb" = {
        driver = "usbhid-ups";
        port = "/dev/input/event0";
      };
    };
    users."nut-admin" = {
      passwordFile = config.sops.secrets."nut/adminPassword".path;
      upsmon = "primary";
    };
    users."nut-view" = {
      passwordFile = config.sops.secrets."nut/viewPassword".path;
      upsmon = "secondary";
    };
    upsd.listen = [
      {
        address = "0.0.0.0";
      }
      {
        address = "::";
      }
    ];
    upsmon.monitor = {
      "apc-rack-pdu01" = {
        system = "apc-rack-pdu01@localhost";
        user = "nut-admin";
        powerValue = 1; # Number of power supplies that the UPS feeds on this system
        passwordFile = config.sops.secrets."nut/adminPassword".path;
      };
      # TODO: Cannot be seen for some reason
      # "apc-usb" = {
      #   system = "apc-usb@localhost";
      #   user = "nut-admin";
      #   powerValue = 0; # Number of power supplies that the UPS feeds on this system
      #   passwordFile = config.sops.secrets."ups/apcPassword".path;
      # };
    };
  };
  services.prometheus.exporters.nut = {
    enable = true;
  };
  networking.nftables.firewall.rules.allow_nut_access = {
    from = [
      "iot"
      "lab_space"
    ];
    to = [ "fw" ];
    allowedTCPPorts = [
      3493
      config.services.prometheus.exporters.nut.port
    ];
  };
  sops.secrets."nut/adminPassword" = {
    sopsFile = ../secrets.yaml;
  };
  sops.secrets."nut/viewPassword" = {
    sopsFile = ../../common/secrets.yaml;
  };
}
