{ pkgs, config, ... }:
{
  home.packages = [ pkgs.rclone ];

  xdg.configFile."rclone/rclone-sftp.conf".text = ''
    [franta-music]
    type = sftp
    host = ssh.franta.dev
    key_use_agent = true
  '';

  systemd.user.services.rclone-music = {
    Unit = {
      Description = "rclone SFTP mount ssh.franta.dev:/music";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Music";
      ExecStart = "${pkgs.rclone}/bin/rclone mount --config=%h/.config/rclone/rclone-sftp.conf franta-music:/music %h/Music --vfs-cache-mode minimal --temp-dir=/tmp";
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u %h/Music";
      Environment = "SSH_AUTH_SOCK=%h/.1password/agent.sock";
    };
  };
}
