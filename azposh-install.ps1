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

# Install Az PowerShell modules and dependencies

# Set TLS to 1.2 - PowerShell Gallery requires TLS 1.2 for successful connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install NuGet package manager - dependency for Install-Module
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Trust the PowerShell Gallery Repository
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Install Az PowerShell Modules
Install-Module -Name Az -MinimumVersion 2.0.0 -Scope AllUsers -Repository PSGallery -Force
Install-Module -Name AzTable -MinimumVersion 2.0.0 -Scope AllUsers -Repository PSGallery -Force
