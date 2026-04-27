{ lib, ... }:
{
  services.openssh.settings = {
    # Restrict to modern key exchange, ciphers, and MACs
    KexAlgorithms = [
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
      "diffie-hellman-group14-sha256"
    ];
    Ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
    ];
    Macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
      "umac-128-etm@openssh.com"
    ];
    HostKeyAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com";

    # Reduce brute-force window
    LoginGraceTime = 30;
    MaxAuthTries = 3;
    MaxSessions = 5;
    # Start dropping unauthenticated connections at 10, hard cap at 20
    MaxStartups = "10:30:20";

    # Drop idle sessions after ~10 min (5 min interval × 2 missed pings)
    ClientAliveInterval = 300;
    ClientAliveCountMax = 2;

    # Explicit auth method
    AuthenticationMethods = "publickey";

    GatewayPorts = lib.mkForce "no";
  };
}
