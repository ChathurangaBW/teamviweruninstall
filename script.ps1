# Function to stop any running TeamViewer processes
function Stop-TeamViewerProcesses {
    try {
        Stop-Process -Name "TeamViewer" -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped any running TeamViewer processes."
    } catch {
        Write-Host "No running TeamViewer processes found."
    }
}

# Function to uninstall TeamViewer using the uninstall string from the registry
function Uninstall-TeamViewer {
    param (
        [string]$uninstallString
    )

    try {
        Write-Host "Uninstalling using command: $uninstallString"
        Start-Process -FilePath $uninstallString -ArgumentList "/S" -Wait
        Write-Host "TeamViewer has been uninstalled."
    } catch {
        Write-Host "Error during uninstallation: $($_.Exception.Message)"
    }
}

# Function to clean up leftover files and registry entries
function Clean-Up-TeamViewer {
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
}

# Main script execution
try {
    # Stop any running TeamViewer processes
    Stop-TeamViewerProcesses

    # Define registry paths for uninstall
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    # Loop through each uninstall path to find and uninstall TeamViewer
    foreach ($path in $uninstallPaths) {
        $installedApps = Get-ItemProperty $path -ErrorAction SilentlyContinue
        foreach ($app in $installedApps) {
            if ($app.DisplayName -like "*TeamViewer*") {
                Write-Host "Found $($app.DisplayName). Uninstalling..."
                if ($app.UninstallString) {
                    Uninstall-TeamViewer -uninstallString $app.UninstallString
                }
            }
        }
    }

    # Clean up any remaining files and registry entries
    Clean-Up-TeamViewer

    Write-Host "All TeamViewer installations and remnants have been removed."

} catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
}
