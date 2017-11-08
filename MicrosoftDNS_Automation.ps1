# Create new zone

$zoneName = "int"

Add-DnsServerPrimaryZone -Name $zoneName -DynamicUpdate NonsecureAndSecure -ZoneFile "${zoneName}.dns"

# Get DNS resource records

Get-DnsServerResourceRecord -ZoneName $zoneName

# Remove all DNS resource records for a particular subdomain

$subdomainName = "webapp01"

Get-DnsServerResourceRecord -ZoneName $zoneName |
    Where-Object HostName -like "*.${subdomainName}" |
    Remove-DnsServerResourceRecord -ZoneName $zoneName -Force

(Get-WMIObject MicrosoftDNS_Zone -Namespace "root\MicrosoftDNS" -Filter "ContainerName='$zoneName'").ReloadZone()