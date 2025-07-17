{
  services = {
    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true; # Only necessary for Wayland apparently
      openFirewall = true;
    };
  };
}
