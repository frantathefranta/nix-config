{
  outputs,
  lib,
  ...

}:
let
  nixosConfigs = builtins.attrNames outputs.nixosConfigurations;
  homeConfigs = map (n: lib.last (lib.splitString "@" n)) (
    builtins.attrNames outputs.homeConfigurations
  );
  hostnames = lib.unique (homeConfigs ++ nixosConfigs);
in
{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "brocade*" = {
        user = "admin";
        identityFile = "~/.ssh/brocade_2048";
        extraOptions = {
          KexAlgorithms = "+diffie-hellman-group1-sha1";
          HostKeyAlgorithms = "+ssh-rsa";
          PubkeyAcceptedAlgorithms = "+ssh-rsa";
        };
      };
      "github.com" = {
        identityFile = "~/.ssh/git_key";
      };
      "*" = {
        identityAgent = "~/.1password/agent.sock";
      };
      net = {
        host = lib.concatStringsSep " " (
          lib.flatten (
            map (host: [
              host
              "${host}.franta.us"
              "${host}.infra.franta.us"

            ]) hostnames
          )
        );
      };
    };
  };
}
