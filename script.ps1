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
                # Extract the uninstall command
                $uninstallCommand = $app.UninstallString

                # Handle the command based on whether it has quotes
                if ($uninstallCommand -match '"(.+?)"') {
                    $uninstallExe = $matches[1]
                    $arguments = $uninstallCommand -replace '"[^"]*"', '' # Remove the executable path from the command
                    # Run the uninstall command silently
                    Write-Host "Uninstalling $($app.DisplayName)..."
                    Start-Process -FilePath $uninstallExe -ArgumentList "/S" -Wait
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

# Additional cleanup for TeamViewer installations that might not be found via the uninstall string
$msiUninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\*"
)

foreach ($msiPath in $msiUninstallPaths) {
    $msiInstalledApps = Get-ItemProperty $msiPath -ErrorAction SilentlyContinue

    foreach ($msiApp in $msiInstalledApps) {
        if ($msiApp.DisplayName -like "*TeamViewer*") {
            Write-Host "Uninstalling MSI version of $($msiApp.DisplayName)..."
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($msiApp.PSChildName) /quiet" -Wait
            Write-Host "$($msiApp.DisplayName) has been uninstalled."
        }
    }
}
