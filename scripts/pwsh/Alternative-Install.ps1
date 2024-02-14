# Credit to https://azureis.fun/posts/Simplify-Azure-VM-App-deployment-with-WinGet/ and https://github.com/DeanCefola/Azure-WVD/blob/master/PowerShell/FSLogixSetup.ps1
#PowerShell wrapper script for WinGet

#List of apps that will be installed like this:
#silently
#scope: all users
#preferabbly from msstore

$DesktopPath = "c:\temp"
Start-Transcript -Append "./log.txt"

if ((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
}

$FSLogixURI = 'https://aka.ms/fslogix_download'
$FSInstaller = 'FSLogixAppsSetup.zip'
Invoke-WebRequest -Uri $FSLogixURI -OutFile "$DesktopPath\$FSInstaller"

Expand-Archive `
    -LiteralPath "C:\temp\$FSInstaller" `
    -DestinationPath "$DesktopPath\FSLogix" `
    -Force `
    -Verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
cd $DesktopPath 

$apps = @(
    @{name = "Microsoft.PowerShell" }                            #MicrosoftPowerShell
    @{name = "Microsoft.Azure.AZCopy.10" }                       #AZCopy
    @{name = "JanDeDobbeleer.OhMyPosh" }                         #OhMyPosh
    @{name = "Microsoft.Azure.StorageExplorer" }                 #Azure Storage Explorer
    @{name = "Anaconda.Anaconda3" }                              #Anaconda
    @{name = "PostgreSQL.pgAdmin" }                              #pgAdmin
    @{name = "OSGeo.QGIS_LTR" }                                  #QGIS LTR
    @{name = "Microsoft.SQLServerManagementStudio" }             #SSMS
    @{name = "Microsoft.AzureDataStudio" }                       #Azure Data Studio
    @{name = "Git.Git" }                                         #Git
    @{name = "Microsoft.WindowsTerminal" }                       #Windows Terminal
    @{name = "Microsoft.VisualStudioCode" }                      #vscode
    
)

#Check if WinGet is installed:

$WingetInstalled = Get-Command winget
$errorlog = "winget_error.log"

if (!$WingetInstalled) {
    Write-Host -ForegroundColor Red "WinGet is not installed! End of script"
    #Winget can be installed if missing
    break
}

Write-Host -ForegroundColor Cyan "Installing new Apps..."
Foreach ($app in $apps) {
    $listApp = winget list --accept-package-agreements --exact -q $app.name
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-Host -ForegroundColor Yellow  "Install:" $app.name
        # MS Store apps
        if ($app.source -ne $null) {
            winget install --exact --accept-package-agreements --accept-source-agreements $app.name --source $app.source
            if ($LASTEXITCODE -eq 0) {
                Write-Host -ForegroundColor Green $app.name "successfully installed."
            }
            else {
                $app.name + " couldn't be installed." | Add-Content "$DesktopPath\$errorlog"
                Write-Host
                Write-Host -ForegroundColor Red $app.name "couldn't be installed."
                Write-Host -ForegroundColor Yellow "Write in $DesktopPath\$errorlog"
                Write-Host
                Pause
            }    
        }
        # All other Apps
        else {
            winget install --exact --scope machine --accept-package-agreements --accept-source-agreements $app.name
            if ($LASTEXITCODE -eq 0) {
                Write-Host -ForegroundColor Green $app.name "successfully installed."
            }
            else {
                $app.name + " couldn't be installed." | Add-Content "$DesktopPath\$errorlog"
                Write-Host
                Write-Host -ForegroundColor Red $app.name "couldn't be installed."
                Write-Host -ForegroundColor Yellow "Write in $DesktopPath\$errorlog"
                Write-Host
                Pause
            }  
        }
    }
    else {
        Write-Host -ForegroundColor Yellow "Skip installation of" $app.name
    }
}

Stop-Transcript
Copy-Item -Path .\log.txt -Destination c:\temp\install-log.txt -Force