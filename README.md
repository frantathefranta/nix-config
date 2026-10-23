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
1. Add the host name to `serverHosts` in `flake.nix`. Its host module should
   import `../common/roles/server.nix`, which enables comin. Hosts that do not
   use the server role must import `../common/optional/comin.nix` explicitly.
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

## Server deployments

Servers use [comin](https://github.com/frantathefranta/comin), following the
[nix-cloud deployment](https://git.franta.us/franta/nix-cloud/src/branch/main/hosts/common/global/comin.nix).
The Hydra executor follows
[molybdenum's configuration](https://git.franta.us/franta/nix-cloud/src/branch/main/hosts/molybdenum/default.nix).
The shared configuration is `hosts/common/optional/comin.nix`; it is enabled on
hydrogen, ytterbium, nix-bastion, nixos-firewall, qotom, and neon.
Workstations and the installer ISO do not run comin.

Comin polls `https://git.franta.us/franta/nix-home.git` every 60 seconds. For each
commit on `main`, its Hydra executor waits for a successful
`nix-home/main/hosts.<hostname>` build at `https://hydra.infra.franta.us`, then
downloads the system closure through the existing trusted
`https://nix-cache.infra.franta.us` binary cache and activates it. Servers do not
evaluate or build their configurations locally. Merge changes into `main` to
deploy; unattended pulls use public HTTPS, not SSH agent forwarding or a deploy
key.

The weekly `system.autoUpgrade` job has been removed so it cannot race comin.
Unlike nix-cloud, this configuration does not install its cloud-specific remote
builder credentials or BGP-gated reboot hook.
Reboots are manual; check `sudo comin status` for pending reboots.

### Initial rollout and recovery

Merge this migration into `main` **before** activating it on existing servers,
otherwise comin can immediately deploy the previous configuration from `main`.
Each existing server needs one manual switch to install comin. From a Linux
machine with `nixos-rebuild`, for example:

``` sh
NIX_SSHOPTS="-A" nixos-rebuild switch --flake .#nix-bastion \
  --build-host fbartik@nix-bastion.infra.franta.us \
  --target-host fbartik@nix-bastion.infra.franta.us --sudo
ssh fbartik@nix-bastion.infra.franta.us 'systemctl is-active comin; sudo comin status'
```

Repeat with each server's host name and FQDN. New installations provisioned with
`nixos-anywhere` already include comin. The old `just deploy` push workflow has
been removed; `just deploy-darwin` is unchanged.

On a server, inspect or trigger reconciliation with:

``` sh
sudo comin status
sudo comin fetch
sudo journalctl -u comin -f
```

Comin supports `testing-<hostname>` branches based on `main`, using
`switch-to-configuration test` without changing the boot default. The Hydra
executor also needs a matching `testing-<hostname>` jobset. This repository's
jobset generator creates only `main` and `pr-<number>` jobsets, so testing branches
will wait for a build unless their Hydra jobsets are provisioned separately.
PR builds validate changes before merging them into `main` for deployment.

For manual recovery, stop comin (`sudo systemctl stop comin`) before applying
another configuration so reconciliation cannot race the repair. Revert the bad
commit on `main`, then restart comin when ready (`sudo systemctl start comin`).


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
