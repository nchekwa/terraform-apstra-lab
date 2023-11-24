#################################################
terraform {
    required_providers {
    apstra = {
        source = "Juniper/apstra"
        version = "0.43.0"
      }
    }
}
#################################################

#################################################
# In case of debug needed - run:
# terraform apply -var="debug=true"
variable "debug" {
  description = "Enable or disable debug output"
  type        = bool
  default     = false
}
#################################################

#################################################
# Apstra credentials can be supplied through environment variables:
#export APSTRA_USER=<username>
#export APSTRA_PASS=<password>
# Alternatively, credentials can be embedded in the URL using HTTP basic authentication format
variable "apstra_credentials" {
  type = map(string)
  default = {
    username = "admin"
    password = "admin"
    ip       = "172.30.108.196"
  }
}

provider "apstra" {
  url                       = "https://${var.apstra_credentials["username"]}:${var.apstra_credentials["password"]}@${var.apstra_credentials["ip"]}"
  tls_validation_disabled   = true                         # optional
  blueprint_mutex_enabled   = false                        # optional
  api_timeout               = 60                           # optional; 0 == infinite
  experimental              = true
}
#################################################

#################################################
### Get Access token for Curl Commands
data "external" "get_access_token" {
  program = ["bash", "-c", <<-EOT
    token=$(curl --silent -k -X POST 'https://${var.apstra_credentials["ip"]}/api/user/login' \
      -H 'accept: application/json' \
      -H 'content-type: application/json' \
      -d "{ \"username\":\"${var.apstra_credentials["username"]}\", \"password\":\"${var.apstra_credentials["password"]}\" }" | jq --raw-output '.token')

    echo "{\"access_token\": \"$token\"}"   
  EOT
  ]
}

locals {
  access_token = data.external.get_access_token.result.access_token
}
output "access_token" {  value = var.debug ? local.access_token : null}
#################################################

