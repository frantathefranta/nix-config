{ config, lib, pkgs, ... }:
let
  yaml = pkgs.formats.yaml { };
  configFile = yaml.generate "go2rtc.yaml" config.services.go2rtc.settings;
  initialState = yaml.generate "go2rtc-state.yaml" {
    homekit = {
      sunroom.name = "Sunroom";
      yard.name = "Yard";
    };
  };
in
{
  services.go2rtc = {
    enable = true;
    settings = {
      # HomeKit shares the API listener; firewall access is limited to VLAN 20.
      api.listen = ":1984";
      rtsp.listen = "127.0.0.1:8554";
      webrtc.listen = ":8555";
      srtp.listen = ":8443";
      streams = {
        sunroom = [
          "rtmp://10.0.50.201/bcs/channel0_main.bcs?channel=0&stream=0&user=admin&password=\${REOLINK_PASSWORD}"
          "rtmp://10.0.50.201/bcs/channel0_ext.bcs?channel=0&stream=1&user=admin&password=\${REOLINK_PASSWORD}"
          "rtmp://10.0.50.201/bcs/channel0_sub.bcs?channel=0&stream=1&user=admin&password=\${REOLINK_PASSWORD}"
          "ffmpeg:sunroom#audio=opus"
        ];
        yard = [
          "rtmp://10.0.50.202/bcs/channel0_main.bcs?channel=0&stream=0&user=admin&password=\${REOLINK_PASSWORD}"
          "rtmp://10.0.50.202/bcs/channel0_ext.bcs?channel=0&stream=1&user=admin&password=\${REOLINK_PASSWORD}"
          "rtmp://10.0.50.202/bcs/channel0_sub.bcs?channel=0&stream=1&user=admin&password=\${REOLINK_PASSWORD}"
          "ffmpeg:yard#audio=opus"
        ];
      };
    };
  };

  sops.secrets."go2rtc/env" = {
    sopsFile = ../secrets.yaml;
    restartUnits = [ "go2rtc.service" ];
  };
  systemd.services.go2rtc = {
    # go2rtc writes API changes to the first config file. Seed it only once.
    # Keep HomeKit settings here so later Nix settings don't replace pairings.
    preStart = ''
      if [ ! -e /var/lib/go2rtc/state.yaml ]; then
        ${pkgs.coreutils}/bin/install -m 0600 ${initialState} /var/lib/go2rtc/state.yaml
      fi
    '';
    serviceConfig = {
      EnvironmentFile = config.sops.secrets."go2rtc/env".path;
      ExecStart = lib.mkForce "${lib.getExe config.services.go2rtc.package} -config /var/lib/go2rtc/state.yaml -config ${configFile}";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 8555 ];
    allowedUDPPorts = [ 8555 ];
    interfaces."eno3.20" = {
      allowedTCPPorts = [ 1984 ]; # HomeKit pairing/control and go2rtc API.
      allowedUDPPorts = [ 8443 ]; # HomeKit SRTP media.
    };
  };
}
