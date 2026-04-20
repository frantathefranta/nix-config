{ lib, config, ... }:
{
  services.timesyncd = {
    servers = lib.mkIf (config.networking.domain == "infra.franta.us") ["time.infra.franta.us"];
    # fallbackServers are 0.nixos.pool.ntp.org 1.nixos.pool.ntp.org 2.nixos.pool.ntp.org 3.nixos.pool.ntp.org
  };
}
