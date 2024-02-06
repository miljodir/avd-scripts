Start-Transcript -Append "./custom-install-log.txt"

Write-Host "installing powershell 7"
msiexec.exe /package PowerShell-7.3.4-win-x64.msi /quiet

Write-Host "Copying files to C:\install"
New-Item -ItemType Directory -Force -Path c:\install
Copy-Item -Path ./* -Destination c:\install -Include "*.ps1", "*.jsonc", "*.json", "*.msixbundle"

Write-Host "=========================`n"

Write-Host "Unzipping all zips"
foreach ($f in $(Get-ChildItem -Path .\* -Include *.zip)) {
    Expand-Archive -Path $f.fullName -DestinationPath ./ -Force
    Remove-Item -Path $f.fullName -Force
}

Write-Host "Installing fonts"
foreach ($f in $(Get-ChildItem -Path .\* -Include *.ttf)) {
    try {
        $font = $f.fullName | split-path -Leaf
        If (!(Test-Path "c:\windows\fonts\$($font)")) {
            switch (($font -split "\.")[-1]) {
                "TTF" {
                    $fn = "$(($font -split "\.")[0]) (TrueType)"
                    break
                }
                "OTF" {
                    $fn = "$(($font -split "\.")[0]) (OpenType)"
                    break
                }
            }
            Copy-Item -Path $f.fullName -Destination "C:\Windows\Fonts\$font" -Force
            New-ItemProperty -Name $fn -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $font | Out-Null
            Write-Host $fn ":" $font " - added to registry"
        }
    }
    catch {
        write-warning $_.exception.message
    }
}

Copy-Item -Path ../utils/ws-terminal-profile.json -Destination c:\ws-terminal-profile.json -Force
# Copy the profile to the default profile
Copy-Item -Path ../utils/ps-profile.ps1 -Destination $PROFILE.AllUsersCurrentHost -Force

. ../utils/Install-WingetProgram.ps1
Install-WingetProgram -Path ../utils/hp-install-winget.jsonc -Type winget

Write-Host "Copies acl from link to target exe"
foreach ($f in (Get-Item 'C:\Program Files\WinGet\Links\*')) {
    $acl = Get-Acl -Path $f.Target
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl -Path $f.Target
}

Write-Host "### Done installing ###"

Stop-Transcript
