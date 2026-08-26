{
  config,
  ...
}:

{
  services = {
    hostapd = {
      enable = true;
      radios.wlp2s0 = {
        countryCode = "US";
        networks.wlp2s0 = {
          ssid = "qotom";
          ignoreBroadcastSsid = "empty"; # Hides the SSID
          authentication = {
            wpaPasswordFile = config.sops.secrets.wpa-password.path;
            mode = "wpa2-sha256";
          };

        };
      };
    };
  };
  networking = {
    firewall.interfaces.wlp2s0.allowedUDPPorts = [
      67 # DHCP server
    ];
    nat = {
      enable = true;
      internalInterfaces = [ "wlp2s0" ];
      externalInterface = "enp1s0";
    };
  };
  systemd.network.networks."40-wlp2s0" = {
    matchConfig.Name = "wlp2s0";
    address = [ "172.32.254.1/27" ];
    # networkConfig.DHCPServer = true;
    # dhcpServerConfig = {
    #   # PoolSubnet = "172.32.254.16/29"; # 172.32.254.16 - 172.32.254.31
    #   PoolSize = 16;
    #   ServerAddress = "172.32.254.1";
    # };
  };

  sops.secrets.wpa-password = {
    sopsFile = ../secrets.yaml;
  };
}
