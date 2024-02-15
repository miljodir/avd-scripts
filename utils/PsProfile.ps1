#this is the profile file that will be added for all users

#Set oh-my-posh theme
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cloud-native-azure.omp.json" | Invoke-Expression

#Sets terminal settings
if (!(Get-Item $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json)) {
    #Incase file does not exists
    Copy-Item -Path c:\install\ws-terminal-profile.json -Destination $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Force
}
else {
    $settings = Get-Content $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -raw | ConvertFrom-Json
    if (!($settings.profiles.defaults.startingDirectory)) {
        #Set default starting directory to userprofile
        $settings.profiles.defaults | Add-Member -Type NoteProperty -Name 'startingDirectory' -Value '%USERPROFILE%'
    }
    if (!($settings.profiles.defaults.font)) {
        #Sets default font
        $font = New-Object -TypeName PSObject -Property @{face = 'LiterationMono Nerd Font' }
        $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'font' -Value $font
    }
    if (!($settings.profiles.list | Where-Object name -eq 'Git Bash')) {
        #Adds git bash profile
        $guid = '{' + [guid]::NewGuid() + '}'
        $gitbash = New-Object -TypeName PSObject -Property @{name = 'Git Bash'; commandline = 'C:\Program Files\Git\bin\bash.exe'; icon = 'C:\Program Files\Git\mingw64\share\git\git-for-windows.ico'; guid = $guid }
        $settings.profiles.list += $gitbash
    }

    #Hide cmd and old ps from list
    if (($settings.profiles.list | Where-Object name -eq 'Command Prompt').hidden -eq $false) {
        ($settings.profiles.list | Where-Object name -eq 'Command Prompt').hidden = $true
    }
    if (($settings.profiles.list | Where-Object name -eq 'Windows PowerShell').hidden -eq $false) {
        ($settings.profiles.list | Where-Object name -eq 'Windows PowerShell').hidden = $true
    }
    $settings | ConvertTo-Json -Depth 32 | Out-File $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
}

# Aliases

Set-Alias grep Select-String

function touch ($name) {
    New-Item -Path . -Name $name
}

function New-BashStyleAlias([string]$name, [string]$command) {
    $sb = [scriptblock]::Create($command)
    New-Item "Function:\global:$name" -Value $sb -Force | Out-Null
}
# Quick Folder movement
New-BashStyleAlias home 'cd ~'
New-BashStyleAlias .. 'cd ..'
New-BashStyleAlias ... "cd ../../"
New-BashStyleAlias .... "cd ../../../"
New-BashStyleAlias ..... "cd ../../../../"
