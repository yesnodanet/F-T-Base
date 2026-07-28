param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,

    [string]$DestinationRoot
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $DestinationRoot = Join-Path $repositoryRoot "third_party\workshop"
}

$snapshotDefinitions = @(
    [ordered]@{
        id = "2910505837"
        directory = "arc9_weapon_base_2910505837"
        title = "ARC9 Weapon Base"
    },
    [ordered]@{
        id = "2131057232"
        directory = "arccw_arctic_s_customizable_weapons_base_2131057232"
        title = "[ArcCW] Arctic's Customizable Weapons (Base)"
    },
    [ordered]@{
        id = "2459720887"
        directory = "modern_wokefare_base_2459720887"
        title = "Modern Wokefare Base"
    },
    [ordered]@{
        id = "1967187358"
        directory = "swb_1967187358"
        title = "SWB"
    },
    [ordered]@{
        id = "3734712166"
        directory = "tacrp_tactical_rp_weapons_official_3734712166"
        title = "[TacRP] Tactical RP Weapons (OFFICIAL)"
    },
    [ordered]@{
        id = "2840031720"
        directory = "tfa_base_2840031720"
        title = "TFA Base"
    }
)

if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
    throw "Workshop source root does not exist: $SourceRoot"
}

New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
$destinationRootPath = [System.IO.Path]::GetFullPath($DestinationRoot).TrimEnd('\', '/')
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

foreach ($snapshot in $snapshotDefinitions) {
    $sourcePath = Join-Path $SourceRoot $snapshot.directory
    $destinationPath = [System.IO.Path]::GetFullPath((Join-Path $DestinationRoot $snapshot.id))
    $requiredPrefix = $destinationRootPath + [System.IO.Path]::DirectorySeparatorChar

    if (-not $destinationPath.StartsWith($requiredPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to replace a snapshot outside the destination root: $destinationPath"
    }

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
        throw "Required Workshop snapshot does not exist: $sourcePath"
    }

    Write-Host "Copying $($snapshot.title) ($($snapshot.id))..."
    if (Test-Path -LiteralPath $destinationPath) {
        Remove-Item -LiteralPath $destinationPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    Get-ChildItem -LiteralPath $sourcePath -Force | Copy-Item -Destination $destinationPath -Recurse -Force

    $payloadFiles = [object[]]@(
        Get-ChildItem -LiteralPath $destinationPath -File -Recurse -Force |
            Where-Object { $_.Name -notin @("MANIFEST.sha256", "SNAPSHOT.json") } |
            ForEach-Object {
                [PSCustomObject]@{
                    file = $_
                    relativePath = $_.FullName.Substring($destinationPath.Length + 1).Replace('\', '/')
                }
            }
    )
    $ordinalComparer = [System.Collections.Generic.Comparer[object]]::Create(
        [System.Comparison[object]] {
            param($left, $right)
            [System.StringComparer]::Ordinal.Compare(
                [string]$left.relativePath,
                [string]$right.relativePath
            )
        }
    )
    [Array]::Sort($payloadFiles, $ordinalComparer)

    $manifestLines = foreach ($payloadFile in $payloadFiles) {
        $hash = (Get-FileHash -LiteralPath $payloadFile.file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $($payloadFile.relativePath)"
    }

    $manifestPath = Join-Path $destinationPath "MANIFEST.sha256"
    $manifestText = if ($manifestLines.Count -gt 0) {
        ($manifestLines -join "`n") + "`n"
    } else {
        ""
    }
    [System.IO.File]::WriteAllText($manifestPath, $manifestText, $utf8WithoutBom)

    $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $payloadBytes = ($payloadFiles | ForEach-Object { $_.file.Length } | Measure-Object -Sum).Sum

    $metadata = [ordered]@{
        schemaVersion = 1
        workshopId = $snapshot.id
        workshopUrl = "https://steamcommunity.com/sharedfiles/filedetails/?id=$($snapshot.id)"
        title = $snapshot.title
        sourceDirectory = $snapshot.directory
        payloadFileCount = $payloadFiles.Count
        payloadBytes = [long]$payloadBytes
        manifestAlgorithm = "SHA-256"
        manifestFile = "MANIFEST.sha256"
        manifestSha256 = $manifestHash
        isolation = "Reference snapshot only; this directory is outside the Garry's Mod lua/ load tree."
    }

    $metadataPath = Join-Path $destinationPath "SNAPSHOT.json"
    $metadataText = ($metadata | ConvertTo-Json -Depth 4) + "`n"
    [System.IO.File]::WriteAllText($metadataPath, $metadataText, $utf8WithoutBom)

    Write-Host "  $($payloadFiles.Count) files, $payloadBytes bytes, manifest SHA-256 $manifestHash"
}
