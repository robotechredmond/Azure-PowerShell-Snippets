#-------------------------------------------------------------------------
# Copyright (c) Microsoft.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

# PowerShell Snippet for finding Azure Region in which a Public IP is provisioned

# Helper functions

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

# Authenticate to Azure

    Connect-AzAccount

# Get Region for Public IP Address

    Get-AzRegionForPublicIp -IpAddress "13.78.132.23" 