# Credit to https://azureis.fun/posts/Simplify-Azure-VM-App-deployment-with-WinGet/ and https://github.com/DeanCefola/Azure-WVD/blob/master/PowerShell/FSLogixSetup.ps1
#PowerShell wrapper script for WinGet

#List of apps that will be installed like this:
#silently
#scope: all users
#preferabbly from msstore

$DesktopPath = "c:\install"
Start-Transcript -Append "./log.txt"

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

$FSLogixURI = 'https://aka.ms/fslogix_download'
$FSInstaller = 'FSLogixAppsSetup.zip'

if ((test-path "$DesktopPath\$FSInstaller") -and (test-path "$DesktopPath\FSLogix") -eq $false) {

    Invoke-WebRequest -Uri $FSLogixURI -OutFile "$DesktopPath\$FSInstaller"

    Expand-Archive `
        -LiteralPath "C:\install\$FSInstaller" `
        -DestinationPath "$DesktopPath\FSLogix" `
        -Force `
        -Verbose
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    cd $DesktopPath 
    
    Add-Content -LiteralPath  C:\install\New-WVDSessionHost.log " $(Get-Date) Installing FSLogix"
    $fslogix_deploy_status = Start-Process `
        -FilePath "$DesktopPath\FSLogix\x64\Release\FSLogixAppsSetup.exe" `
        -ArgumentList "/install /quiet" `
        -Wait `
        -Passthru

}
else {
    Write-host "FSLogix installer already downloaded and presumed installed" -ForegroundColor Green
}

$apps = @(
    @{name = "Microsoft.PowerShell" }                            #MicrosoftPowerShell
    @{name = "Microsoft.Azure.AZCopy.10" }                       #AZCopy
    @{name = "JanDeDobbeleer.OhMyPosh" }                         #OhMyPosh
    @{name = "Microsoft.Azure.StorageExplorer" }                 #Azure Storage Explorer
    @{name = "Microsoft.AzureDataStudio" }                       #Azure Data Studio
    @{name = "Git.Git" }                                         #Git
    @{name = "Microsoft.VisualStudioCode" }                      #vscode
    #@{name = "Anaconda.Anaconda3" }                              #Anaconda - seems to crash winget install
    @{name = "PostgreSQL.pgAdmin" }                              #pgAdmin
    @{name = "OSGeo.QGIS" }                                  #QGIS LTR
    @{name = "Microsoft.SQLServerManagementStudio" }             #SSMS
    @{name = "Microsoft.DotNet.DesktopRuntime.8"}
    @{name = "github.cli"}
    @{name = "Microsoft.azurecli"}
    @{name = "jgraph.draw"}
    @{name = "putty.putty"}
    @{name = "WinSCP.WinSCP"}
    @{name = "hashicorp.terraform"} # geoserver terraform provider
    
)

Invoke-RestMethod https://raw.githubusercontent.com/miljodir/avd-scripts/main/utils/PsProfile.ps1 -OutFile c:\install\PsProfile.ps1
Invoke-RestMethod https://raw.githubusercontent.com/miljodir/avd-scripts/main/utils/ws-terminal-profile.json -OutFile c:\install\ws-terminal-profile.json

# Copy the profile to the default profile
$testpath = Test-Path -Path $PROFILE

if ($testpath -eq $false) {
    New-Item -ItemType Directory -Force -Path $PROFILE.CurrentUserCurrentHost
}
else {
    Copy-Item -Path c:\install\PsProfile.ps1 -Destination $PROFILE.CurrentUserCurrentHost -Force
}

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