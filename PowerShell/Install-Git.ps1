function Install-LatestGit {
    [CmdletBinding()]
    param (
        [string] $Sku = "32"
    )

    function Get-CurrentGitVersion {
        $gitExePath = "C:\Program Files\Git\bin\git.exe"

        if (!(Test-Path $gitExePath)) {
            return $null
        } else {
            (git version) -match "(\d*\.\d*\.\d*)" | Out-Null
            return $matches[0].split('.')
        }
    }

    function Get-LatestGitVersion {
        [CmdletBinding()]
        param (
            [string] $Sku
        )

        foreach ($asset in (Invoke-RestMethod https://api.github.com/repos/git-for-windows/git/releases/latest).assets) {
            if ($asset.name -match ('Git-\d*\.\d*\.\d*-' + $Sku + '-bit\.exe')) {
                $name = $asset.name
                $name -match "(\d*\.\d*\.\d*)" | Out-Null
                $version = $matches[0].split('.')
                return @{
                    'Name'        = $asset.name
                    'Version'     = $version
                    'DownloadURL' = $asset.browser_download_url
                }
            }
        }
        return $null
    }

    function Install-Git {
        [CmdletBinding()]
        param (
            [string] $DownloadUrl
        )

        Write-Host "Start downloading latest version of Git."
        Remove-Item -Force $env:TEMP\git-installation.exe -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $env:TEMP\git-installation.exe
        Write-Host "Download latest version of Git complete" -ForegroundColor Green

        Write-Host "Installing Git."
        Start-Process -Wait $env:TEMP\git-installation.exe -ArgumentList /silent
        Write-Host "Git Installation complete." -ForegroundColor Green
    }

    $LatestGit = Get-LatestGitVersion -sku $sku
    if (!$LatestGit) {
        $NotFindGitError = New-Object System.NotSupportedException "Cannot get the inforamtion about latest Git."
        throw $NotFindGitError
    }

    $CurrentGitVersion = Get-CurrentGitVersion
    if ($CurrentGitVersion) {
        Write-Host "Already installed Git, version is $CurrentGitVersion." -ForegroundColor Yellow

        if (($LatestGit.Version[0] -gt $CurrentGitVersion[0]) -or
            ($LatestGit.Version[0] -eq $CurrentGitVersion[0] -and
             $LatestGit.Version[1] -gt $CurrentGitVersion[1]) -or
            ($LatestGit.Version[0] -eq $CurrentGitVersion[0] -and
             $LatestGit.Version[1] -eq $CurrentGitVersion[1] -and
             $LatestGit.Version[2] -gt $CurrentGitVersion[2])
        ) {
            Write-Host "Current Git version is old, newer version is " + $LatestGit.Version + ". Try update Git." -ForegroundColor Yellow

            Write-Host "Check ssh-agent process" -ForegroundColor Yellow
            $sshagentrunning = get-process ssh-agent -ErrorAction SilentlyContinue
            if ($sshagentrunning) {
                Write-Host "Try killing ssh-agent process." -ForegroundColor Yellow
                Stop-Process $sshagentrunning.Id
                Write-Host "Killed ssh-agent process." -ForegroundColor Green
            }
            Write-Host "No ssh-agent process still running." -ForegroundColor Green
            Install-Git -DownloadUrl $LatestGit.DownloadURL
        } else {
            Write-Host "Already have latest version of Git." -ForegroundColor Green
        }
    } else {
        Write-Host "Git is not installed." -ForegroundColor Yellow
        Install-Git -DownloadUrl $LatestGit.DownloadURL
    }
}
