# Sample Azure Function 
# Receive queue message, call API, send API response to Logic App for processing

$in = Get-Content $triggerInput
Write-Output "Function processed queue message '$in'"

$apiUri = "uri-for-api-to-call"

try
{
    $apiResponse = Invoke-RestMethod -Uri $apiUri -Method Get 
}
catch 
{
    Write-Output "${in}: Error calling API"
    Return $false
}

if ($apiResponse) {
    $logicAppUri = "azure-logic-app-webhook-uri"
    $jsonBody = ConvertTo-Json($apiResponse)
    $contentType = "application/json;charset=utf-8"
    try
    {
        $logicAppResponse = Invoke-RestMethod -Uri $logicAppUri -Method Post -ContentType $contentType -Body $jsonBody
        Return $true
    }
    catch
    {
        Write-Output "${in}: Error calling Logic App"
        Return $false
    }
}

