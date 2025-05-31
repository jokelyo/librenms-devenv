#!/bin/bash
# Update package list and install prerequisites
sudo apt-get update -y
sudo apt-get install -y snmpd snmp inetutils-ping tcpdump curl

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

echo "SNMPD installation and basic configuration complete."
