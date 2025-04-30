# Malware Removal Automation Script
# Usage: Run as Administrator

param(
    [string]$DiscordWebhook = "YOUR_DISCORD_WEBHOOKhttps://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY",
    [ValidateSet("Quick","Full","Offline")][string]$ScanType = "Full"
)

#region Initialization
$ErrorActionPreference = "Stop"
$tempDir = $env:TEMP
$logFile = "$tempDir\MalwareScan-$(Get-Date -f yyyyMMddHHmm).log"

# Check admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Check Tamper Protection
function Test-TamperProtection {
    try {
        $tamperStatus = (Get-MpComputerStatus).TamperProtectionEnabled
        if ($tamperStatus) {
            throw "Tamper Protection enabled - disable via Windows Security GUI first"
        }
    }
    catch { throw $_ }
}
#endregion

#region Defender Functions
function Update-Defender {
    try {
        Write-Output "Updating Defender signatures..." | Tee-Object $logFile -Append
        Update-MpSignature -UpdateSource MicrosoftUpdateServer
    }
    catch { throw "Defender update failed: $_" }
}

function Run-DefenderScan {
    param([string]$Type)
    try {
        Write-Output "Starting Defender $Type scan..." | Tee-Object $logFile -Append
        $scan = Start-MpScan -ScanType $Type -AsJob
        while ($scan.State -eq 'Running') {
            Write-Progress -Activity "Defender Scan" -Status "$Type scan in progress"
            Start-Sleep -Seconds 30
        }
        return Get-MpThreat
    }
    catch { throw "Defender scan failed: $_" }
}
#endregion

#region MSERT Functions
function Invoke-MSERTScan {
    try {
        $msertPath = "$tempDir\msert.exe"
        $msertUrl = "https://definitionupdates.microsoft.com/download/DefinitionUpdates/safety-scanner/msert.exe"

        Write-Output "Downloading Microsoft Safety Scanner..." | Tee-Object $logFile -Append
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $msertUrl -OutFile $msertPath -UseBasicParsing

        Write-Output "Running MSERT scan..." | Tee-Object $logFile -Append
        Start-Process $msertPath -ArgumentList "/q /norestart" -Wait
        
        $msertLog = Get-Content "$env:windir\debug\msert.log" -Tail 100 -ErrorAction SilentlyContinue
        return $msertLog
    }
    catch { throw "MSERT operation failed: $_" }
    finally { Remove-Item $msertPath -ErrorAction SilentlyContinue }
}
#endregion

#region System Checks
function Check-ScheduledTasks {
    try {
        Write-Output "Checking suspicious scheduled tasks..." | Tee-Object $logFile -Append
        $badTasks = Get-ScheduledTask | Where-Object {
            $_.TaskName -match "Update|Malware|Temp|Script" -and 
            $_.State -eq "Ready"
        }
        $badTasks | Disable-ScheduledTask
        return $badTasks
    }
    catch { throw "Task check failed: $_" }
}

function Check-WMIMalware {
    try {
        Write-Output "Checking WMI for malware..." | Tee-Object $logFile -Append
        $suspiciousWMI = Get-WmiObject -Namespace root\subscription -Class __EventFilter -Filter "Name LIKE '%malware%'" -ErrorAction Stop
        $suspiciousWMI | Remove-WmiObject
        return $suspiciousWMI
    }
    catch { throw "WMI check failed: $_" }
}
#endregion

#region Reporting
function Send-DiscordReport {
    param([string]$Message, [string]$File)
    try {
        $payload = @{
            content = $Message
            file    = Get-Item $File
        }
        curl.exe -F "file1=@$File" $DiscordWebhook
    }
    catch { Write-Error "Discord report failed: $_" }
}
#endregion

# Main Execution
try {
    # Initial checks
    Test-TamperProtection
    
    # Defender operations
    Update-Defender
    $threats = Run-DefenderScan -Type $ScanType
    if ($threats) { $threats | Remove-MpThreat -Force }
    
    # Additional scans
    $msertResults = Invoke-MSERTScan
    $badTasks = Check-ScheduledTasks
    $wmiObjects = Check-WMIMalware
    
    # Compile report
    $report = @"
=== MALWARE REMOVAL REPORT ===
Defender Threats Found: $($threats.Count)
MSERT Findings: $($msertResults -join "`n")
Scheduled Tasks Disabled: $($badTasks.TaskName -join ", ")
WMI Objects Removed: $($wmiObjects.Name -join ", ")
"@
    
    $report | Out-File $logFile
    Send-DiscordReport -Message "Malware removal completed" -File $logFile
}
catch {
    $errorMsg = "Error: $_`nStack Trace: $($_.ScriptStackTrace)"
    $errorMsg | Out-File $logFile -Append
    Send-DiscordReport -Message "Malware removal failed" -File $logFile
    exit 1
}
finally {
    Remove-Item $logFile -ErrorAction SilentlyContinue
}
