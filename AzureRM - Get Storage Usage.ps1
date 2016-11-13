[System.Reflection.Assembly]::LoadWithPartialName("System.Web")

# Sign-in to Azure

Login-AzureRmAccount

# Select an Azure Subscription for which to report usage data

$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Get amount of in-use storage across all storage accounts

$reportedStartTime = "2016-11-11"

$reportedEndTime = "2016-11-12"

# Set path to exported CSV file

$filename = ".\usageData-${subscriptionId}-${reportedStartTime}-${reportedEndTime}.csv"

# Set usage parameters

$granularity = "Daily" # Can be Hourly or Daily

$showDetails = $true

$continuationToken = ""

$appendFile = $false

# Export storage usage to CSV

$usageData = Get-UsageAggregates `
    -ReportedStartTime $reportedStartTime `
    -ReportedEndTime $reportedEndTime `
    -AggregationGranularity $granularity `
    -ShowDetails:$showDetails

Do { 

    $usageData.UsageAggregations.Properties | 
        Where-Object `
            MeterCategory -EQ "Storage" |
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
            [System.Web.HttpUtility]::UrlDecode($usageData.NextLink.Split("=")[-1])

        $usageData = Get-UsageAggregates `
            -ReportedStartTime $reportedStartTime `
            -ReportedEndTime $reportedEndTime `
            -AggregationGranularity $granularity `
            -ShowDetails:$showDetails `
            -ContinuationToken $continuationToken

    } else {

        $continuationToken = ""

    }

    $appendFile = $true

} until (!$continuationToken)

