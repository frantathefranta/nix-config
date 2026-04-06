# Taken from https://github.com/budimanjojo/nix-config/blob/main/system/hosts/budimanjojo-firewall/_modules/services/kea/default.nix
{ config, ... }:
let
  leaseOption = {
    valid-lifetime = 86400;
    renew-timer = 43200; # 50% of valid lifetime
    rebind-timer = 75600; # 87.5% of valid lifetime
  };
  commonDhcpOptions = [
    {
      name = "domain-name-servers";
      data = "10.0.10.1";
    }
    {
      name = "time-servers";
      data = "10.0.10.1";
    }
  ];
  keaddnsUser = "kea";
in
{
  services.resolved.enable = false;
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          "lan0"
          "lan0.20"
          "lan0.50"
          "lan0.920"
        ];
      };
      subnet4 = [
        (
          {
            id = 1;
            interface = "lan0";
            subnet = "10.0.10.0/24";
            pools = [ { pool = "10.0.10.50 - 10.0.10.199"; } ];
            option-data = [
              {
                name = "routers";
                data = "10.0.10.1";
              }
              {
                name = "domain-name";
                data = "franta.us";
              }
              {
                name = "domain-search";
                data = "franta.us";
              }
            ]
            ++ commonDhcpOptions;
          }
          // leaseOption
        )

        (
          {
            id = 2;
            interface = "lan0.20";
            subnet = "10.0.20.0/24";
            pools = [ { pool = "10.0.20.50 - 10.0.20.199"; } ];
            ddns-qualifying-suffix = "wifi.franta.us";
            option-data = [
              {
                name = "routers";
                data = "10.0.20.1";
              }
              {
                name = "domain-name";
                data = "wifi.franta.us";
              }
              {
                name = "domain-search";
                data = "wifi.franta.us";
              }
            ]
            ++ commonDhcpOptions;
          }
          // leaseOption
        )
        (
          {
            id = 3;
            interface = "lan0.50";
            subnet = "10.0.50.0/24";
            pools = [ { pool = "10.0.50.50 - 10.0.50.199"; } ];
            ddns-qualifying-suffix = "iot.franta.us";
            option-data = [
              {
                name = "routers";
                data = "10.0.50.1";
              }
              {
                name = "domain-name";
                data = "iot.franta.us";
              }
              {
                name = "domain-search";
                data = "iot.franta.us";
              }
            ]
            ++ commonDhcpOptions;
            reservations = [
              {
                hostname = "zigbee-poe";
                ip-address = "10.0.50.40";
                hw-address = "94:54:c5:eb:33:9f";
              }
              {
                hostname = "upper-bathroom-presence-sensor";
                ip-address = "10.0.50.94";
                hw-address = "f0:f5:bd:f8:88:b0";
              }
              {
                hostname = "freezer-temp-probe";
                ip-address = "10.0.50.95";
                hw-address = "a0:85:e3:26:7a:60";
              }
              {
                hostname = "fridge-temp-probe";
                ip-address = "10.0.50.96";
                hw-address = "a0:85:e3:26:41:e8";
              }
              {
                hostname = "prusa-mini";
                ip-address = "10.0.50.97";
                hw-address = "10:9c:70:0a:95:70";
              }
              {
                hostname = "emporiavue2";
                ip-address = "10.0.50.98";
                hw-address = "b8:d6:1a:9d:13:6c";
              }
              {
                hostname = "dreamevacuump2029";
                ip-address = "10.0.50.100";
                hw-address = "24:18:c6:14:5d:6e";
              }
              {
                hostname = "camera-yard";
                ip-address = "10.0.50.201";
                hw-address = "ec:71:db:c5:2a:94";
              }
              {
                hostname = "camera-sunroom";
                ip-address = "10.0.50.202";
                hw-address = "ec:71:db:f4:55:23";
              }
              {
                hostname = "amcrest-garage";
                ip-address = "10.0.50.203";
                hw-address = "9c:8e:cd:3e:32:31";
              }
            ];
          }
          // leaseOption
        )
        (
          {
            id = 4;
            interface = "lan0.920";
            subnet = "10.9.20.0/24";
            pools = [ { pool = "10.9.20.50 - 10.9.20.199"; } ];
            ddns-qualifying-suffix = "iot.franta.us";
            option-data = [
              {
                name = "routers";
                data = "10.9.20.1";
              }
              {
                name = "domain-name";
                data = "iot.franta.us";
              }
              {
                name = "domain-search";
                data = "iot.franta.us";
              }
            ]
            ++ commonDhcpOptions;
          }
          // leaseOption
        )
      ];
    };
  };
  users = {
    users.${keaddnsUser} = {
      isSystemUser = true;
      group = keaddnsUser;
    };
    groups.${keaddnsUser} = { };
  };

  sops.secrets."kea/tsig-key" = {
    sopsFile = ../secrets.yaml;
    owner = keaddnsUser;
    group = keaddnsUser;
  };

  services.kea = {
    dhcp4.settings = {
      dhcp-ddns.enable-updates = true;
      ddns-replace-client-name = "when-not-present";
      ddns-update-on-renew = true; # always update when a lease is renewed, in case I lost the DNS server database
      ddns-override-client-update = true; # always generate ddns update request ignoring the client's wishes not to
      ddns-override-no-update = true; # same as above but for different client's wishes
      ddns-qualifying-suffix = "franta.us";
    };
    dhcp-ddns = {
      enable = true;
      settings =
        let
          pdnsServer = [
            {
              ip-address = "10.0.10.1";
              port = 8853;
            }
          ];
        in
        {
          tsig-keys = [
            {
              name = "kea";
              algorithm = "hmac-sha512";
              secret-file = "${config.sops.secrets."kea/tsig-key".path}";
            }
          ];
          forward-ddns = {
            ddns-domains = [
              {
                name = "franta.us.";
                key-name = "kea";
                dns-servers = pdnsServer;
              }
              {
                name = "iot.franta.us.";
                key-name = "kea";
                dns-servers = pdnsServer;
              }
              {
                name = "wifi.franta.us.";
                key-name = "kea";
                dns-servers = pdnsServer;
              }
            ];
          };
          reverse-ddns = {
            ddns-domains = [
              {
                name = "10.in-addr.arpa.";
                key-name = "kea";
                dns-servers = pdnsServer;
              }
            ];
          };
        };
    };
  };
}
