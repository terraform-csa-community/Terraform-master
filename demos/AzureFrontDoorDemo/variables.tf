variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "locations" {
  description = "list of locations for deployment"
  default = ["EastUS","WestUS"]
}