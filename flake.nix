{
  description = "My nix config";
  nixConfig = {
    extra-substituters = [
      "https://nix-cache.infra.franta.us"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-cache.infra.franta.us:0CrUfMACpZRvB1x9CkcHs54BSqjz6L3TAZYRbI/YpCo="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {

    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    oh-my-pi = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin-x64.follows = "nixpkgs";
    };

    comin = {
      url = "github:frantathefranta/comin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";
    hardware = {
      url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";

    };
    gobgp = {
      url = "github:wavelens/gobgp.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote?ref=refs/tags/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs.nixpkgs.follows = "nixpkgs";

    };
    nnf.url = "github:thelegy/nixos-nftables-firewall";
    nixos-dns = {
      url = "github:Janik-Haag/nixos-dns";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ssm (Secure Shell Manager) -- keyboard TUI to browse/tag the nix-generated
    # SSH hosts. Pulled as a plain source (flake = false) and built ourselves:
    # the upstream flake's pinned Go-module (vendor) hash is stale for current
    # nixpkgs, so building via its flake fails a hash check.
    ssm-src = {
      url = "github:lfaoro/ssm?rev=f8f1bb65f7012fac5ed302c560a0fe3bd0335fdc";
      flake = false;
    };
    # Cloud hosts (cloud.franta.us) live in a separate repo, pulled in as a plain
    # source (flake = false) so its flake input graph stays out of our lock.
    # Only the host list is read from its flake.nix.
    nix-cloud-src = {
      url = "git+https://git.franta.us/franta/nix-cloud";
      flake = false;
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
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
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Emacs
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    nh = {
      url = "github:nix-community/nh?ref=refs/tags/v4.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko?ref=refs/tags/v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    moonshine = {
      url = "github:hgaiser/moonshine";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-init = {
      url = "github:nix-community/nix-init";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mlnx-ofed-nixos = {
      url = "github:codgician/mlnx-ofed-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-tramp-rpc = {
      url = "github:ArthurHeymans/emacs-tramp-rpc";
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
      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            name = hostname;
          };
          modules = [ ./hosts/${hostname} ];
        };
      dnsConfig = {
        inherit (self) nixosConfigurations;
        extraConfig = import ./dns.nix;
      };
      # Servers managed by comin; workstations and the installer stay manual.
      serverHosts = [
        "hydrogen"
        "ytterbium"
        "nix-bastion"
        "nixos-firewall"
        "qotom"
        "neon"
      ];
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
        })
        // {
          zoneFiles = generate.zoneFiles dnsConfig;
          octodns = generate.octodnsConfig {
            inherit dnsConfig;
            config = {
              providers = {
                powerdns = {
                  class = "octodns_powerdns.PowerDnsProvider";
                  host = "ns1.franta.us";
                  api_key = "env/POWERDNS_API_KEY";
                };
              };
            };
            zones = {
              "infra.franta.us." = inputs.nixos-dns.utils.octodns.generateZoneAttrs [ "powerdns" ];
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
      devShells = forEachSystem (
        pkgs:
        import ./shell.nix {
          inherit pkgs;
        }
      );

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
        lanthanum = mkHost "lanthanum";
        silicium = mkHost "silicium";

        installer-iso = mkHost "installer-iso";
        # r2s = mkHost "r2s";
      }
      // lib.genAttrs serverHosts mkHost;

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        "fbartik@NC312237" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor.aarch64-darwin;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
          modules = [
            ./home/fbartik/NC312237.nix
            ./home/fbartik/nixpkgs.nix
          ];
        };
      };
    };
}
