{ ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };
  networking = {
    firewall.enable = false;
    nat.enable = false;
    nftables = {
      enable = true;
      flushRuleset = true;
      tables = {
        home_nat = {
          family = "ip";
          content = ''
            chain PREROUTING {
              type nat hook prerouting priority dstnat; policy accept;
            }
            chain POSTROUTING {
              type nat hook postrouting priority srcnat; policy accept;
              oifname "wan0" ip daddr 0.0.0.0/0 counter masquerade comment "outbound will use the public IP so I can browse internet"
            }
          '';
        };
      };
    };
  };
}
