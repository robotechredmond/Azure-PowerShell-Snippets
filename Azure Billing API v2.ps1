# Set date range for exported usage data

$reportedStartTime = "2015-05-01"

$reportedEndTime = "2015-06-28"

# Authenticate to Azure

Add-AzureAccount

# Switch to Azure Resource Manager mode

Switch-AzureMode -Name AzureResourceManager

# Select an Azure Subscription for which to report usage data

$subscriptionId = 
    (Get-AzureSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureSubscription -SubscriptionId $subscriptionId

# Set path to exported CSV file

$filename = ".\usageData-${subscriptionId}-${reportedStartTime}-${reportedEndTime}.csv"

# Set usage parameters

$granularity = "Daily" # Can be Hourly or Daily

$showDetails = $true

# Export Usage to CSV

$appendFile = $false

$continuationToken = ""

Do { 

    $usageData = Get-UsageAggregates `
        -ReportedStartTime $reportedStartTime `
        -ReportedEndTime $reportedEndTime `
        -AggregationGranularity $granularity `
        -ShowDetails:$showDetails `
        -ContinuationToken $continuationToken

    $usageData.UsageAggregations.Properties | 
        Select-Object `
            UsageStartTime, `
            UsageEndTime, `
            @{n='SubscriptionId';e={$subscriptionId}}, `
            MeterCategory, `
            MeterId, `
            MeterName, `
            MeterSubCategory, `
            MeterRegion, `
            Unit, `
            Quantity, `
            @{n='Project';e={$_.InfoFields.Project}}, `
            InstanceData | 
        Export-Csv `
            -Append:$appendFile `
            -NoTypeInformation:$true `
            -Path $filename

    if ($usageData.NextLink) {

        $continuationToken = `
            [System.Web.HttpUtility]::`
            UrlDecode($usageData.NextLink.Split("=")[-1])

    } else {

        $continuationToken = ""

    }

    $appendFile = $true

} until (!$continuationToken)

