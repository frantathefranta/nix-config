resource "akeyless_static_secret" "push_tokens" {
  path  = "/uptimekuma/push_tokens"
  value = jsonencode({
    for k, m in uptimekuma_monitor_push.monitors : k => "https://uptime.franta.us/api/push/${m.push_token}?"
    # TODO: Gotta figure out how to reach the endpoint from anywhere (without IPv6), so this var can go back
    # for k, m in uptimekuma_monitor_push.monitors : k => "${var.uptimekuma_endpoint}/api/push/${m.push_token}?status=up&msg=OK&ping="
  })
}
