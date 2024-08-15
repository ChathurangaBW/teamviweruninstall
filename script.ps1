$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TeamViewer 11 Host_is1",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\TeamViewer 11 Host_is1"
)

foreach ($key in $uninstallKeys) {
    if (Test-Path $key) {
        $uninstallString = (Get-ItemProperty -Path $key -Name UninstallString).UninstallString
        if ($uninstallString -match '"(.+?)"') {
            $uninstallExe = $matches[1]
            Start-Process -FilePath $uninstallExe -ArgumentList "/S" -Wait
        }
    }
}
