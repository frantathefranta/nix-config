{
  programs.rust-motd = {
    enable = true;
    settings = {
      uptime = { prefix = "Uptime"; };
      filesystems.root = "/";
      fail_2_ban.jails = [ "sshd" ];
    };
  };
}
