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

# Register NetworkWatcher Feature

    Register-AzureRmProviderFeature -FeatureName AllowNetworkWatcher -ProviderNamespace Microsoft.Network

# Wait until NetworkWatcher Feature is Registered

do
{
    Start-Sleep -Seconds 60
}
until ( (Get-AzureRmProviderFeature -FeatureName AllowNetworkWatcher -ProviderNamespace  Microsoft.Network).RegistrationState -eq "Registered" )

