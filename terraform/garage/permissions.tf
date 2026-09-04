resource "garage_bucket_permission" "this" {
  for_each = var.bucket_permissions

  bucket_id     = local.bucket_id_by_alias[each.value.bucket]
  access_key_id = local.key_id_by_name[each.value.key]
  read          = each.value.read
  write         = each.value.write
  owner         = each.value.owner
}