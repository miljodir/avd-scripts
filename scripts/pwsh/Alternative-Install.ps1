# Credit to https://azureis.fun/posts/Simplify-Azure-VM-App-deployment-with-WinGet/ and https://github.com/DeanCefola/Azure-WVD/blob/master/PowerShell/FSLogixSetup.ps1
#PowerShell wrapper script for WinGet

#List of apps that will be installed like this:
#silently
#scope: all users
#preferabbly from msstore

$DesktopPath = "c:\temp"
Start-Transcript -Append "./log.txt"

if ((Test-Path c:\temp) -eq $false) {
    New-Item -ItemType Directory -Force -Path "c:\temp"
    Add-Content -LiteralPath C:\temp\New-WVDSessionHost.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
}

# credit to: https://github.com/ChrisTitusTech/winutil/blob/a1c7501b98d56c5b554f9cfe70cb5a0767385796/functions/private/Install-WinUtilWinget.ps1#L1

function Install-WinUtilWinget {
    
    <#
    
        .DESCRIPTION
        Function is meant to ensure winget is installed 
    
    #>
    Try {
        Write-Host "Checking if Winget is Installed..."
        if (Test-WinUtilPackageManager -winget) {
            #Checks if winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget Already Installed"
            return
        }

        #Gets the computer's information
        if ($null -eq $sync.ComputerInfo) {
            $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
        }
        Else {
            $ComputerInfo = $sync.ComputerInfo
        }

        if (($ComputerInfo.WindowsVersion) -lt "1809") {
            #Checks if Windows Version is too old for winget
            Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
            return
        }

        #Gets the Windows Edition
        $OSName = if ($ComputerInfo.OSName) {
            $ComputerInfo.OSName
        }
        else {
            $ComputerInfo.WindowsProductName
        }

        if (((($OSName.IndexOf("LTSC")) -ne -1) -or ($OSName.IndexOf("Server") -ne -1)) -and (($ComputerInfo.WindowsVersion) -ge "1809")) {

            Write-Host "Running Alternative Installer for LTSC/Server Editions"

            # Switching to winget-install from PSGallery from asheroto
            # Source: https://github.com/asheroto/winget-installer

            Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/winget.ps1 | iex | Out-Host" -WindowStyle Normal -ErrorAction Stop

            if (!(Test-WinUtilPackageManager -winget)) {
                break
            }
        }

        else {
            #Installing Winget from the Microsoft Store
            Write-Host "Winget not found, installing it now."
            Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
            $nid = (Get-Process AppInstaller).Id
            Wait-Process -Id $nid

            if (!(Test-WinUtilPackageManager -winget)) {
                break
            }
        }
        Write-Host "Winget Installed"
    }
    Catch {
        Write-Error "Failed to install winget"
    }
}

Install-WinUtilWinget

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

Add-Content -LiteralPath  C:\temp\New-WVDSessionHost.log "Installing FSLogix"
$fslogix_deploy_status = Start-Process `
    -FilePath "$LocalWVDpath\FSLogix\x64\Release\FSLogixAppsSetup.exe" `
    -ArgumentList "/install /quiet" `
    -Wait `
    -Passthru

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