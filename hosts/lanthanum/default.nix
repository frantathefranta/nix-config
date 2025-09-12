{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/kde.nix
    ../common/optional/1password.nix
    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "lanthanum";
    # useDHCP = true;
    # dhcpcd.IPv6rs = true;
    interfaces.eno1 = {
      ipv4 = {
        addresses = [
          {
            address = "10.254.0.2";
            prefixLength = 30;
          }
        ];
        routes = [
          {
            address = "0.0.0.0";
            prefixLength = 0;
            via = "10.254.0.1";
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = "2600:1702:6630:3fec::254:1";
            prefixLength = 127;
          }
        ];
        routes = [
          {
            address = "::";
            prefixLength = 0;
            via = "2600:1702:6630:3fec::254:0";
          }
        ];
      };
    };
    nameservers = [
      "10.33.10.0"
      "10.33.10.1"
    ];
    # vlans = {
    #   vlan33 = { id=33; interface="eno1"; };
    # };
    # interfaces.vlan33 = {
    #   useDHCP = true;
    # };
    firewall.interfaces.enp1s0.allowedTCPPorts = [
      22000
    ];
    firewall.interfaces.enp1s0.allowedUDPPorts = [
      21027
      22000
    ];
  };
  # services.frr = {
  #   ospf6d = {
  #     enable = true;
  #   };
  #   config = ''
  #     interface eno1
  #       ipv6 ospf6 area 0.0.0.0
  #       ipv6 ospf6 instance-id 0
  #     router ospf6
  #       ospf6 router-id 10.254.0.2
  #   '';
  # };

  programs = {
    dconf.enable = true;
    steam.enable = true;
  };
  services.xserver.videoDrivers = [ "nvidia"];
  hardware = {
    graphics.enable = true;
    nvidia.modesetting.enable = true;
    nvidia.open = true;
    nvidia.powerManagement.enable = true;
    nvidia.nvidiaPersistenced = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    enableAllFirmware = true;
  };
  environment.systemPackages = with pkgs; [
    nvme-cli
    vial
    via
  ];
  services.udev.packages = with pkgs; [
    vial
    via
  ];
  fonts.packages = with pkgs; [
    etBembo
  ];
  system.stateVersion = "24.11";
}
