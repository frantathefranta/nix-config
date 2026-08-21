{
  nix = {
    sshServe = {
      enable = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBCywl0okd42aNipEyUmV4iXLxf17QzWSZDgXQFSPqk"
      ];
      protocol = "ssh";
      write = true;
      trusted = true;
    };
  };
}
