# Terraform GCP Test Environment
This config was initially vibe coded with Github Copilot Agent using Gemini 2.5 Pro (Preview). 
The structure is a little different than I would have done it, but it works and was a fun learning experience.

> [!WARNING]
> Applying this plan will generate cloud charges. You will be responsible for any costs incurred.

This Terraform project sets up a Google Cloud environment within a **single project**.
It creates a standard VPC network, a subnet, and deploys several Compute Engine instances with snmpd enabled for polling.
Two of these instances are configured with **FRRouting (FRR)** via a startup script,
allowing them to function as basic IP routers.
This setup is intended for testing inter-VM communication, basic routing, and SNMP polling.

It will also create the following resources in the local LibreNMS (see [librenms.tf](librenms.tf)):
 * GCP devices
 * dummy device (force added)
 * test device groups
 * test fixed location
 * test services
 * a few default alerts

### GCP Environment Details (Courtesy of Copilot Agent)
**VERY IMPORTANT NOTES ON FREE TIER AND COSTS:**

* **FRRouting on Debian:** The `frr-router-*` instances use a standard Debian image (free-tier eligible `e2-micro`) and install FRR software. This provides routing functionality without the licensing costs of proprietary virtual appliances. However, performance is limited by the `e2-micro` instance type.
* **Compute Engine Free Tier:** Google Cloud offers one `e2-micro` instance per month for free (in specific US regions, subject to change). This project creates multiple `e2-micro` instances. To stay within free tier limits and avoid costs:
	* **STOP** instances when not in use: `gcloud compute instances stop [INSTANCE_NAME] --project [PROJECT_ID] --zone [ZONE]`
	* Delete all resources when done: `terraform destroy`
	* **External IP Addresses:** Instances are configured with ephemeral external IP addresses by default for easier SSH access. These can incur small costs.
* **SNMP Firewall Rule:** The `allow-snmp` firewall rule is configured to allow UDP/161 from the public source CIDR specified in your tfvars file.**

### Prerequisites

1.  **Google Cloud Account & Project:**
* An active Google Cloud account with billing enabled.
* A Google Cloud project created. Note its Project ID.
2.  **Permissions:** Ensure the user or service account running Terraform has the necessary permissions in the project:
* `roles/compute.admin` (or more granular `roles/compute.networkAdmin`, `roles/compute.instanceAdmin`, `roles/compute.securityAdmin`)
* `roles/serviceusage.serviceUsageAdmin` (to enable APIs)
3.  **Terraform:** Install Terraform (version 1.0 or later).
4.  **Google Cloud SDK (`gcloud`):** Install and initialize `gcloud`. Authenticate with appropriate credentials:
```bash
gcloud auth application-default login
```

### Setup & Deployment

1.  **Configure Variables:**
* Create a `terraform.tfvars` file in the same directory.
* Set `project_id` with your actual project ID.
* Set `snmp_source_ip_cidr` to your current public IP address in CIDR format (e.g., `"1.2.3.4/32"`). You can get your public IP by visiting a site like `ifconfig.me`.
```terraform
# terraform.tfvars
project_id = "your-gcp-project-id"
snmp_source_ip_cidr = "your_public_ip/32"
# region     = "us-central1" # Optional: override defaults if needed
# zone       = "us-central1-a" # Optional: override defaults if needed
# snmp_community_string = "your_custom_community_string" # Optional: override default random string
```
2.  **Initialize Terraform:**
```bash
terraform init
```
3.  **Review Plan:**
```bash
terraform plan
```
Carefully review the resources that will be created.
4.  **Apply Configuration:**
```bash
terraform apply
```
Type `yes` when prompted. This will take a few minutes to provision all resources, including running the startup script on the FRR instances.

### Testing Connectivity & FRRouting

1.  **SSH Access:** Use the SSH commands provided in the `instance_details` output from `terraform apply` (or `terraform output instance_details`).
	Example:
```bash
gcloud compute ssh --project [PROJECT_ID] --zone [ZONE] [INSTANCE_NAME]
```
2.  **Basic Connectivity:** Inside an instance, you can ping another instance's internal IP address (also available in the `instance_details` output) to test connectivity.
```bash
ping [INTERNAL_IP_OF_ANOTHER_INSTANCE_ON_SUBNET]
```
3.  **FRRouting Configuration:**
* SSH into one of the `frr-router-*` instances.
* Enter the FRR configuration shell using `vtysh` (similar to Cisco/Juniper CLI):
```bash
sudo vtysh
```
* Inside `vtysh`, you can configure routing protocols (e.g., BGP, OSPF), interfaces, etc.
  Example basic commands in `vtysh`:
```
conf t
router bgp 65001
neighbor 10.0.1.X remote-as 65002 ! (where 10.0.1.X is other frr-router's IP)
exit
interface eth0
ip address 10.0.1.Y/24 ! (ensure this matches GCP assigned IP or add secondary)
exit
end
write memory ! (to save config)
```
* The startup script enables `bgpd` and `ospfd` by default in `/etc/frr/daemons`. You can modify this file and restart FRR (`sudo systemctl restart frr`) if you need other daemons.
* IP forwarding is also enabled by the startup script.

4.  **SNMP Polling:**
*   SNMPd is automatically installed and configured on all instances.
*   The default community string is a randomly generated 16-character string (`5581eb63764a093c`). You can change this by setting the `snmp_community_string` variable in your `terraform.tfvars` file.
*   You can poll the instances using their external IP addresses on UDP port 161.

* **SNMP Firewall Rule:** The `allow-snmp` firewall rule is configured to allow UDP/161 from the IP address specified in the `snmp_source_ip_cidr` variable (e.g. your public IP). **If your public IP changes, you will need to update this variable in `terraform.tfvars` and re-apply the configuration.**

### Cleanup

To remove all resources created by this project and avoid ongoing charges:
```bash
terraform destroy
```
Type `yes` when prompted.
