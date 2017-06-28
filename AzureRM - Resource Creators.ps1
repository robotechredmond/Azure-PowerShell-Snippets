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

 # Pull Activity Log History

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

# Filter Activity Log for "Created" events

    $auditLog | 
        ? Caller -like "*@*" | 
        ? ResourceGroupName -notlike "" | 
        ? { $_.Properties.Content.Value -Contains "Created" } |
        Sort-Object -Property ResourceGroupName, ResourceId | 
        Select-Object -Property ResourceGroupName, Caller, ResourceId -Unique | 
        Format-Table -Wrap

