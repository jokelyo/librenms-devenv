# add a delay to allow the VMs to boot and make SNMP available
resource "time_sleep" "instance_creations" {
  for_each = local.instance_definitions

  create_duration = "60s"

  triggers = {
    #instance_id = google_compute_instance.lab_instances[each.key].id
    ip_address = google_compute_instance.lab_instances[each.key].network_interface.0.access_config.0.nat_ip
  }
}

resource "librenms_device" "compute_instances" {
  for_each = local.instance_definitions

  # get the instance's IP address from the time_sleep resource
  hostname = time_sleep.instance_creations[each.key].triggers["ip_address"]

  snmp_v2c = {
    community = var.snmp_community_string
  }
}

resource "librenms_devicegroup" "gcp" {
  name = "GCP Instances"
  type = "dynamic"

  rules = jsonencode({
    "condition" : "AND",
    "rules" : [
      {
        "id" : "devices.sysDescr",
        "field" : "devices.sysDescr",
        "operator" : "contains",
        "value" : "cloud"
      }
    ],
    "joins" : [],
    "valid" : true,
  })
}
