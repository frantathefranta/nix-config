{
  config,
  ...
}:
{
  # smartmontools monitoring for SATA drives
  services.smartd = {
    enable = true;
    notifications.mail = {
      sender = (config.networking.hostName) + "-smartd" + "@" + (config.services.postfix.settings.main.mydomain);
      recipient = "admin@franta.us";
      enable = true;
    };
  };
}
