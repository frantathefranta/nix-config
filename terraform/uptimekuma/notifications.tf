resource "uptimekuma_notification_pushover" "pushover" {
  name      = "Pushover"
  is_active = true
  user_key  = var.uptimekuma_pushover_user_key
  app_token = var.uptimekuma_pushover_api_token
}

locals {
  notification_ids = {
    pushover = uptimekuma_notification_pushover.pushover.id
  }
}
