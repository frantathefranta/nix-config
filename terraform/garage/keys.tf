resource "garage_key" "this" {
  for_each = var.access_keys

  name = each.value.name
}

locals {
  bucket_id_by_alias = { for b in garage_bucket.this : b.global_alias => b.id }
  key_id_by_name     = { for k in garage_key.this : k.name => k.id }
}