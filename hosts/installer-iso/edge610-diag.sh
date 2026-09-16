#!/usr/bin/env bash
# edge610-diag — Dell Edge 610 (VEP1400) network diagnosis
#
# Hardware topology (4x Intel X553 backplane, all bound to ixgbe):
#   03:00.0 / 03:00.1   (subsys 0000)  -> CPU uplinks INTO the on-board
#                                          Marvell 88E6190 DSA switch. The 6 RJ45
#                                          ports live behind that switch.
#   05:00.0 / 05:00.1   (subsys 15c4)  -> the two SFP cages. DIRECT — they are NOT
#                                          behind the DSA switch.
#
# The SFP problem has two competing explanations:
#   H1  The SFP cage is held off (TX line / PHY enable) and needs the vendor
#       I2C/SMBus init that DiagOS performs.  => `ethtool -m <sfp>` FAILS.
#   H2  The transceiver is fine but the >=6.1 kernel ixgbe driver has the
#       AN-37 SFI regression (commit 565736048bd5) so the link never negotiates.
#       => `ethtool -m <sfp>` READS the module, but carrier stays 0 on 6.1+.
#
# This ISO ships linuxPackages_5_10 (pre-6.1) on purpose: if the SFP comes up here,
# H2 is confirmed and you have a working stopgap kernel. If it's still dead here,
# it's a hardware-enable problem (H1) and the i2c section below is where to look.
#
# Default run is READ-ONLY. State changes need an explicit flag:
#   --watchdog    i2cset -y 1 0x22 0 0 b   (disable the 5-min reboot watchdog)
#   --sfp-up      bring the SFP netdevs up, wait, re-check carrier + dmesg
#   --all-up      bring every eth netdev up, wait, show `ip -br link`
#   -h, --help    this header

set -u

do_watchdog=0
do_sfp_up=0
do_all_up=0
for a in "$@"; do
  case "$a" in
    --watchdog) do_watchdog=1 ;;
    --sfp-up)   do_sfp_up=1 ;;
    --all-up)   do_all_up=1 ;;
    -h|--help)  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $a (try --help)"; exit 2 ;;
  esac
done

H(){ printf '\n########## %s ##########\n' "$*"; }
R(){ printf '\n$ %s\n' "$*"; "$@" 2>&1 | sed 's/^/  | /'; }

# netdev -> PCI BDF (e.g. 0000:05:00.0)
bdf(){ readlink -f "/sys/class/net/$1/device" 2>/dev/null | xargs -r basename; }

H "Environment"
R uname -a
R "lspci -nnk"
R "ls -1 /sys/class/net"

H "Interface -> PCI mapping"
sfp_ifs=""
up_ifs=""
for p in /sys/class/net/*; do
  i=$(basename "$p"); [ "$i" = lo ] && continue
  d=$(bdf "$i"); c=$(cat "/sys/class/net/$i/carrier" 2>/dev/null)
  case "$d" in
    *:05:00.*) tag="SFP (direct X553 SFP MAC)";  sfp_ifs="$sfp_ifs $i" ;;
    *:03:00.*) tag="UPLINK (-> 88E6190 DSA switch)"; up_ifs="$up_ifs $i" ;;
    *)         tag="other" ;;
  esac
  printf '  %-8s %-15s carrier=%s  %s\n' "$i" "${d:-<none>}" "${c:-?}" "$tag"
done
[ -z "$sfp_ifs" ] && sfp_ifs=" eno3 eno4"
[ -z "$up_ifs" ]  && up_ifs=" eno1 eno2"

H "SFP ports  [ifs:$sfp_ifs]"
for i in $sfp_ifs; do
  H "  -- $i --"
  R "ip -br link show $i"
  R "ethtool $i"
  R "ethtool -m $i"        # <== the H1/H2 divider: does the SFP EEPROM answer?
  R "cat /sys/class/net/$i/carrier"
done

H "Uplink ports into the 88E6190 DSA switch  [ifs:$up_ifs]"
for i in $up_ifs; do
  R "ip -br link show $i"
  R "ethtool $i"
done

H "Kernel log (ixgbe / e1000 / sfp / dsa / phy)"
R "dmesg | grep -iE 'ixgbe|e1000|sfp|dsa|mv88e|libphy|link'"

if [ "$do_sfp_up" = 1 ]; then
  H "Bringing SFP ports up (wait ~5s for link)"
  for i in $sfp_ifs; do R "ip link set $i up"; done
  sleep 5
  for i in $sfp_ifs; do
    printf '  %-6s carrier=' "$i"; cat "/sys/class/net/$i/carrier" 2>/dev/null; printf '\n'
  done
  R "dmesg | tail -n 25"
fi

if [ "$do_all_up" = 1 ]; then
  H "Bringing ALL eth up (wait ~5s)"
  for p in /sys/class/net/*; do i=$(basename "$p"); [ "$i" = lo ] && continue; R "ip link set $i up"; done
  sleep 5
  R "ip -br link"
fi

H "I2C / SMBus  (watchdog chip + SFP/switch exploration)"
R "modprobe i2c-core i2c-algo-bit i2c-i801 i2c-dev" || true
R "i2cdetect -l"
for b in $(i2cdetect -l 2>/dev/null | awk '{print $1}'); do
  R "i2cdetect -y ${b#i2c-}"
done

H "DSA / MDIO probe  (88E6190)"
R "modprobe libphy dsa mv88e6xxx" || true
R "ls -l /sys/bus/mdio_bus/devices" 2>/dev/null || echo "  (no /sys/bus/mdio_bus/devices)"
[ -d /sys/kernel/debug ] || mount -t debugfs none /sys/kernel/debug 2>/dev/null || true
R "ls /sys/kernel/debug/dsa" 2>/dev/null || echo "  (no /sys/kernel/debug/dsa — DSA not probed; expected on x86 with no DT)"
R "lsmod | grep -E 'dsa|mv88e|libphy'" || true

H "Sensors / disks  (bonus)"
R "modprobe coretemp" || true
R "sensors" || true
R "lsblk"

if [ "$do_watchdog" = 1 ]; then
  H "WATCHDOG DISABLE  (state change)"
  R "i2cset -y 1 0x22 0 0 b"
  echo "  If that writes OK, the 5-min reboot watchdog should be off. Verify by idling >5 min."
else
  H "Watchdog  (NOT run automatically — state change)"
  echo "  Known-good disable:   i2cset -y 1 0x22 0 0 b"
  echo "  Run it with:          edge610-diag --watchdog"
fi

H "How to read the results"
cat <<'EOF'
  1. `ethtool -m <sfp>` READS a module  -> transceiver OK  -> it's a LINK/AN problem.
       We're on 5.10 (pre-regression). If carrier is STILL 0 here, the SFP path is a
       hardware-enable issue (look at the i2c section), not the 6.1 ixgbe bug.
  2. `ethtool -m <sfp>` FAILS to detect -> cage held off -> vendor i2c/SMBus enable needed.
  3. Force a link attempt and re-check:   edge610-diag --sfp-up
  4. Throughput once a port is up:        iperf3 -s      /      iperf3 -c <peer>

  Kernel: this ISO ships linuxPackages_5_10 (pre-6.1). To test the 6.1 AN-37 ixgbe
  SFP regression (commit 565736048bd5), rebuild with pkgs.linuxPackages_6_1 (the
  first kernel that contains it) or the default 6.x kernel.
EOF