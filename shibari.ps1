# Vulnerability Scanner with Secure Reporting
# Usage: Run as Administrator

param(
    [Parameter(Mandatory=$true)]
    [string]$DiscordWebhook,
    [string]$ReportPath = "$env:TEMP\SecurityAudit-$(Get-Date -f yyyyMMddHHmm).txt"
)

# Initialization
$ErrorActionPreference = "Stop"
$webhookValidated = $false

# Check administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrative privileges"
    exit 1
}

# Validate Discord webhook format
if ($DiscordWebhook -notmatch '^https://discord\.com/api/webhooks/\d+/[\w-]+$') {
    Write-Error "Invalid Discord webhook format"
    exit 1
}

# Configure TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Vulnerability Checks
$securityChecks = @{
    'UAC Status' = {
        try {
            (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA).EnableLUA -ne 1
        }
        catch { $false }
    }
    
    'SMBv1 Enabled' = {
        try {
            (Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop).State -eq 'Enabled'
        }
        catch { $false }
    }
    
    'PowerShell v2' = {
        try {
            (Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -ErrorAction Stop).State -eq 'Enabled'
        }
        catch { $false }
    }
    
    'Unquoted Service Paths' = {
        try {
            Get-CimInstance -ClassName Win32_Service | Where-Object {
                $_.PathName -match '^[^"].*\s.+\.exe' -and $_.PathName -notmatch '^"'
            }
        }
        catch { $null }
    }
    
    'Admin Users' = {
        try {
            ([adsi]"WinNT://$env:COMPUTERNAME").Children | Where-Object {
                $_.SchemaClassName -eq 'User' -and 
                ($_.Groups() | Where-Object { $_.Name -eq 'Administrators' })
            } | Select-Object -ExpandProperty Name
        }
        catch { $null }
    }
}

# Main Execution
try {
    # Create report header
    "=== Vulnerability Scan Report ===`n" | Out-File $ReportPath
    "Scan Timestamp: $(Get-Date -Format u)`n" | Out-File $ReportPath -Append

    # Run security checks
    foreach ($check in $securityChecks.GetEnumerator()) {
        try {
            $result = & $check.Value
            $status = if ($result) { "VULNERABLE" } else { "Secure" }
            
            if ($check.Key -eq 'Admin Users' -and $result) {
                "Admin Users:`n$($result -join "`n")" | Out-File $ReportPath -Append
            }
            else {
                "$($check.Key): $status" | Out-File $ReportPath -Append
            }
        }
        catch {
            "$($check.Key): Check failed - $($_.Exception.Message)" | Out-File $ReportPath -Append
        }
    }

    # Network Information
    "`n=== Network Configuration ===" | Out-File $ReportPath -Append
    ipconfig /all | Out-File $ReportPath -Append
    "`nActive Connections:" | Out-File $ReportPath -Append
    netstat -ano | Select-String -Pattern 'ESTABLISHED|LISTEN' | Out-File $ReportPath -Append

    # Upload report
    $uploadResult = curl.exe -F "file1=@$ReportPath" $DiscordWebhook 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Upload failed: $uploadResult"
    }
}
catch {
    Write-Error "Scan failed: $_"
    exit 1
}
finally {
    # Secure cleanup
    if (Test-Path $ReportPath) {
        Remove-Item $ReportPath -Force -ErrorAction SilentlyContinue
    }
}
