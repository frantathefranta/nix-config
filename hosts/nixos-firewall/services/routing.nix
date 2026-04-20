{
  services.bird = {
    enable = true;
    checkConfig = true;
    config = builtins.readFile ./bird.conf;
  };
}
