#################################################
### Apstra Resources
variable "resources_file_path" {
  description = "Path to the YAML file - resources"
  default     = "/config/resources.yaml"
}
locals {
  resources_file_yaml = fileexists("${path.module}${var.resources_file_path}") ? file("${path.module}${var.resources_file_path}") : ""
  resources_data = try(yamldecode(local.resources_file_yaml).resources, {})
  resources = can(local.resources_data) && length(keys(local.resources_data)) > 0 ? local.resources_data : null
}
output "debug_resources_data" { value = var.debug ? local.resources_data : null }
#################################################

#################################################
### ASN
resource "apstra_asn_pool" "all" {
  for_each = can(local.resources["asn_pool"]) ? local.resources["asn_pool"] : {}
  name = each.key
  ranges = [ for range in each.value: { first = range.first, last = range.last} ]
}

### VNI
resource "apstra_vni_pool" "all" {
  for_each = can(local.resources["vni_pool"]) ? local.resources["vni_pool"] : {}
  name = each.key
  ranges = [ for range in each.value: { first = range.first, last = range.last} ]
}

### INTIGER
resource "apstra_integer_pool" "all" {
  for_each = can(local.resources["integer_pool"]) ? local.resources["integer_pool"] : {}
  name = each.key
  ranges = [ for range in each.value: { first = range.first, last = range.last} ]
}

### IPv4
resource "apstra_ipv4_pool" "all" {
  for_each = can(local.resources["ipv4_pool"]) ? local.resources["ipv4_pool"] : {}
  name = each.key
  subnets = [ for subnet in each.value: { network = subnet } ]
}

### IPv6
resource "apstra_ipv6_pool" "all" {
  for_each = can(local.resources["ipv6_pool"]) ? local.resources["ipv6_pool"] : {}
  name = each.key
  subnets = [ for subnet in each.value: { network = subnet } ]
}
#################################################
