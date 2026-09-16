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
  users.users.nixos = {
    isNormalUser = true;
    group = "users";
    openssh.authorizedKeys.keys = lib.splitString "\n" (
      builtins.readFile ../../home/fbartik/ssh.pub
    );
  };
  environment.systemPackages = [
    pkgs.gitMinimal
  ];
  networking.hostName = "nixos-installer";
  time.timeZone = "America/Detroit";
  /*
    Headless boxes boot over the serial console. Bake it into the kernel command
    line so it's the default for EVERY boot-menu entry: nixpkgs iso-image.nix puts
    cfg.boot.kernelParams into each isolinux APPEND / grub linux line. boot.kernelParams
    is an accumulating list option, so this coexists with the CD defaults
    (nohibernate, root=fstab, loglevel=4, lsm=...). Without this you must pick the
    "Serial console=ttyS0,115200n8" submenu entry every boot.
  */
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  security = {
    sudo.wheelNeedsPassword = false;
  };
  # Required to satisfy nix flake check assertions; actual values don't matter
  # for image builds since build-image/isoImage replace the filesystem layout.
  fileSystems."/" = lib.mkDefault { device = "none"; fsType = "tmpfs"; };
  boot.loader.grub.enable = lib.mkDefault false;

  nixpkgs.hostPlatform = "x86_64-linux";
}
