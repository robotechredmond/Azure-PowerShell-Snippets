Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName "Contoso Sports"

$VNetName  = "vnet01"
$Sub1Name = "web-subnet"
$Sub2Name = "app-subnet"
$GWSubName = "GatewaySubnet"
$VNetPrefix1 = "192.168.0.0/16"
$VNetPrefix2 = "10.254.0.0/16"
$Sub1Prefix = "192.168.1.0/24"
$Sub2Prefix = "10.254.1.0/24"
$GWSubPrefix = "192.168.200.0/26"
$VPNClientAddressPool = "172.16.201.0/24"
$RG = "kemvnet01-rg"
$Location = "southeastasia"
$DNS = "8.8.8.8"
$GWName = "GW"
$GWIPName = "GWIP"
$GWIPconfName = "gwipconf"
$P2SRootCertName = "point-to-site-root-cert"

New-AzureRmResourceGroup -Name $RG -Location $Location

$Sub1 = New-AzureRmVirtualNetworkSubnetConfig -Name $Sub1Name -AddressPrefix $Sub1Prefix
$Sub2 = New-AzureRmVirtualNetworkSubnetConfig -Name $Sub2Name -AddressPrefix $Sub2Prefix
$GWSub = New-AzureRmVirtualNetworkSubnetConfig -Name $GWSubName -AddressPrefix $GWSubPrefix

New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $RG -Location $Location -AddressPrefix $VNetPrefix1,$VNetPrefix2 -Subnet $Sub1, $Sub2, $GWSub -DnsServer $DNS

$pip = New-AzureRmPublicIpAddress -Name $GWIPName -ResourceGroupName $RG -Location $Location -AllocationMethod Dynamic
$ipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName -Subnet $subnet -PublicIpAddress $pip

$P2SRootCertB64 = "MIIDETCCAf2gAwIBAgIQXnZohKv6O4dAUrseQ3Eg5zAJBgUrDgMCHQUAMB4xHDAaBgNVBAMTE1Jvb3RDZXJ0aWZpY2F0ZU5hbWUwHhcNMTYwNjIxMTIxNDU0WhcNMzkxMjMxMjM1OTU5WjAeMRwwGgYDVQQDExNSb290Q2VydGlmaWNhdGVOYW1lMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2+pOxzw9yw44wAoYocHZ7TNMq/obJwj8vMDOzn1k7gww1uYCU3x5b2UoR5DaIBtus4aWESfgkmOc3MqcVlqBccB9m69IyVQCwhXNPb0w2j++Q3WV+cz+OtEjsR/jEbCUZy5JSVbrKRZEImecaR6w8gZedHxWdcybBuGgMEMnUEHW57y9by5jcxW8m6Gqq+I4kvSZxA4p0lhHsjvnDEeNfdHPmN3Rzg+te3ebRcKJRtJeDOG34YiMgMor1iUgI1sCfCWzsh46NQN2xvZfNGbk+smh+L10w2c5w6jI0NXDeYizjkQnnpqEcUXws4GIu+ZO2O09ZzipnuqHfqSu13KmlwIDAQABo1MwUTBPBgNVHQEESDBGgBD+mhAyjBQj12DogCQ8ocqBoSAwHjEcMBoGA1UEAxMTUm9vdENlcnRpZmljYXRlTmFtZYIQXnZohKv6O4dAUrseQ3Eg5zAJBgUrDgMCHQUAA4IBAQCO0++0klydOFYmQ4B7LsxVGmowW9L1Xdx/9UksRAhNwc6X5g4qppT71FLDOEzwf5Op5WKiFdEVPHjuq6GR0+d0EhdGSRcbIBQj7VA64ojGQwelrfcuskNSnUzqxTPKrB8BHBFHfKqBs1/hA78ngSmmfqJ/vQQQ/TtTfDJbsvXi8j5LC493e/vMxIxecQLITs0GpFOSIznr3a2hJNI+v1eBv496si7b79yJjtiPaKQjccxu+GyxfRZpa3z+QM3sH++Qwvt26m4Lxy4dhP/8OyrI1v9Oa0Lqgz5nLd4qwPDoHp/Js2uxbETbufnCIFRarqinxbkw21m4rcBpreBFPf6c"
$P2SRootCert = New-AzureRmVpnClientRootCertificate -Name $P2SRootCertName -PublicCertData $P2SRootCertB64

New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $RG -Location $Location -IpConfigurations $ipconf -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku Standard -VpnClientAddressPool $VPNClientAddressPool -VpnClientRootCertificates $P2SRootCert -Debug