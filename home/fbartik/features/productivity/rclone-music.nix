{ config, lib, ... }:
{
  programs.rclone = {
    enable = true;
    remotes.franta-music = {
      config = {
        type = "sftp";
        host = "ssh.franta.dev";
        key_use_agent = true;
      };
      mounts."/music" = {
        enable = true;
        mountPoint = "${config.home.homeDirectory}/Music";
        options.vfs-cache-mode = "minimal";
      };
    };
  };

  # The module hardcodes WantedBy = [ "default.target" ] with no opt-out,
  # and has no way to inject SSH_AUTH_SOCK. Override both here.
  # Service name is derived from: rclone-mount:<slashes-as-dots in path>@<remote>
  systemd.user.services."rclone-mount:.music@franta-music" = {
    Service.Environment = lib.mkForce [
      "PATH=/run/wrappers/bin"
      "SSH_AUTH_SOCK=%h/.1password/agent.sock"
    ];
    Install.WantedBy = lib.mkForce [ ];
  };
}
