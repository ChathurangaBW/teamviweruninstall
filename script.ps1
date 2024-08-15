# Define the registry paths to search for installed applications
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Loop through each uninstall path
foreach ($path in $uninstallPaths) {
    # Get all installed applications
    $installedApps = Get-ItemProperty $path -ErrorAction SilentlyContinue

    foreach ($app in $installedApps) {
        # Check if the application name contains "TeamViewer"
        if ($app.DisplayName -like "*TeamViewer*") {
            # Check if the uninstall string exists
            if ($app.UninstallString) {
                # Check for the presence of quotes in the uninstall string
                $uninstallCommand = $app.UninstallString
                if ($uninstallCommand -match '"(.*)"') {
                    $uninstallExe = $matches[1]
                    $arguments = $uninstallCommand -replace '"[^"]*"', '' # Remove the executable path from the command
                    # Run the uninstall command silently
                    Write-Host "Uninstalling $($app.DisplayName)..."
                    Start-Process -FilePath $uninstallExe -ArgumentList $arguments, "/S" -Wait
                    Write-Host "$($app.DisplayName) has been uninstalled."
                } else {
                    # If the uninstall string does not have quotes, run it directly
                    Write-Host "Uninstalling $($app.DisplayName)..."
                    Start-Process -FilePath $uninstallCommand -ArgumentList "/S" -Wait
                    Write-Host "$($app.DisplayName) has been uninstalled."
                }
            }
        }
    }
}
