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
  python = pkgs.unstable.python3Packages;
  beets = (
    python.beets.override {
      pluginOverrides = {
        badfiles.enable = true;
        beetcamp = {
          enable = true;
          propagatedBuildInputs = [ python.beetcamp ];
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
            (python.callPackage ../../../../pkgs/beets-originquery { })
          ];
        };
      };
    }
  );
  secret = config.sops.secrets;

in
{
  programs.beets = {
    enable = true;
    package = beets;
    settings = {
      directory = "/music";
      library = "${beetsdir}/library.db";
      statefile = "${beetsdir}/state.pickle";
      art_filename = "cover";
      include = [
        "${secret."beets/musicbrainz.yaml".path}"
        "${secret."beets/plex.yaml".path}"
        "${secret."beets/discogs.yaml".path}"
      ];
      threaded = "yes";
      original_date = "yes";
      per_disc_numbering = "yes";
      plugins = [
        "badfiles"
        "bandcamp"
        "deezer"
        "discogs"
        "duplicates"
        "edit"
        "embedart"
        "fetchart"
        "fish"
        "fromfilename"
        "ftintitle"
        "hook"
        "info"
        "inline"
        "mbcollection"
        "mbsync"
        "musicbrainz"
        "originquery"
        "plexupdate"
        "the"
      ];
      hook = {
        event = "import";
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
        data_source_mismatch_penalty = "0.1";
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
      musicbrainz = {
        data_source_mismatch_penalty = "0.0";
      };
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
      badfiles = {
        check_on_import = true;
        commands = {
          flac = "${pkgs.flac}/bin/flac --test --silent";
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
    "beets/discogs.yaml" = {
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
    "beets/plex.yaml" = {
      sopsFile = ../../secrets.yml;
    };
  };
}
