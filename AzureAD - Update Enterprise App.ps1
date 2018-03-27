# Install Azure AD v2 PowerShell Module

Install-Module -Name AzureAD

# Authenticate to Azure AD Tenant

$envName = "AzureCloud" # Set to "AzureUSGovernment" if using GovCloud

$tenantId = "00000000-0000-0000-0000-00000000" # Set Azure AD Tenant ID 

Connect-AzureAD -AzureEnvironmentName $envName -TenantId $tenantId

# Select Azure AD App

$appDisplayName = 
    (Get-AzureAdApplication | 
        Sort-Object -Property DisplayName | 
        Out-GridView -Title "Select an App" -PassThru).DisplayName

# Set Reply Url to Add to list of ReplyUrls

$newReplyUrl = "https://localhost:40192" # Change to match new ReplyUrl needed

# Get object for Enterprise App

$app = Get-AzureADApplication -Filter "DisplayName eq '$appDisplayName'"

# Get list of current ReplyUrls

$replyUrls = $app.ReplyUrls

# Add Reply URL if not already in the list 

if ($replyUrls -NotContains $newReplyUrl) {
    $replyUrls.Add($newReplyUrl)
    Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $replyUrls
}
