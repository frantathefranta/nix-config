{
  config,
  lib,
  ...
}:
let
  topConfig = config;

  hostType = lib.types.submodule (
    { config, ... }:
    {
      options = {
        ipv4 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "172.20.0.1";
          description = "DN42 IPv4 address for this host.";
        };
        ipv4PrefixLength = lib.mkOption {
          type = lib.types.int;
          default = 32;
          description = "DN42 IPv4 prefix length.";
        };
        ipv6Subnet = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "0100";
          description = ''
            Full 4th group of the IPv6 address (16 bits, hex).
            Combined with meta.dn42.ipv6Prefix48 to form the node's /64 prefix:
            prefix48:ipv6Subnet::/64.
          '';
        };
        ipv6Suffix = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "0:0:0:1";
          description = ''
            IPv6 interface identifier (last 4 groups of a /64 address).
            Combined with resolvedIPv6Prefix64 to form the full address.
          '';
        };
        ipv6 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "fd42:aaaa:bbbb:0100::1";
          description = ''
            Explicit full IPv6 address. Takes precedence over ipv6Suffix.
            Use for hosts whose address does not follow the global prefix scheme.
          '';
        };
        ipv6PrefixLength = lib.mkOption {
          type = lib.types.int;
          default = 128;
          description = "IPv6 prefix length for the host address.";
        };
        resolvedIPv6Prefix64 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          readOnly = true;
          description = ''
            Resolved /64 prefix for this node (first 4 groups).
            Combines meta.dn42.ipv6Prefix48 with ipv6Subnet, or null if either is unset.
          '';
        };
        resolvedIPv6 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          readOnly = true;
          description = ''
            Resolved IPv6 address. Returns ipv6 if set, otherwise combines
            resolvedIPv6Prefix64 with ipv6Suffix, or null if neither is available.
          '';
        };
      };
      config = {
        resolvedIPv6Prefix64 =
          if topConfig.meta.dn42.ipv6Prefix48 != null && config.ipv6Subnet != null then
            "${topConfig.meta.dn42.ipv6Prefix48}:${config.ipv6Subnet}"
          else
            null;
        resolvedIPv6 =
          if config.ipv6 != null then
            config.ipv6
          else if config.resolvedIPv6Prefix64 != null && config.ipv6Suffix != null then
            "${config.resolvedIPv6Prefix64}:${config.ipv6Suffix}"
          else
            null;
      };
    }
  );
in
{
  options.meta.dn42 = {
    ipv6Prefix48 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "fd42:aaaa:bbbb";
      description = ''
        Global DN42 IPv6 /48 prefix (first 3 groups, 48 bits).
        Each node derives its /64 from this prefix plus its ipv6Subnet value.
      '';
    };

    host = lib.mkOption {
      type = hostType;
      default = { };
      description = "DN42 IPAM configuration for this host.";
      example = lib.literalExpression ''
        {
          ipv4 = "172.20.0.1";
          ipv6Subnet = "0100";
          ipv6Suffix = "0:0:0:1";
        }
      '';
    };

    region = lib.mkOption {
      type = lib.types.int;
      default = { };
      description = "DN42 region configuration for this host.";
      example = "42";
    };
    country = lib.mkOption {
      type = lib.types.int;
      default = { };
      description = ''
        DN42 country configuration for this host.
        Uses ISO-3166 country-code https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/blob/master/all/all.csv
      '';
      example = "840";
    };
  };
}
