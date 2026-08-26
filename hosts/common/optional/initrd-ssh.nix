{
  config,
  ...
}:

let
interface = config.systemd.network.networks."10-mgmt";
in
{
  boot.initrd = {
    systemd.network = {
      enable = true;
      networks.backup = {
        matchConfig.Name = interface.matchConfig.Name;
        address = interface.address;
      };
    };
    network = {
      enable = true;
      ssh = {
        enable = true;
        authorizedKeys = config.users.users.fbartik.openssh.authorizedKeys.keys;
        hostKeys = [
          config.sops.secrets."initrd-ssh/ssh_host_rsa_key".path
          config.sops.secrets."initrd-ssh/ssh_host_ed25519_key".path
        ];
      };
    };
  };
  sops.secrets."initrd-ssh/ssh_host_rsa_key".sopsFile = ../secrets.yaml;
  sops.secrets."initrd-ssh/ssh_host_ed25519_key".sopsFile = ../secrets.yaml;
}
