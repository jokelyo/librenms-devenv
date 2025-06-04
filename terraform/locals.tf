locals {
  # Define the instances to be created
  instance_definitions = {
    "compute-vm-1" = {
      description         = "A general purpose compute instance."
      tags                = ["test-vm"]
      startup_script_path = "scripts/snmp_only_startup_script.tpl"
    }
    "compute-vm-2" = {
      description         = "Another general purpose compute instance."
      tags                = ["test-vm"]
      startup_script_path = "scripts/snmp_only_startup_script.tpl"
    }
    "frr-router-1" = {
      description         = "FRRouting instance 1. Installs FRR via startup script."
      tags                = ["frr-router", "test-vm"]
      startup_script_path = "scripts/frr_startup_script.tpl"
    }
    "frr-router-2" = {
      description         = "FRRouting instance 2. Installs FRR via startup script."
      tags                = ["frr-router", "test-vm"]
      startup_script_path = "scripts/frr_startup_script.tpl"
    }
    "testing-device-1" = {
      description         = "Additional testing device instance."
      tags                = ["test-vm"]
      startup_script_path = "scripts/snmp_only_startup_script.tpl"
    }
  }
}
