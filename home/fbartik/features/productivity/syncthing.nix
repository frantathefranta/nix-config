{
  services.syncthing = {
    enable = true;
    settings = {
      options = {
        localAnnounceEnabled = true;
      };
    };
    overrideDevices = false;
    overrideFolders = false;
  };
}
