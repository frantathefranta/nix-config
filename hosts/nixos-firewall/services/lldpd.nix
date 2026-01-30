{ ... }:

{
  services.lldpd = {
    enable = true;
    extraArgs = [
      "-m mgmt" # Select mgmt interface for advertising management IP
      # "-I !wan0,mgmt" # Don't advertise on wan interface, do advertise on mgmt
    ];
  };
}
