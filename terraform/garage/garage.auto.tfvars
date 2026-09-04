buckets = {
  kubernetes = {}
}

access_keys = {
  kubernetes = { name = "kubernetes" }
}

bucket_permissions = {
  kubernetes = {
    bucket = "kubernetes"
    key    = "kubernetes"
    # read/write default true, owner false
  }
}
