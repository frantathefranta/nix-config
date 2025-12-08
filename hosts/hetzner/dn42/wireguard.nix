{ config, lib, pkgs, ... }:

{
  services.custom-wireguard.interfaces."50-wg42424242" = {
    listenPort = "50000";
    peerEndpoint = "google.com:50000";
    peerPublicKey = "EC1Jv5z/AejlMRL44ultM8rVm8tpOnsbwJNy8/iAYUo=";
  };
}
