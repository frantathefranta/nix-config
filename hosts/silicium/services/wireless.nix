{
  config,
  pkgs,
  ...
}:

let
  wpaActionScript = pkgs.writeShellScript "wpa-action" ''
    case "$2" in
      CONNECTED)
        sleep 2
        ${pkgs.systemd}/bin/networkctl reconfigure "$1"
        ;;
    esac
  '';
in

{
  hardware.bluetooth = {
    enable = true;
  };
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
    # neededForUsers = true;
  };

  networking.wireless = {
    enable = true;
    # Declarative
    secretsFile = config.sops.secrets.wireless.path;
    networks = {
      "VPWHBNCHzxLr" = {
        pskRaw = "ext:VPWHBNCHzxLr";
        authProtocols = [ "WPA-PSK" ];
      };
    };
    allowAuxiliaryImperativeNetworks = false;
    # extraConfig = ''
    #   ctrl_interface=DIR=/run/wpa_supplicant GROUP=${config.users.groups.network.name}
    #   update_config=1
    # '';
  };
  # Ensure group exists
  users.groups.network = { };
  # systemd.services.wpa_supplicant.preStart = "touch /etc/wpa_supplicant.conf";

  # systemd.services.wpa-action = {
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "wpa_supplicant.service" ];
  #   requires = [ "wpa_supplicant.service" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.wpa_supplicant}/bin/wpa_cli -i wlp3s0 -a ${wpaActionScript}";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #   };
  # };
}
