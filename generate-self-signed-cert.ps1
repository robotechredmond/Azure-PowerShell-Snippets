$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "\*.contoso.com","\*.scm.contoso.com"

$certThumbprint = "cert:\localMachine\my\" +$certificate.Thumbprint
$password = ConvertTo-SecureString -String "CHANGETHISPASSWORD" -Force -AsPlainText

$fileName = "exportedcert.pfx" 
Export-PfxCertificate -cert $certThumbprint -FilePath $fileName -Password $password