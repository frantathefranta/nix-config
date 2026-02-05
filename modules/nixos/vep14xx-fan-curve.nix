{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.vep14xx-fan-curve;

  fanCurveScript = pkgs.writeShellScript "vep14xx-fan-curve.sh" ''
    set -euo pipefail

    FANTOOL="${cfg.package}/bin/fantool"
    LOCK="/run/vep14xx-fantool.lock"

    MIN_RPM=1750
    MAX_RPM=8000

    rpm_for_temp() {
      local t="$1"
      if   (( t <= 45 )); then echo 1750
      elif (( t <= 50 )); then echo 2000
      elif (( t <= 55 )); then echo 2400
      elif (( t <= 60 )); then echo 2800
      elif (( t <= 65 )); then echo 3200
      elif (( t <= 70 )); then echo 3800
      elif (( t <= 75 )); then echo 4500
      else                      echo 6500
      fi
    }

    read_cpu_pkg_temp_c() {
      for hw in /sys/class/hwmon/hwmon*; do
        [[ -f "$hw/name" ]] || continue
        [[ "$(cat "$hw/name")" == "coretemp" ]] || continue
        for lbl in "$hw"/temp*_label; do
          [[ -f "$lbl" ]] || continue
          if grep -qx "Package id 0" "$lbl"; then
            local base="''${lbl%_label}"
            local input="''${base}_input"
            [[ -f "$input" ]] || continue
            ${pkgs.gawk}/bin/awk '{print int($1/1000)}' "$input"
            return 0
          fi
        done
      done
      return 1
    }

    read_lm75_temp_c() {
      for hw in /sys/class/hwmon/hwmon*; do
        [[ -f "$hw/name" ]] || continue
        [[ "$(cat "$hw/name")" == "lm75" ]] || continue
        [[ -f "$hw/temp1_input" ]] || continue
        ${pkgs.gawk}/bin/awk '{print int($1/1000)}' "$hw/temp1_input"
        return 0
      done
      return 1
    }

    clamp() {
      local v="$1" lo="$2" hi="$3"
      (( v < lo )) && v="$lo"
      (( v > hi )) && v="$hi"
      echo "$v"
    }

    set_fans() {
      local rpm="$1"
      ${pkgs.util-linux}/bin/flock -w 5 "$LOCK" ${pkgs.bash}/bin/bash -c '
        rpm="'"$rpm"'"
        for attempt in 1 2 3; do
          ${cfg.package}/bin/fantool --set --fan=all --speed="$rpm" >/dev/null 2>&1 && exit 0
          sleep 0.3
        done
        exit 1
      '
    }

    LAST_SET=0
    LAST_TARGET=0

    ${pkgs.util-linux}/bin/flock -w 5 "$LOCK" "$FANTOOL" --init >/dev/null 2>&1 || true

    while true; do
      cpu=""
      lm75=""
      worst=""

      if cpu=$(read_cpu_pkg_temp_c 2>/dev/null); then :; fi
      if lm75=$(read_lm75_temp_c 2>/dev/null); then :; fi

      if [[ -n "''${cpu:-}" && -n "''${lm75:-}" ]]; then
        worst=$(( cpu > lm75 ? cpu : lm75 ))
      elif [[ -n "''${cpu:-}" ]]; then
        worst="$cpu"
      elif [[ -n "''${lm75:-}" ]]; then
        worst="$lm75"
      else
        worst=80
      fi

      target=$(rpm_for_temp "$worst")
      target=$(clamp "$target" "$MIN_RPM" "$MAX_RPM")

      now=$(date +%s)
      delta=$(( target - LAST_TARGET )); (( delta < 0 )) && delta=$(( -delta ))

      if (( delta >= 250 || (now - LAST_SET) >= 60 )); then
        if set_fans "$target"; then
          LAST_SET="$now"
          LAST_TARGET="$target"
        fi
      fi

      sleep 3
    done
  '';
in
{
  options.services.vep14xx-fan-curve = {
    enable = lib.mkEnableOption "VEP14xx fan curve daemon (TC654 via Dell fantool)";

    package = lib.mkPackageOption pkgs "vep14xx-diags" { };
  };

  config = lib.mkIf cfg.enable {
    # Load required I2C kernel modules
    boot.kernelModules = [
      "i2c-dev"
      "i2c-i801"
      "i2c-ismt"
    ];

    environment.systemPackages = [ cfg.package ];

    # Detect which I2C bus the TC654 lives on (bus numbering is unstable
    # across reboots) and deploy config files with the correct bus path.
    systemd.services.vep14xx-i2c-config = {
      description = "Detect VEP14xx I2C bus and deploy DiagOS config";
      wantedBy = [ "multi-user.target" ];
      before = [ "vep14xx-fan-curve.service" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.i2c-tools ];
      script = ''
        # Find the I2C bus with a TC654 at address 0x1b
        bus=""
        for dev in /dev/i2c-*; do
          [ -e "$dev" ] || continue
          num="''${dev#/dev/i2c-}"
          if i2cdetect -y "$num" 0x1b 0x1b 2>/dev/null | grep -q "1b"; then
            bus="$dev"
            break
          fi
        done

        if [ -z "$bus" ]; then
          echo "WARNING: TC654 not found on any I2C bus, using /dev/i2c-1 default" >&2
          bus="/dev/i2c-1"
        else
          echo "Found TC654 on $bus"
        fi

        # Copy config files from the package and patch the I2C bus path
        rm -rf /etc/dn/diag
        mkdir -p /etc/dn/diag
        cp -r ${cfg.package}/share/dn-diags/* /etc/dn/diag/
        chmod -R u+w /etc/dn/diag

        find /etc/dn/diag -name '*.xml' -exec \
          sed -i "s|/dev/i2c-[0-9]\+|$bus|g" {} +
      '';
    };

    systemd.services.vep14xx-fan-curve = {
      description = "VEP14xx Fan Curve (TC654 via Dell fantool)";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" "vep14xx-i2c-config.service" ];
      requires = [ "vep14xx-i2c-config.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${fanCurveScript}";
        Restart = "always";
        RestartSec = 2;
      };
    };
  };
}
