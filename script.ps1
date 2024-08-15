# Define the list of computers to remove TeamViewer from
$ComputersToRemoveTeamViewerFrom = @("Computer1", "Computer2") # Replace with actual computer names

# Define log file path
$logPath = "C:\Temp\TeamViewerUninstallRemote.log"

# Function to log messages
function Write-Log {
    param (
        [string]$ComputerName,
        [string]$Message
    )
    Add-Content -Path $logPath -Value "$([DateTime]::Now) - $ComputerName - $Message"
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
    param (
        [string]$ComputerName
    )
    Write-Log -ComputerName $ComputerName -Message "Attempting to stop TeamViewer service."
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        param ($serviceName)
        try {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
            Write-Log -ComputerName $env:COMPUTERNAME -Message "Successfully stopped TeamViewer service."
        } catch {
            Write-Log -ComputerName $env:COMPUTERNAME -Message "Failed to stop TeamViewer service: $_"
        }
    } -ArgumentList "TeamViewer"
}

# Main script logic
$ComputersToRemoveTeamViewerFrom | ForEach-Object {
    $computerName = $_

    # Stop the TeamViewer service on the remote computer
    Stop-TeamViewerService -ComputerName $computerName

    # Start a remote PowerShell session on the computer.
    Invoke-Command -ComputerName $computerName -ScriptBlock {
        param ($logPath)

        # Log the start of the process
        Write-Log -ComputerName $env:COMPUTERNAME -Message "Starting TeamViewer uninstallation."

        try {
            # Find all apps installed on this machine.
            $AllApps = Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
            
            # Find the one named TeamViewer.
            $TeamViewer = $AllApps | Where-Object { $_.DisplayName -Like "TeamViewer*" }

            if ($TeamViewer) {
                foreach ($app in $TeamViewer) {
                    $uninstallString = $app.UninstallString
                    if ($uninstallString) {
                        # Log the uninstall process
                        Write-Log -ComputerName $env:COMPUTERNAME -Message "Found TeamViewer with uninstall string: $uninstallString"

                        # Remove quotes from the uninstall string if present
                        $uninstallString = $uninstallString.Trim('"')

                        # Execute the uninstall command with silent switch
                        Execute-Process -Path $uninstallString -Parameters '/S'

                        # Log successful uninstallation
                        Write-Log -ComputerName $env:COMPUTERNAME -Message "Successfully initiated uninstall for TeamViewer."
                    } else {
                        Write-Log -ComputerName $env:COMPUTERNAME -Message "No uninstall string found for TeamViewer."
                    }
                }
            } else {
                Write-Log -ComputerName $env:COMPUTERNAME -Message "TeamViewer not found on this machine."
            }
        } catch {
            # Log any errors encountered
            Write-Log -ComputerName $env:COMPUTERNAME -Message "Error encountered: $_"
        }

        # Log the completion of the process
        Write-Log -ComputerName $env:COMPUTERNAME -Message "Completed TeamViewer uninstallation process."
    } -ArgumentList $logPath
}
