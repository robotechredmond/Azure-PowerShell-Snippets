# Sign-in to Azure via Azure Resource Manager

    Login-AzureRmAccount

# Select Azure Subscription

    $subscriptionId = 
        ( Get-AzureRmSubscription |
            Out-GridView `
              -Title "Select an Azure Subscription ..." `
              -PassThru
        ).SubscriptionId

    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId

# If needed, register ARM core resource providers

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Compute

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Storage

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Network

    Get-AzureRmResourceProvider | 
        Select-Object `
        -Property ProviderNamespace `
        -ExpandProperty ResourceTypes

# Select Azure Resource Group in which to provision the Load Balancer

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

# Reserve Public IP Addresses

    $pipCount = 5

    $pips = @()

    $pipName = 'lbpip'

    for ($i = 1; $i -le $pipCount; $i++)
    { 
              
        $pips += 
            New-AzureRmPublicIpAddress `
                -Name "${pipName}${i}" `
                -ResourceGroupName $rgName `
                -Location $location `
                -AllocationMethod Static

    }

# Build LB Front-End IP Configurations

    $feips = @()

    $feipName = 'lbfeip'

    for ($i = 1; $i -le $pipCount; $i++)
    { 
              
        $feips += 
            New-AzureRmLoadBalancerFrontendIpConfig `
                -Name "${feipName}${i}" `
                -PublicIpAddress $pips[$i-1]

    }

# Build LB Back-End Pool

    $beipName = 'lbbeip'

    $beip = 
        New-AzureRmLoadBalancerBackendAddressPoolConfig `
            -Name $beipName

# Build LB Probes and Rules

    $probeName = "lbprobe"

    $probes = @()

    $ruleName = "lbrule"

    $rules = @()

    $fePort = 80

    $bePortStart = 80

    for ($i = 1; $i -le $pipCount; $i++)
    { 
        $bePort = $bePortStart + $i - 1
              
        $probes += 
            New-AzureRmLoadBalancerProbeConfig `
                -Name "${probeName}${i}" `
                -RequestPath "/" `
                -Protocol Http `
                -Port $bePort `
                -IntervalInSeconds 15 `
                -ProbeCount 2                

    }

    for ($i = 1; $i -le $pipCount; $i++)
    { 
        $bePort = $bePortStart + $i - 1

        $rules += 
            New-AzureRmLoadBalancerRuleConfig `
                -Name "${ruleName}${i}" `
                -FrontendIpConfigurationId $feips[$i-1].Id `
                -BackendAddressPoolId $beip.Id `
                -ProbeId $probes[$i-1].Id `
                -Protocol Tcp `
                -FrontendPort 80 `
                -BackendPort $bePort `
                -LoadDistribution Default

    }

# Provision Load Balancer

    $lbName = 'lb1'
    
    $lb = 
        New-AzureRmLoadBalancer `
            -Name $lbName `
            -ResourceGroupName $rgName `
            -Location $location `
            -FrontendIpConfiguration $feips `
            -BackendAddressPool $beip `
            -Probe $probes `
            -LoadBalancingRule $rules 
