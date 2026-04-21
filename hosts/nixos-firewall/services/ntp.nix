{
  services = {
    timesyncd.enable = false;
    ntpd-rs = {
      enable = true;
      settings = {
        server = [
          { listen = "0.0.0.0:123"; }
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
