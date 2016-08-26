Add-AzureEnvironment `
        -Name "AzureGovernmentCloud" `
        -PublishSettingsFileUrl "https://manage.windowsazure.us/publishsettings/index?client=xplat" `
        -ServiceEndpoint "https://management.core.usgovcloudapi.net" `
        -ActiveDirectoryEndpoint "https://login.windows.net/" `
        -ActiveDirectoryServiceEndpointResourceId "https://management.core.usgovcloudapi.net/" `
        -GalleryEndpoint "https://gallery.usgovcloudapi.net" `
        -ManagementPortalUrl "https://manage.windowsazure.us" `
        -ResourceManagerEndpoint "https://management.usgovcloudapi.net" `
        -StorageEndpoint "core.usgovcloudapi.net" 

Add-AzureAccount -Environment "AzureGovernmentCloud"

Get-AzureLocation