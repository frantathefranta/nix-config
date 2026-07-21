# Manual steps:
# 1. bootctl status
# 2. Make sure you have BIOS password and disk encryption
# 3. sbctl create-keys
# 4. Put secure boot into setup mode
# 5. sbctl enroll-keys --microsoft
# 6. Enable secure boot
# 7. systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12+13+14+15:sha256=0000000000000000000000000000000000000000000000000000000000000000 --wipe-slot=tpm2 <DEVICE>
#      Explanation:
#      - PCR7: Secure boot is on
#      - PCR0+2: UEFI integrity
#      - PCR12+13+14: Boot loader integrity
#      - PCR15: No LUKS partition has been opened yet
{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      autoGenerateKeys.enable = true;
      # autoEnrollKeys = {
      #   enable = true;
      #   autoReboot = true;
      # };
    };
  };

  environment.systemPackages = [ pkgs.sbctl ];
  # environment.persistence = {
  #   "/persist".directories = [{directory = "/var/lib/sbctl";}];
  # };

  /* fwupd's compiled-in EFI_APP_LOCATION defaults to the read-only
     fwupd-efi store path, but lanzaboote's fwupd-efi.service signs the
     binary into /run/fwupd-efi and (in fwupd < 2.1.6) relied on the
     FWUPD_EFIAPPDIR env var to point fwupd there. That env var was removed
     upstream, so we now have to bake /run/fwupd-efi in at build time via
     the efi_app_location meson option instead (needs fwupd from
     nixpkgs-unstable for that option to exist). */
  services.fwupd.package = lib.mkIf config.services.fwupd.enable (
    pkgs.unstable.fwupd.overrideAttrs (old: {
      mesonFlags = map (
        flag: if lib.hasPrefix "-Defi_app_location=" flag then "-Defi_app_location=/run/fwupd-efi" else flag
      ) old.mesonFlags;
    })
  );
}
