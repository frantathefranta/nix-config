# Home Assistant Container on neon

The native Home Assistant configuration has been retired. This deployment does
not delete `/var/lib/hass` or the old `hass` database.

Onboard directly at <http://10.0.20.30:8123> on VLAN 20. In **Settings → System
→ Network → HTTP server**, enable **Trust X-Forwarded-For** and add `127.0.0.1`
to **Trusted proxies**. Restart Home Assistant if prompted. Caddy shares
Home Assistant's network namespace and proxies over loopback.

Apply the `hass.infra.franta.us` DNS change with `just update-dns-doit` after
reviewing `just update-dns`. The name resolves to `10.0.20.30` and
`2600:1702:6630:3fe1:10:0:20:30`. Use <https://hass.infra.franta.us> once the
ACME certificate is ready. Caddy does not filter client source addresses;
reachability from other networks depends on routing and firewall policy.

Home Assistant generates its own configuration in the writable Podman volume `home-assistant`, mounted at `/config`. It uses SQLite until you configure PostgreSQL. After the first start, open the generated file on neon:

```sh
sudoedit "$(sudo podman volume inspect --format '{{.Mountpoint}}' home-assistant)/configuration.yaml"
```

Add this top-level entry, then run `sudo systemctl restart podman-home-assistant`:

```yaml
recorder:
  db_url: "postgresql://homeassistant@/homeassistant?host=/run/postgresql"
```

PostgreSQL uses peer authentication over the mounted Unix socket. Recorder history collected in SQLite before the switch is not migrated.

Quadlet manages the `ha-vlan20` macvlan and the `home-assistant` pod. The pod
owns the dual-stack addresses and shared loopback; restarting Home Assistant
does not restart Matter or Caddy. Check the pod with
`systemctl status home-assistant-pod` and the application with
`journalctl -u podman-home-assistant -b`. If VLAN 20's IPv6 prefix changes,
update the network and pod in `default.nix` and the Caddy bind and DNS record
in `proxy.nix`.

## MQTT

Mosquitto starts with a fresh `mosquitto` named volume; old broker data is not
imported. Add the MQTT integration in Home Assistant with broker `127.0.0.1`
and port `1883`.
Point external MQTT clients at `10.0.20.30:1883` (or
`[2600:1702:6630:3fe1:10:0:20:30]:1883`). Anonymous access is unchanged;
do not expose port `1883` to untrusted networks.

## go2rtc

go2rtc runs in the pod. For Home Assistant's external go2rtc integration, use
`http://127.0.0.1:1984`. HomeKit clients discover the cameras on VLAN 20; WebRTC
uses port `8555` on the pod addresses. The pod must be able to reach the camera
addresses on VLAN 50.

Before deploying, run `sudo podman volume create --ignore go2rtc` on neon.
Use `sudo podman volume inspect --format '{{.Mountpoint}}' go2rtc` to find
the directory and place your writable `go2rtc.yaml` there. The image reads it
at `/config/go2rtc.yaml`. Copy any HomeKit pairings you want to keep from
`/var/lib/private/go2rtc/state.yaml`. Nix does not seed or overwrite either file.
`${REOLINK_PASSWORD}` is still supplied through the SOPS environment file.

## Matter

In the new Home Assistant instance, add the Matter integration, select the
existing-server option, and enter `ws://127.0.0.1:5580/ws`. The Matter Server
container shares the pod's macvlan network namespace, so the WebSocket is
loopback-only while Matter discovery uses VLAN 20 directly. The
`matter-server` volume stores a fresh fabric; the native server's fabric is
not imported.

Commission with the phone, Matter device (for Wi-Fi), and Thread border router
(for Thread) on VLAN 20. This setup requires local IPv6 multicast and, for
Thread, a reachable border router advertising the Thread routes. No host
Bluetooth adapter is passed through; use the Companion app for commissioning.
The standalone container setup is not officially supported upstream.

Check `journalctl -u podman-matter-server -b` if the integration cannot
connect. For Thread routing, check `sudo podman exec home-assistant ip -6
route show proto ra`; expect a route for the Thread prefix via the border
router. Confirm operation by commissioning a device and controlling it from HA.
