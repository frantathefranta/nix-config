# Garage (ytterbium)

Manages buckets, access keys, and bucket permissions on the Garage instance
running on ytterbium via the [terraform-provider-garage](https://github.com/jkossis/terraform-provider-garage)
Admin API.

## Usage

State is stored in the `terraform-state` bucket on Garage (`garage/terraform.tfstate`),
created by the `garage` service at boot (`--default-bucket`). Credentials come from
the `Garage default S3 key` item in the `nix-config` 1Password vault, injected as
`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` via the repo-root `.1password` file.

Run from a network where `ytterbium.franta.us` resolves to the reachable IPv6 address.
The repo-root `.envrc` (direnv + `from_op .1password`) injects the token and S3
credentials, so a plain call works:

```sh
tofu -chdir=terraform/garage plan
tofu -chdir=terraform/garage apply
```

Without direnv, resolve them explicitly for the command instead:

```sh
op run --env-file=.1password -- tofu -chdir=terraform/garage apply
```

### Migrating existing local state

The first `tofu init` with the s3 backend detects the existing local `terraform.tfstate`
and offers to copy it into the bucket — answer yes:

```sh
tofu -chdir=terraform/garage init
```

### Locking

No state locking: Garage's S3 API doesn't support the conditional writes that the
`use_lockfile` backend option relies on, and there's no DynamoDB. Run tofu against a
given state from one place at a time.


Buckets, keys, and permissions are driven by the map variables in
`variables.tf`, configured in `garage.auto.tfvars`:

```hcl
buckets = {
  kubernetes = {} # global_alias defaults to the map key
  website = {
    website_enabled        = true
    website_index_document = "index.html"
    max_size               = 10737418240 # 10 GB
  }
}

access_keys = {
  backup = { name = "backup-agent" }
}

bucket_permissions = {
  backup_photos = {
    bucket = "kubernetes"
    key    = "backup-agent"
    write  = false # read-only
  }
}
```

Access key secrets are only available at creation time; read them with
`tofu output -raw access_keys` and store them in sops/1Password for the
consuming services.