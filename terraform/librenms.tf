# add a delay to allow the VMs to boot and make SNMP available
resource "time_sleep" "instance_creations" {
  for_each = local.instance_definitions

  create_duration = "60s"

  triggers = {
    #instance_id = google_compute_instance.lab_instances[each.key].id
    ip_address = google_compute_instance.lab_instances[each.key].network_interface[0].access_config[0].nat_ip
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

### -- Create a few default alert rules -- ###

# Unfortunately, the API doesn't currently have CRUD ops for alert transports or templates.

# To get the JSON for the alert rule builder, you can create the rule in LibreNMS and then get it from the API:
#   curl -H "X-Auth-Token: <token>" http://localhost:8000/api/v0/rules/1 | jq '.rules.[0].builder | fromjson'

resource "librenms_alertrule" "device_down_icmp" {
  name = "Device Down! Due to no ICMP response."

  builder = jsonencode({
    "condition" : "AND",
    "rules" : [
      {
        "id" : "macros.device_down",
        "field" : "macros.device_down",
        "type" : "integer",
        "input" : "radio",
        "operator" : "equal",
        "value" : "1"
      },
      {
        "id" : "devices.status_reason",
        "field" : "devices.status_reason",
        "type" : "string",
        "input" : "text",
        "operator" : "equal",
        "value" : "icmp"
      }
    ],
    "valid" : true
  })

  delay      = "11m"
  interval   = "5m"
  max_alerts = 1

  disabled = false
  severity = "critical"

  # defaults to all devices if devices is not defined
  # devices = [1, 2]
}

resource "librenms_alertrule" "device_down_snmp" {
  name = "Device Down (SNMP unreachable)"

  builder = jsonencode({
    "condition" : "AND",
    "rules" : [
      {
        "id" : "macros.device_down",
        "field" : "macros.device_down",
        "type" : "integer",
        "input" : "radio",
        "operator" : "equal",
        "value" : "1"
      },
      {
        "id" : "devices.status_reason",
        "field" : "devices.status_reason",
        "type" : "string",
        "input" : "text",
        "operator" : "equal",
        "value" : "snmp"
      }
    ],
    "valid" : true
  })

  delay      = "11m"
  interval   = "5m"
  max_alerts = 1

  disabled = false
  severity = "critical"

  # defaults to all devices if devices is not defined
  # devices = [1, 2]
}

resource "librenms_alertrule" "device_down_rebooted" {
  name = "Device rebooted"

  builder = jsonencode({
    "condition" : "AND",
    "rules" : [
      {
        "id" : "devices.uptime",
        "field" : "devices.uptime",
        "type" : "string",
        "input" : "text",
        "operator" : "less",
        "value" : "300"
      },
      {
        "id" : "macros.device",
        "field" : "macros.device",
        "type" : "integer",
        "input" : "radio",
        "operator" : "equal",
        "value" : "1"
      }
    ],
    "valid" : true
  })

  delay      = "1m"
  interval   = "5m"
  max_alerts = 1

  disabled = false
  severity = "critical"

  # defaults to all devices if devices is not defined
  # devices = [1, 2]
}
