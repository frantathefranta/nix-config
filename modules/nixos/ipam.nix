{
  config,
  lib,
  ...
}:
let
  topConfig = config;

  # lib.types.macAddr is not available in the pinned nixpkgs.
  macAddr = lib.types.mkOptionType {
    name = "macAddr";
    description = "a MAC address";
    check =
      v: builtins.match "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}" (toString v) != null;
    merge = loc: defs: lib.mergeOverrideMerge loc (v: v) defs;
  };

  hostType = lib.types.submodule (
    { config, ... }:
    {
      options = {
        ipv4 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "10.32.10.90";
          description = "IPv4 address for this host.";
        };
        ipv4PrefixLength = lib.mkOption {
          type = lib.types.int;
          default = 24;
          description = "IPv4 prefix length.";
        };
        macAddress = lib.mkOption {
          type = lib.types.nullOr macAddr;
          default = null;
          example = "52:54:00:12:34:56";
          description = ''
            Primary NIC MAC address for this host.
            Used to track hardware identity alongside the IP assignments.
          '';
        };
        ipv6Suffix = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "10:32:10:90";
          description = ''
            IPv6 interface identifier (last 4 groups of a /64 address).
            Combined with meta.ipam.ipv6Prefix to form the full address.
          '';
        };
        ipv6 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "2a01:4ff:1f0:d924::1";
          description = ''
            Explicit full IPv6 address. Takes precedence over ipv6Suffix.
            Use for hosts whose IPv6 does not follow the global prefix scheme.
          '';
        };
        ipv6PrefixLength = lib.mkOption {
          type = lib.types.int;
          default = 64;
          description = "IPv6 prefix length.";
        };
        resolvedIPv6 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          readOnly = true;
          description = ''
            Resolved IPv6 address. Returns ipv6 if set, otherwise combines
            meta.ipam.ipv6Prefix with ipv6Suffix, or null if neither is available.
          '';
        };
      };
      config.resolvedIPv6 =
        if config.ipv6 != null then
          config.ipv6
        else if config.ipv6Suffix != null && topConfig.meta.ipam.ipv6Prefix != null then
          "${topConfig.meta.ipam.ipv6Prefix}:${config.ipv6Suffix}"
        else
          null;
    }
  );
in
{
  options.meta.ipam = {
    ipv6Prefix = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "2600:1702:6630:3fed";
      description = ''
        Global IPv6 /64 prefix. Combined with each host's ipv6Suffix to form
        the full host address: prefix:suffix.
      '';
    };

    host = lib.mkOption {
      type = hostType;
      default = { };
      description = "IPAM configuration for this host.";
      example = lib.literalExpression ''
        {
          ipv4 = "10.32.10.90";
          macAddress = "52:54:00:12:34:56";
          ipv6Suffix = "10:32:10:90";
        }
      '';
    };
  };
}
