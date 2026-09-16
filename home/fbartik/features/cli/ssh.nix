{
  config,
  inputs,
  outputs,
  lib,
  pkgs,
  ...
}:
let
  nixosConfigs = builtins.attrNames outputs.nixosConfigurations;
  hostnames = lib.unique nixosConfigs;

  # Cloud hosts (cloud.franta.us) are managed by a separate repo, pulled in as a
  # plain source (flake = false) so its flake input graph stays out of our lock.
  # Its enabled hosts are the `serverHosts = [ ... ]` list in nix-cloud/flake.nix,
  # which we read straight from source (commented-out entries are skipped).
  readServerHosts = flakeNix:
    let
      parts = lib.splitString "serverHosts = [" (builtins.readFile flakeNix);
      body =
        if lib.length parts > 1
        then lib.head (lib.splitString "]" (lib.elemAt parts 1))
        else "";
      extract = line:
        let
          t = lib.trim line;
        in
          if t == "" || lib.hasPrefix "#" t
          then null
          else builtins.match "\"([^\"]+)\"" t;
    in
    lib.flatten (lib.filter (x: x != null) (map extract (lib.splitString "\n" body)));

  # Cloud hosts are only reachable as <name>.cloud.franta.us (user admin).
  cloudHosts =
    let
      hosts = readServerHosts (inputs.nix-cloud-src + "/flake.nix");
    in
    if hosts == [ ]
    then lib.throw "Could not parse serverHosts from nix-cloud/flake.nix (input nix-cloud-src); did its format change?"
    else hosts;

  # ssm (Secure Shell Manager) is not in nixpkgs, so build it from source. The
  # upstream flake's pinned Go-module (vendor) hash is stale for current nixpkgs
  # and fails a hash check; this one is stable across nixpkgs revs and systems
  # (verified for aarch64-darwin/unstable and x86_64-linux/stable).
  ssmPkg = pkgs.buildGoModule rec {
    pname = "ssm";
    version = "0.1.0";
    src = inputs.ssm-src;
    subPackages = [ "." ];
    vendorHash = "sha256-zb36KXthOrNb3ghDgdgHexNeIbUyBKG6Se8r0fdMUPM=";
  };

  isWorkstation =
    pkgs.stdenv.hostPlatform.isDarwin || (builtins.length config.monitors != 0);
  identityAgent =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "'${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock'"
    else if isWorkstation then
      "${config.home.homeDirectory}/.1password/agent.sock"
    else
      "${config.home.homeDirectory}/.ssh/ssh_auth_sock";

  # ---------------------------------------------------------------------------
  # ssm rendering helpers
  #
  # ssm (https://github.com/lfaoro/ssm) reads an existing ssh config (following
  # Include) and organises hosts with `#tag:` comments. Two constraints shape
  # the output:
  #   - a `#tag:` line attaches to the *preceding* `Host` line,
  #   - ssm connects with `ssh -F <config> -- <name>`, so each Host line must be
  #     a single, resolvable name (multi-pattern `Host a b c` lines break it).
  # ---------------------------------------------------------------------------
  # A host block for the ssm file: single-name Host line, `#tag:` on the next
  # line, then the options.
  ssmHost =
    { name, tag, opts }:
    "Host ${name}\n"
    + "#tag: ${tag}\n"
    + lib.concatStrings (map (o: "    ${o}\n") opts);

  # A plain host block for the operational config (no tag).
  plainHost =
    { name, opts }:
    "Host ${name}\n" + lib.concatStrings (map (o: "    ${o}\n") opts);
in
{
  # We no longer let home-manager's programs.ssh render ~/.ssh/config. Keep the
  # SSH client and add ssm (for the tag-based TUI browser). known_hosts is not
  # managed here.
  home.packages = [
    pkgs.openssh
    ssmPkg
  ];

  # The nix-generated host list, browsable via ssm. Only the dynamically
  # generated hosts live here: NixOS/home machines from this flake (net) and
  # cloud hosts from nix-cloud (cloud). The `ssm` fish alias points
  # SSM_SSH_CONFIG_PATH at this file. Do not edit by hand; it is overwritten on
  # rebuild. Each host is a single resolvable name (ssm connects with
  # `ssh <name>`).
  home.file.".ssh/nix_hosts" =
    {
      text =
        let
          netHosts = map (h: ssmHost {
            name = h;
            tag = "net";
            opts = [
              "Hostname ${h}.infra.franta.us"
              "ForwardAgent yes"
              "IdentityAgent ${identityAgent}"
            ];
          }) hostnames;
          cloudHostsBlocks = map (h: ssmHost {
            name = h;
            tag = "cloud";
            opts = [
              "Hostname ${h}.cloud.franta.us"
              "User admin"
              "IdentityAgent ${identityAgent}"
            ];
          }) cloudHosts;
        in
        ''
          # Managed by nix (home-manager). Do not edit by hand -- your changes
          # will be overwritten on the next build. Browsed by `ssm` (see the
          # fish alias, which sets SSM_SSH_CONFIG_PATH to this path). `ssh`
          # reaches these hosts through the Include in ~/.ssh/config.
          ${lib.concatStringsSep "\n" (netHosts ++ cloudHostsBlocks)}
        '';
    };

  # The operational ssh config: plain ssh_config. It pulls in the hand-managed
  # ephemeral config and the generated host list, then declares the static
  # patterns / shared endpoints. ephemeral is included first so hand-managed
  # hosts keep precedence over the generated ones.
  home.file.".ssh/config" =
    {
      text =
        let
          staticHosts =
            [
              (plainHost {
                name = "*.cloud.franta.us";
                opts = [
                  "User admin"
                  "IdentityAgent ${identityAgent}"
                ];
              })
              (plainHost {
                name = "*.franta.us";
                opts = [ "IdentityAgent ${identityAgent}" ];
              })
              (plainHost {
                name = "git.franta.us";
                opts = [ "IdentityAgent ${identityAgent}" ];
              })
              (plainHost {
                name = "github.com";
                opts = [ "IdentityAgent ${identityAgent}" ];
              })
            ]
            ++ lib.optional (!pkgs.stdenv.hostPlatform.isDarwin) (plainHost {
              name = "brocade*";
              opts = [
                "User admin"
                "IdentityAgent ${identityAgent}"
                "KexAlgorithms +diffie-hellman-group1-sha1"
                "HostKeyAlgorithms +ssh-rsa"
                "PubkeyAcceptedAlgorithms +ssh-rsa"
              ];
            });
        in
        ''
          # Managed by nix (home-manager). Do not edit by hand.
          Include ${config.home.homeDirectory}/.ssh/ephemeral_config
          Include ${config.home.homeDirectory}/.ssh/nix_hosts

          ${lib.concatStringsSep "\n" staticHosts}
        '';
    };

  home.file.".config/1Password/ssh/agent.toml" = lib.mkIf isWorkstation {
    source = (pkgs.formats.toml { }).generate "agent.toml" {
      "ssh-keys" = [
        {
          vault = "SSH";
          item = "rcrhyzps3y7tpmg5ghz7xpwyj4";
        }
        {
          vault = "SSH";
          item = "5yo45wnti4mcbz3eahp3dcfn5i"; # Brocade
        }
        {
          vault = "SSH";
          item = "Hetzner Key";
        }
        {
          vault = "SSH";
          item = "Google Key";
        }
      ];
    };
  };

  home.file.".ssh/rc" = lib.mkIf (!isWorkstation && config.programs.tmux.enable) {
    executable = true;
    text = /* bash */ ''
      #!/usr/bin/env bash

      # Fix SSH auth socket location so agent forwarding works with tmux.
      if test "$SSH_AUTH_SOCK" ; then
        ln -sf $SSH_AUTH_SOCK ${config.home.homeDirectory}/.ssh/ssh_auth_sock
      fi
    '';
  };
}
