# Function to uninstall TeamViewer using WMIC
function Uninstall-TeamViewer {
    param (
        [string]$appName
    )

    try {
        Write-Host "Attempting to uninstall $appName..."
        $result = wmic product where "name='$appName'" call uninstall /nointeractive
        if ($result.ReturnValue -eq 0) {
            Write-Host "$appName has been uninstalled successfully."
        } else {
            Write-Host "Failed to uninstall $appName. Return code: $($result.ReturnValue)"
        }
    } catch {
        Write-Host "Error during uninstallation of $appName: ${$_}"  # Correctly reference the error variable
    }
}

# Define the registry paths to search for installed applications
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Check for and stop any running TeamViewer processes
try {
    Stop-Process -Name "TeamViewer" -Force -ErrorAction SilentlyContinue
    Write-Host "Stopped any running TeamViewer processes."
} catch {
    Write-Host "No running TeamViewer processes found."
}

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

# Attempt to uninstall TeamViewer 11 Host using WMIC
Uninstall-TeamViewer -appName "TeamViewer 11 Host"

# Attempt to uninstall TeamViewer 11 Host (MSI Wrapper) using WMIC
Uninstall-TeamViewer -appName "TeamViewer 11 Host (MSI Wrapper)"

# Attempt to uninstall TeamViewer 15 if present
Uninstall-TeamViewer -appName "TeamViewer 15"

# Directly call the uninstall executable if known
$teamViewerUninstallPath = "C:\Program Files\TeamViewer\uninstall.exe"
if (Test-Path $teamViewerUninstallPath) {
    Write-Host "Directly calling the uninstall executable..."
    Start-Process -FilePath $teamViewerUninstallPath -ArgumentList "/S" -Wait
    Write-Host "TeamViewer has been uninstalled using the direct uninstall executable."
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
                Write-Host "Failed to uninstall $($msiApp.DisplayName). Error: ${$_}"  # Correctly reference the error variable
            }
        }
    }
}

# Final check for any remaining TeamViewer installations
$remainingApps = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%TeamViewer%'"
if ($remainingApps) {
    foreach ($app in $remainingApps) {
        Write-Host "Found remaining installation: $($app.Name). Attempting to uninstall..."
        try {
            $app.Uninstall()
            Write-Host "$($app.Name) has been uninstalled."
        } catch {
            Write-Host "Failed to uninstall $($app.Name). Error: ${$_}"  # Correctly reference the error variable
        }
    }
}

# Forcefully remove any remaining files and registry entries if necessary
$teamViewerPaths = @(
    "C:\Program Files\TeamViewer",
    "C:\Program Files (x86)\TeamViewer",
    "C:\ProgramData\TeamViewer",
    "C:\Users\$env:USERNAME\AppData\Local\TeamViewer",
    "C:\Users\$env:USERNAME\AppData\Roaming\TeamViewer"
)

foreach ($path in $teamViewerPaths) {
    if (Test-Path $path) {
        Write-Host "Removing remaining files at $path..."
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Clean up registry entries
$teamViewerRegistryPaths = @(
    "HKLM:\SOFTWARE\TeamViewer",
    "HKLM:\SOFTWARE\Wow6432Node\TeamViewer",
    "HKCU:\Software\TeamViewer"
)

foreach ($regPath in $teamViewerRegistryPaths) {
    if (Test-Path $regPath) {
        Write-Host "Removing registry key $regPath..."
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "All TeamViewer installations and remnants have been removed."
