#################################################
### Template
variable "templates_file_path" {
  description = "Path to the YAML file - templates"
  default     = "/config/templates.yaml"
}
locals {
  templates_file_yaml = fileexists("${path.module}${var.templates_file_path}") ? file("${path.module}${var.templates_file_path}") : ""
  templates_data = try(yamldecode(local.templates_file_yaml)["templates"], {})
  templates = can(local.templates_data) && length(keys(coalesce(local.templates_data, {}))) > 0 ? local.templates_data : {}
}
#################################################

#################################################
### Get Maping Spine "LogicalDevice"=>"ID"
locals {
  logical_devices_for_templates = flatten([
    for template_name, template in local.templates : template.spine.logical_device
  ])
}
data "apstra_logical_device" "selected_for_templates" {
  for_each = { for aos_model in local.logical_devices_for_templates : aos_model => aos_model }
  name = each.value
}
locals {
  logical_devices_for_templates_ids = {
    for key, value in data.apstra_logical_device.selected_for_templates : key => value.id
  }
}
output "debug_logical_devices_for_templates_ids" { value = var.debug ? local.logical_devices_for_templates_ids : null }
#################################################

#################################################
## Create Templates
resource "apstra_template_rack_based" "r" {
  for_each                  = can(local.templates) ? local.templates : {}
  name                      = each.key
  asn_allocation_scheme     = each.value.asn_allocation_scheme
  overlay_control_protocol  = each.value.overlay_control_protocol
  spine = {
    logical_device_id = local.logical_devices_for_templates_ids[each.value.spine.logical_device]
    count = 2
  }
  rack_infos = {
    for label, count in each.value.racks:
      apstra_rack_type.all[label].id => { count = count }
  }
}
#################################################
