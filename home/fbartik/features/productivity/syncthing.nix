{
  services.syncthing = {
    enable = true;
    settings = {
      options = {
        localAnnounceEnabled = true;
      };
    };
  };
}
