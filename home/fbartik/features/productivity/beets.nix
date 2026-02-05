{
  config,
  pkgs,
  ...
}:

{
  programs.beets = {
    enable = true;
    package = (
      pkgs.python313Packages.beets.override {
        pluginOverrides = {
          badfiles.enable = true;
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
            propagatedBuildInputs = [ pkgs.beets-originquery ];
          };
        };
      }
    );
    settings = {
      directory = "/music";
      # library = "/config/library.db";
      art_filename = "cover";
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
        log = "/config/beet.log";
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
        minwidth = "600";
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

}
