# Define the registry paths to search for installed applications
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Loop through each uninstall path to find TeamViewer installations
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

# Attempt to uninstall the MSI Wrapper using WMIC
try {
    Write-Host "Attempting to uninstall TeamViewer 11 Host (MSI Wrapper)..."
    wmic product where "name='TeamViewer 11 Host (MSI Wrapper)'" call uninstall /nointeractive
    Write-Host "TeamViewer 11 Host (MSI Wrapper) has been uninstalled."
} catch {
    Write-Host "Failed to uninstall TeamViewer 11 Host (MSI Wrapper). Error: $_"
}

# Additional cleanup for any remaining TeamViewer installations
$msiUninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\*"
)

foreach ($msiPath in $msiUninstallPaths) {
    $msiInstalledApps = Get-ItemProperty $msiPath -ErrorAction SilentlyContinue

    foreach ($msiApp in $msiInstalledApps) {
        if ($msiApp.DisplayName -like "*TeamViewer*") {
            Write-Host "Attempting to uninstall MSI version of $($msiApp.DisplayName)..."
            try {
                # Use msiexec to uninstall the MSI version
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($msiApp.PSChildName) /quiet" -Wait
                Write-Host "$($msiApp.DisplayName) has been uninstalled."
            } catch {
                Write-Host "Failed to uninstall $($msiApp.DisplayName). Error: $_"
            }
        }
    }
}
