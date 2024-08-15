# Define log file path
$logPath = "C:\Temp\TeamViewerUninstall.log"

# Function to log messages
function Write-Log {
    param (
        [string]$Message
    )
    Add-Content -Path $logPath -Value "$([DateTime]::Now) - $Message"
}

# Function to execute a process
function Execute-Process {
    param (
        [string]$Path,
        [string]$Parameters
    )
    Start-Process -FilePath $Path -ArgumentList $Parameters -Wait -NoNewWindow
}

# Function to stop the TeamViewer service
function Stop-TeamViewerService {
    Write-Log -Message "Attempting to stop TeamViewer service."
    try {
        Stop-Service -Name "TeamViewer" -Force -ErrorAction Stop
        Write-Log -Message "Successfully stopped TeamViewer service."
    } catch {
        Write-Log -Message "Failed to stop TeamViewer service: $_"
    }
}

# Main script logic
# Stop the TeamViewer service
Stop-TeamViewerService

# Start the uninstallation process
Write-Log -Message "Starting TeamViewer uninstallation."

try {
    # Find all apps installed on this machine.
    $AllApps = Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    
    # Find the one named TeamViewer.
    $TeamViewer = $AllApps | Where-Object { $_.DisplayName -Like "TeamViewer*" }

    if ($TeamViewer) {
        foreach ($app in $TeamViewer) {
            $uninstallString = $app.UninstallString
            if ($uninstallString) {
                # Ensure the uninstall string is properly formatted for silent uninstallation
                $uninstallString = $uninstallString.Trim('"')
                Write-Log -Message "Found TeamViewer with uninstall string: $uninstallString"

                # Execute the uninstall command with silent switch
                Execute-Process -Path $uninstallString -Parameters '/S'

                # Log successful uninstallation
                Write-Log -Message "Successfully initiated silent uninstall for TeamViewer."
            } else {
                Write-Log -Message "No uninstall string found for TeamViewer."
            }
        }
    } else {
        Write-Log -Message "TeamViewer not found on this machine."
    }
} catch {
    # Log any errors encountered
    Write-Log -Message "Error encountered: $_"
}

# Log the completion of the process
Write-Log -Message "Completed TeamViewer uninstallation process."
