# To view all subscriptions for your account
Login-AzureRmAccount
       
# To view all subscriptions for your account
Get-AzureRmSubscription
              
# To select a default subscription for your current session
Get-AzureRmSubscription –SubscriptionID “SUBID” | Select-AzureRmSubscription
Get-AzureRmVM -Name "VMname" -ResourceGroupName 'RGName' | Update-AzureRmVM 