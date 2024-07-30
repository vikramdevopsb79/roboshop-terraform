provider "vault" {
  address         = "https://vault-internal.vikramdevops.store:8200"
  skip_tls_verify = true
  token           = var.vault_token
}
terraform  {
  backend "s3" {}

}