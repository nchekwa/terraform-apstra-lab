variable "logical_devices_file_path" {
  description = "Path to the YAML file - logical devices"
  default     = "/config/logical_devices.yaml"
}
locals {
  logical_devices_file_yaml = fileexists("${path.module}${var.logical_devices_file_path}") ? file("${path.module}${var.logical_devices_file_path}") : ""
  logical_devices_data = try(yamldecode(local.logical_devices_file_yaml)["logical_devices"], {})
  logical_devices = can(local.logical_devices_data) && length(keys(coalesce(local.logical_devices_data, {}))) > 0 ? local.logical_devices_data : {}
}

resource "apstra_logical_device" "all" {
  for_each = can(local.logical_devices) ? local.logical_devices : {}

  name   = each.value.name
  panels = each.value.panels
}
