#################################################
### interface_map
variable "interface_maps_file_path" {
  description = "Path to the YAML file - interface maps"
  default     = "/config/interface_maps.yaml"
}
locals {
  interface_maps_file_yaml = fileexists("${path.module}${var.interface_maps_file_path}") ? file("${path.module}${var.interface_maps_file_path}") : ""
  interface_maps_data = try(yamldecode(local.interface_maps_file_yaml)["interface_maps"], {})
  interface_maps = can(local.interface_maps_data) && length(keys(coalesce(local.interface_maps_data, {}))) > 0 ? local.interface_maps_data : {}
}
#################################################

#################################################
### Get Maping Leaf "LogicalDevice"=>"ID"
locals {
  logical_devices_for_interface_maps = [
    for interface_map_name, interface_map_config in local.interface_maps : interface_map_config.logical_device
  ]
}
data "apstra_logical_device" "selected_for_interface_maps" {
  for_each = { for device in local.logical_devices_for_interface_maps : device => device }
  name = each.value
}
locals {
  logical_devices_for_interface_maps_ids = {
    for key, value in data.apstra_logical_device.selected_for_interface_maps : key => value.id
  }
}
output "debug_logical_devices_for_interface_maps_ids" { value = var.debug ? local.logical_devices_for_interface_maps_ids : null }
#################################################

#################################################
## Create Interface Map
resource "apstra_interface_map" "all" {
  for_each            = can(local.interface_maps) ? local.interface_maps: {}
  name                = each.value.name
  logical_device_id   = local.logical_devices_for_interface_maps_ids[each.value.logical_device]
  device_profile_id   = each.value.device_profile_id
  interfaces          = flatten([
    for map in each.value.device_mapping : [
      for i in range(map.count) : {
        logical_device_port     = format("%d/%d", map.ld_panel, map.ld_first_port + i)
        physical_interface_name = format("%s%d", map.phy_prefix, map.phy_first_port + i)
      }
    ]
  ])
}
#################################################
