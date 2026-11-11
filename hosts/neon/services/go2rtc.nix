{ config, ... }:
{
  services.go2rtc = {
    enable = true;
    settings = {
      # Home Assistant runs locally; keep the unauthenticated API and RTSP local.
      api.listen = "127.0.0.1:1984";
      rtsp.listen = "127.0.0.1:8554";
      webrtc.listen = ":8555";
      streams = {
        sunroom = [
          "rtmp://10.0.50.201/bcs/channel0_main.bcs?channel=0&stream=0&user=admin&password=\${REOLINK_PASSWORD}"
          "rtmp://10.0.50.201/bcs/channel0_ext.bcs?channel=0&stream=1&user=admin&password=\${REOLINK_PASSWORD}"
          "rtmp://10.0.50.201/bcs/channel0_sub.bcs?channel=0&stream=1&user=admin&password=\${REOLINK_PASSWORD}"
        ];
        yard = [
          "rtmp://10.0.50.202/bcs/channel0_main.bcs?channel=0&stream=0&user=admin&password=\${REOLINK_PASSWORD}"
          "rtmp://10.0.50.202/bcs/channel0_ext.bcs?channel=0&stream=1&user=admin&password=\${REOLINK_PASSWORD}"
          "rtmp://10.0.50.202/bcs/channel0_sub.bcs?channel=0&stream=1&user=admin&password=\${REOLINK_PASSWORD}"
        ];
      };
    };
  };

  sops.secrets."go2rtc/env" = {
    sopsFile = ../secrets.yaml;
    restartUnits = [ "go2rtc.service" ];
  };
  systemd.services.go2rtc.serviceConfig.EnvironmentFile = config.sops.secrets."go2rtc/env".path;

  networking.firewall = {
    allowedTCPPorts = [ 8555 ];
    allowedUDPPorts = [ 8555 ];
  };
}
