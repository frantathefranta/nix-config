resource "uptimekuma_monitor_push" "monitors" {
  for_each = var.push_monitors

  name             = each.value.name
  interval         = each.value.interval
  notification_ids = [for n in each.value.notifications : local.notification_ids[n]]
}
