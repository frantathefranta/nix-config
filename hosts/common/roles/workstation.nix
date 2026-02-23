{ lib, ... }:
{
  imports = [
    ../optional/1password.nix
  ];
  # Sound via pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  # Hardware support
  hardware = {
    bluetooth.enable = lib.mkDefault true;
    enableRedistributableFirmware = lib.mkDefault true;
  };
  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true; # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
  security.tpm2.tctiEnvironment.enable = true; # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables
  users.users.fbartik.extraGroups = [ "tss" ]; # tss group has access to TPM devices
  # Smart cards
  services.pcscd.enable = true;
  programs.yubikey-manager.enable = true;

  # Printing
  services.printing.enable = lib.mkDefault true;

  # Graphical boot
  boot.plymouth.enable = lib.mkDefault true;
}
