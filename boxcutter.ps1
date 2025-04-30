function Decrypt-File($path){
    $aes=New-Object System.Security.Cryptography.AesManaged
    $aes.Key=[System.Text.Encoding]::UTF8.GetBytes('hormonereplacementtherapy'.PadRight(32))
    $decryptor=$aes.CreateDecryptor()
    $fsIn=New-Object System.IO.FileStream $path,'Open'
    $fsOut=New-Object System.IO.FileStream ($path -replace '\.encrypted$'),'Create'
    $cs=New-Object System.Security.Cryptography.CryptoStream $fsOut,$decryptor,'Write'
    $fsIn.CopyTo($cs)
    $cs.Close()
    $fsIn.Close()
    Remove-Item $path
}
