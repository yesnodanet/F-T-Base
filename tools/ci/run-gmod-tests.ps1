param(
    [string]$ServerRoot = $env:GARRYSMOD_SERVER_ROOT,
    [string]$AddonRoot = $env:FT_BASE_GMOD_ADDON_ROOT,
    [string]$NativeSourceRoot = $(if ($env:FT_BASE_BASES_ROOT) { $env:FT_BASE_BASES_ROOT } else { "C:\Users\ameri\AppData\Local\Temp\gmpublisher\bases" }),
    [switch]$InstallNativeDependencies,
    [switch]$UseInstalledNativeDependencies,
    [switch]$CleanAddon,
    [switch]$KeepAddon,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"

function Remove-TestTree {
    param([Parameter(Mandatory = $true)][string]$Path)

    for ($attempt = 1; $attempt -le 10; $attempt++) {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return
        } catch {
            if ($attempt -eq 10) {
                throw
            }

            Start-Sleep -Milliseconds 500
        }
    }
}

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

$AddonName = Split-Path -Leaf $AddonRoot

if (-not $KeepAddon -and ($CleanAddon -or $AddonName -eq "ft_base_visual_test")) {
    if ($AddonName -notmatch '^ft_(base|native)_') {
        throw "Refusing to clean an addon outside the F&T test/native naming convention: '$AddonRoot'."
    }

    if (Test-Path -LiteralPath $AddonRoot) {
        Remove-TestTree -Path $AddonRoot
    }
}

if ($InstallNativeDependencies -and $UseInstalledNativeDependencies) {
    throw "Choose either -InstallNativeDependencies or -UseInstalledNativeDependencies, not both."
}

if ($InstallNativeDependencies) {
    $DependencyInstaller = Join-Path $RepositoryRoot "tools\server\install_native_dependencies.ps1"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $DependencyInstaller `
        -ServerRoot $ServerRoot -SourceRoot $NativeSourceRoot -Clean

    if ($LASTEXITCODE -ne 0) {
        throw "Native dependency installation failed with exit code $LASTEXITCODE."
    }
}

$NativeMode = $InstallNativeDependencies -or $UseInstalledNativeDependencies

if ($UseInstalledNativeDependencies) {
    $requiredDependencyAddons = @(
        "ft_native_dep_tfa_base",
        "ft_native_dep_tfa_ar15",
        "ft_native_dep_arc9_base",
        "ft_native_dep_arc9_gsr",
        "ft_native_dep_arccw_base",
        "ft_native_dep_arccw_gso",
        "ft_native_dep_mw_base",
        "ft_native_dep_mw_assault_rifles",
        "ft_native_dep_tacrp_base",
        "ft_native_dep_tacrp_exoops",
        "ft_native_dep_swb"
    )

    foreach ($dependencyAddon in $requiredDependencyAddons) {
        $dependencyPath = Join-Path $AddonsRoot $dependencyAddon

        if (-not (Test-Path -LiteralPath $dependencyPath -PathType Container)) {
            throw "Installed native dependency addon '$dependencyPath' was not found."
        }
    }
}

$ConfigName = if ($NativeMode) { "ft_base_native_test.cfg" } else { "ft_base_test.cfg" }
$SourceConfig = Join-Path $RepositoryRoot (Join-Path "tools\server" $ConfigName)
$TargetConfig = Join-Path $ServerRoot (Join-Path "cfg" $ConfigName)

if (-not (Test-Path -LiteralPath $SourceConfig -PathType Leaf)) {
    throw "The test configuration '$SourceConfig' was not found."
}

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
            "+servercfgfile", $ConfigName,
            "+map", "gm_construct",
            "+maxplayers", "1"
        ) `
        -WindowStyle Hidden -PassThru

    $Expected = @(
        "F&T Base visual smoke test passed",
        "F&T core regression tests passed",
        "F&T native compatibility registry tests passed",
        "F&T runtime regression tests passed",
        "F&T Base template regression passed"
    )

    if ($NativeMode) {
        $Expected += "F&T native dependency server test passed"
    }
    $Deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)

    while ([DateTime]::UtcNow -lt $Deadline) {
        [string]$Output = if (Test-Path -LiteralPath $OutputLog) {
            Get-Content -LiteralPath $OutputLog -Raw
        } else {
            ""
        }

        $Missing = @($Expected | Where-Object { -not $Output.Contains($_) })

        if ($Missing.Count -eq 0) {
            $LuaErrors = @($Output -split "`r?`n" | Where-Object {
                $_ -match "Lua Error:|Lua Error$"
            })

            if ($LuaErrors.Count -gt 0) {
                throw "srcds emitted Lua errors during the dedicated test suite.`n$($LuaErrors -join "`n")"
            }

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
