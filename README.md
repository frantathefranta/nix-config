## Inspiration
[Misterio77/nix-config](https://github.com/Misterio77/nix-config) - file structure

--image-variant iso-installer .#installer-iso --hostname installer-iso## Building an installer ISO
`nh` has added a way to replicate `nixos-rebuild build-image` functionality
``` shell
nix run github:nix-community/nh -- os build-image --image-variant iso-installer .#installer-iso --hostname installer-iso
```
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


## Credentials
Direnv loads only the Nix development shell; entering the repo does not query
1Password or export credentials. Enable 1Password CLI desktop integration or
sign in with `op signin`. No service-account token is fetched automatically.

The `just` recipes use `op run` to resolve task-specific `op://` references only
when invoked. Credentials are scoped to the command and its child processes,
not exported into your interactive shell.

After updating `.envrc`, run `direnv allow` and let your shell reload it to remove
the previously injected environment variables.

## Terraform
Use the wrapper with a stack name (`garage` or `uptimekuma`) and tofu arguments:
``` sh
$ just tofu garage init
$ just tofu garage plan
$ just tofu garage apply
$ just tofu uptimekuma apply
```
Each stack has its own `terraform/<stack>/.env.1password` file. Without `just`:
``` sh
$ op run --env-file=terraform/garage/.env.1password -- tofu -chdir=terraform/garage apply
$ op run --env-file=terraform/uptimekuma/.env.1password -- tofu -chdir=terraform/uptimekuma apply
```
Commands that don't need credentials can still run directly, e.g.
`tofu -chdir=terraform/garage fmt`.

## DNS
The root `.1password` file contains only the PowerDNS API key. DNS recipes build
the config first, then resolve the key for `octodns-sync`:
``` sh
$ just update-dns       # Preview
$ just update-dns-doit  # Apply
```

`just add-host-key <ssh-host> <hostname>` also uses your 1Password CLI login,
querying credentials only while provisioning the host.
