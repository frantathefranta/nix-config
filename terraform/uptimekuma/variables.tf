variable "uptimekuma_endpoint" {
  description = "URL of the Uptime Kuma instance"
  type        = string
  default     = "https://uptime.franta.us"
}

variable "uptimekuma_username" {
  description = "Uptime Kuma username"
  type        = string
  sensitive   = true
}

variable "uptimekuma_password" {
  description = "Uptime Kuma password"
  type        = string
  sensitive   = true
}

variable "push_monitors" {
  description = "Map of push monitors to create, keyed by identifier used in Akeyless"
  type = map(object({
    name              = string
    interval          = optional(number, 3600)
    notifications     = optional(list(string), ["pushover"])
  }))
  default = {}
}

variable "access_id" {
  description = "Akeyless Access ID"
  type        = string
  sensitive   = true
  default     = null
}

variable "access_key" {
  description = "Akeyless Access Key"
  type        = string
  sensitive   = true
  default     = null
}

variable "uptimekuma_pushover_api_token" {
  description = "Uptime Kuma Pushover API token"
  type        = string
  sensitive   = true
}

variable "uptimekuma_pushover_user_key" {
  description = "Uptime Kuma Pushover user key"
  type        = string
  sensitive   = true
}
