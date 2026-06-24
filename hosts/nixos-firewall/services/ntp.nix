{
  services = {
    timesyncd.enable = false;
    ntpd-rs = {
      enable = true;
      settings = {
        server = [
          { listen = "[::]:123"; }
        ];
      };
      # settings = {
      #   source = [
      #     "time.cloudflare.com"
      #   ];
      # };
    };
  };
}
