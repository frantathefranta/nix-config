{
  imports = [
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/optional/qemu-guest-agent.nix
    ../common/optional/1password.nix
    ../common/users/fbartik
  ];
  networking = {
    hostName = "nix-bastion";
    useDHCP = true;
    dhcpcd.IPv6rs = true;
    interfaces.ens18 = {
      useDHCP = true;
    };
    # hosts = {
    #   "10.33.35.1" = [
    #     "talos-actinium"
    #     "talos-actinium.infra.franta.us"
    #   ];
    #   "10.33.35.2" = [
    #     "talos-thorium"
    #     "talos-thorium.infra.franta.us"
    #   ];
    #   "10.33.35.3" = [
    #     "talos-protactinium"
    #     "talos-protactinium.infra.franta.us"
    #   ];
    #   "10.33.35.21" = [
    #     "talos-g3-mini"
    #     "talos-g3-mini.infra.franta.us"
    #   ];
    #   "10.33.35.22" = [
    #     "talos-n150-01"
    #     "talos-n150-01.infra.franta.us"
    #   ];
    # };
    # extraHosts = ''
    #   10.33.35.1 talos-actinium.infra.franta.us
    #   10.33.35.2 talos-thorium.infra.franta.us
    #   10.33.35.3 talos-actinium.infra.franta.us
    #   10.33.35.21 talos-g3-mini.infra.franta.us
    #   10.33.35.22 talos-n150-01.infra.franta.us
    # '';
  };
  system.stateVersion = "24.11";
}
