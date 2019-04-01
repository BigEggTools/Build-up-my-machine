function Install-LatestGit {
    [CmdletBinding()]
    param (
        [string] $Sku = "64"
    )

    function Get-CurrentGitVersion {
        if (Get-Command git -errorAction SilentlyContinue) {
            (git version) -match "(\d*\.\d*\.\d*)" | Out-Null
            return $matches[0].split('.')
        } else {
            return $null
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

        Write-Host "[Git] Start downloading latest version of Git."
        Remove-Item -Force $env:TEMP\git-installer.exe -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $env:TEMP\git-installer.exe
        Write-Host "[Git] Download latest version of Git complete" -ForegroundColor Green

        Write-Host "[Git] Installing Git."
        Start-Process -Wait $env:TEMP\git-installer.exe -ArgumentList /silent
        Write-Host "[Git] Git Installation complete." -ForegroundColor Green
    }

    $LatestGit = Get-LatestGitVersion -sku $sku
    if (!$LatestGit) {
        $NotFindGitError = New-Object System.NotSupportedException "Cannot get the inforamtion about latest Git."
        throw $NotFindGitError
    }

    $CurrentGitVersion = Get-CurrentGitVersion
    if ($CurrentGitVersion) {
        Write-Host "[Git] Already installed Git, version is $CurrentGitVersion." -ForegroundColor Yellow

        if (($LatestGit.Version[0] -gt $CurrentGitVersion[0]) -or
            ($LatestGit.Version[0] -eq $CurrentGitVersion[0] -and
             $LatestGit.Version[1] -gt $CurrentGitVersion[1]) -or
            ($LatestGit.Version[0] -eq $CurrentGitVersion[0] -and
             $LatestGit.Version[1] -eq $CurrentGitVersion[1] -and
             $LatestGit.Version[2] -gt $CurrentGitVersion[2])
        ) {
            Write-Host "[Git] Current Git version is old, newer version is " + $LatestGit.Version + ". Try update Git." -ForegroundColor Yellow

            Write-Host "[Git] Check ssh-agent process" -ForegroundColor Yellow
            $sshagentrunning = get-process ssh-agent -ErrorAction SilentlyContinue
            if ($sshagentrunning) {
                Write-Host "[Git] Try killing ssh-agent process." -ForegroundColor Yellow
                Stop-Process $sshagentrunning.Id
                Write-Host "[Git] Killed ssh-agent process." -ForegroundColor Green
            }
            Write-Host "[Git] No ssh-agent process still running." -ForegroundColor Green
            Install-Git -DownloadUrl $LatestGit.DownloadURL
        } else {
            Write-Host "[Git] Already have latest version of Git." -ForegroundColor Green
        }
    } else {
        Write-Host "[Git] Git is not installed." -ForegroundColor Yellow
        Install-Git -DownloadUrl $LatestGit.DownloadURL
    }
}
