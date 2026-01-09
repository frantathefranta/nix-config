{ config, pkgs, ... }:
{
  services.iperf3 = {
    enable = true;
    package = pkgs.unstable.iperf3;
    openFirewall = true;
    port = 52001;
    bind = "2600:1702:6630:3fed:10:32:10:11";
    # https://ittavern.com/iperf3-user-authentication-with-password-and-rsa-public-keypair/
    rsaPrivateKey = config.sops.secrets."iperf3/rsa-private-key".path;
    authorizedUsersFile = config.sops.secrets."iperf3/authorized-users".path;
  };
  sops.secrets = {
    "iperf3/rsa-private-key" = {
      sopsFile = ../secrets.yaml;
      mode = "0644";
    };
    "iperf3/authorized-users" = {
      sopsFile = ../secrets.yaml;
      mode = "0644";
    };
  };
}
