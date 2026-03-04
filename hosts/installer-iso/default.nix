{
  modulesPath,
  lib,
  pkgs,
  ...
}:

{
  /*
    Only import installation-cd-minimal.nix if using nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage
    If using nixos-rebuild build-image (or nh os build-image), this is not necessary
  */
  # imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
  # isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  users.users.nixos.openssh.authorizedKeys.keys = lib.splitString "\n" (
    builtins.readFile ../../home/fbartik/ssh.pub
  );
  environment.systemPackages = [
    pkgs.gitMinimal
  ];
  networking.hostName = "nixos-installer";
  time.timeZone = "America/Detroit";
  security = {
    sudo.wheelNeedsPassword = false;
  };
  nixpkgs.hostPlatform = "x86_64-linux";
}
