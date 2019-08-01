
$uri = "https://management.azure.com/subscriptions/${subId}?api-version=2015-01-01"

try 
{
    $response = Invoke-RestMethod -Method Get -Uri $uri 
}
catch 
{
    $header = $_.Exception.Response.Headers["WWW-Authenticate"]
}

$tenantId = $header.Split("/`"")[4]