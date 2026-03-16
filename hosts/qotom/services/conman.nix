{ config, ... }:
{
  services.conman = {
    enable = true;
    configFile = config.sops.secrets."conman.conf".path;
  };
  # This will make conman wait until USB serial device is ready
  systemd.services.conmand.after = [ "sys-devices-pci0000:00-0000:00:14.0-usb2-2-4-2-4:1.0-ttyUSB0-tty-ttyUSB0.device" ];
  sops.secrets."conman.conf" = {
    sopsFile = ../secrets.yaml;
  };
}
