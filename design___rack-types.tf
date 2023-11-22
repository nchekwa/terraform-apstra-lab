#### rack
variable "rack_types_file_path" {
  description = "Path to the YAML file - rack types"
  default     = "/config/rack_types.yaml"
}
locals {
  rack_types_file_yaml = fileexists("${path.module}${var.rack_types_file_path}") ? file("${path.module}${var.rack_types_file_path}") : ""
  rack_types_data = try(yamldecode(local.rack_types_file_yaml)["rack_types"], {})
  rack_types = can(local.rack_types_data) && length(keys(coalesce(local.rack_types_data, {}))) > 0 ? local.rack_types_data : {}
}
output "debug_rack_types" { value = var.debug ? local.rack_types : null }


##############################################
## Get Maping Leaf "LogicalDevice"=>"ID"
locals {
  rack_types_with_ids = distinct(flatten([
    for rack_name, rack_config in local.rack_types : [
      for leaf_config in rack_config.leaf_switches : leaf_config.logical_device
    ]
  ]))
}
data "apstra_logical_device" "selected" {
  for_each = { for device in local.rack_types_with_ids : device => device }
  name = each.value
}
locals {
  logical_device_ids = {
    for key, value in data.apstra_logical_device.selected : key => value.id
  }
}
output "debug_logical_device_ids" { value = var.debug ? local.logical_device_ids : null }



############################################
## Create Racks
resource "apstra_rack_type" "all" {
  for_each                    = local.rack_types
  name                        = each.value.name
  description                 = each.value.description
  fabric_connectivity_design  = each.value.fabric_connectivity_design
  leaf_switches = {
    leaf_switch = {
      logical_device_id     = local.logical_device_ids[each.value.leaf_switches.0.logical_device]
      spine_link_count      = each.value.leaf_switches.0.spine_link_count
      spine_link_speed      = each.value.leaf_switches.0.spine_link_speed
      redundancy_protocol   = each.value.leaf_switches.0.redundancy_protocol
    }
  }
}


###
# First, collect all Rack Type IDs
data "apstra_rack_types" "all" {}

# Loop over Rack Type IDs, collect full details of each Rack Type
data "apstra_rack_type" "each" {
  for_each = data.apstra_rack_types.all.ids
  id       = each.key
}
output "debug_apstra_rack_type" { value = var.debug ? data.apstra_rack_type.each : null }
