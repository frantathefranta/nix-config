resource "garage_bucket" "this" {
  for_each = var.buckets

  global_alias           = coalesce(each.value.global_alias, each.key)
  website_enabled        = each.value.website_enabled
  website_index_document = each.value.website_index_document
  website_error_document = each.value.website_error_document
  max_size               = each.value.max_size
  max_objects            = each.value.max_objects
}