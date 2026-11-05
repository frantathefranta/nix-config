{
  services.matterjs-server = {
    enable = true;
    extraArgs = [
      "--primary-interface=eno3.20"
      "--log-level=debug"
    ];
  };
}
