#################################################
### Devices > Agent Profiles
locals {
  config_agent_profiles = yamldecode(file("${path.module}/config/devices.yaml")).agent_profiles
  config_managed_devices = yamldecode(file("${path.module}/config/devices.yaml")).managed_devices
}
#################################################

#################################################
### Create not existin profiles
resource "apstra_agent_profile" "create" {
  depends_on = [ apstra_managed_device.all ]
  for_each = { for key, value in local.config_agent_profiles : key => value }
  name      = each.key
}
# For all created profiles - set password via API
resource "null_resource" "set_password_for_profile" {
    for_each = local.config_agent_profiles
    provisioner "local-exec" { 
        command = <<-EOT
            curl -s -k -H 'accept: application/json' \
            -H  'content-type: application/json' \
            -H 'AuthToken: ${local.access_token}' \
            -X PATCH https://${var.apstra_credentials["ip"]}/api/system-agent-profiles/${apstra_agent_profile.create[each.key].id}  \
            -d '{"username": "${local.config_agent_profiles[each.key].username}", "password": "${local.config_agent_profiles[each.key].password}", "platform": "${local.config_agent_profiles[each.key].platform}" }'
        EOT
        }   
}
#################################################

#################################################
### Collect data
data "apstra_agent_profiles" "all" {}
data "apstra_agent_profile" "each" {
  for_each  = data.apstra_agent_profiles.all.ids
  id        = each.key
}

# Get locals about agent_profiles
locals {
    apstra_agent_profile_names = length(data.apstra_agent_profile.each) > 0 ? { for id, profile in data.apstra_agent_profile.each : profile.name => id } : {}
}
output "debug_apstra_agent_profile_names" { value = var.debug ? local.apstra_agent_profile_names : null }
#################################################





#################################################
### Devices > Managed Devices >> Systems 
data "apstra_agents" "all" {}
data "apstra_agent" "each" {
    for_each = coalesce(data.apstra_agents.all.ids, [])
    agent_id = each.key
} 
#################################################

#################################################
### List of Apstra Systems to be created (exist in config and not exist in system)
locals {
    depends_on = apstra_agent_profile.create
    device_map = flatten([
        for profile_name, device_list in local.config_managed_devices: [
            for agent_profile in data.apstra_agent_profile.each: [
              for ip in device_list:
                {
                  id = agent_profile.id
                  ip = ip
                }
            ]
        ] 
    ])
}
output "debug_device_map" { value = var.debug ? local.device_map : null }

# Create Apstra System if not exist
resource "apstra_managed_device" "all" {
  count = length(local.device_map)
  agent_profile_id = local.device_map[count.index].id
  off_box = true
  management_ip = local.device_map[count.index].ip
} 

## ACK for just added system:
resource "apstra_managed_device_ack" "all" {
  count = length(local.device_map)
  agent_id = apstra_managed_device.all[count.index].agent_id
  device_key = apstra_managed_device.all[count.index].system_id
}
#################################################
