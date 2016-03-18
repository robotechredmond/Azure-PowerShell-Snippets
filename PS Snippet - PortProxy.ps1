# Reset Port Proxy configuration

netsh interface portproxy reset

# Setup Port Proxy on ASR PS Proxy in on-premises network

netsh interface portproxy add v4tov4 listenport=9443 listenaddress=<local_ps_ip_address> connectport=9443 connectaddress=<public_ps_ip_address>

# Setup Port Proxy on ASR CS Proxy in Azure VNET

netsh interface portproxy add v4tov4 listenport=443 listenaddress=<local_cs_ip_address> connectport=443 connectaddress=<public_cs_ip_address>

# Display current Port Proxy configuration

netsh interface portproxy show all

# Test Port Proxy configuration from within each ASR Proxy VM

Test-NetConnection -ComputerName <local_cs_or_ps_ip_address> -Port <listenport>

Test-NetConnection -ComputerName 192.168.249.167 -Port 443