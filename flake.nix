{
  description = "My nix config";
  nixConfig = {
    extra-substituters = [
      "https://frantathefranta.cachix.org"
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "frantathefranta.cachix.org-1:7bZkmbZyIToRYYH7uI7ItS9l8/X5Hw2TPzAfqOIme1I="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };
  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # Nixpkgs
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    systems.url = "github:nix-systems/default";
    hardware = {
      url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs-unstable";

    };
    gobgp = {
      url = "github:wavelens/gobgp.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    vpsadminos = {
      url = "github:vpsfreecz/vpsadminos";
      inputs.nixpkgsUnstable.follows = "nixpkgs-unstable";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote?ref=refs/tags/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs.nixpkgs.follows = "nixpkgs-unstable";

    };
    nnf.url = "github:thelegy/nixos-nftables-firewall";
    nixos-dns = {
      url = "github:Janik-Haag/nixos-dns";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix - secrets with mozilla sops
    # https://github.com/Mic92/sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      # Home manager
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Emacs
    # emacs-overlay.url = "github:nix-community/emacs-overlay";
    # emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nh.url = "github:nix-community/nh?ref=refs/tags/v4.4.1";
    disko = {
      url = "github:nix-community/disko?ref=refs/tags/v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      systems,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs (import systems) (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );
      mkServer =
        hostname:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            isStableHM = true;
          };
          modules = [ ./hosts/${hostname} ];
        };
      mkWorkstation =
        hostname:
        inputs.nixpkgs-unstable.lib.nixosSystem {
          specialArgs = {
            inherit outputs;
            isStableHM = false;
            inputs = inputs // {
              home-manager = inputs.home-manager-unstable;
            };
          };
          modules = [ ./hosts/${hostname} ];
        };
      dnsConfig = {
        inherit (self) nixosConfigurations;
        extraConfig = import ./dns.nix;
      };
    in
    {
      inherit lib;
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages = forEachSystem (
        pkgs:
        let
          generate = inputs.nixos-dns.utils.generate pkgs;
        in
        (import ./pkgs {
          inherit pkgs;
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit (pkgs) system;
            config.allowUnfree = true;
          };
        })
        // {
          zoneFiles = generate.zoneFiles dnsConfig;
          octodns = generate.octodnsConfig {
            inherit dnsConfig;
            config = {
              providers = {
                bind = {
                  class = "octodns_bind.Rfc2136Provider";
                  host = "2600:1702:6630:3fed::242";
                  port = 53;
                  ipv6 = true;
                  key_name = "env/AXFR_KEY_NAME";
                  key_secret = "env/AXFR_KEY_SECRET";
                  key_algorithm = "hmac-sha256";
                };
                powerdns = {
                  class = "octodns_powerdns.PowerDnsProvider";
                  host = "ns1.franta.us";
                  api_key = "env/POWERDNS_API_KEY";
                };
                desec = {
                  class = "octodns_desec.DesecProvider";
                  token = "env/DESEC_TOKEN";
                };
              };
            };
            zones = {
              "franta.dn42." = inputs.nixos-dns.utils.octodns.generateZoneAttrs [ "bind" ];
              "f.0.3.f.f.1.2.c.7.b.d.f.ip6.arpa." = {
                sources = [
                  "config"
                  "auto-arpa"
                ];
                targets = [ "bind" ];
              };
              "infra.franta.us." = inputs.nixos-dns.utils.octodns.generateZoneAttrs [ "powerdns" ];
              "cloud.franta.us." = inputs.nixos-dns.utils.octodns.generateZoneAttrs [
                "desec"
              ];
              "e.f.3.0.3.6.6.2.0.7.1.0.0.6.2.ip6.arpa." = {
                sources = [
                  "config"
                  "auto-arpa"
                ];
                targets = [ "powerdns" ];
              };
            };
            manager.auto_arpa = true;
          };
        }
      );
      formatter = forEachSystem (pkgs: pkgs.alejandra);
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });

      hydraJobs = import ./hydra.nix { inherit inputs outputs; };
      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs outputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        lanthanum = mkWorkstation "lanthanum";
        silicium = mkWorkstation "silicium";

        installer-iso = mkServer "installer-iso";
        molybdenum = mkServer "molybdenum";
        nix-bastion = mkServer "nix-bastion";
        nix-hetzner = mkServer "nix-hetzner";
        nix-oci = mkServer "nix-oci";
        nix-vultr = mkServer "nix-vultr";
        nix-vps-cz = mkServer "nix-vps-cz";
        nixos-firewall = mkServer "nixos-firewall";
        qotom = mkServer "qotom";
        # r2s = mkServer "r2s";
        hydrogen = mkServer "hydrogen";
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        "fbartik@nix-bastion" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {
            inherit inputs outputs;
            hostname = "nix-bastion";
            isStableHM = true;
          };
          modules = [
            # > Our main home-manager configuration file <
            ./home/fbartik/nix-bastion.nix
            ./home/fbartik/nixpkgs.nix
          ];
        };
        "fbartik@NC312237" = inputs.home-manager-unstable.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs-unstable {
            system = "aarch64-darwin";
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs outputs;
            isStableHM = false;
          };
          modules = [
            ./home/fbartik/NC312237.nix
            ./home/fbartik/nixpkgs.nix
          ];
        };
      };
    };
}
