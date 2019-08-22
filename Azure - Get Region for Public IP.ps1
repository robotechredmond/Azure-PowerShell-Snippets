function Convert-IPv4ToInt ($IPv4Address)
{

  try
  {
    $ipAddress=[IPAddress]::Parse($IPv4Address)

    $bytes=$ipAddress.GetAddressBytes()
    [Array]::Reverse($bytes)

    [System.BitConverter]::ToUInt32($bytes,0)
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }

}

function Convert-IntToIPv4 ($Integer) 
{

  try
  {
    $bytes=[System.BitConverter]::GetBytes($Integer)
    [Array]::Reverse($bytes)
    ([IPAddress]($bytes)).ToString()
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }

}

function Convert-CIDRToNetMask ($PrefixLength) {

  $bitString=('1' * $PrefixLength).PadRight(32,'0')
  $strBuilder=New-Object -TypeName Text.StringBuilder

  for($i=0;$i -lt 32;$i+=8){
    $8bitString=$bitString.Substring($i,8)
    [void]$strBuilder.Append("$([Convert]::ToInt32($8bitString,2)).")
  }

  $strBuilder.ToString().TrimEnd('.')

}

function Get-CIDRId ( $IpAddress, $PrefixLength )
{

    $SubnetMask = Convert-CIDRToNetMask -PrefixLength $PrefixLength
    $SubnetMaskInt = Convert-IPv4ToInt -IPv4Address $SubnetMask
    $IpInt = Convert-IPv4ToInt -IPv4Address $IpAddress
    $NetworkId = Convert-IntToIPv4 -Integer ($SubnetMaskInt -band $IpInt)
    "$NetworkId/$PrefixLength"

}

function Get-AzRegionForPublicIp ( $IpAddress, $Region = "EastUS" )
{

    $cidrIds = @()

    for ($i = 32; $i -ge 8; $i--)
    { 
    
       $cidrIds = $cidrIds + (Get-CIDRId -IpAddress $IpAddress -PrefixLength $i)

    }

    (Get-AzNetworkServiceTag -Location $Region).Values |

    Where-Object { $_.Name -like "AzureCloud.*" } | 

    Foreach-Object {

        if ((Compare-Object -ReferenceObject $cidrIds -DifferenceObject $_.Properties.AddressPrefixes -ExcludeDifferent -IncludeEqual) -ne $null)
        {
            $_.Properties.Region
        }

    } 

}

# Main entry point

Connect-AzAccount

Get-AzRegionForPublicIp -IpAddress "13.78.132.23" 