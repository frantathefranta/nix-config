variable "garage_endpoint" {
  description = "URL of the Garage Admin API endpoint"
  type        = string
  default     = "http://s3.infra.franta.us:3903"
}

variable "garage_token" {
  description = "Garage Admin API bearer token"
  type        = string
  sensitive   = true
  default     = null
}

variable "buckets" {
  description = "Map of buckets to manage, keyed by identifier. The key is also the global alias unless overridden."
  type = map(object({
    global_alias           = optional(string)
    website_enabled        = optional(bool, false)
    website_index_document = optional(string)
    website_error_document = optional(string)
    max_size               = optional(number)
    max_objects            = optional(number)
  }))
  default = {}
}

variable "access_keys" {
  description = "Map of access keys to manage, keyed by identifier"
  type = map(object({
    name = string
  }))
  default = {}
}

variable "bucket_permissions" {
  description = "Map of bucket permissions, keyed by identifier. `bucket` is the bucket global alias, `key` is the access key name."
  type = map(object({
    bucket = string
    key    = string
    read   = optional(bool, true)
    write  = optional(bool, true)
    owner  = optional(bool, false)
  }))
  default = {}
}
