function Decrypt-File($path) {
    $key = 'hormonereplacementtherapy'
    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($key.PadRight(32))

    $fsIn = New-Object System.IO.FileStream $path, 'Open'
    
    # Read IV from beginning of file
    $iv = New-Object byte[] $aes.IV.Length
    $fsIn.Read($iv, 0, $iv.Length) | Out-Null
    $aes.IV = $iv

    $decryptor = $aes.CreateDecryptor()
    $outputPath = $path -replace '\.encrypted$'
    
    $fsOut = New-Object System.IO.FileStream $outputPath, 'Create'
    $cs = New-Object System.Security.Cryptography.CryptoStream $fsOut, $decryptor, 'Write'
    $fsIn.CopyTo($cs)
    
    $cs.Close()
    $fsIn.Close()
    Remove-Item $path
}

# Usage: Decrypt all .encrypted files
Get-ChildItem -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) -Recurse -File -Filter *.encrypted | % {
    Decrypt-File $_.FullName
}
