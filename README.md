# README

## Overview

This script is designed to interact with Microsoft Graph API to manage Windows Autopilot Deployment Profiles (WADP). It includes functions to authenticate and retrieve access tokens, perform CRUD (Create, Read, Update, Delete) operations on WADP profiles, and manage assignments and configurations.

## Prerequisites

Before running the script, ensure you have the following prerequisites:

1. **PowerShell 5.1 or higher**: Make sure you have at least PowerShell 5.1 installed.
2. **Azure PowerShell Module**: Install the Azure PowerShell module using `Install-Module -Name Az -AllowClobber -Force`.
3. **MSAL.PS Module**: Install the MSAL.PS module using `Install-Module MSAL.PS -Scope CurrentUser`.

## Setup

1. **Install Modules**:
   ```powershell
   Install-Module MSAL.PS -Scope CurrentUser
   Import-Module MSAL.PS
   ```

2. **Authentication**: The script uses device code flow to authenticate and retrieve access tokens.

## Functions

### 1. `Get-GraphAPIAccessToken`

This function performs device code flow to get an access token for Microsoft Graph API.

**Parameters**:
- `tenantId`: Your Azure AD tenant ID.
- `clientId`: The client ID of your Azure AD application.

### 2. `Get-graphdata`

This function retrieves data from Microsoft Graph API using a GET request. It handles pagination and retries.

**Parameters**:
- `graphToken`: The access token for Microsoft Graph API.
- `url`: The API endpoint URL.

### 3. `Patch-GraphData`

This function updates data using a PATCH request to Microsoft Graph API. It handles retries for rate limiting and service unavailability.

**Parameters**:
- `graphToken`: The access token for Microsoft Graph API.
- `url`: The API endpoint URL.
- `body`: The JSON body for the PATCH request.

### 4. `Post-GraphData`

This function posts new data using a POST request to Microsoft Graph API. It handles retries for rate limiting and service unavailability.

**Parameters**:
- `graphToken`: The access token for Microsoft Graph API.
- `url`: The API endpoint URL.
- `body`: The JSON body for the POST request.

### 5. `Delete-GraphData`

This function deletes data using a DELETE request to Microsoft Graph API. It handles retries for rate limiting and service unavailability.

**Parameters**:
- `graphToken`: The access token for Microsoft Graph API.
- `url`: The API endpoint URL.

## Usage

### 1. Authenticate and Get Access Token

```powershell
$session = Connect-AzAccount
$tenantId = $session.context.Tenant.id
$clientId = "<Your-Client-Id>"
$graphToken = Get-GraphAPIAccessToken -tenantId $tenantId -ClientId $clientId
```

### 2. Retrieve WADP Profiles & Settings

```powershell
$wadpprofiles = Get-graphdata -graphToken $graphToken -url "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$select=id,name,description,platforms,lastModifiedDateTime,technologies,settingCount,roleScopeTagIds,isAssigned,templateReference,priorityMetaData%20&`$top=100%20&`$filter=(technologies%20has%20%27enrollment%27)%20and%20(platforms%20eq%20%27windows10%27)%20and%20(TemplateReference/templateId%20eq%20%2780d33118-b7b4-40d8-b15f-81be745e053f_1%27)%20and%20(Templatereference/templateFamily%20eq%20%27enrollmentConfiguration%27)%20"
```

### 3. Create WADP Profiles & Assignments

```powershell
$justInTimeSecurityGroup = "<Your-Security-Group-Id>"
$UserSecurityGroup = "<Your-User-Security-Group-Id>"

$body = @"
{
    "id": "00000000-0000-0000-0000-000000000000",
    "name": "WADP_DEMO_GRAPH",
    ...
}
"@

$response = Post-GraphData -graphToken $graphToken -body $body -url "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies"

$body = @"
{
    "justInTimeAssignments": {
        "targetType": "entraSecurityGroup",
        "target": [
            "$($justInTimeSecurityGroup)"
        ]
    }
}
"@

Post-GraphData -graphToken $graphToken -body $body -url "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($response.id)')/assignJustInTimeConfiguration"

$body = @"
{
    "assignments": [
        {
            "id": "",
            "source": "direct",
            "target": {
                "groupId": "$($UserSecurityGroup)",
                "@odata.type": "#microsoft.graph.groupAssignmentTarget",
                "deviceAndAppManagementAssignmentFilterType": "none"
            }
        }
    ]
}
"@

Post-GraphData -graphToken $graphToken -body $body -url "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($response.id)')/assign"
```

### 4. Delete the WADP Policy

```powershell
Delete-GraphData -graphToken $graphToken -url "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($response.id)')"
```

## Error Handling and Retries

The functions include retry logic for handling rate limiting (`429 Too Many Requests`) and service unavailability (`503 Service Unavailable`). If the maximum retry attempts are reached, an error is logged.

## Conclusion

This script provides a comprehensive set of functions to manage Windows Autopilot Deployment Profiles via the Microsoft Graph API. Customize the parameters and functions as needed for your specific use case.
