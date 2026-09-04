output "bucket_ids" {
  description = "Global alias to bucket ID mapping"
  value       = local.bucket_id_by_alias
}

output "access_keys" {
  description = "Access key ID and secret per key name"
  sensitive   = true
  value = {
    for k in garage_key.this : k.name => {
      id     = k.id
      secret = k.secret_access_key
    }
  }
}