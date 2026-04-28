_: {
  services.udpbroadcastrelay = {
    enable = true;
    instances = {
      ssdp = {
        port = 1900;
        id = 1;
        interfaces = [
          "lan0.20"
          "lan0.50"
        ];
        multicast = "239.255.255.250";
      };
      # mdns = {
      #   port = 5353;
      #   id = 1;
      #   interfaces = [
      #     "lan0.20"
      #     "lan0.50"
      #     "lan0.920"
      #     "lan0.950"
      #   ];
      #   multicast = "224.0.0.251";
      # };
      # syncthing = {
      #   port = 21027;
      #   id = 2;
      #   interfaces = [
      #     "lan0"
      #   ];
      # };
    };

  };
}
