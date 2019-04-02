function Install-LatestNodeJS {
    [CmdletBinding()]
    param (
        [string] $Sku = "64",
        [string] $Version = "latest"
    )

    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        $InsufficientPrivilegesError = New-Object System.NotSupportedException "This setup must run with administrator permission."
        throw $InsufficientPrivilegesError
    }

    function Get-CurrentNodeJSVersion {
        if (Get-Command node -errorAction SilentlyContinue) {
            (node -v) -match "(\d*\.\d*\.\d*)" | Out-Null
            return $matches[0].split('.')
        }
        else {
            return $null
        }
    }

    function Get-LatestNodeJSVersion {
        $latestRelease = (Invoke-RestMethod https://api.github.com/repos/nodejs/node/releases/latest)

        if ($latestRelease.tag_name) {
            $latestRelease.tag_name -match "(\d*\.\d*\.\d*)" | Out-Null
            $version = $matches[0].split('.')

            return @{
                'Name'    = $latestRelease.name
                'Version' = $version
            }
        }
        else {
            return $null
        }
    }

    function Install-NodeJS {
        [CmdletBinding()]
        param (
            [string] $Sku,
            [String[]] $Version
        )

        $VersionString = "v" + ($Version -join '.')
        Write-Host $VersionString
        $DownloadUrl = "https://nodejs.org/dist/$VersionString/node-$VersionString-x$Sku.msi"

        Write-Host "[NodeJS] Start downloading latest version of NodeJS."
        Remove-Item -Force $env:TEMP\node-$VersionString-x$Sku.msi -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $env:TEMP\node-$VersionString-x$Sku.msi
        Write-Host "[NodeJS] Download latest version of NodeJS complete" -ForegroundColor Green

        Write-Host "[NodeJS] Installing NodeJS."
        Start-Process -Wait $env:TEMP\node-$VersionString-x$Sku.msi -ArgumentList /passive
        Write-Host "[NodeJS] NodeJS Installation complete." -ForegroundColor Green

        Write-Host "[NodeJS] Update Current Session's Environment Path."
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }

    if ($Version -eq "latest") {
        $LatestNodeJS = Get-LatestNodeJSVersion
        if (!$LatestNodeJS) {
            $NotFindNodeJSError = New-Object System.NotSupportedException "Cannot get the inforamtion about latest version of NodeJS."
            throw $NotFindNodeJSError
        }
        else {
            Write-Host "[NodeJS] Latest version of NodeJS is $($LatestNodeJS.Version -join '.')"
            $InstallVersion = $LatestNodeJS.Version
        }
    }
    else {
        Write-Host "[NodeJS] Want to install NodeJS with version $Version"
        $InstallVersion = $Version.split('.')
    }

    $CurrentNodeJSVersion = Get-CurrentNodeJSVersion
    if ($CurrentNodeJSVersion) {
        Write-Host "[NodeJS] Already installed Node, version is $($CurrentNodeJSVersion -join '.')." -ForegroundColor Yellow

        if (($InstallVersion[0] -gt $CurrentNodeJSVersion[0]) -or
            ($InstallVersion[0] -eq $CurrentNodeJSVersion[0] -and
                $InstallVersion[1] -gt $CurrentNodeJSVersion[1]) -or
            ($InstallVersion[0] -eq $CurrentNodeJSVersion[0] -and
                $InstallVersion[1] -eq $CurrentNodeJSVersion[1] -and
                $InstallVersion[2] -gt $CurrentNodeJSVersion[2])
        ) {
            Write-Host "[NodeJS] Current NodeJS version is old. Try update NodeJS." -ForegroundColor Yellow
            Install-NodeJS -Sku $Sku -Version $InstallVersion
        }
        else {
            Write-Host "[NodeJS] Already have a newer version NodeJS installed." -ForegroundColor Green
        }
    }
    else {
        Write-Host "[NodeJS] NodeJS is not installed in this machine." -ForegroundColor Yellow
        Install-NodeJS -Sku $Sku -Version $InstallVersion
    }
}
