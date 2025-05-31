#!/bin/bash
# Update package list and install prerequisites
sudo apt-get update -y
sudo apt-get install -y curl gnupg2 snmpd snmp inetutils-ping tcpdump

# Configure SNMPD
# Ensure snmpd listens on all IPv4 and IPv6 interfaces
# Remove existing agentaddress lines (if any) to avoid duplicates
sudo sed -i '/^agentaddress/d' /etc/snmp/snmpd.conf
# Add the desired agentaddress line
echo "agentaddress udp:161,udp6:161" | sudo tee -a /etc/snmp/snmpd.conf

# Comment out any existing rocommunity and rocommunity6 lines to avoid conflicts
sudo sed -i -E 's/^(rocommunity[[:space:]].*)/#\1/' /etc/snmp/snmpd.conf
sudo sed -i -E 's/^(rocommunity6[[:space:]].*)/#\1/' /etc/snmp/snmpd.conf

# Add our desired rocommunity lines for the specified community, default source, and full OID tree access
echo "rocommunity ${snmp_community} default .1" | sudo tee -a /etc/snmp/snmpd.conf
echo "rocommunity6 ${snmp_community} default .1" | sudo tee -a /etc/snmp/snmpd.conf

sudo systemctl enable snmpd
sudo systemctl restart snmpd

# Add FRRouting repository and GPG key
curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
FRRVER="frr-stable" # Or specify a version like frr-8.2
echo "deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER" | sudo tee -a /etc/apt/sources.list.d/frr.list

# Update package list again and install FRR
sudo apt-get update -y
sudo apt-get install -y frr frr-pythontools

# Enable daemons you want to use (e.g., zebra, bgpd, ospfd) in /etc/frr/daemons
# For example, to enable BGP and OSPF:
sudo sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
sudo sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
# Add other daemons as needed (e.g., isisd, pimd, ldpd, ripd, ripngd, ospf6d)

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

# Start FRR service
sudo systemctl enable frr
sudo systemctl restart frr

echo "FRRouting installation and basic configuration complete."
