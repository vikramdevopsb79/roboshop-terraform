variable "components" {
  default = [
    "frontend",
    "mongodb",
    "catalogue",
    "redis",
    "user",
    "cart",
    "mysql",
    "shipping",
    "rabbitmq",
    "payment",
    "dispatch"
  ]
}
variable "env" {
  default = "dev"
}
variable "vault_token" {}