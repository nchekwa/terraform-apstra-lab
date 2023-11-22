#### template
variable "templates_file_path" {
  description = "Path to the YAML file - templates"
  default     = "/config/templates.yaml"
}
locals {
  templates_file_yaml = fileexists("${path.module}${var.templates_file_path}") ? file("${path.module}${var.templates_file_path}") : ""
  templates_data = try(yamldecode(local.templates_file_yaml)["templates"], {})
  templates = can(local.templates_data) && length(keys(coalesce(local.templates_data, {}))) > 0 ? local.templates_data : {}
}


##############################################
## Get Maping Spine "LogicalDevice"=>"ID"
locals {
  templates_spine_names = flatten([
    for template_name, template in local.templates : template.spine.logical_device
  ])
}
output "debug_templates_spine_names" { value = var.debug ? local.templates_spine_names : null }

data "apstra_logical_device" "spines" {
  for_each = { for aos_model in local.templates_spine_names : aos_model => aos_model }
  name = each.value
}
locals {
  spine_logical_device_ids = {
    for key, value in data.apstra_logical_device.spines : key => value.id
  }
}
output "debug_spine_logical_device_ids" { value = var.debug ? local.spine_logical_device_ids : null }






resource "apstra_template_rack_based" "r" {
  for_each                  = local.templates
  name                      = each.key
  asn_allocation_scheme     = each.value.asn_allocation_scheme
  overlay_control_protocol  = each.value.overlay_control_protocol
  spine = {
    logical_device_id = local.spine_logical_device_ids[each.value.spine.logical_device]
    count = 2
  }
  rack_infos = {
    for label, count in each.value.racks:
      apstra_rack_type.all[label].id => { count = count }
  }
  #depends_on = [ apstra_rack_type.all ]
}