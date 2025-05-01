# Enhanced Malware Removal Automation Script
# Usage: Run as Administrator

param(
    [string]$DiscordWebhook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY",
    [ValidateSet("Quick","Full","Offline")][string]$ScanType = "Full",
    [int]$ScanTimeout = 14400  # 4 hour timeout
)

#region Initialization
$ErrorActionPreference = "Stop"
$tempDir = $env:TEMP
$logFile = "$tempDir\MalwareScan-$(Get-Date -f yyyyMMddHHmm).txt"

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

try {
    # Initial checks
    Test-TamperProtection
    
    # Initialize report
    "=== Windows Defender Scan Report ===" | Out-File $logFile
    "Scan started: $(Get-Date -Format u)" | Out-File $logFile -Append

    # Update Defender signatures with retry logic
    try {
        Update-MpSignature -UpdateSource MicrosoftUpdateServer -ErrorAction Stop
        "Signature update completed" | Out-File $logFile -Append
    }
    catch {
        "WARNING: Automatic update failed. Attempting manual fallback..." | Out-File $logFile -Append
        & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate -MMPC
    }

    # Start scan
    $scan = Start-MpScan -ScanType $ScanType -AsJob -ErrorAction Stop
    
    # Monitor progress
    while ($scan.State -eq 'Running') {
        $progress = (Get-MpComputerStatus).FullScanProgress
        "Scan progress: $progress%" | Out-File $logFile -Append
        Start-Sleep -Seconds 30
    }

    # Get results
    $threats = Get-CimInstance -Namespace root/Microsoft/Windows/Defender -ClassName MSFT_MpThreat
    
    if ($threats) {
        "`n=== Detected Threats ===" | Out-File $logFile -Append
        $threats | Select-Object ThreatName,Path,Severity | Format-Table -AutoSize | Out-File $logFile -Append
    }
    else {
        "`nNo threats detected" | Out-File $logFile -Append
    }

    # Protection status
    "`n=== Protection Status ===" | Out-File $logFile -Append
    Get-MpComputerStatus | Select-Object AntivirusEnabled,AntivirusSignatureAge,RealTimeProtectionEnabled | Format-List | Out-File $logFile -Append

    # Upload to Discord
    curl.exe -F "file1=@$logFile" $DiscordWebhook
}
catch {
    $errorMsg = "ERROR: $($_.Exception.Message)`nStack Trace: $($_.ScriptStackTrace)"
    $errorMsg | Out-File $logFile -Append
    curl.exe -F "file1=@$logFile" $DiscordWebhook
}
finally {
    if (Test-Path $logFile) {
        Remove-Item $logFile -Force -ErrorAction SilentlyContinue
    }
}
