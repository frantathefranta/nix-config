## Inspiration
[Misterio77/nix-config](https://github.com/Misterio77/nix-config) - file structure

## New server bootstrap
### Server-side
1. Boot it up with NixOS (ideally with a modified liveCD so SSH already works). If SSH isn't set up, get a video/serial output from the server and set a password for the nixos user.
2. Save the generated `ed25519` SSH private/public key off of the server.

### Repo-side
1. Add a `nixosConfigurations` stanza for the new host:
``` nix
        qotom = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/qotom
          ];
        };
```
2. Add a basic folder structure for the host:
``` sh
hosts/qotom
├── default.nix
├── hardware-configuration.nix
├── ssh_host_ed25519_key.pub
└── ssh_host_rsa_key.pub
```
3. Convert public ed25519 key into an age key

``` sh
nix-shell -p ssh-to-age --run "ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub"
```
4. Add public key to `.sops.yaml`
5. Run `nixos-anywhere` with the `--copy-host-keys` option, which will preserve the SSH keys (if you don't do that, you'll lock yourself out)

``` sh
nix run github:nix-community/nixos-anywhere -- --flake .#qotom --target-host nixos@10.32.10.10 --copy-host-keys
```
