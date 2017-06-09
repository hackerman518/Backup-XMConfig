# Backup-XMConfig
Script to backup XenMobile 10 configuration: Server Properties, Client Properties and App Container options.

## Features
* Documenting the following in a HTML report:
  * Server properties
  * Client properties
  * App Container properties for Web apps and Public Store apps
  * App Container properties for MDX/Enterprise apps **with**:
    * iOS policies
    * Android policies
* Running in Interactive Mode
* Running in Automated Mode (useful for scheduling or working with other scripts)
  * Using a plaintext username/password combination
  * Using a PSCredential object (secure)

## Requirements
* This script is built for PowerShell version 5, which is already in Windows 10 and is a free upgrade.
* This script is tested to work with XenMobile versions 10.5.0.24 and 10.5.0.10011
* This script requires a XenMobile user with either API or SuperUser access. 

## Usage
See formatted Get-Help output below, or run `Get-Help .\Backup-XMConfig.ps1 -Full`

---

# .\Backup-XMConfig.ps1
## SYNOPSIS
Backup XenMobile Server options for documentation purposes. Extracts Client Properties, Server Properties and App Container options.

## SYNTAX
### Interactive mode
````powershell
.\Backup-XMConfig.ps1 [-Server <String>] [-Port <String>] [-Credential <PSCredential>] [-Path <String>] [<CommonParameters>]
````

### Automated mode with PSCredential
````powershell
.\Backup-XMConfig.ps1 -Server <String> -Port <String> -Credential <PSCredential> -Path <String> [<CommonParameters>]
````

### Automated mode with username/password combination
````powershell
.\Backup-XMConfig.ps1 -Server <String> -Port <String> -User <String> -Password <String> -Path <String> [<CommonParameters>]
````

## DESCRIPTION
This command will connect to the XenMobile Server using REST API and extract the Client Properties, Server Properties and App Container options. You will need a user which has API access or SuperUser access.

Because of PowerShell restrictions, connecting using an IP address will not work. You will need FQDN access to the XenMobile Server. The FQDN needs to match the certificate, the certificate needs to be valid and be trusted by the system.

You can run the script interactively by just calling the script, or automated (useful in other scripts) by providing the parameters. You can enter the username/password pair, or use a PSCredential object for more security. If both are provided, the PSCredential will take precedence.

## PARAMETERS
### -Server &lt;String&gt;

Specify the XenMobile server to connect to. Because of PowerShell restrictions, this needs to be a FQDN, not an IP address. Furthermore, the FQDN needs to match the certificate, the certificate must be valid and trusted by the system.

### -Port &lt;String&gt;

Specify the XenMobile server port to connect to.

### -User &lt;String&gt;

Specify the XenMobile username. This user must have API or Super-User access.

### -Password &lt;String&gt;

Specify the password.

### -Credential &lt;PSCredential&gt;

Specify a PSCredential object. This will replace the User and Password variables.

### -Path &lt;String&gt;

Full path to where you want to create the backup.

## NOTES
    Version:        1.0-beta1
    Author:         Patrick de Ritter
    Creation Date:  2017-06-09
    Purpose/Change: Initial script beta

## Examples
### EXAMPLE 1: Interactive Mode
````powershell
PS >.\Backup-XMConfig.ps1
````
Backup the Client Properties, Server Properties and App Container options from your environment. Interactive mode.

### EXAMPLE 2: Automated Mode with PSCredential
````powershell
PS >.\Backup-XMConfig.ps1-Server fqdn.xenmobileserver.com -Port 4443 -Credential $MyCredential -Path .\backup.html
````

Backup the Client Properties, Server Properties and App Container options from your environment. Automated mode using PSCredential object.

### EXAMPLE 3: Automated with username/password combination
````powershell
PS >.\Backup-XMConfig.ps1 -Server fqdn.xenmobileserver.com -Port 4443 -User administrator -Password secret123 -Path .\backup.html
````

Backup the Client Properties, Server Properties and App Container options from your environment. Automated mode using username/password combination.
