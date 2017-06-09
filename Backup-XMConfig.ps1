#Requires -version 5

<#
.SYNOPSIS
Backup XenMobile Server options for documentation purposes. Extracts Client Properties, Server Properties and App Container options.

.DESCRIPTION
This command will connect to the XenMobile Server using REST API and extract the Client Properties, Server Properties and App Container options.
You will need a user which has API access or SuperUser access.
Because of PowerShell restrictions, connecting using an IP address will not work. You will need FQDN access to the XenMobile Server. The FQDN needs to match the certificate, the certificate needs to be valid and be trusted by the system.
You can run the script interactively by just calling the script, or automated (useful in other scripts) by providing the parameters. You can enter the username/password pair, or use a PSCredential object for more security. If both are provided, the PSCredential will take precedence.
  
.PARAMETER Server
Specify the XenMobile server to connect to. Because of PowerShell restrictions, this needs to be a FQDN, not an IP address. Furthermore, the FQDN needs to match the certificate, the certificate must be valid and trusted by the system.

.PARAMETER Port
Specify the XenMobile server port to connect to.

.PARAMETER User
Specify the XenMobile username. This user must have API or Super-User access.

.PARAMETER Password
Specify the password.

.PARAMETER Credential
Specify a PSCredential object. This will replace the User and Password variables.

.PARAMETER Path
Full path to where you want to create the backup.

.NOTES
Version:        1.0-beta1
Author:         Patrick de Ritter
Creation Date:  2017-06-09
Purpose/Change: Initial script beta

.EXAMPLE
.\Backup-XMConfig.ps1

Backup the Client Properties, Server Properties and App Container options from your environment. Interactive mode.


.EXAMPLE
.\Backup-XMConfig.ps1 -Server fqdn.xenmobileserver.com -Port 4443 -Credential $MyCredential -Path .\backup.html

Backup the Client Properties, Server Properties and App Container options from your environment. Automated mode using PSCredential object.


.EXAMPLE
.\Backup-XMConfig.ps1 -Server fqdn.xenmobileserver.com -Port 4443 -User administrator -Password secret123 -Path .\backup.html

Backup the Client Properties, Server Properties and App Container options from your environment. Automated mode using username/password combination.
#>

[CmdletBinding(DefaultParameterSetName='Interactive')]
Param (
    [Parameter(ParameterSetName='Automated with username/password combination', Mandatory=$true)]
    [Parameter(ParameterSetName='Automated with PSCredential', Mandatory=$true)]
    [Parameter(ParameterSetName='Interactive', Mandatory=$false)]
    [string]$Server,

    [Parameter(ParameterSetName='Automated with username/password combination', Mandatory=$true)]
    [Parameter(ParameterSetName='Automated with PSCredential', Mandatory=$true)]
    [Parameter(ParameterSetName='Interactive', Mandatory=$false)]
    [string]$Port,

    [Parameter(ParameterSetName='Automated with username/password combination', Mandatory=$true)]
    [string]$User,

    [Parameter(ParameterSetName='Automated with username/password combination', Mandatory=$true)]
    [string]$Password,

    [Parameter(ParameterSetName='Automated with PSCredential', Mandatory=$true)]
    [Parameter(ParameterSetName='Interactive', Mandatory=$false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(ParameterSetName='Automated with username/password combination', Mandatory=$true)]
    [Parameter(ParameterSetName='Automated with PSCredential', Mandatory=$true)]
    [Parameter(ParameterSetName='Interactive', Mandatory=$false)]
    [string]$Path
)

if (!$Server) {
    $Server = Read-Host -Prompt "Enter the XenMobile Server FQDN, without the port"
}

if (!$Port) {
    $Port = Read-Host -Prompt "Enter the XenMobile Server port [default '4443']"
    if (!$Port -or ($Port -eq "")) { $Port = "4443" }
}

if (!$Path) {
    $Path = Read-Host -Prompt "Enter the path to the location where you would like to save the output [default '.\backup-xmconfig_yyyyMMdd.html']"
    if (!$Path -or ($Path -eq "")) { $Path = Join-Path $PSScriptRoot "\backup-xmconfig_$(Get-Date -Format "yyyyMMdd").html" }
}

if (!$Credential -and (!$User -or !$Password)) {
    $Credential = Get-Credential -Message "Enter the credentials for a user with API access or SuperUser rights on the XenMobile Server"
}

Set-Variable -Name "XMServer" -Value $Server -Scope Global
Set-Variable -Name "XMPort" -Value $(if ($Port -ne $null) { $Port } else { "4443" }) -Scope Global
Set-Variable -Name "XMUser" -Value $(if ($Credential -ne $null) { $Credential.GetNetworkCredential().username } else { $User }) -Scope Global
Set-Variable -Name "XMPassword" -Value $(if ($Credential -ne $null) { $Credential.GetNetworkCredential().password } else { $Password }) -Scope Global

# Functions

Function Get-XMToken {
    Param (
        [string]$Server,
        [string]$Port,
        [string]$User,
        [string]$Password
    )

    $url = "https://" + $Server + ":" + $Port + "/xenmobile/api/v1/authentication/login"
    $header = @{ 'Content-Type' = 'application/json'}
    $body = @{
        login = $User;
        password = $Password
    }
    
    Try {
        $request = Invoke-RestMethod -Uri $url -Method Post -Body (ConvertTo-Json $body) -Headers $header
    }
    
    Catch {
        Write-Host -BackgroundColor Red "Authentication Failed."
        Break
    }

    return [string]$request.auth_token
}

Function Get-XMServerProperties {
    Param (
        [string]$Server,
        [string]$Port,
        [string]$Token
    )

    $url = "https://" + $Server + ":" + $Port + "/xenmobile/api/v1/serverproperties"
    $header = @{
        'auth_token' = $Token;
        'Content-Type' = 'application/json'
    }
    $body = $null

    Try {
        $request = Invoke-RestMethod -Uri $url -Method Get -Body (ConvertTo-Json $body) -Headers $header
    }

    Catch {
        Write-Host -BackgroundColor Red "Could not get Server Properties."
        Break
    }
    
    return $request.allEwProperties
}

Function Get-XMClientProperties {
    Param (
        [string]$Server,
        [string]$Port,
        [string]$Token
    )

    $url = "https://" + $Server + ":" + $Port + "/xenmobile/api/v1/clientproperties"
    $header = @{
        'auth_token' = $Token;
        'Content-Type' = 'application/json'
    }
    $body = $null

    Try {
        $request = Invoke-RestMethod -Uri $url -Method Get -Body (ConvertTo-Json $body) -Headers $header
    }

    Catch {
        Write-Host -BackgroundColor Red "Could not get Client Properties."
        Break
    }
    
    return $request.allClientProperties
}

Function Get-XMAppContainers {
    Param (
        [string]$Server,
        [string]$Port,
        [string]$Token
    )

    $url = "https://" + $Server + ":" + $Port + "/xenmobile/api/v1/application/filter"
    $header = @{
        'auth_token' = $Token;
        'Content-Type' = 'application/json'
    }
    $body = @{
        'start' = 0;
        'applicationSortColumn' = 'name';
        'sortOrder' = 'ASC'
    }

    Try {
        $request = Invoke-RestMethod -Uri $url -Method Post -Body (ConvertTo-Json $body) -Headers $header
    }

    Catch {
        Write-Host -BackgroundColor Red "Could not get applications."
        Break
    }

    return $request.applicationListData
}

Function Get-XMAppProperties {
    Param (
        [string]$Server,
        [string]$Port,
        [string]$Token,
        [string]$Type,        
        [string]$Id
    )

    $url = "https://" + $Server + ":" + $Port + "/xenmobile/api/v1/application/" + $Type + "/" + $Id
    $header = @{
        'auth_token' = $Token;
        'Content-Type' = 'application/json'
    }
    $body = $null

    Try {
        $request = Invoke-RestMethod -Uri $url -Method GET -Body (ConvertTo-Json $body) -Headers $header
    }

    Catch {
        Write-Host -BackgroundColor Red "Could not get application properties for application ID: $Id"
    }

    return $request.container
    
}

# Login

Set-Variable -Name "XMToken" -Value (Get-XMToken -Server $XMServer -Port $XMPort -User $XMUser -Password $XMPassword) -Scope Global -ErrorAction Stop

# Build HTML prefix

$outputPrefix = @"
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <title>XenMobile Server Backup - $XMServer - $(Get-Date -Format "yyyyMMdd")</title>
        <style type="text/css">
            body {
                font-size:12px;
                font-family:Verdana, Arial, Helvetica, sans-serif;
            }
            img {
                float: left;
                margin-right: 10px;
                clear: both;
            }
            ul.next {
                margin-left: 0px;
                overflow: auto;
                display: block;
            }
            p.clear {
                clear:both;
            }
            .tg {
                border-collapse: collapse;
                border-spacing: 0;
                border-color: #999;
                margin: 0px auto;
            }
            .tg td {
                font-family: Arial, sans-serif;
                font-size: 14px;
                padding: 10px 5px;
                border-style: solid;
                border-width: 0px;
                overflow: hidden;
                word-break: normal;
                border-color: #999;
                color: #444;
                background-color: #F7FDFA;
                border-top-width: 1px;
                border-bottom-width: 1px;
            }
            .tg th {
                font-family: Arial, sans-serif;
                font-size: 14px;
                font-weight: normal;
                padding: 10px 5px;
                border-style: solid;
                border-width: 0px;
                overflow: hidden;
                word-break: normal;
                border-color: #999;
                color: #fff;
                background-color: #26ADE4;
                border-top-width: 1px;
                border-bottom-width: 1px;
            }
            .tg .tg-baqh {
                text-align: center;
                vertical-align: top
            }
            .tg .tg-yw4l { vertical-align:top }
            @media screen and (max-width: 767px) {
                .tg { width: auto !important; }
                .tg col { width: auto !important; }
                .tg-wrap {
                    overflow-x: auto;
                    -webkit-overflow-scrolling: touch;
                    margin: auto 0px;
                }
            }
        </style>
    </head>
    <body>
        <h1>XenMobile Server Backup - $XMServer - $(Get-Date)</h1>
"@

# Build Server properties 

$serverProperties = Get-XMServerProperties -Server $XMServer -Port $XMPort -Token $XMToken

$outputServerProperties = @"
    <h2>Server Properties</h2>
    <p>These are the configured server properties.</p>
    <div class="tg-wrap"><table class="tg">
    <tr>
        <th class="tg-baqh">Name</th>
        <th class="tg-baqh">Value</th>
        <th class="tg-baqh">Display Name</th>
        <!-- <th class="tg-baqh">Description</th> -->
        <th class="tg-baqh">Default Value</th>
    </tr>
"@

foreach ($serverproperty in $serverProperties) {
    $outputServerProperties += @"
        <tr>
            <td class="tg-yw4l">$($serverproperty.name)</td>
            <td class="tg-yw4l">$($serverproperty.value)</td>
            <td class="tg-yw4l">$($serverproperty.displayName)</td>
            <!-- <td class="tg-yw4l">$($serverproperty.description)</td> -->
            <td class="tg-yw41">$($serverproperty.defaultValue)</td>
        </tr>
"@
}

$outputServerProperties += "</table></div><hr />"

# Build Client Properties

$clientProperties = Get-XMClientProperties -Server $XMServer -Port $XMPort -Token $XMToken

$outputClientProperties = @"
    <h2>Client Properties</h2>
    <p>These are the configured client properties.</p>
    <div class="tg-wrap"><table class="tg">
    <tr>
        <th class="tg-baqh">Display Name</th>
        <th class="tg-baqh">Key</th>
        <th class="tg-baqh">Value</th>
    </tr>
"@

foreach ($clientproperty in $clientProperties) {
    $outputClientProperties += @"
        <tr>
            <td class="tg-yw4l">$($clientproperty.displayName)</td>
            <td class="tg-yw4l">$($clientproperty.key)</td>
            <td class="tg-yw4l">$($clientproperty.value)</td>
        </tr>
"@
}

$outputClientProperties += "</table></div><hr />"

# Build App Containers
$applications = Get-XMAppContainers -Server $XMServer -Port $XMPort -Token $XMToken

$outputApplications = @"
    <h2>App Container Properties</h2>
    <p>These are the settings per App Container</p>
"@

foreach ($app in $applications.applist) {
    switch ($app.appType) {
        MDX { $apptype = "mobile" }
        Enterprise { $apptype = "mobile" }
        "App Store App" { $apptype = "appstore" }
        "Web Link" { $apptype = $null }
        Default { $apptype = $null }
    }
    
    if ($apptype -eq "mobile") {
        $applicationProperties = Get-XMAppProperties -Server $XMServer -Port $XMPort -Token $XMToken -Type $apptype -Id $app.id

        $outputApplications += @"
            <h3>$($applicationProperties.name)</h3>
            <img height="50px" width="50px" src="data:image/png;base64,$($applicationProperties.iconData)" />
            <ul class="next">
                <li><strong>ID:</strong> $($applicationProperties.id)</li>
                <li><strong>name:</strong> $($applicationProperties.name)</li>
                <li><strong>description:</strong> $($applicationProperties.description)</li>
                <li><strong>disabled:</strong> $($applicationProperties.disabled)</li>
                <li><strong>appType:</strong> $($applicationProperties.appType)</li>
                <li><strong>categories:</strong> $($applicationProperties.categories -join ", ")</li>
                <li><strong>roles:</strong> $($applicationProperties.roles -join ", ")</li>
                <li><strong>workflow:</strong> $($appplicationProperties.workflow)</li>
                <li><strong>vppAccount:</strong> $($applicationProperties.vppAccount)</li>
            </ul>
"@
        
        if ($applicationProperties.ios -ne $null) {
            $outputApplications += @"
                <h4>iOS Settings</h4>
                <ul class="next">
                    <li><strong>displayName:</strong> $($applicationProperties.ios.displayName)</li>
                    <li><strong>Description:</strong> $($applicationProperties.ios.description)</li>
                    <li><strong>paid:</strong> $($applicationProperties.ios.paid)</li>
                    <li><strong>removeWithMdm:</strong> $($applicationProperties.ios.removeWithMdm)</li>
                    <li><strong>preventBackup:</strong> $($applicationProperties.ios.preventBackup)</li>
                    <li><strong>changeManagementState:</strong> $($applicationProperties.ios.changeManagementState)</li>
                    <li><strong>associateToDevice:</strong> $($applicationProperties.ios.associateToDevice)</li>
                    <li><strong>canAssociateToDevice:</strong> $($applicationProperties.ios.canAssociateToDevice)</li>
                    <li><strong>appVersion:</strong> $($applicationProperties.ios.appVersion)</li>
                    <li><strong>minOsVersion:</strong> $($applicationProperties.ios.minOsVersion)</li>
                    <li><strong>maxOsVersion:</strong> $($applicationProperties.ios.maxOsVersion)</li>
                    <li><strong>ExcludedDevices:</strong> $($applicationProperties.ios.ExcludedDevices)</li>
                </ul>
                <div class="tg-wrap"><table class="tg">
                <tr>
                    <th class="tg-baqh">policyName</th>
                    <th class="tg-baqh">policyValue</th>
                    <th class="tg-baqh">policyType</th>
                    <th class="tg-baqh">policyCategory</th>
                    <th class="tg-baqh">title</th>
                    <th class="tg-baqh">description</th>
                    <th class="tg-baqh">units</th>
                    <th class="tg-baqh">explanation</th>
                </tr>
"@

            foreach ($policy in $applicationProperties.ios.policies) {
                $outputApplications += @"
                    <tr>
                        <td class="tg-yw4l">$($policy.policyName)</td>
                        <td class="tg-yw4l">$($policy.policyValue)</td>
                        <td class="tg-yw4l">$($policy.policyType)</td>
                        <td class="tg-yw4l">$($policy.policyCategory)</td>
                        <td class="tg-yw4l">$($policy.title)</td>
                        <td class="tg-yw4l">$($policy.description)</td>
                        <td class="tg-yw4l">$($policy.units)</td>
                        <td class="tg-yw4l">$($policy.explanation)</td>
                    </tr>            
"@
            }

            $outputApplications += "</table></div>"
        } else { $outputApplications += "<h4>iOS Settings - Not Configured</h4>" }

        if ($applicationProperties.android -ne $null) {
            $outputApplications += @"
                <h4>Android Settings</h4>
                <ul class="next">
                    <li><strong>displayName:</strong> $($applicationProperties.android.displayName)</li>
                    <li><strong>Description:</strong> $($applicationProperties.android.description)</li>
                    <li><strong>paid:</strong> $($applicationProperties.android.paid)</li>
                    <li><strong>removeWithMdm:</strong> $($applicationProperties.android.removeWithMdm)</li>
                    <li><strong>preventBackup:</strong> $($applicationProperties.android.preventBackup)</li>
                    <li><strong>changeManagementState:</strong> $($applicationProperties.android.changeManagementState)</li>
                    <li><strong>associateToDevice:</strong> $($applicationProperties.android.associateToDevice)</li>
                    <li><strong>canAssociateToDevice:</strong> $($applicationProperties.android.canAssociateToDevice)</li>
                    <li><strong>appVersion:</strong> $($applicationProperties.android.appVersion)</li>
                    <li><strong>minOsVersion:</strong> $($applicationProperties.android.minOsVersion)</li>
                    <li><strong>maxOsVersion:</strong> $($applicationProperties.android.maxOsVersion)</li>
                    <li><strong>ExcludedDevices:</strong> $($applicationProperties.android.ExcludedDevices)</li>
                </ul>
                <div class="tg-wrap"><table class="tg">
                <tr>
                    <th class="tg-baqh">policyName</th>
                    <th class="tg-baqh">policyValue</th>
                    <th class="tg-baqh">policyType</th>
                    <th class="tg-baqh">policyCategory</th>
                    <th class="tg-baqh">title</th>
                    <th class="tg-baqh">description</th>
                    <th class="tg-baqh">units</th>
                    <th class="tg-baqh">explanation</th>
                </tr>
"@

            foreach ($policy in $applicationProperties.android.policies) {
                $outputApplications += @"
                    <tr>
                        <td class="tg-yw4l">$($policy.policyName)</td>
                        <td class="tg-yw4l">$($policy.policyValue)</td>
                        <td class="tg-yw4l">$($policy.policyType)</td>
                        <td class="tg-yw4l">$($policy.policyCategory)</td>
                        <td class="tg-yw4l">$($policy.title)</td>
                        <td class="tg-yw4l">$($policy.description)</td>
                        <td class="tg-yw4l">$($policy.units)</td>
                        <td class="tg-yw4l">$($policy.explanation)</td>
                    </tr>            
"@
            }

            $outputApplications += "</table></div><hr />"
        } else { $outputApplications += "<h4>Android Settings - Not Configured</h4><hr />" }

    } else {
        $outputApplications += @"
            <h3>$($app.name)</h3>
            <img height="50px" width="50px" src="data:image/png;base64,$($app.iconData)" />
            <ul class="next">
                <li><strong>ID:</strong> $($app.id)</li>
                <li><strong>name:</strong> $($app.name)</li>
                <li><strong>description:</strong> $($app.description)</li>
                <li><strong>disabled:</strong> $($app.disabled)</li>
                <li><strong>appType:</strong> $($app.appType)</li>
                <li><strong>categories:</strong> $($app.categories -join ", ")</li>
                <li><strong>workflow:</strong> $($app.workflow)</li>
            </ul>
            <hr />
"@
    }
}

# Finish up

$outputPostfix = @"
  <p class="footer">Generated on <em>$(Get-Date)</em> for XenMobile Server <em>$XMServer</em> using <a href="https://github.com/patrickderitter/Backup-XMConfig" title="Backup-XMConfig on GitHub">Backup-XMConfig</a>.<p>
  </body>
</html>
"@

$report = $outputPrefix + $outputServerProperties + $outputClientProperties + $outputApplications + $outputPostfix
$report | Out-File -FilePath $Path