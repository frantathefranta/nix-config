# Taken from https://github.com/budimanjojo/nix-config/blob/main/system/hosts/budimanjojo-firewall/_modules/services/powerdns/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  directory = "/var/lib/pdns";
  user = "pdns";
  group = "pdns";
in
{
  systemd.tmpfiles.rules = [ "d ${directory} 0750 ${user} ${group}" ];

  sops.secrets."powerdns/env" = {
    sopsFile = ../secrets.yaml;
    owner = user;
    group = group;
  };

  services.powerdns = {
    enable = true;
    extraConfig = ''
      local-address=10.0.10.1:53 # TODO: Add lan0 IPv6 address
      launch=gsqlite3
      gsqlite3-database=${directory}/pdns.sqlite3
      dnsupdate=yes
      # allow-dnsupdate-from=192.168.10.1/32
      default-soa-content=@ gateway.franta.us. 0 7200 3600 120960 3600
    '';
    secretFile = config.sops.secrets."powerdns/env".path;
  };

  systemd.services.pdns.serviceConfig = {
    # powerdns doesn't create the sqlite database for us
    # so we gotta either do it manually one-off or do the below to ensure it's created
    # if the file is missing before service start
    ExecStartPre = lib.mkBefore [
      (pkgs.writeScript "pdns-sqlite-init.sh" ''
        #!${pkgs.bash}/bin/bash

        pdns_folder="${directory}"
        echo "INIT: checking if pdns sqlite exists"
        if [ ! -f "${directory}/pdns.sqlite3" ]; then
          echo "INIT: no sqlite db found, initializing from pdns pkgs schema..."
          ${pkgs.sqlite}/bin/sqlite3 "${directory}/pdns.sqlite3" < "${pkgs.pdns}/share/doc/pdns/schema.sqlite3.sql"
          ${pkgs.busybox}/bin/chown pdns:pdns ${directory}/pdns.sqlite3
        fi

        # exit successfully
        exit 0
      '')
    ];
    ExecStartPost = (
      pkgs.writeScript "pdns-ddns-setup.sh" ''
        #!${pkgs.bash}/bin/bash

        cmd=${pkgs.pdns}/bin/pdnsutil

        add_record_if_missing() {
          local zone="$1" name="$2" type="$3" content="$4"
          if $cmd list-zone "$zone" 2>/dev/null | grep -qF "$content"; then
            echo "INIT: record $name $type $content already exists, skipping"
          else
            $cmd add-record "$zone" "$name" "$type" "$content"
          fi
        }

        $cmd create-zone franta.us. || true
        $cmd create-zone 10.in-addr.arpa. || true
        add_record_if_missing franta.us. ns1 A 10.0.10.1
        add_record_if_missing 10.in-addr.arpa. @ NS 1.10.0.10.in-addr.arpa.
        add_record_if_missing franta.us. @ NS ns1.franta.us.

        $cmd import-tsig-key kea hmac-sha512 $KEA_TSIG_KEY
        $cmd set-meta franta.us. TSIG-ALLOW-DNSUPDATE kea
        $cmd set-meta 10.in-addr.arpa. TSIG-ALLOW-DNSUPDATE kea
      ''
    );
  };
}
