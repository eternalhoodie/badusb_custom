# Enhanced Malware Removal Automation Script
# Usage: Run as Administrator

param(
    [string]$DiscordWebhook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY",
    [ValidateSet("Quick","Full","Offline")][string]$ScanType = "Full",
    [int]$ScanTimeout = 14400  # 4 hour timeout for full scans
)

#region Initialization
$ErrorActionPreference = "Stop"
$tempDir = $env:TEMP
$logFile = "$tempDir\MalwareScan-$(Get-Date -f yyyyMMddHHmm).log"
$global:lastStatusUpdate = [DateTime]::MinValue

# Validate Discord webhook format
if ($DiscordWebhook -notmatch '^https:\/\/discord\.com\/api\/webhooks\/\d+\/[\w-]+$') {
    throw "Invalid Discord webhook format"
}

# Check admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-File `"$PSCommandPath`" -DiscordWebhook '$DiscordWebhook' -ScanType $ScanType" -Verb RunAs
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

#region Enhanced Defender Functions
function Update-Defender {
    try {
        Add-Log "Updating Defender signatures..."
        Update-MpSignature -UpdateSource MicrosoftUpdateServer -ErrorAction Stop
        Add-Log "Defender signatures updated successfully"
    }
    catch { throw "Defender update failed: $_" }
}

function Run-DefenderScan {
    param([string]$Type)
    try {
        Add-Log "Starting Defender $Type scan..."
        $scanStart = Get-Date
        $scan = Start-MpScan -ScanType $Type -AsJob -ErrorAction Stop
        
        while ((Get-Date) - $scanStart -lt [TimeSpan]::FromSeconds($ScanTimeout)) {
            $status = Get-MpScanStatus
            if ($status -eq "Running") {
                if ((Get-Date) - $lastStatusUpdate -gt [TimeSpan]::FromMinutes(5)) {
                    $global:lastStatusUpdate = Get-Date
                    Add-Log "Scan in progress... Estimated remaining: $((Get-MpThreatCatalog).ScanInProgress.RemainingTime)"
                }
                Start-Sleep -Seconds 30
            }
            else {
                break
            }
        }
        
        if ((Get-Date) - $scanStart -ge [TimeSpan]::FromSeconds($ScanTimeout)) {
            throw "Scan timed out after $ScanTimeout seconds"
        }
        
        return Get-MpThreat -ErrorAction SilentlyContinue | Where-Object { $_.IsActive }
    }
    catch { throw "Defender scan failed: $_" }
}
#endregion

#region Enhanced MSERT Functions
function Invoke-MSERTScan {
    try {
        $msertPath = "$tempDir\msert.exe"
        $msertUrl = "https://definitionupdates.microsoft.com/download/DefinitionUpdates/safety-scanner/msert.exe"

        Add-Log "Downloading Microsoft Safety Scanner..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $msertUrl -OutFile $msertPath -UseBasicParsing -ErrorAction Stop

        Add-Log "Running MSERT scan..."
        $process = Start-Process $msertPath -ArgumentList "/q /norestart" -PassThru -Wait
        
        if ($process.ExitCode -ne 0) {
            throw "MSERT exited with code $($process.ExitCode). Check %windir%\debug\msert.log"
        }
        
        return Get-Content "$env:windir\debug\msert.log" -Tail 500 | Select-String -Pattern "detected|removed|error" -CaseSensitive
    }
    catch { throw "MSERT operation failed: $_" }
    finally { Remove-Item $msertPath -ErrorAction SilentlyContinue }
}
#endregion

#region Enhanced System Checks
function Check-ScheduledTasks {
    try {
        Add-Log "Checking suspicious scheduled tasks..."
        $badTasks = Get-ScheduledTask | Where-Object {
            $_.TaskName -match "(?i)(Update|Malware|Temp|Script|Loader|Persistence)" -and 
            $_.State -eq "Ready" -and
            $_.Actions.Execute -match "\.(exe|dll|ps1|js|vbs|bat|cmd)$" -and
            $_.Author -notmatch "Microsoft|Windows"
        }
        
        $badTasks | Disable-ScheduledTask -ErrorAction Stop | Out-Null
        return $badTasks
    }
    catch { throw "Task check failed: $_" }
}

function Check-WMIMalware {
    try {
        Add-Log "Checking WMI for malware..."
        $suspiciousWMI = Get-WmiObject -Namespace root\subscription -Class __EventFilter -Filter '
            Name LIKE "%malware%" OR 
            Query LIKE "%malicious%" OR
            Query LIKE "%powershell%" OR
            Query LIKE "%encodedcommand%"
        ' -ErrorAction Stop
        
        $suspiciousWMI | Remove-WmiObject
        return $suspiciousWMI
    }
    catch { throw "WMI check failed: $_" }
}
#endregion

#region Enhanced Reporting
function Add-Log {
    param([string]$Message)
    "$(Get-Date -Format u) - $Message" | Out-File $logFile -Append
}

function Send-DiscordReport {
    param([string]$Message, [string]$File)
    try {
        $retryCount = 0
        $maxRetries = 3
        
        while ($retryCount -lt $maxRetries) {
            try {
                $boundary = [System.Guid]::NewGuid().ToString()
                $LF = "`r`n"
                
                $body = (
                    "--$boundary",
                    "Content-Disposition: form-data; name=`"content`"$LF",
                    $Message,
                    "--$boundary",
                    "Content-Disposition: form-data; name=`"file`"; filename=`"$(Split-Path $File -Leaf)`"",
