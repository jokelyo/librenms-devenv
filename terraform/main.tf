# FILENAME: main.tf

# --- Project Setup ---

# Enable necessary APIs for the Project
resource "google_project_service" "compute_api" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false # Keep API enabled if Terraform is run again
}

# --- VPC Network Setup ---

# Create the VPC network
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false # We will create a custom subnet
  routing_mode            = "REGIONAL"

  depends_on = [
    google_project_service.compute_api
  ]
}

# Create a subnet in the VPC network
resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = var.subnet_name
  ip_cidr_range = var.subnet_ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc_network.self_link
}

# --- Firewall Rules ---
# These rules apply to the VPC network.

resource "google_compute_firewall" "allow_internal_ssh_icmp_frr" {
  project = var.project_id
  name    = "${var.network_name}-allow-internal-ssh-icmp-frr"
  network = google_compute_network.vpc_network.self_link

  # Allow SSH (TCP port 22)
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  # Allow ICMP (for ping)
  allow {
    protocol = "icmp"
  }
  # Allow BGP (TCP port 179) for FRRouting if you plan to peer them
  allow {
    protocol = "tcp"
    ports    = ["179"]
  }
  # Allow OSPF (IP protocol 89) if you plan to use OSPF
  allow {
    protocol = "89" # OSPF
  }

  # Only allow from within the subnet itself and the specified external IP for SNMP.
  source_ranges = [var.subnet_ip_cidr_range, var.snmp_source_ip_cidr]
  # You could also use target_tags if you assign tags to your instances
  # target_tags = ["lab-vm"]
}

resource "google_compute_firewall" "allow_snmp" {
  project = var.project_id
  name    = "${var.network_name}-allow-snmp"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "udp"
    ports    = ["161"] # SNMP
  }
  allow {
    protocol = "tcp"
    ports    = ["161"] # SNMP (sometimes TCP is used for traps or bulk)
  }

  # If your polling station is also within the subnet, you can use:
  # source_ranges = [var.subnet_ip_cidr_range]
  source_ranges = [var.snmp_source_ip_cidr]

  # Apply to instances tagged 'frr-router' or any other tag you want to poll
  target_tags = ["frr-router", "test-vm"]
}

# --- Compute Instances ---

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

resource "google_compute_instance" "lab_instances" {
  for_each = local.instance_definitions

  project      = var.project_id
  zone         = var.zone
  name         = each.key
  machine_type = var.instance_machine_type
  description  = each.value.description
  tags         = each.value.tags

  boot_disk {
    initialize_params {
      image = var.instance_image
      size  = 10 # GB, smallest standard persistent disk, free-tier eligible
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link

    # This empty access_config block requests an ephemeral external IP.
    access_config {}
  }

  # Add startup script if defined for the instance
  metadata_startup_script = templatefile(each.value.startup_script_path, {
    snmp_community = var.snmp_community_string
  })

  scheduling {
    preemptible         = true
    automatic_restart   = false
    on_host_maintenance = "TERMINATE" # Required for preemptible instances, or can be omitted as it defaults to TERMINATE
  }

  allow_stopping_for_update = true

  depends_on = [
    google_compute_firewall.allow_internal_ssh_icmp_frr,
    google_compute_firewall.allow_snmp
  ]
}
