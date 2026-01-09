{ outputs, ... }:

{
  imports = [
    ./vpsadminos.nix
    ../../hosts/common/global/nix.nix
    ../../hosts/common/global/sops.nix
  ]
  ++ (builtins.attrValues outputs.nixosModules);
  networking = {
    hostName = "nix-vps-cz";
  };
  services.openssh = {
    enable = true;

    # Allow root login with password, needed for passwords set through vpsAdmin
    settings.PermitRootLogin = "prohibit-password";

    # Needed for public keys deployed through vpsAdmin, can be disabled if you
    # authorize your keys in configuration
    authorizedKeysInHomedir = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt+w4TKskIFLpEfvHui00mf4sqoDHLuVDuyfRlG5GlYXPXyP1ow6kdwqDfS+KlOGVao6ekzdcUEDSUnuE++BGyYtvfIzZWSNhuOgeXcAnQNnikWpZQsHSTjrNhZr8W5OYT9Q6qz+1e+TcQ0K6oxkvE9Ydzt2fH5jIgLL/WDwIycPXkpCE9C9pEZVLGfUxrYvYSGdnDckKtG02S9JwcH9gi8E/T/P1UrArB9YDBbZtr6jAKINj2CHyvXMsU3vFdDcgoP0KGgb0eARuMvh9ec21rmsuj2xEMRvHdW3jt+OrMPqr4LgoHOpJAPP63yalL4srwT7i9HvQhpdsKhm5cyf3LYvrp3FAWFEJxZfIxbxwJKYjychgY89Sk7LWZj+dYArwP51WPzovMI2acUeoeb4cAk49KTLBnTHGuPxnQ83/eOUGquf2vJQA96MrXXOSeHMve0er2uJn/qxALFUOoI7ievFPIRMZnELe1vqw8Mm7o6zYn/OAEW93/QlvgWpZdIh0="
  ];

  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "900s";
  };

  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "x86_64-linux";
}
