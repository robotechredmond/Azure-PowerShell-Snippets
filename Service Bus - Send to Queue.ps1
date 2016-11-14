Import-Module "C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.ServiceBus.dll"

$ConnectionString="Endpoint=sb://kemsb01.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=VGqccHfK6Pt+ahCCAI/dgaeEQWRx41ZGF5xD3ARlktQ=;EntityPath=kemsbq01"
$AlertName="Test"
$AlertDescription="Blah"
$To="user@company.com"

$String = $AlertName  + ": " + $AlertDescription
#Limit string to 250 characters
$String = $String.Substring(0, [System.Math]::Min(250, $String.Length))

#Create an instance of Service Bus Queue Client and pass the connection string
$QueueClient = [Microsoft.ServiceBus.Messaging.QueueClient]::CreateFromConnectionString($ConnectionString)

#Create encoding instance
$Encoding = [system.Text.Encoding]::UTF8
#Convert alert string to UTF8
$UTF8String= $Encoding.GetBytes($String)
#Create memory stream from byte array
$MemoryStream = New-Object IO.MemoryStream -ArgumentList $UTF8String,$true

#Create instance of Service Bus message object add memory stream
$Message =  New-Object Microsoft.ServiceBus.Messaging.BrokeredMessage -ArgumentList $MemoryStream
#Define message id (random GUID)
$Message.MessageId = [Guid]::NewGuid()
#Set the recepient property of the SB message
$Message.to = $To
#If you need to set properties do it so
$Message.Properties.Add("Property1","My Property1")
$Message.Properties.Add("Property2","My Property2")

#Finally fire off the message to Service Bus
$QueueClient.Send($Message)
