{
  config,
  pkgs,
  lib,
  ...
}:
let
  beetsdir = "/music/beets";
  backup-script = pkgs.writeShellScript "beets-backup-script" /* bash */ ''
    ${pkgs.coreutils}/bin/echo "Starting db backup...\n"
    SERVICE="restic-backups-beets.service"
    ${pkgs.systemdMinimal}/bin/systemctl start --user $SERVICE
    ID=$(systemctl show --value -p InvocationID $SERVICE)
    ${pkgs.systemdMinimal}/bin/journalctl -q _SYSTEMD_INVOCATION_ID=$ID
  '';

in
{
  programs.beets = {
    enable = true;
    package = (
      pkgs.unstable.python3Packages.beets.override {
        pluginOverrides = {
          badfiles.enable = true;
          beetcamp = {
            enable = true;
            propagatedBuildInputs = [ pkgs.unstable.python3Packages.beetcamp ];
          };
          convert.disable = true;
          replaygain.disable = true;
          deezer.enable = true;
          discogs.enable = true;
          duplicates.enable = true;
          edit.enable = true;
          embedart.enable = true;
          fetchart.enable = true;
          fish.enable = true;
          plexupdate.enable = true;
          originquery = {
            enable = true;
            propagatedBuildInputs = [
              (pkgs.unstable.python3Packages.callPackage ../../../../pkgs/beets-originquery { })
            ];
          };
        };
      }
    );
    settings = {
      directory = "/music";
      library = "${beetsdir}/library.db";
      statefile = "${beetsdir}/state.pickle";
      art_filename = "cover";
      include = [ "${config.sops.secrets."beets/musicbrainz.yaml".path}" ];
      threaded = "yes";
      original_date = "yes";
      per_disc_numbering = "yes";
      plugins = [
        "duplicates"
        "hook"
        "badfiles"
        "discogs"
        "deezer"
        "ftintitle"
        "mbsync"
        "mbcollection"
        "musicbrainz"
        "edit"
        "the"
        "fromfilename"
        "inline"
        "info"
        "bandcamp"
        "embedart"
        "originquery"
        "plexupdate"
        "fetchart"
      ];
      hook = {
        event = "cli_exit";
        command = "${pkgs.bash}/bin/bash ${backup-script}";
      };
      originquery = {
        origin_file = "TrackerMetadata/red - Release.json";
        tag_patterns = {
          media = "$.torrent.media";
          year = "$.torrent.remasterYear";
          label = "$.torrent.remasterRecordLabel";
          catalognum = "$.torrent.remasterCatalogueNumber";
          albumdisambig = "$.torrent.remasterTitle";
        };
      };
      asciify_paths = "yes";
      import = {
        write = "yes";
        copy = "yes";
        resume = "ask";
        incremental = "yes";
        incremental_ask_later = "no";
        quiet_fallback = "skip";
        timid = "yes";
        log = "${beetsdir}/beet.log";
        bell = "yes";
        duplicate_action = "ask";
      };
      match = {
        preferred = {
          media = [
            "Digital Media|File"
            "CD"
          ];
        };
      };
      discogs = {
        source_weight = "0.0";
        index_tracks = "yes";
      };
      replace = {
        "^\." = "_";
        "[\x00-\x1f]" = "_";
        "[\xE8-\xEB]" = "e";
        "[\xEC-\xEF]" = "i";
        "[\xE2-\xE6]" = "a";
        "[\xF2-\xF6]" = "o";
        "[\xF8]" = "o";
        "\.$" = "_";
        "\s+$" = "''";
      };
      ftintitle = {
        auto = "yes";
      };
      # acoustid = {
      #   apikey = "{{.ACOUSTID_API_KEY}}";
      # };
      # musicbrainz = {
      #     user = "{{.MB_USER}}";
      #     pass = "'{{.MB_PASS}}'";
      #     extra_tags = "[year, catalognum, country, media, label]";
      # };
      the = {
        a = "no";
        the = "yes";
      };
      # acousticbrainz = {
      #     auto = "yes";
      item_fields = {
        deezer = "1 if media in [''] else 0";
        multidisc = "1 if disctotal > 1 else 0";
        surround = "1 if channels > 2 else 0";
      };
      bandcamp = {
        art = "yes";
      };
      # plex = {
      #   host = "plex.franta.us";
      #   port = "32400";
      #   token = "{{.PLEX_TOKEN}}";
      #   library_name = "Music";
      # };
      badfiles = {
        check_on_import = "yes";
        commands = {
          flac = "flac --test --silent";
        };
      };
      embedart = {
        auto = "no";
      };
      fetchart = {
        auto = "yes";
        minwidth = 600;
        sources = "coverart itunes amazon albumart wikipedia lastfm fanarttv";
        # lastfm_key = "{{.LASTFM_API_KEY}}";
        # fanarttv_key = "{{.FANART_API_KEY}}";
      };
      paths = {
        singleton = "Non-Album/$albumartist/$album/$artist - $title";
        #comp = "Compilations/$albumartist - %if{$original_year,$original_year,$year} - $album%aunique{} - [%if{$deezer,Digital Media,$media}%if{$label,$, $label}%if{$catalognum,$, $catalognum}]/%if{$multidisc,Disc $disc/}$track - $title";
        albumtype_soundtrack = "Soundtracks/$album/$track $title";
        default = "%if{$surround,surround,stereo}/%the{$albumartist}/$albumartist - %if{$original_year,$original_year,$year} - $album%aunique{} - [%if{$deezer,Digital Media,$media}%if{$label,$, $label}%if{$catalognum,$, $catalognum}]/%if{$multidisc,Disc $disc/}$track - $title";
      };
    };
  };
  services.restic.enable = true;
  services.restic.backups.beets = (
    lib.mkIf (builtins.length config.monitors == 0) {
      paths = [ beetsdir ];
      initialize = true;
      repositoryFile = config.sops.secrets."restic/beets".path;
      passwordFile = config.sops.secrets."restic/password".path;
      environmentFile = config.sops.secrets."restic/s3-credentials".path;
      timerConfig = null;
    }
  );

  sops.secrets = {
    "beets/musicbrainz.yaml" = {
      sopsFile = ../../secrets.yml;
    };
    "restic/beets" = {
      sopsFile = ../../secrets.yml;
    };
    "restic/password" = {
      sopsFile = ../../secrets.yml;
    };
    "restic/s3-credentials" = {
      sopsFile = ../../secrets.yml;
    };
  };
}
