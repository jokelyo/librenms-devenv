# FILENAME: variables.tf

variable "project_id" {
  description = "The ID of the Google Cloud project where all resources will be deployed."
  type        = string
}

variable "region" {
  description = "The Google Cloud region to deploy resources in."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The Google Cloud zone for deploying instances."
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Name for the VPC network."
  type        = string
  default     = "tf-lab-network"
}

variable "subnet_name" {
  description = "Name for the subnet in the VPC."
  type        = string
  default     = "tf-lab-subnet"
}

variable "subnet_ip_cidr_range" {
  description = "IP CIDR range for the subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_machine_type" {
  description = "Machine type for the test instances. e2-micro is in the free tier."
  type        = string
  default     = "e2-micro"
}

variable "instance_image" {
  description = "Default image for test instances. Using a Debian image, free tier eligible."
  # Fetches the latest stable Debian 11 image.
  type    = string
  default = "projects/debian-cloud/global/images/family/debian-11"
}

variable "snmp_community_string" {
  description = "SNMP community string for read-only access."
  type        = string
  default     = "5581eb63764a093c"
}

variable "snmp_source_ip_cidr" {
  description = "The IP address (CIDR format) from which SNMP (UDP/161) access is allowed to the instances. Example: \"your_ip/32\"."
  type        = string
  # No default, to ensure it's explicitly set in terraform.tfvars
}

variable "librenms_host" {
  description = "The hostname or IP address of the LibreNMS server."
  type        = string
  default     = "http://localhost:8000/" # Default to localhost, can be overridden
}

variable "librenms_token" {
  description = "The API token for LibreNMS. Can also be set via the LIBRENMS_TOKEN environment variable."
  type        = string
}
