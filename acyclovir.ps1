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
