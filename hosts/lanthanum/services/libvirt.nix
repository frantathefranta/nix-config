{
  config,
  pkgs,
  ...
}:

{
  # Set up virtualisation
  virtualisation.libvirtd = {
    enable = true;

    # Enable TPM emulation (for Windows 11)
    qemu = {
      swtpm.enable = true;
      # ovmf.packages = [ pkgs.OVMFFull ];
    };
  };

  # Enable USB redirection
  virtualisation.spiceUSBRedirection.enable = true;

  # Allow VM management
  users.groups.libvirtd.members = [ config.users.users.fbartik.name ];
  users.groups.kvm.members = [ config.users.users.fbartik.name ];

  # Enable VM networking and file sharing
  environment.systemPackages = with pkgs; [
    # ... your other packages ...
    swtpm
    OVMFFull
    gnome-boxes # VM management
    dnsmasq # VM networking
    phodav # (optional) Share files with guest VMs
  ];

  virtualisation.incus = {
    enable = true;
  };
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
}
