Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName "Contoso Sports"

$rgName="sqla2-s2d-rg"

$lbName = "sqla2-ilb"

$lb = Get-AzureRmLoadBalancer -Name $lbName -ResourceGroupName $rgName

for ($i = 20000; $i -lt 20101; $i++)
{ 
    $lb | Add-AzureRmLoadBalancerRuleConfig -Name "dtc-dyn${i}-rule" -FrontendIpConfigurationId $lb.FrontendIpConfigurations[0].Id -ProbeId $lb.Probes[1].Id -EnableFloatingIP -FrontendPort $i -BackendPort $i -Protocol Tcp -BackendAddressPoolId $lb.BackendAddressPools[0].Id
}

$lb | Set-AzureRmLoadBalancer

