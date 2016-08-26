# Sign-in with Azure account credentials

    Login-AzureRmAccount

# Select Azure Subscription

    $subscriptionId = 
        (Get-AzureRmSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId


    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId

# Determine owner for each resource from Audit Logs

    $resourceOwners = @{}

    Get-AzureRmResource | % {

        $resourceId = $_.ResourceId

        $currentTime = Get-Date

        $endTime = $currentTime

        $startTime = $endTime.AddDays(-15)

        do {

            $resourceOwner = (Get-AzureRmLog -StartTime $startTime -EndTime $endTime -ResourceId $resourceId | ? Caller -Like "*@*" | Select-Object -Property Caller -First 1 -Wait).Caller

            $endTime = $endTime.AddDays(-15)

            $startTime = $startTime.AddDays(-15)

        }

        until ( ( $resourceOwner ) -or ( $startTime -lt $currentTime.AddDays(-90) ) )

        if ( $resourceOwner ) {

            $resourceOwners.Add($resourceId, $resourceOwner)

        }

    }

    $resourceOwners | Format-Table -AutoSize


# Alternate approach - pulling all audit logs entries once (faster, but may list resources that are no longer deployed)

    $auditLog = $null

    $currentTime = Get-Date

    $endTime = $currentTime

    $startTime = $endTime.AddDays(-15)

    do {

        $auditLog += Get-AzureRmLog -StartTime $startTime -EndTime $endTime -DetailedOutput

        $endTime = $endTime.AddDays(-15)

        $startTime = $startTime.AddDays(-15)

    }

    until ( $startTime -lt $currentTime.AddDays(-90) )

    $auditLog | 
        ? Caller -like "*@*" | 
        ? ResourceGroupName -notlike "" | 
        Sort-Object -Property ResourceGroupName, ResourceId | 
        Select-Object -Property ResourceGroupName, Caller, ResourceId -Unique 


    Get-AzureRmResource | ? Tags -like $null