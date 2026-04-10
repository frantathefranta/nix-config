_: {
  services.udpbroadcastrelay = {
    enable = true;
    instances = {
      mdns = {
        port = 5353;
        id = 1;
        interfaces = [
          "lan0.20"
          "lan0.50"
          "lan0.920"
          "lan0.950"
        ];
        multicast = "224.0.0.251";
      };
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
