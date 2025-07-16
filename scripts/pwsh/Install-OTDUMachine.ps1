# Credit to https://azureis.fun/posts/Simplify-Azure-VM-App-deployment-with-WinGet/
#PowerShell wrapper script for WinGet

$DesktopPath = "c:\install"
Start-Transcript -Append "./log.txt"

Write-Host "Installing powershell modules for Windows Update"
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PSWindowsUpdate -Force

if ((Test-Path c:\install) -eq $false) {
    New-Item -ItemType Directory -Force -Path "c:\install"
    Add-Content -LiteralPath C:\install\New-WVDSessionHost.log " $(Get-Date) Create C:\install Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating install directory"
}

# Pre-installed winget on win 11 is buggy and should be removed and reinstalled with latest version
# https://github.com/microsoft/winget-cli/issues/3832#issuecomment-1872387214
function Install-WinUtilWinget {
    
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile c:\install\winget.msixbundle
    Start-sleep 3
    Add-AppxPackage -ForceApplicationShutdown -Path c:\install\winget.msixbundle
    Remove-Item -Path c:\install\winget.msixbundle -Force
}

if ((winget --version) -like "v1.2*") {
    Add-Content -LiteralPath C:\install\New-WVDSessionHost.log " $(Get-Date) Reinstalling winget"
    Install-WinUtilWinget
}

$apps = @(
    @{name = "Microsoft.PowerShell" }
    @{name = "RoyalApps.RoyalTS" }
)

#Check if WinGet is installed:

$WingetInstalled = Get-Command winget
$errorlog = "winget_error.log"

if (!$WingetInstalled) {
    Write-Host -ForegroundColor Red "WinGet is not installed! End of script"
    #Winget can be installed if missing
    break
}

Write-Host -ForegroundColor Cyan " $(Get-Date) Installing new and upgrading already installed Apps..."
Foreach ($app in $apps) {
    $listApp = winget list --accept-package-agreements --exact -q $app.name
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-Host -ForegroundColor Yellow  " $(Get-Date) Install:" $app.name
        # MS Store apps
        if ($app.source -ne $null) {
            winget install --exact --accept-package-agreements --accept-source-agreements $app.name --source $app.source
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
                Write-Host "$(Get-Date) local time"
                Write-Host -ForegroundColor Green $app.name "successfully installed."
                (Get-Date).ToString() + $app.name + "successfully installed." | Add-Content "$DesktopPath\$errorlog"
            }
            else {
                Write-Host "$(Get-Date) local time"
                (Get-Date).ToString() + $app.name + " couldn't be installed." | Add-Content "$DesktopPath\$errorlog"
                Write-Host
                Write-Host -ForegroundColor Red $app.name "couldn't be installed."
                Write-Host -ForegroundColor Yellow "Write in $DesktopPath\$errorlog"
                Write-Host
                #Pause
            }    
        }
        # All other Apps
        else {
            winget install --exact --scope machine --accept-package-agreements --accept-source-agreements $app.name
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
                Write-Host "$(Get-Date) local time"
                Write-Host -ForegroundColor Green $app.name "successfully installed."
                (Get-Date).ToString() + $app.name + "successfully installed." | Add-Content "$DesktopPath\$errorlog"
            }
            else {
                Write-Host "$(Get-Date) local time"
                (Get-Date).ToString() + $app.name + " couldn't be installed." | Add-Content "$DesktopPath\$errorlog"
                $app.name + " couldn't be installed." | Add-Content "$DesktopPath\$errorlog"
                Write-Host
                Write-Host -ForegroundColor Red $app.name "couldn't be installed."
                Write-Host -ForegroundColor Yellow "Write in $DesktopPath\$errorlog"
                Write-Host
                #Pause
            }  
        }
    }
    else {
        Write-Host -ForegroundColor Yellow " $(Get-Date) Skip installation of" $app.name
    }
}

Stop-Transcript
Copy-Item -Path .\log.txt -Destination c:\install\install-log.txt -Force
