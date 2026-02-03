{
  config,
  ...
}:

{
  hardware.bluetooth = {
    enable = true;
  };
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  networking.wireless = {
    enable = true;
    # Declarative
    secretsFile = config.sops.secrets.wireless.path;
    networks = {
      "VPWHBNCHzxLr" = {
        pskRaw = "ext:VPWHBNCHzxLr";
	authProtocols = ["WPA-PSK"];
      };
    };
    allowAuxiliaryImperativeNetworks = true;
    extraConfig = ''
      ctrl_interface=DIR=/run/wpa_supplicant GROUP=${config.users.groups.network.name}
      update_config=1
      '';
  };
  # Ensure group exists
  users.groups.network = {};
  systemd.services.wpa_supplicant.preStart = "touch /etc/wpa_supplicant.conf";
}
