# Create custom Azure RBAC role that can view effective Routes

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

# Create a new custom RBAC role based on the Reader role
$role = Get-AzureRmRoleDefinition "Reader"
$role.Id = $null

# Define name and description for new role
$role.Name = "Route Reader"
$role.Description = "Can read all resources and view effective routes"

# Add additional permission actions beyond what the base Reader role provides
$role.Actions.Add("Microsoft.Network/networkInterfaces/effectiveRouteTable/action")

# Add Azure subscription ID as a valid assignable scope
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/00000000-0000-0000-0000-000000000000")

# Save new custom RBAC role
New-AzureRmRoleDefinition -Role $role