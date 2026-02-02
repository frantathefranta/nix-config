{
  lib,
  pkgs,
  ...
}:

{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.tcp_l3mdev_accept" = 1;
    "net.ipv4.udp_l3mdev_accept" = 1;
  };
  networking = {
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    wait-online = {
      anyInterface = false;
      ignoredInterfaces = [
        # "wan0"
        # "wan1"
        "lan1"
        "ctr0"
        "mgmt"
        # "wg0"
      ];
    };
    links = {
      # rename all interface names to be easier to identify
      "10-wan0" = {
        matchConfig.Path = "pci-0000:05:00.1";
        linkConfig.Name = "wan0";
      };
      "10-lan0" = {
        matchConfig.Path = "pci-0000:05:00.0";
        linkConfig.Name = "lan0";
      };
      "10-eth6" = {
        matchConfig.Path = "pci-0000:07:00.0";
        linkConfig.Name = "eth6";
      };
      # "10-lan1" = {
      #   matchConfig.Path = "pci-0000:04:00.0";
      #   linkConfig.Name = "lan1";
      # };
    };
    netdevs = {
      # VLANs
      "10-mgmt" = {
        netdevConfig = {
          Name = "mgmt";
          Kind = "vrf";
        };
        vrfConfig = {
          Table = 1000;
        };
      };
      "20-lan0.20" = {
        netdevConfig = {
          Name = "lan0.20";
          Description = "WiFi";
          Kind = "vlan";
        };
        vlanConfig.Id = 20;
      };
      "20-lan0.50" = {
        netdevConfig = {
          Name = "lan0.50";
          Description = "IOT";
          Kind = "vlan";
        };
        vlanConfig.Id = 50;
      };
    };
    networks = {
      # Disabled interfaces
      # "30-wan1" = {
      #   matchConfig.Name = "wan1";
      #   networkConfig.ConfigureWithoutCarrier = true;
      #   linkConfig.ActivationPolicy = "always-down";
      # };
      # "30-lan1" = {
      #   matchConfig.Name = "lan1";
      #   networkConfig.ConfigureWithoutCarrier = true;
      #   linkConfig.ActivationPolicy = "always-down";
      # };

      # WAN0
      "30-wan0" = {
        matchConfig.Name = "wan0";
        networkConfig.DHCP = "yes";
        linkConfig = {
          MTUBytes = "1500";
          RequiredForOnline = "routable";
        };
      };
      "30-mgmt" = {
        matchConfig.Name = "mgmt";
        linkConfig = {
          ActivationPolicy = "up";
          RequiredForOnline = false;
        };
      };
      "30-eth6" = {
        matchConfig.Name = "eth6";
        networkConfig = {
          IPv6AcceptRA = true;
          VRF = "mgmt";
        };
        addresses = [
          { Address = "10.32.10.230/24"; }
        ];
      };

      # LAN0
      "30-lan0" = {
        matchConfig.Name = "lan0";
        address = [ "10.0.10.1/24" ];
        networkConfig.ConfigureWithoutCarrier = "yes";
        linkConfig.RequiredForOnline = "no"; # TODO: Change when interface is connected
        # linkConfig.RequiredForOnline = "carrier";
        vlan = [
          "lan0.20" # WIFI
          "lan0.50" # IOT
          # "lan0.200" # SERVER
          # "lan0.250" # GUEST
        ];
      };

      #   # HOME VLAN
      "30-lan0.20" = {
        matchConfig.Name = "lan0.20";
        address = [ "10.0.20.1/24" ];
        networkConfig.ConfigureWithoutCarrier = "yes";
        linkConfig.RequiredForOnline = "no"; # TODO: Change when interface is connected
        # linkConfig.RequiredForOnline = "routable";
      };

      #   # IOT VLAN
      "30-lan0.50" = {
        matchConfig.Name = "lan0.50";
        address = [ "10.0.50.1/24" ];
        networkConfig.ConfigureWithoutCarrier = "yes";
        linkConfig.RequiredForOnline = "no"; # TODO: Change when interface is connected
        # linkConfig.RequiredForOnline = "routable";
      };
    };
  };
  # Override sshd so it listens in mgmt vrf
  services.prometheus.exporters.node = {
    listenAddress = "0.0.0.0";
  };
  systemd.services.prometheus-node-exporter = {
    after = [ "pyvrf@mgmt.service" ];
    unitConfig = {
      Requires = "pyvrf@mgmt.service";
    };
    serviceConfig.BPFProgram = "sock_create:/sys/fs/bpf/pyvrf_mgmt";
  };
  systemd.services.sshd = {
    after = [ "pyvrf@mgmt.service" ];
    unitConfig = {
      Requires = "pyvrf@mgmt.service";
    };
    serviceConfig.BPFProgram = "sock_create:/sys/fs/bpf/pyvrf_mgmt";
  };
  # Taken from here: https://jerryxiao.cc/archives/1004
  systemd.services."pyvrf@" =
    let
      # python = pkgs.python3.withPackages (ps: with ps; [ libbpf ]);
      bpf_script = ''
        from ctypes import (CDLL, Structure, c_uint8, c_int16, c_int32, c_ulong,
                    c_int, c_char_p, byref, POINTER)
        from pathlib import Path
        from subprocess import run
        from json import loads
        from argparse import ArgumentParser
        from sys import stderr

        parser = ArgumentParser(description='pyvrf')
        parser.add_argument('action', type=str, choices=['start', 'stop'], help='what to do')
        parser.add_argument('ifname', type=str, help='interface name')
        parser.add_argument('-q', '--quiet', action='store_true', help='be quiet')
        args = parser.parse_args()

        pin_path = Path("/sys/fs/bpf")
        assert pin_path.is_dir()
        pin_loc = pin_path / f"pyvrf_{args.ifname}"

        if args.action == 'stop':
            assert pin_loc.exists()
            pin_loc.unlink()
            exit(0)

        assert not pin_loc.exists()
        p = run(['${pkgs.iproute2}/bin/ip', '--json', 'link', 'show', 'dev', args.ifname], encoding='utf-8', capture_output=True)
        if p.returncode:
            print('iproute2:', p.stderr.strip(), file=stderr)
            exit(1)
        netif = loads(p.stdout)
        assert len(netif) == 1 and netif[0]['ifname'] == args.ifname
        idx = netif[0]['ifindex']

        MAX_BPF_REG = 11
        BPF_ALU64 = 0x07
        BPF_MOV = 0xb0
        BPF_STX = 0x03
        BPF_MEM = 0x60
        BPF_JMP = 0x05
        BPF_EXIT = 0x90
        BPF_X = 0x08
        BPF_K = 0x00
        BPF_SIZE = lambda i: i & 0x18 # define BPF_SIZE(code)  ((code) & 0x18)
        BPF_PROG_TYPE_CGROUP_SOCK = 9
        globals().update({f"BPF_REG_{i}": i for i in range(MAX_BPF_REG)})

        class bpf_insn(Structure):
            _fields_ = [
                ("code", c_uint8),       # opcode
                ("dst_reg", c_uint8, 4), # dest register
                ("src_reg", c_uint8, 4), # source register
                ("off", c_int16),        # signed offset
                ("imm", c_int32),        # signed immediate constant
            ]

        _prog = (
            # BPF_MOV64_REG(BPF_REG_6, BPF_REG_1)
            # { .code = BPF_ALU64 | BPF_MOV | BPF_X, .dst_reg = BPF_REG_6, .src_reg = BPF_REG_1, .off = 0, .imm = 0 }
            bpf_insn(
                BPF_ALU64 | BPF_MOV | BPF_X,
                BPF_REG_6,
                BPF_REG_1,
                0,
                0,
            ),
            # BPF_MOV64_IMM(BPF_REG_3, idx)
            # { .code = BPF_ALU64 | BPF_MOV | BPF_K, .dst_reg = BPF_REG_3, .src_reg = 0, .off = 0, .imm = idx }
            bpf_insn(
                BPF_ALU64 | BPF_MOV | BPF_K,
                BPF_REG_3,
                0,
                0,
                idx,
            ),
            # BPF_MOV64_IMM(BPF_REG_2, offsetof(struct bpf_sock, bound_dev_if))
            # { .code = BPF_ALU64 | BPF_MOV | BPF_K, .dst_reg = BPF_REG_2, .src_reg = 0, .off = 0, .imm = __builtin_offsetof(struct bpf_sock, bound_dev_if) }
            bpf_insn(
                BPF_ALU64 | BPF_MOV | BPF_K,
                BPF_REG_2,
                0,
                0,
                0, # offsetof(struct bpf_sock, bound_dev_if) = 0 (currently)
            ),
            # BPF_STX_MEM(BPF_W, BPF_REG_1, BPF_REG_3, offsetof(struct bpf_sock, bound_dev_if))
            # { .code = BPF_STX | BPF_SIZE(0x00) | BPF_MEM, .dst_reg = BPF_REG_1, .src_reg = BPF_REG_3, .off = __builtin_offsetof(struct bpf_sock, bound_dev_if), .imm = 0 }
            bpf_insn(
                BPF_STX | BPF_SIZE(0x00) | BPF_MEM,
                BPF_REG_1,
                BPF_REG_3,
                0,
                0, # offsetof(struct bpf_sock, bound_dev_if) = 0 (currently)
            ),
            # BPF_MOV64_IMM(BPF_REG_0, 1)
            # { .code = BPF_ALU64 | BPF_MOV | BPF_K, .dst_reg = BPF_REG_0, .src_reg = 0, .off = 0, .imm = 1 }
            bpf_insn(
                BPF_ALU64 | BPF_MOV | BPF_K,
                BPF_REG_0,
                0,
                0,
                1,
            ),
            # BPF_EXIT_INSN()
            # { .code = BPF_JMP | BPF_EXIT, .dst_reg = 0, .src_reg = 0, .off = 0, .imm = 0 }
            bpf_insn(
                BPF_JMP | BPF_EXIT,
                0,
                0,
                0,
                0,
            ),
        )
        prog = (bpf_insn * len(_prog))(*_prog)

        libbpf = CDLL('libbpf.so')
        ''''
        int bpf_prog_load(enum bpf_prog_type prog_type,
        			     const char *prog_name, const char *license,
        			     const struct bpf_insn *insns, size_t insn_cnt,
        			     const struct bpf_prog_load_opts *opts);
        ''''
        bpf_prog_load_opts = c_int # nullptr, whatever
        libbpf.bpf_prog_load.argtypes = [c_int, c_char_p, c_char_p, POINTER(bpf_insn), c_ulong, POINTER(bpf_prog_load_opts)]
        libbpf.bpf_prog_load.restype = c_int
        fd = libbpf.bpf_prog_load(
            BPF_PROG_TYPE_CGROUP_SOCK,
            b"pyvrf",
            b"GPL",
            byref(prog[0]),
            len(prog),
            None
        )
        if fd < 0:
            print(f"failed to load prog: libbpf returned {fd}", file=stderr)
            exit(1)
        libbpf.bpf_obj_pin.argtypes = [c_int, c_char_p]
        libbpf.bpf_obj_pin.restype = c_int
        ret = libbpf.bpf_obj_pin(fd, str(pin_loc).encode('ascii'))
        if ret:
            print(f"failed to pin prog at {pin_loc}: libbpf returned {ret}", file=stderr)
            exit(1)
        if not args.quiet:
            print(f"BPFProgram=sock_create:{pin_loc}")
      '';
      b64Drv = pkgs.runCommand "text.b64" { } ''
        echo -n ${lib.escapeShellArg bpf_script} | ${pkgs.coreutils}/bin/base64 -w0 > $out
      '';
      b64Text = builtins.readFile b64Drv;
    in
    {
      description = "Load and unload persistent vrf bpf objects";
      serviceConfig = {
        Environment = "LD_LIBRARY_PATH=${pkgs.libbpf}/lib";
        Type = "simple";
        User = "root";
        RemainAfterExit = true;
        StandardInput = "data";
        # StandardInputData = "ZnJvbSBjdHlwZXMgaW1wb3J0IChDRExMLCBTdHJ1Y3R1cmUsIGNfdWludDgsIGNfaW50MTYsIGNfaW50MzIsIGNfdWxvbmcsCiAgICAgICAgICAgICAgICAgICAgY19pbnQsIGNfY2hhcl9wLCBieXJlZiwgUE9JTlRFUikKZnJvbSBwYXRobGliIGltcG9ydCBQYXRoCmZyb20gc3VicHJvY2VzcyBpbXBvcnQgcnVuCmZyb20ganNvbiBpbXBvcnQgbG9hZHMKZnJvbSBhcmdwYXJzZSBpbXBvcnQgQXJndW1lbnRQYXJzZXIKZnJvbSBzeXMgaW1wb3J0IHN0ZGVycgoKcGFyc2VyID0gQXJndW1lbnRQYXJzZXIoZGVzY3JpcHRpb249J3B5dnJmJykKcGFyc2VyLmFkZF9hcmd1bWVudCgnYWN0aW9uJywgdHlwZT1zdHIsIGNob2ljZXM9WydzdGFydCcsICdzdG9wJ10sIGhlbHA9J3doYXQgdG8gZG8nKQpwYXJzZXIuYWRkX2FyZ3VtZW50KCdpZm5hbWUnLCB0eXBlPXN0ciwgaGVscD0naW50ZXJmYWNlIG5hbWUnKQpwYXJzZXIuYWRkX2FyZ3VtZW50KCctcScsICctLXF1aWV0JywgYWN0aW9uPSdzdG9yZV90cnVlJywgaGVscD0nYmUgcXVpZXQnKQphcmdzID0gcGFyc2VyLnBhcnNlX2FyZ3MoKQoKcGluX3BhdGggPSBQYXRoKCIvc3lzL2ZzL2JwZiIpCmFzc2VydCBwaW5fcGF0aC5pc19kaXIoKQpwaW5fbG9jID0gcGluX3BhdGggLyBmInB5dnJmX3thcmdzLmlmbmFtZX0iCgppZiBhcmdzLmFjdGlvbiA9PSAnc3RvcCc6CiAgICBhc3NlcnQgcGluX2xvYy5leGlzdHMoKQogICAgcGluX2xvYy51bmxpbmsoKQogICAgZXhpdCgwKQoKYXNzZXJ0IG5vdCBwaW5fbG9jLmV4aXN0cygpCnAgPSBydW4oWydpcCcsICctLWpzb24nLCAnbGluaycsICdzaG93JywgJ2RldicsIGFyZ3MuaWZuYW1lXSwgZW5jb2Rpbmc9J3V0Zi04JywgY2FwdHVyZV9vdXRwdXQ9VHJ1ZSkKaWYgcC5yZXR1cm5jb2RlOgogICAgcHJpbnQoJ2lwcm91dGUyOicsIHAuc3RkZXJyLnN0cmlwKCksIGZpbGU9c3RkZXJyKQogICAgZXhpdCgxKQpuZXRpZiA9IGxvYWRzKHAuc3Rkb3V0KQphc3NlcnQgbGVuKG5ldGlmKSA9PSAxIGFuZCBuZXRpZlswXVsnaWZuYW1lJ10gPT0gYXJncy5pZm5hbWUKaWR4ID0gbmV0aWZbMF1bJ2lmaW5kZXgnXQoKTUFYX0JQRl9SRUcgPSAxMQpCUEZfQUxVNjQgPSAweDA3CkJQRl9NT1YgPSAweGIwCkJQRl9TVFggPSAweDAzCkJQRl9NRU0gPSAweDYwCkJQRl9KTVAgPSAweDA1CkJQRl9FWElUID0gMHg5MApCUEZfWCA9IDB4MDgKQlBGX0sgPSAweDAwCkJQRl9TSVpFID0gbGFtYmRhIGk6IGkgJiAweDE4ICMgZGVmaW5lIEJQRl9TSVpFKGNvZGUpICAoKGNvZGUpICYgMHgxOCkKQlBGX1BST0dfVFlQRV9DR1JPVVBfU09DSyA9IDkKZ2xvYmFscygpLnVwZGF0ZSh7ZiJCUEZfUkVHX3tpfSI6IGkgZm9yIGkgaW4gcmFuZ2UoTUFYX0JQRl9SRUcpfSkKCmNsYXNzIGJwZl9pbnNuKFN0cnVjdHVyZSk6CiAgICBfZmllbGRzXyA9IFsKICAgICAgICAoImNvZGUiLCBjX3VpbnQ4KSwgICAgICAgIyBvcGNvZGUKICAgICAgICAoImRzdF9yZWciLCBjX3VpbnQ4LCA0KSwgIyBkZXN0IHJlZ2lzdGVyCiAgICAgICAgKCJzcmNfcmVnIiwgY191aW50OCwgNCksICMgc291cmNlIHJlZ2lzdGVyCiAgICAgICAgKCJvZmYiLCBjX2ludDE2KSwgICAgICAgICMgc2lnbmVkIG9mZnNldAogICAgICAgICgiaW1tIiwgY19pbnQzMiksICAgICAgICAjIHNpZ25lZCBpbW1lZGlhdGUgY29uc3RhbnQKICAgIF0KCl9wcm9nID0gKAogICAgIyBCUEZfTU9WNjRfUkVHKEJQRl9SRUdfNiwgQlBGX1JFR18xKQogICAgIyB7IC5jb2RlID0gQlBGX0FMVTY0IHwgQlBGX01PViB8IEJQRl9YLCAuZHN0X3JlZyA9IEJQRl9SRUdfNiwgLnNyY19yZWcgPSBCUEZfUkVHXzEsIC5vZmYgPSAwLCAuaW1tID0gMCB9CiAgICBicGZfaW5zbigKICAgICAgICBCUEZfQUxVNjQgfCBCUEZfTU9WIHwgQlBGX1gsCiAgICAgICAgQlBGX1JFR182LAogICAgICAgIEJQRl9SRUdfMSwKICAgICAgICAwLAogICAgICAgIDAsCiAgICApLAogICAgIyBCUEZfTU9WNjRfSU1NKEJQRl9SRUdfMywgaWR4KQogICAgIyB7IC5jb2RlID0gQlBGX0FMVTY0IHwgQlBGX01PViB8IEJQRl9LLCAuZHN0X3JlZyA9IEJQRl9SRUdfMywgLnNyY19yZWcgPSAwLCAub2ZmID0gMCwgLmltbSA9IGlkeCB9CiAgICBicGZfaW5zbigKICAgICAgICBCUEZfQUxVNjQgfCBCUEZfTU9WIHwgQlBGX0ssCiAgICAgICAgQlBGX1JFR18zLAogICAgICAgIDAsCiAgICAgICAgMCwKICAgICAgICBpZHgsCiAgICApLAogICAgIyBCUEZfTU9WNjRfSU1NKEJQRl9SRUdfMiwgb2Zmc2V0b2Yoc3RydWN0IGJwZl9zb2NrLCBib3VuZF9kZXZfaWYpKQogICAgIyB7IC5jb2RlID0gQlBGX0FMVTY0IHwgQlBGX01PViB8IEJQRl9LLCAuZHN0X3JlZyA9IEJQRl9SRUdfMiwgLnNyY19yZWcgPSAwLCAub2ZmID0gMCwgLmltbSA9IF9fYnVpbHRpbl9vZmZzZXRvZihzdHJ1Y3QgYnBmX3NvY2ssIGJvdW5kX2Rldl9pZikgfQogICAgYnBmX2luc24oCiAgICAgICAgQlBGX0FMVTY0IHwgQlBGX01PViB8IEJQRl9LLAogICAgICAgIEJQRl9SRUdfMiwKICAgICAgICAwLAogICAgICAgIDAsCiAgICAgICAgMCwgIyBvZmZzZXRvZihzdHJ1Y3QgYnBmX3NvY2ssIGJvdW5kX2Rldl9pZikgPSAwIChjdXJyZW50bHkpCiAgICApLAogICAgIyBCUEZfU1RYX01FTShCUEZfVywgQlBGX1JFR18xLCBCUEZfUkVHXzMsIG9mZnNldG9mKHN0cnVjdCBicGZfc29jaywgYm91bmRfZGV2X2lmKSkKICAgICMgeyAuY29kZSA9IEJQRl9TVFggfCBCUEZfU0laRSgweDAwKSB8IEJQRl9NRU0sIC5kc3RfcmVnID0gQlBGX1JFR18xLCAuc3JjX3JlZyA9IEJQRl9SRUdfMywgLm9mZiA9IF9fYnVpbHRpbl9vZmZzZXRvZihzdHJ1Y3QgYnBmX3NvY2ssIGJvdW5kX2Rldl9pZiksIC5pbW0gPSAwIH0KICAgIGJwZl9pbnNuKAogICAgICAgIEJQRl9TVFggfCBCUEZfU0laRSgweDAwKSB8IEJQRl9NRU0sCiAgICAgICAgQlBGX1JFR18xLAogICAgICAgIEJQRl9SRUdfMywKICAgICAgICAwLAogICAgICAgIDAsICMgb2Zmc2V0b2Yoc3RydWN0IGJwZl9zb2NrLCBib3VuZF9kZXZfaWYpID0gMCAoY3VycmVudGx5KQogICAgKSwKICAgICMgQlBGX01PVjY0X0lNTShCUEZfUkVHXzAsIDEpCiAgICAjIHsgLmNvZGUgPSBCUEZfQUxVNjQgfCBCUEZfTU9WIHwgQlBGX0ssIC5kc3RfcmVnID0gQlBGX1JFR18wLCAuc3JjX3JlZyA9IDAsIC5vZmYgPSAwLCAuaW1tID0gMSB9CiAgICBicGZfaW5zbigKICAgICAgICBCUEZfQUxVNjQgfCBCUEZfTU9WIHwgQlBGX0ssCiAgICAgICAgQlBGX1JFR18wLAogICAgICAgIDAsCiAgICAgICAgMCwKICAgICAgICAxLAogICAgKSwKICAgICMgQlBGX0VYSVRfSU5TTigpCiAgICAjIHsgLmNvZGUgPSBCUEZfSk1QIHwgQlBGX0VYSVQsIC5kc3RfcmVnID0gMCwgLnNyY19yZWcgPSAwLCAub2ZmID0gMCwgLmltbSA9IDAgfQogICAgYnBmX2luc24oCiAgICAgICAgQlBGX0pNUCB8IEJQRl9FWElULAogICAgICAgIDAsCiAgICAgICAgMCwKICAgICAgICAwLAogICAgICAgIDAsCiAgICApLAopCnByb2cgPSAoYnBmX2luc24gKiBsZW4oX3Byb2cpKSgqX3Byb2cpCgpsaWJicGYgPSBDRExMKCdsaWJicGYuc28nKQonJycKaW50IGJwZl9wcm9nX2xvYWQoZW51bSBicGZfcHJvZ190eXBlIHByb2dfdHlwZSwKCQkJICAgICBjb25zdCBjaGFyICpwcm9nX25hbWUsIGNvbnN0IGNoYXIgKmxpY2Vuc2UsCgkJCSAgICAgY29uc3Qgc3RydWN0IGJwZl9pbnNuICppbnNucywgc2l6ZV90IGluc25fY250LAoJCQkgICAgIGNvbnN0IHN0cnVjdCBicGZfcHJvZ19sb2FkX29wdHMgKm9wdHMpOwonJycKYnBmX3Byb2dfbG9hZF9vcHRzID0gY19pbnQgIyBudWxscHRyLCB3aGF0ZXZlcgpsaWJicGYuYnBmX3Byb2dfbG9hZC5hcmd0eXBlcyA9IFtjX2ludCwgY19jaGFyX3AsIGNfY2hhcl9wLCBQT0lOVEVSKGJwZl9pbnNuKSwgY191bG9uZywgUE9JTlRFUihicGZfcHJvZ19sb2FkX29wdHMpXQpsaWJicGYuYnBmX3Byb2dfbG9hZC5yZXN0eXBlID0gY19pbnQKZmQgPSBsaWJicGYuYnBmX3Byb2dfbG9hZCgKICAgIEJQRl9QUk9HX1RZUEVfQ0dST1VQX1NPQ0ssCiAgICBiInB5dnJmIiwKICAgIGIiR1BMIiwKICAgIGJ5cmVmKHByb2dbMF0pLAogICAgbGVuKHByb2cpLAogICAgTm9uZQopCmlmIGZkIDwgMDoKICAgIHByaW50KGYiZmFpbGVkIHRvIGxvYWQgcHJvZzogbGliYnBmIHJldHVybmVkIHtmZH0iLCBmaWxlPXN0ZGVycikKICAgIGV4aXQoMSkKbGliYnBmLmJwZl9vYmpfcGluLmFyZ3R5cGVzID0gW2NfaW50LCBjX2NoYXJfcF0KbGliYnBmLmJwZl9vYmpfcGluLnJlc3R5cGUgPSBjX2ludApyZXQgPSBsaWJicGYuYnBmX29ial9waW4oZmQsIHN0cihwaW5fbG9jKS5lbmNvZGUoJ2FzY2lpJykpCmlmIHJldDoKICAgIHByaW50KGYiZmFpbGVkIHRvIHBpbiBwcm9nIGF0IHtwaW5fbG9jfTogbGliYnBmIHJldHVybmVkIHtyZXR9IiwgZmlsZT1zdGRlcnIpCiAgICBleGl0KDEpCmlmIG5vdCBhcmdzLnF1aWV0OgogICAgcHJpbnQoZiJCUEZQcm9ncmFtPXNvY2tfY3JlYXRlOntwaW5fbG9jfSIpCg==";
        StandardInputData = b64Text;
        ExecStart = "${pkgs.python3}/bin/python -u - start %i -q";
        ExecStop = "${pkgs.python3}/bin/python -u - stop %i -q";
      };
    };
}
