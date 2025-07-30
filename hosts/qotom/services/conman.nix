{
  services.conman = {
    enable = true;
    extraConfig = ''
      console="opnsense" dev="/dev/ttyS5" seropts="115200,8n1"
    '';
  };
}
