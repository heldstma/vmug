# ----------------------------------------------------------
# VMware to Omnissa Horizon Agent Silent Install Script for Liquidware ProfileUnity and Stratusphere Users
# Includes stopping Liquidware Profile Unity and UX services
# Includes changing Liquidware Profile Unity userinit.exe original and expected path in registry 
# Tested with Omnissa Horizon Agent 2506
# Written by Matt Heldstab @mattheldstab
# Not meant for Production without testing
# ----------------------------------------------------------

# ----------------------
# CONFIGURABLE VARIABLES
# ----------------------

# Path to the Horizon Agent installer
$InstallerPath = "path-to-OmnissaHorizonAgent.exe"  # Replace with your actual file

# ----------------------------------
# HORIZON AGENT INSTALL COMMANDLINE
# ----------------------------------

# This script uses the ADDLOCAL options in the Horizon Agent that existed previously
# Feel free to edit the install arguments below
$installArgs = "/s /v`" /qr REBOOT=ReallySuppress"

# -----------------------------------------------
# STOP LIQUIDWARE PROU AND STRATUSPHERE SERVICES
# -----------------------------------------------

# Stop all services that have display names starting with Liquidware
$services = Get-Service -ErrorAction SilentlyContinue | Where-Object {
     $_.DisplayName -like 'Liquidware*' -and $_.Status -eq 'Running'
}

foreach ($svc in $services) {
   try {
       Write-Host "Stopping service: $($svc.DisplayName) [$($svc.Name)]" -ForegroundColor Yellow
	   Stop-Service -Name $svc.Name -Force -ErrorAction Stop
	   Write-Host "Successfully stopped: $($svc.DisplayName)" -ForegroundColor Green
    } catch {
	    Write-Warning "Failed to stop service: $($svc.DisplayName). Reason: $($_.Exception.Message)"
	}
}


# ------------------------------------
# RUN OMNISSA HORIZON AGENT INSTALLER
# ------------------------------------

Write-Host "Starting Horizon Agent installation..." -ForegroundColor Cyan
Write-Host "Installer: $InstallerPath" -ForegroundColor Gray
Write-Host "Arguments: $installArgs" -ForegroundColor Gray

try {
    Start-Process -FilePath $InstallerPath -ArgumentList $installArgs -Wait -NoNewWindow
    Write-Host "Horizon Agent installation completed successfully." -ForegroundColor Green
} catch {
    Write-Error "Installation failed: $_"
}

# ---------------------------------
# REPLACE LIQUIDWARE REGISTRY KEYS
# ---------------------------------

$regPath = 'HKLM:\SOFTWARE\Liquidware Labs\ProfileUnity'
$valueNameExpected = 'ExpectedUserinit'
$valueNameOriginal = 'OriginalUserinit'
$newValueExpected = '"C:\Program Files\ProfileUnity\client.net\LwL.ProfileUnity.Client.UserInit.exe","C:\Program Files\Omnissa\Horizon\Agent\bin\wssm.exe",'
$newValueOriginal = 'C:\windows\system32\userinit.exe,"C:\Program Files\Omnissa\Horizon\Agent\bin\wssm.exe",'

# Check if the registry key exists
if (Test-Path $regPath) {
    try {
        # Retrieve the current value
        $currentValue = Get-ItemProperty -Path $regPath -Name $valueNameExpected -ErrorAction Stop | Select-Object -ExpandProperty $valueNameExpected

        # Check if it contains "VMware"
        if ($currentValue -match 'VMware') {
            # Set the new value
            Set-ItemProperty -Path $regPath -Name $valueNameExpected -Value $newValueExpected
            Write-Output "Updated 'ExpectedUserinit' to new value."
            Set-ItemProperty -Path $regPath -Name $valueNameOriginal -Value $newValueOriginal
            Write-Output "Updated 'OriginalUserinit' to new value."
        } else {
            Write-Output "'ExpectedUserinit' does not contain 'VMware'. No change made."
        }
    }
    catch {
        Write-Output "'ExpectedUserinit' value not found at registry path."
    }
} else {
    Write-Output "Registry key '$regPath' does not exist."
}
