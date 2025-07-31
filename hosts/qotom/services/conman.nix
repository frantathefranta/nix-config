{
  services.conman = {
    enable = true;
    extraConfig = ''
      console name="opnsense" dev="/dev/ttyS5" seropts="115200,8n1"
    '';
  };
}
