{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    unstable.wrtag
  ];
  home.file.".config/wrtag/config" = {
    text = ''
      path-format /music/stereo/{{ artists .Release.Artists | sort | join "; " | safepath }}/{{ .Release.Title | safepath }}{{ if not (eq .ReleaseDisambiguation "") }} ({{ .ReleaseDisambiguation | safepath }}){{ end }} ({{ .Release.ReleaseGroup.FirstReleaseDate.Year }}) [{{ .Media.Format}}]/{{ if gt (len .Release.Media) 1 }}{{ .Media.Position }}{{ end }}{{ pad0 2 .Track.Position }} {{ if .IsCompilation }}{{ artistsString .Track.Artists | safepath }} - {{ end }}{{ .Track.Title | safepath }}{{ .Ext }}

      research-link apple-music https://music.apple.com/search?term={{ printf "%s %s" .Artist .Album | urlquery }}

      keep-file origin.yaml
    '';
  };
}
