#Short scripts that needs to be run by admin on VM
Write-Host "Installing winget"
$winget = Get-Item .\*msixbundle
Add-AppxPackage -Path $winget.FullName #Installs winget for the current user

# TODO - ensure choco in path

git clone https://github.com/miljodir/avd-scripts.git && Set-Location ./avd-scripts

. .utils\Install-Program.ps1
Install-Program -Path ./programs/winget.jsonc -Type winget
Install-Program -Path ./programs/aksmgt-choco.jsonc -Type choco