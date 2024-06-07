#Install-Module MSAL.PS -Scope CurrentUser
Import-Module MSAL.PS

function Get-GraphAPIAccessToken {
    param (
        [string]$tenantId,
        [string]$clientId
    )

    
    $scopes = "https://graph.microsoft.com/.default"

    try {
        # Perform device code flow to get the token
        $deviceCodeResponse = Get-MsalToken -ClientId $clientId -TenantId $tenantId -Scopes $scopes -DeviceCode

        # Wait for the user to complete the authentication
        $tokenResponse = $deviceCodeResponse

        return $tokenResponse.AccessToken
    }
    catch {
        Write-Error "Failed to get the access token: $_"
        return $null
    }
}
# Function to get data from Microsoft Graph API
function Get-graphdata {
    param(
        [Parameter(Mandatory=$true)]
        [string] $graphToken,
        [string] $url
    )
    $authHeader = @{
        'Authorization' = "$graphToken"
        'Content-Type'  = 'application/json'
    }
    $retryCount = 0
    $maxRetries = 3
    $Results = @()

    # Loop to handle retries
    while ($retryCount -le $maxRetries) {
        try {
            do {
                # Send GET request to Microsoft Graph API
                $response = Invoke-WebRequest -Uri $url -Method Get -Headers $authHeader -UseBasicParsing
                $pageResults = $response.Content | ConvertFrom-Json
                $retryCount = 0
                if ($pageResults.'@odata.nextLink' -ne $null) {
                    $url = $pageResults.'@odata.nextLink'
                    $results += $pageResults
                } else {
                    $results += $pageResults
                    return $results
                }
            } while ($pageResults.'@odata.nextLink')
        } catch {
            $statusCode = $_.Exception.Response.StatusCode

            if ($statusCode -in $retryStatusCodes) {
                $retryCount++
                $retryAfter = [int]($_.Exception.Response.Headers.'Retry-After')
                $sleepcount = if ($retryAfter) { $retryAfter } else { $retryCount * $global:apiTtimeout }
                Start-Sleep -Seconds $sleepcount
            } elseif ($statusCode -in $statusCodesObject.code) {
                return $null
            } else {
                Write-Error "$($_.Exception)"
                return $null
            }
        }
    }
}
# Function to update data using PATCH method in Microsoft Graph API
function Patch-GraphData {
    param(
        [Parameter(Mandatory=$true)]
        [string] $graphToken,

        [Parameter(Mandatory=$true)]
        [string] $url,

        [Parameter(Mandatory=$true)]
        [string] $body
    )
    $authHeader = @{
        'Authorization' = "$graphToken"
        'Content-Type'  = 'application/json'
    }
    $retryCount = 0
    $maxRetries = 3

    # Loop to handle retries
    while ($retryCount -le $maxRetries) {
        try {
            # Send PATCH request to Microsoft Graph API
            $response = Invoke-RestMethod -Uri $url -Method Patch -Headers $authHeader -Body $body -ContentType "application/json"
            return $response
        } catch {
            $statusCode = $_.Exception.Response.StatusCode
            if ($statusCode -eq 429) { # Too many requests
                $retryCount++
                $retryAfter = [int]($_.Exception.Response.Headers.'Retry-After')
                $sleepcount = if ($retryAfter) { $retryAfter } else { $retryCount * 10 } # Default backoff if Retry-After not available
                Write-Warning "API call returned error $statusCode. Too many requests. Retrying in $($sleepcount) seconds."
                Start-Sleep -Seconds $sleepcount
            } elseif ($statusCode -eq 503) { # Service unavailable
                $retryCount++
                $sleepcount = $retryCount * 10
                Write-Warning "API call returned error $statusCode. Service unavailable. Retrying in $($sleepcount) seconds."
                Start-Sleep -Seconds $sleepcount
            } else {
                Write-Error "API call returned error $statusCode."
                return $null
            }
        }
    }
    Write-Warning "Max retry attempts reached."
    return $null
}
# Function to post new data using POST method in Microsoft Graph API
function Post-GraphData {
    param(
        [Parameter(Mandatory=$true)]
        [string] $graphToken,

        [Parameter(Mandatory=$true)]
        [string] $url,

        [Parameter(Mandatory=$true)]
        [string] $body
    )
    $authHeader = @{
        'Authorization' = "$graphToken"
        'Content-Type'  = 'application/json'
    }
    $retryCount = 0
    $maxRetries = 3

    # Loop to handle retries
    while ($retryCount -le $maxRetries) {
        try {
            # Send POST request to Microsoft Graph API
            $response = Invoke-RestMethod -Uri $url -Method POST -Headers $authHeader -Body $body -ContentType "application/json"
            return $response
        } catch {
            $statusCode = $_.Exception.Response.StatusCode
            if ($statusCode -eq 429) { # Too many requests
                $retryCount++
                $retryAfter = [int]($_.Exception.Response.Headers.'Retry-After')
                $sleepcount = if ($retryAfter) { $retryAfter } else { $retryCount * 10 } # Default backoff if Retry-After not available
                Write-Warning "API call returned error $statusCode. Too many requests. Retrying in $($sleepcount) seconds."
                Start-Sleep -Seconds $sleepcount
            } elseif ($statusCode -eq 503) { # Service unavailable
                $retryCount++
                $sleepcount = $retryCount * 10
                Write-Warning "API call returned error $statusCode. Service unavailable. Retrying in $($sleepcount) seconds."
                Start-Sleep -Seconds $sleepcount
            } else {
                Write-Error "API call returned error $statusCode."
                return $null
            }
        }
    }
    Write-Warning "Max retry attempts reached."
    return $null
}
# Function to delete data using DELETE method in Microsoft Graph API
function Delete-GraphData {
    param(
        [Parameter(Mandatory=$true)]
        [string] $graphToken,

        [Parameter(Mandatory=$true)]
        [string] $url
    )
    $authHeader = @{
        'Authorization' = "$graphToken"
        'Content-Type'  = 'application/json'
    }
    $retryCount = 0
    $maxRetries = 3

    # Loop to handle retries
    while ($retryCount -le $maxRetries) {
        try {
            # Send DELETE request to Microsoft Graph API
            $response = Invoke-RestMethod -Uri $url -Method DELETE -Headers $authHeader -Body $body -ContentType "application/json"
            return $response
        } catch {
            $statusCode = $_.Exception.Response.StatusCode
            if ($statusCode -eq 429) { # Too many requests
                $retryCount++
                $retryAfter = [int]($_.Exception.Response.Headers.'Retry-After')
                $sleepcount = if ($retryAfter) { $retryAfter } else { $retryCount * 10 } # Default backoff if Retry-After not available
                Write-Warning "API call returned error $statusCode. Too many requests. Retrying in $($sleepcount) seconds."
                Start-Sleep -Seconds $sleepcount
            } elseif ($statusCode -eq 503) { # Service unavailable
                $retryCount++
                $sleepcount = $retryCount * 10
                Write-Warning "API call returned error $statusCode. Service unavailable. Retrying in $($sleepcount) seconds."
                Start-Sleep -Seconds $sleepcount
            } else {
                Write-Error "API call returned error $statusCode."
                return $null
            }
        }
    }
    Write-Warning "Max retry attempts reached."
    return $null
}
$session = Connect-AzAccount
#$graphtoken = (Get-AzAccessToken -ResourceTypeName MSGraph).token
$tenantId = $session.context.Tenant.id
$graphToken = Get-GraphAPIAccessToken -tenantId $tenantId -ClientId ""

#Retrieving WADP Profiles & Settings

$wadpprofiles = (Get-graphdata -graphToken $graphToken -url "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$select=id,name,description,platforms,lastModifiedDateTime,technologies,settingCount,roleScopeTagIds,isAssigned,templateReference,priorityMetaData%20&`$top=100%20&`$filter=(technologies%20has%20%27enrollment%27)%20and%20(platforms%20eq%20%27windows10%27)%20and%20(TemplateReference/templateId%20eq%20%2780d33118-b7b4-40d8-b15f-81be745e053f_1%27)%20and%20(Templatereference/templateFamily%20eq%20%27enrollmentConfiguration%27)%20").Value

$wadpprofilessettings = $wadpprofiles.id | ForEach-Object {
    $url = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($_)')?`$expand=settings"
    Get-graphdata -graphToken $graphToken -url $url
}
$wadpprofileassignmetns = $wadpprofiles.id | ForEach-Object {
    $url = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($_)')/assignments"
    Get-graphdata -graphToken $graphToken -url $url
}
$wadpprofilejustintimeconfig = $wadpprofiles.id | ForEach-Object {
    $url = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($_)')/retrieveJustInTimeConfiguration"
    Get-graphdata -graphToken $graphToken -url $url
}



#Creating WADP Profiles & Assignments

$justInTimeSecurityGroup = ""
$UserSecurityGroup = ""

$body = @"
    {
        "id": "00000000-0000-0000-0000-000000000000",
        "name": "WADP_DEMO_GRAPH",
        "description": "",
        "settings": [
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                    "choiceSettingValue": {
                        "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                        "children": [],
                        "settingValueTemplateReference": {
                            "settingValueTemplateId": "5874c2f6-bcf1-463b-a9eb-bee64e2f2d82"
                        },
                        "value": "enrollment_autopilot_dpp_deploymentmode_0"
                    },
                    "settingDefinitionId": "enrollment_autopilot_dpp_deploymentmode",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "5180aeab-886e-4589-97d4-40855c646315"
                    }
                }
            },
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                    "choiceSettingValue": {
                        "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                        "children": [],
                        "settingValueTemplateReference": {
                            "settingValueTemplateId": "e0af022f-37f3-4a40-916d-1ab7281c88d9"
                        },
                        "value": "enrollment_autopilot_dpp_deploymenttype_0"
                    },
                    "settingDefinitionId": "enrollment_autopilot_dpp_deploymenttype",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "f4184296-fa9f-4b67-8b12-1723b3f8456b"
                    }
                }
            },
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                    "choiceSettingValue": {
                        "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                        "children": [],
                        "settingValueTemplateReference": {
                            "settingValueTemplateId": "1fa84eb3-fcfa-4ed6-9687-0f3d486402c4"
                        },
                        "value": "enrollment_autopilot_dpp_jointype_0"
                    },
                    "settingDefinitionId": "enrollment_autopilot_dpp_jointype",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "6310e95d-6cfa-4d2f-aae0-1e7af12e2182"
                    }
                }
            },
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                    "choiceSettingValue": {
                        "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                        "children": [],
                        "settingValueTemplateReference": {
                            "settingValueTemplateId": "bf13bb47-69ef-4e06-97c1-50c2859a49c2"
                        },
                        "value": "enrollment_autopilot_dpp_accountype_1"
                    },
                    "settingDefinitionId": "enrollment_autopilot_dpp_accountype",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "d4f2a840-86d5-4162-9a08-fa8cc608b94e"
                    }
                }
            },
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance",
                    "settingDefinitionId": "enrollment_autopilot_dpp_timeout",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "6dec0657-dfb8-4906-a7ee-3ac6ee1edecb"
                    },
                    "simpleSettingValue": {
                        "@odata.type": "#microsoft.graph.deviceManagementConfigurationIntegerSettingValue",
                        "settingValueTemplateReference": {
                            "settingValueTemplateId": "0bbcce5b-a55a-4e05-821a-94bf576d6cc8"
                        },
                        "value": 90
                    }
                }
            },
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance",
                    "settingDefinitionId": "enrollment_autopilot_dpp_customerrormessage",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "2ddf0619-2b7a-46de-b29b-c6191e9dda6e"
                    },
                    "simpleSettingValue": {
                        "@odata.type": "#microsoft.graph.deviceManagementConfigurationStringSettingValue",
                        "settingValueTemplateReference": {
                            "settingValueTemplateId": "fe5002d5-fbe9-4920-9e2d-26bfc4b4cc97"
                        },
                        "value": "Contact your oganization's support person for help."
                    }
                }
            },
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                    "choiceSettingValue": {
                        "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                        "children": [],
                        "settingValueTemplateReference": {
                            "settingValueTemplateId": "a2323e5e-ac56-4517-8847-b0a6fdb467e7"
                        },
                        "value": "enrollment_autopilot_dpp_allowskip_1"
                    },
                    "settingDefinitionId": "enrollment_autopilot_dpp_allowskip",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "2a71dc89-0f17-4ba9-bb27-af2521d34710"
                    }
                }
            },
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                    "choiceSettingValue": {
                        "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                        "children": [],
                        "settingValueTemplateReference": {
                            "settingValueTemplateId": "c59d26fd-3460-4b26-b47a-f7e202e7d5a3"
                        },
                        "value": "enrollment_autopilot_dpp_allowdiagnostics_1"
                    },
                    "settingDefinitionId": "enrollment_autopilot_dpp_allowdiagnostics",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "e2b7a81b-f243-4abd-bce3-c1856345f405"
                    }
                }
            },
            {
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance",
                    "settingDefinitionId": "enrollment_autopilot_dpp_allowedappids",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "70d22a8a-a03c-4f62-b8df-dded3e327639"
                    },
                    "simpleSettingCollectionValue": [
                        {
                            "@odata.type": "#microsoft.graph.deviceManagementConfigurationStringSettingValue",
                            "value": "{\"id\":\"85b74d79-9e57-4bf3-92bc-a2b8d8af3be8\",\"type\":\"#microsoft.graph.winGetApp\"}"
                        }
                    ]
                }
            },
            {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
                "settingInstance": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance",
                    "settingDefinitionId": "enrollment_autopilot_dpp_allowedscriptids",
                    "settingInstanceTemplateReference": {
                        "settingInstanceTemplateId": "1bc67702-800c-4271-8fd9-609351cc19cf"
                    },
                    "simpleSettingCollectionValue": [
                        {
                            "@odata.type": "#microsoft.graph.deviceManagementConfigurationStringSettingValue",
                            "value": " "
                        }
                    ]
                }
            }
        ],
        "roleScopeTagIds": [
            "0"
        ],
        "platforms": "windows10",
        "technologies": "enrollment",
        "templateReference": {
            "templateId": "80d33118-b7b4-40d8-b15f-81be745e053f_1"
        }
    }
"@
$($response.id)
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



#Deleteing the WADP Policy that you just created
Delete-GraphData -graphToken $graphToken -url "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$($response.id)')"