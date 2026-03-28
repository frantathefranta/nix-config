{ config, lib, pkgs, ... }:
{
  programs.rclone = {
    enable = true;
    remotes.franta-music = {
      config = {
        type = "sftp";
        host = "ssh.franta.dev";
        key_use_agent = false;
        key_file = "${config.home.homeDirectory}/.ssh/local_sshkey";
        known_hosts_file = "${config.home.homeDirectory}/.ssh/known_hosts";
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
    Service = {
      Environment = lib.mkForce [
        "PATH=/run/wrappers/bin"
        "SSH_AUTH_SOCK=%h/.1password/agent.sock"
      ];
      # On restart, the FUSE mount point may still be stale/busy.
      # Lazily unmount it first (-z), ignoring failure if not mounted (-).
      ExecStartPre = lib.mkForce [
        # Lazily unmount any stale FUSE mount BEFORE mkdir, otherwise mkdir
        # fails with "Transport endpoint is not connected" on a dead mountpoint.
        "-/run/wrappers/bin/fusermount -uz %h/Music"
        "${pkgs.coreutils}/bin/mkdir -p %h/Music"
      ];
      RestartSec = "10";
    };
    Install.WantedBy = lib.mkForce [ ];
  };
}
