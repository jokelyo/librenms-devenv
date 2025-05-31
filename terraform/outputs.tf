# FILENAME: outputs.tf

output "project_id" {
  description = "The ID of the project where resources are deployed."
  value       = var.project_id
}

output "vpc_network_name" {
  description = "Name of the VPC network created."
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_self_link" {
  description = "Self-link of the VPC network."
  value       = google_compute_network.vpc_network.self_link
}

output "subnet_name" {
  description = "Name of the subnet created."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "Self-link of the subnet."
  value       = google_compute_subnetwork.subnet.self_link
}

output "instance_details" {
  description = "Details of the created instances."
  value = {
    for k, inst in google_compute_instance.lab_instances : k => {
      name          = inst.name
      zone          = inst.zone
      machine_type  = inst.machine_type
      internal_ip   = inst.network_interface[0].network_ip
      external_ip   = length(inst.network_interface[0].access_config) > 0 ? inst.network_interface[0].access_config[0].nat_ip : "N/A (No external IP)"
      ssh_command   = "gcloud compute ssh --project ${var.project_id} --zone ${inst.zone} ${inst.name}"
      is_frr_router = contains(inst.tags, "frr-router")
    }
  }
  sensitive = false
}

output "frr_router_vtysh_tip" {
  description = "Tip: To configure FRR on the router instances, SSH into them and use 'sudo vtysh'."
  value       = "SSH into an frr-router-* instance, then run 'sudo vtysh' to enter the FRR configuration shell (similar to Cisco/Juniper CLI)."
}

