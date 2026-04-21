{ config, pkgs, ... }:
{
  # security.acme = {
  #   acceptTerms = true;
  #   defaults.email = "franta@franta.us";
  #   certs."znc.franta.us" = {
  #     dnsProvider = "cloudflare";
  #     environmentFile = config.sops.secrets."acme/cloudflare".path;
  #     group = "znc";
  #   };
  # };
  # User auth taken from https://discourse.nixos.org/t/znc-config-without-putting-password-hash-in-configuration-nix/14236/3
  users.users."znc-admin" = {
    isSystemUser = true;
    group = "znc-admin";
    hashedPasswordFile = config.sops.secrets."znc/admin".path;
  };
  users.groups."znc-admin" = { };

  # cyrusauth module talks to saslauthd, default auth mechanism is PAM
  services.saslauthd.enable = true;

  environment.etc = {
    # need to add a PAM service config, cyrusauth identifies itself as "znc"
    # very standard config, copied from others in /etc/pam.d
    # just checks that you have a valid account/password
    "pam.d/znc" = {
      source = pkgs.writeText "znc.pam" ''
        # Account management.
        account required pam_unix.so

        # Authentication management.
        auth sufficient pam_unix.so likeauth try_first_pass
        auth required pam_deny.so

        # Password management.
        password sufficient pam_unix.so nullok sha512

        # Session management.
        session required pam_env.so conffile=/etc/pam/environment readenv=0
        session required pam_unix.so
      '';
    };
  };

  # znc service config has some hardening options that otherwise block
  # interaction with saslauthd's unix socket
  systemd.services.znc.serviceConfig.RestrictAddressFamilies = [ "AF_UNIX" ];

  services.znc = {
    enable = true;
    mutable = false;
    useLegacyConfig = false;
    modulePackages = [ pkgs.zncModules.playback ];
    config = {
      Listener.l = {
        Port = 6697;
        IPv4 = true;
        IPv6 = true;
        SSL = true;
        SSLCertFile = "/var/lib/acme/znc.franta.us/full.pem";
      };
      LoadModule = [
        "adminlog"
        "cyrusauth saslauthd"
        "corecaps"
        "playback"
      ];
      User."znc-admin" = {
        Admin = true;
        # fake hash, auth against this will always fail, user can only login via SASL
        # znc compains if you have no Pass
        Pass = "md5#::#::#";
        Nick = "franta";
        AltNick = "frantathefranta";
        Ident = "franta";
        Network."hackint" = {
          LoadModule = [ "simple_away" "chansaver" ];
          Server = "irc.hackint.org +6697";
          Chan = { "#dn42-registry" = { Detached = false; }; };
        };
      };
    };
  };
  sops.secrets."znc/admin" = {
    sopsFile = ../secrets.yaml;
  };
  sops.secrets."znc/hackint-sasl" = {
    sopsFile = ../secrets.yaml;
  };
  sops.secrets."acme/cloudflare" = {
    sopsFile = ../secrets.yaml;
  };
}
