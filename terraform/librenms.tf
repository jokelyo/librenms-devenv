# add a delay to allow the VMs to boot and make SNMP available
resource "time_sleep" "instance_creations" {
  for_each = local.instance_definitions

  create_duration = "60s"

  triggers =  {
    #instance_id = google_compute_instance.lab_instances[each.key].id
    ip_address = google_compute_instance.lab_instances[each.key].network_interface[0].access_config[0].nat_ip
  }
}

resource "librenms_device" "compute_instances" {
  for_each = local.instance_definitions

  # get the instance's IP address from the time_sleep resource
  hostname = time_sleep.instance_creations[each.key].triggers["ip_address"]
  display  = each.key

  snmp_v2c = {
    community = var.snmp_community_string
  }
}

# add dummy host to test location assignment
resource "librenms_device" "dummy_host" {
  hostname  = "192.168.5.5"
  force_add = true

  snmp_v2c = {
    community = var.snmp_community_string
  }

  location = librenms_location.test_location.name
}

# Create a LibreNMS location to assign to the dummy host
resource "librenms_location" "test_location" {
  name = "test location"

  fixed_coordinates = true
  latitude          = -45.0862462
  longitude         = 37.4220648
}

resource "librenms_location" "test_location2" {
  name = "test location 2"

  fixed_coordinates = true
  latitude          = -35.0862462
  longitude         = 57.4220648
}

# dynamic group for GCP instances
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

# static test group
resource "librenms_devicegroup" "gcp_routers" {
  name = "GCP Routers"
  type = "static"

  devices = [
    librenms_device.compute_instances["frr-router-1"].id,
    librenms_device.compute_instances["frr-router-2"].id
  ]
}


## test services
resource "librenms_service" "vm1_http_yahoo" {
  device_id = librenms_device.compute_instances["compute-vm-1"].id
  name      = "HTTPS Cert Check"
  type      = "http"

  ignore     = false
  parameters = "-C 30,14"
  target     = "yahoo.com"

}

resource "librenms_service" "vm1_http_dummy" {
  device_id = librenms_device.compute_instances["compute-vm-1"].id
  name      = "HTTPS Cert Check"
  type      = "http"

  ignore     = false
  parameters = "-C 30,14"
  target     = "192.168.5.5"

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

resource "librenms_alertrule" "device_rebooted" {
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

  # limit to specific groups and locations for testing purposes
  groups = [
    librenms_devicegroup.gcp.id,
    librenms_devicegroup.gcp_routers.id
  ]

  locations = [
    librenms_location.test_location.id,
    librenms_location.test_location2.id
  ]
}

resource "librenms_alertrule" "ping_latency_groups_locations" {
  name = "Ping Latency (Specific Groups and Locations)"

  builder = jsonencode({
    "condition" : "AND",
    "rules" : [
      {
        "id" : "devices.last_ping_timetaken",
        "field" : "devices.last_ping_timetaken",
        "type" : "string",
        "input" : "text",
        "operator" : "greater",
        "value" : "10"
      },
    ],
    "valid" : true
  })

  delay      = "11m"
  interval   = "5m"
  max_alerts = 1

  disabled = false
  severity = "warning"

  # defaults to all devices if devices is not defined
  # devices = [1, 2]

  # limit to specific groups and locations for testing purposes
  groups = [
    librenms_devicegroup.gcp.id,
    librenms_devicegroup.gcp_routers.id
  ]

  locations = [
    librenms_location.test_location2.id,
    librenms_location.test_location.id
  ]
}
