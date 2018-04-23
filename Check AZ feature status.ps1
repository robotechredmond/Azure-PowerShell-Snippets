iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
choco install armclient 

armclient login
armclient POST /subscriptions/YOUR SUB ID HERE/providers/Microsoft.Compute/register?api-version=2017-03-01 
armclient GET /subscriptions/YOUR SUB ID HERE/providers/Microsoft.Compute?api-version=2017-03-01
