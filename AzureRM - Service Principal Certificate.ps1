# Define certificate start and end dates

$currentDate = Get-Date

$endDate = $currentDate.AddYears(1)

$notAfter = $endDate.AddYears(1)

# Generate new self-signed certificate from "Run as Administrator" PowerShell session

$certName = Read-Host "Enter FQDN Subject Name for certificate:"

$certStore = "Cert:\LocalMachine\My"

$certThumbprint = (New-SelfSignedCertificate -DnsName "$certName" -CertStoreLocation $CertStore -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint

# Export password-protected pfx file

$pfxPassword = Read-Host -Prompt "Enter password to protect exported certificate:" -AsSecureString

$pfxFilepath = Read-Host -Prompt "Enter full path to export certificate (ex C:\folder\filename.pfx)" 

Export-PfxCertificate -Cert "$($certStore)\$($certThumbprint)" -FilePath $pfxFilepath -Password $pfxPassword

# Login to Azure Account

Login-AzureRmAccount

# Create Key Credential Object

$cert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate -ArgumentList @($pfxFilepath, $pfxPassword)

$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

$keyId = [guid]::NewGuid()

Import-Module AzureRM.Resources

$keyCredential = New-Object  Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADKeyCredential

$keyCredential.StartDate = $currentDate

$keyCredential.EndDate= $endDate

$keyCredential.KeyId = $keyId

$keyCredential.Type = "AsymmetricX509Cert"

$keyCredential.Usage = "Verify"

$keyCredential.Value = $keyValue

# Create Azure AD Application

$adAppName = Read-Host "Enter unique Azure AD App name"

$adAppHomePage = Read-Host "Enter unique Azure AD App Homepage URI"

$adAppIdentifierUri = Read-Host "Enter unique Azure AD App Identifier URI"

$adApp = New-AzureRmADApplication -DisplayName $adAppName -HomePage $adAppHomePage -IdentifierUris $adAppIdentifierUri -KeyCredentials $keyCredential

Write-Output "New Azure AD App Id: $($adApp.ApplicationId)"

# Create Azure AD Service Principal

New-AzureRmADServicePrincipal -ApplicationId $adApp.ApplicationId

# Add the Service Principal as Owner to selected subscription

$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

New-AzureRmRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $adApp.ApplicationId

# Test authenticating as Service Principal to Azure

$tenantId = (Get-AzureRmContext).Tenant.TenantId

Login-AzureRmAccount -ServicePrincipal -TenantId $tenantId -ApplicationId $adApp.ApplicationId -CertificateThumbprint $certThumbprint

# Create Azure Automation Assets

$automationAccount = 
     Get-AzureRmAutomationAccount |
     Out-GridView `
        -Title "Select an existing Azure Automation account ..." `
        -PassThru

New-AzureRmAutomationVariable -Name "AutomationAppId" -Value $adApp.ApplicationId -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $automationAccount.ResourceGroupName -Encrypted:$false

New-AzureRmAutomationVariable -Name "AutomationTenantId" -Value $tenantId -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $automationAccount.ResourceGroupName -Encrypted:$false

New-AzureRmAutomationCertificate -Name "AutomationCertificate" -Path $pfxFilepath -Password $pfxPassword -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $automationAccount.ResourceGroupName 

New-AzureRmAutomationVariable -Name "AutomationSubscriptionId" -Value $subscriptionId -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $automationAccount.ResourceGroupName -Encrypted:$false

# ----- Code to add to Azure Automation runbook ----

    # Get Azure Automation Assets
	
	$adAppId = Get-AutomationVariable -Name "AutomationAppId"
		
	Write-Output "Azure AD Application Id: $($adAppId)"

	$tenantId = Get-AutomationVariable -Name "AutomationTenantId"
		
	Write-Output "Azure AD Tenant Id: $($tenantId)"
	
	$subscriptionId = Get-AutomationVariable -Name "AutomationSubscriptionId"
		
	Write-Output "Azure Subscription Id: $($subscriptionId)"
	
	$cert = Get-AutomationCertificate -Name "AutomationCertificate"
		
	$certThumbprint = ($cert.Thumbprint).ToString()
	
	Write-Output "Service Principal Certificate Thumbprint: $($certThumbprint)"
	
	# Install Service Principal Certificate
	
	Write-Output "Install Service Principal certificate..."
	
	if ((Test-Path "Cert:\CurrentUser\My\$($certThumbprint)") -eq $false) {
		
		InlineScript {		    
		
		    $certStore = new-object System.Security.Cryptography.X509Certificates.X509Store("My", "CurrentUser") 
		
		    $certStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
		
		    $certStore.Add($Using:cert) 
		
		    $certStore.Close() 
		
		}
	
	}

	# Login to Azure
	 
	Write-Output "Login to Azure as Service Principal..."
	 
	Login-AzureRmAccount -ServicePrincipal -TenantId $tenantId -ApplicationId $adAppId -CertificateThumbprint $certThumbprint

	# Select Azure Subscription
	
	Write-Output "Select Azure subscription..."
	 
	Select-AzureRmSubscription -SubscriptionId $subscriptionId -TenantId $tenantId
  