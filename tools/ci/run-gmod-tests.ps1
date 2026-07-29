param(
    [string]$ServerRoot = $env:GARRYSMOD_SERVER_ROOT,
    [string]$AddonRoot = $env:FT_BASE_GMOD_ADDON_ROOT,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ServerRoot)) {
    throw "Set GARRYSMOD_SERVER_ROOT to the Garry's Mod dedicated server garrysmod directory."
}

$ServerRoot = [System.IO.Path]::GetFullPath($ServerRoot)
$RepositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$AddonsRoot = [System.IO.Path]::GetFullPath((Join-Path $ServerRoot "addons"))

if ([string]::IsNullOrWhiteSpace($AddonRoot)) {
    $AddonRoot = Join-Path $AddonsRoot "ft_base_visual_test"
}

$AddonRoot = [System.IO.Path]::GetFullPath($AddonRoot)
$AddonsPrefix = $AddonsRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

if (-not $AddonRoot.StartsWith($AddonsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "The test addon path '$AddonRoot' must stay below '$AddonsRoot'."
}

$ServerExecutable = Join-Path (Split-Path $ServerRoot -Parent) "srcds.exe"

if (-not (Test-Path -LiteralPath $ServerExecutable -PathType Leaf)) {
    throw "srcds.exe was not found at '$ServerExecutable'."
}

$SourceConfig = Join-Path $RepositoryRoot "tools\server\ft_base_test.cfg"
$TargetConfig = Join-Path $ServerRoot "cfg\ft_base_test.cfg"

New-Item -ItemType Directory -Path $AddonRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "lua") -Destination $AddonRoot -Recurse -Force
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "tools") -Destination $AddonRoot -Recurse -Force

function Copy-RepositoryTree {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $sourcePath = [System.IO.Path]::GetFullPath((Join-Path $RepositoryRoot $RelativePath))
    $targetPath = [System.IO.Path]::GetFullPath((Join-Path $AddonRoot $RelativePath))
    $repositoryPrefix = $RepositoryRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    $addonPrefix = $AddonRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

    if (-not $sourcePath.StartsWith($repositoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "The asset source '$sourcePath' must stay below '$RepositoryRoot'."
    }

    if (-not $targetPath.StartsWith($addonPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "The asset target '$targetPath' must stay below '$AddonRoot'."
    }

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
        throw "The repository asset directory '$sourcePath' was not found."
    }

    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    Copy-Item -Path (Join-Path $sourcePath "*") -Destination $targetPath -Recurse -Force
}

Copy-RepositoryTree "materials"
Copy-RepositoryTree "resource"
Copy-Item -LiteralPath $SourceConfig -Destination $TargetConfig -Force

$OutputLog = Join-Path $ServerRoot "console.log"
$Process = $null

if (Test-Path -LiteralPath $OutputLog) {
    Remove-Item -LiteralPath $OutputLog -Force
}

try {
    $Process = Start-Process -FilePath $ServerExecutable -WorkingDirectory (Split-Path $ServerRoot -Parent) `
        -ArgumentList @(
            "-console",
            "-condebug",
            "-norestart",
            "-game", "garrysmod",
            "+servercfgfile", "ft_base_test.cfg",
            "+map", "gm_construct",
            "+maxplayers", "1"
        ) `
        -WindowStyle Hidden -PassThru

    $Expected = @(
        "F&T Base visual smoke test passed",
        "F&T core regression tests passed",
        "F&T runtime regression tests passed",
        "F&T Base template regression passed"
    )
    $Deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)

    while ([DateTime]::UtcNow -lt $Deadline) {
        [string]$Output = if (Test-Path -LiteralPath $OutputLog) {
            Get-Content -LiteralPath $OutputLog -Raw
        } else {
            ""
        }

        $Missing = @($Expected | Where-Object { -not $Output.Contains($_) })

        if ($Missing.Count -eq 0) {
            Write-Output $Output.Trim()
            Write-Output "F&T dedicated-server test suite passed"
            exit 0
        }

        if ($Process.HasExited) {
            throw "srcds exited before all tests passed.`n$Output"
        }

        Start-Sleep -Milliseconds 500
    }

    [string]$Output = if (Test-Path -LiteralPath $OutputLog) { Get-Content -LiteralPath $OutputLog -Raw } else { "" }
    throw "Timed out waiting for Garry's Mod tests after $TimeoutSeconds seconds.`n$Output"
} finally {
    if ($Process -and -not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force
        $Process.WaitForExit()
    }
}
