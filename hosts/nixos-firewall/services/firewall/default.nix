{ ... }:
{
  networking = {
    firewall.enable = false;
    nat.enable = false;
    nftables = {
      enable = true;
      flushRuleset = true;
      tables = {
        home_nat = {
          family = "ip";
          content = /* nft */ ''
            chain PREROUTING {
              type nat hook prerouting priority dstnat; policy accept;
            }
            chain POSTROUTING {
              type nat hook postrouting priority srcnat; policy accept;
              oifname "wan0" ip daddr 0.0.0.0/0 counter masquerade comment "outbound will use the public IP so I can browse internet"
            }
          '';
        };
        home_ip_filter = {
          family = "inet";
          content = ''
            chain STATE_POLICY {
              ct state established counter accept
              ct state related counter accept
              return
            }

            ${builtins.readFile ./config/sets.nft}
            ${builtins.readFile ./config/zone-rules.nft}
            ${builtins.readFile ./config/zone-directions.nft}
          '';
        };
        # home_ip6_filter = {
        #   family = "ip6";
        #   content = ''
        #     chain STATE_POLICY {
        #       ct state established counter accept
        #       ct state related counter accept
        #       return
        #     }

        #     ${builtins.readFile ./config/sets-ipv6.nft}
        #     ${builtins.readFile ./config/zone-rules.nft}
        #     ${builtins.readFile ./config/zone-directions.nft}
        #     # chain ZONE_INPUT {
        #     #   type filter hook input priority filter + 1; policy accept;
        #     #   jump STATE_POLICY
        #     #   iifname "lo" counter return
        #     #   counter drop comment "default-action drop"
        #     # }

        #     # # ZONE_FORWARD is disabled for ipv6 in sysctl above

        #     # chain ZONE_OUTPUT {
        #     #   type filter hook output priority filter + 1; policy accept;
        #     #   jump STATE_POLICY
        #     #   oifname "lo" counter return
        #     #   counter drop comment "default-action drop"
        #     # }
        #   '';
        # };
      };
    };
  };
}
