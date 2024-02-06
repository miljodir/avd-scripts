
function Install-Program {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Type = "winget"
    )
    $AllPrograms = Get-Content $Path | Out-String | ConvertFrom-Json
    ForEach ($row in $AllPrograms.programs) {
        $ProgramName = $row.name
        $ProgramInstallation = $row.installation
        if ($ProgramInstallation -eq $true) {
            Write-Output "`n [ START ] installing $ProgramName"
            $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
            $ProgramSlug = $row.program

            if ($Type -eq "winget") {
                winget install -e --id $ProgramSlug
            }
            elseif ($Type -eq "choco") {
                choco install $ProgramSlug -y
            }

            $StopWatch.Stop()
            $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
            Write-Output " [ DONE ] installing $ProgramName ... $StopWatchElapsed  seconds`n"
        }
    }
}