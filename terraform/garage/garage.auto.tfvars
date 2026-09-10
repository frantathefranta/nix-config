buckets = {
  kubernetes = {}
  kopiur     = {}
}

access_keys = {
  kubernetes = { name = "kubernetes" }
  kopiur     = { name = "kopiur" }
}

bucket_permissions = {
  kubernetes = {
    bucket = "kubernetes"
    key    = "kubernetes"
    # read/write default true, owner false
  }
  kopiur = {
    bucket = "kopiur"
    key    = "kopiur"
  }
}
