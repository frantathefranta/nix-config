{
  config,
  lib,
  pkgs,
  ...
}:

let
  haPython = pkgs.unstable.home-assistant.python3Packages;

  scryptedSdk = haPython.buildPythonPackage rec {
    pname = "scrypted-sdk";
    version = "0.1.1";
    pyproject = true;

    src = pkgs.unstable.fetchPypi {
      pname = "scrypted_sdk";
      inherit version;
      hash = "sha256-4RWoY5ANCs1V64/rw4HVCpx+x62/nbk/sO29Y7aDkvA=";
    };

    build-system = [ haPython.hatchling ];
    dependencies = with haPython; [
      aiodns
      aiohttp
      python-engineio
    ];
    pythonImportsCheck = [ "scrypted_sdk" ];

    meta = {
      description = "Python SDK for connecting to Scrypted servers";
      homepage = "https://github.com/koush/scrypted/tree/main/packages/python-client";
      license = lib.licenses.isc;
    };
  };

  scrypted = pkgs.unstable.buildHomeAssistantComponent rec {
    owner = "koush";
    domain = "scrypted";
    version = "0.1.0";

    src = pkgs.unstable.fetchFromGitHub {
      inherit owner;
      repo = "ha_scrypted";
      rev = "1486ca336170da4f9b335fea4ac20652ca333e4f";
      hash = "sha256-4tiBhlbl9WCcA2vDq1H3hfJlKhM6frvJyeXMcNB7wrU=";
    };

    dependencies = [ scryptedSdk ];

    meta = {
      description = "Home Assistant integration for Scrypted";
      homepage = "https://github.com/koush/ha_scrypted";
      license = lib.licenses.mit;
    };
  };

  keymaster = pkgs.unstable.buildHomeAssistantComponent rec {
    owner = "FutureTense";
    domain = "keymaster";
    version = "0.6.1";

    src = pkgs.unstable.fetchFromGitHub {
      inherit owner;
      repo = domain;
      tag = "v${version}";
      hash = "sha256-3jjEfIWVFgGEsD5URDvT3l8Do0dn9VDcer62nIIyiHM=";
    };

    meta = {
      description = "Home Assistant integration for managing access codes on smart locks";
      homepage = "https://github.com/FutureTense/keymaster";
      license = lib.licenses.gpl3Only;
    };
  };
in
{
  services.home-assistant = {
    enable = true;
    package =
      (pkgs.unstable.home-assistant.override {
        extraPackages =
          python3Packages: with python3Packages; [
            psycopg2
          ];
      }).overrideAttrs
        (_oldAttrs: {
          doInstallCheck = false;
        });

    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
    ];
    customComponents = with pkgs.unstable.home-assistant-custom-components; [
      scheduler
      browser-mod
      frigate
      keymaster
      scrypted
    ];
    customLovelaceModules = with pkgs.unstable.home-assistant-custom-lovelace-modules; [
      mini-graph-card
      button-card
      scheduler-card
      advanced-camera-card
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };

      backup = {};
      network = { };
      system_health = { };
      system_log = { };
      zeroconf = { };

      recorder.db_url = "postgresql://@/hass";
    };
  };
  networking.firewall.allowedTCPPorts = [
    config.services.home-assistant.config.http.server_port
  ];

}
