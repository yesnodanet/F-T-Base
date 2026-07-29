[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ServerRoot = $env:GARRYSMOD_SERVER_ROOT,
    [string]$SourceRoot = $(if ($env:FT_BASE_BASES_ROOT) { $env:FT_BASE_BASES_ROOT } else { "C:\Users\ameri\AppData\Local\Temp\gmpublisher\bases" }),
    [switch]$Clean,
    [switch]$Repair
)

$ErrorActionPreference = "Stop"

function Remove-NativeTree {
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

function Resolve-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path)
}

function Assert-ContainedPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $rootPrefix = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

    if (-not $Path.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label '$Path' must stay below '$Root'."
    }
}

if ([string]::IsNullOrWhiteSpace($ServerRoot)) {
    throw "Set GARRYSMOD_SERVER_ROOT to the Garry's Mod dedicated server garrysmod directory."
}

if ($Clean -and $Repair) {
    throw "Choose either -Clean or -Repair, not both."
}

$ServerRoot = Resolve-FullPath $ServerRoot
$SourceRoot = Resolve-FullPath $SourceRoot
$AddonsRoot = Resolve-FullPath (Join-Path $ServerRoot "addons")

if (-not (Test-Path -LiteralPath $ServerRoot -PathType Container)) {
    throw "The server root '$ServerRoot' was not found."
}

if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
    throw "The dependency source root '$SourceRoot' was not found."
}

New-Item -ItemType Directory -Path $AddonsRoot -Force | Out-Null

$dependencies = @(
    @{ Name = "ft_native_dep_tfa_base"; Source = "tfa\tfa_base_2840031720" },
    @{ Name = "ft_native_dep_tfa_ar15"; Source = "tfa\tfa_at_ar_15_1676032134" },
    @{ Name = "ft_native_dep_arc9_base"; Source = "arc9\arc9_weapon_base_2910505837" },
    @{ Name = "ft_native_dep_arc9_gsr"; Source = "arc9\arc9_gunsmith_reloaded_2910537020" },
    @{ Name = "ft_native_dep_arccw_base"; Source = "arccw\arccw_arctic_s_customizable_weapons_base_2131057232" },
    @{ Name = "ft_native_dep_arccw_gso"; Source = "arccw\arccw_gso_2257255110" },
    @{ Name = "ft_native_dep_mw_base"; Source = "mw\modern_wokefare_base_2459720887" },
    @{ Name = "ft_native_dep_mw_assault_rifles"; Source = "mw\modern_warfare_2019_sweps_assault_rifles_2528829149" },
    @{ Name = "ft_native_dep_tacrp_base"; Source = "tacrp\tacrp_tactical_rp_weapons_official_3734712166" },
    @{ Name = "ft_native_dep_tacrp_exoops"; Source = "tacrp\tacrp_exoops_weapon_pack_3271554982" },
    @{ Name = "ft_native_dep_swb"; Source = "swb_1967187358" }
)

$testAddonName = "ft_base_visual_test"
$knownTargets = @($dependencies | ForEach-Object { $_.Name }) + $testAddonName
$installPlan = @()

foreach ($dependency in $dependencies) {
    $source = Resolve-FullPath (Join-Path $SourceRoot $dependency.Source)
    $target = Resolve-FullPath (Join-Path $AddonsRoot $dependency.Name)

    Assert-ContainedPath -Path $source -Root $SourceRoot -Label "Dependency source"
    Assert-ContainedPath -Path $target -Root $AddonsRoot -Label "Dependency target"

    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "The dependency source '$source' was not found."
    }

    $installPlan += [pscustomobject]@{
        Name = $dependency.Name
        Source = $source
        Target = $target
    }
}

$testTarget = Resolve-FullPath (Join-Path $AddonsRoot $testAddonName)
Assert-ContainedPath -Path $testTarget -Root $AddonsRoot -Label "Test addon target"

# Validate every source and target before removing any existing addon.
if ($Clean) {
    $targetsToRemove = @($installPlan | ForEach-Object { $_.Target }) + $testTarget

    foreach ($target in $targetsToRemove) {
        if (-not (Test-Path -LiteralPath $target)) {
            continue
        }

        if ($knownTargets -notcontains (Split-Path -Leaf $target)) {
            throw "Refusing to remove an unrecognized addon target '$target'."
        }

        if ($PSCmdlet.ShouldProcess($target, "Remove old F&T native/test addon")) {
            Remove-NativeTree -Path $target
        }
    }
} elseif (-not $Repair) {
    $existing = @($installPlan | Where-Object { Test-Path -LiteralPath $_.Target })

    if ($existing.Count -gt 0) {
        $names = ($existing | ForEach-Object { $_.Name }) -join ", "
        throw "Native dependency targets already exist ($names). Re-run with -Clean to replace only known F&T directories."
    }
}

foreach ($dependency in $installPlan) {
    if ($PSCmdlet.ShouldProcess($dependency.Target, "Install native dependency from $($dependency.Source)")) {
        New-Item -ItemType Directory -Path $dependency.Target -Force | Out-Null
        Copy-Item -Path (Join-Path $dependency.Source "*") -Destination $dependency.Target -Recurse -Force
    }
}

Write-Output "Installed $($dependencies.Count) native dependency addons under '$AddonsRoot'."
