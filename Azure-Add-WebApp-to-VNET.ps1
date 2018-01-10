function AddExistingVnet{
    param(
        [string] $subscriptionId,
        [string] $resourceGroupName,
        [string] $webAppName

    )


$Vnet = Get-AzureRmVirtualNetwork | Where-Object {$_.ResourceGroupName -like "*Static*"}


IF($Vnet.Name.count -gt 1) {write-host 'Two or networks have been returned. Unable to continue ' return}

        $gatewaySubnet = $vnet.Subnets | Where-Object { $_.Name -eq "GatewaySubnet" }
        $vnetName = $vnet.Name
        $uriParts = $gatewaySubnet.IpConfigurations[0].Id.Split('/')
        $gatewayResourceGroup = $uriParts[4]
        $gatewayName = $uriParts[8]
        $gateway = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $vnet.ResourceGroupName -Name $gatewayName

        $webApp = Get-AzureRmResource -ResourceName $webAppName -ResourceType "Microsoft.Web/sites" -ApiVersion 2015-08-01 -ResourceGroupName $resourceGroupName
        $location = $webApp.Location

        Write-Host "Creating App association to VNET"
        $propertiesObject = @{
         "vnetResourceId" = "/subscriptions/$($subscriptionId)/resourceGroups/$($vnet.ResourceGroupName)/providers/Microsoft.Network/virtualNetworks/$($vnetName)"
        }

        $virtualNetwork = New-AzureRmResource -Location $location -Properties $PropertiesObject -ResourceName "$($webAppName)/$($vnet.Name)" -ResourceType "Microsoft.Web/sites/virtualNetworkConnections" -ApiVersion 2015-08-01 -ResourceGroupName $resourceGroupName -Force

    # Now finish joining by getting the VPN package and giving it to the App
    Write-Host "Retrieving VPN Package and supplying to App"
    $packageUri = Get-AzureRmVpnClientPackage -ResourceGroupName $vnet.ResourceGroupName -VirtualNetworkGatewayName $gateway.Name -ProcessorArchitecture Amd64

    $packageUri = $packageUri.ToString(); 
    $packageUri = $packageUri.Substring(1, $packageUri.Length-2);

    # Put the VPN client configuration package onto the App
    $PropertiesObject = @{
    "vnetName" = $vnet.Name; "vpnPackageUri" = $packageUri.ToString()
    }
    $date = Get-Date -format "HH:mm tt"

    New-AzureRmResource -Location $location -Properties $PropertiesObject -ResourceName "$($webAppName)/$($vnet.Name)/primary" -ResourceType "Microsoft.Web/sites/virtualNetworkConnections/gateways" -ApiVersion 2015-08-01 -ResourceGroupName $resourceGroupName -WarningAction silentlyContinue -Force  

}