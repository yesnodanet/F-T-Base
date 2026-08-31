param(
    [string]$SnapshotRoot
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($SnapshotRoot)) {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $SnapshotRoot = Join-Path $repositoryRoot "third_party\workshop"
}

$snapshotDirectories = @(
    Get-ChildItem -LiteralPath $SnapshotRoot -Directory |
        Where-Object { $_.Name -match '^\d+$' } |
        Sort-Object -Property Name
)

if ($snapshotDirectories.Count -eq 0) {
    throw "No numeric Workshop snapshot directories found under $SnapshotRoot"
}

foreach ($snapshotDirectory in $snapshotDirectories) {
    $metadataPath = Join-Path $snapshotDirectory.FullName "SNAPSHOT.json"
    $manifestPath = Join-Path $snapshotDirectory.FullName "MANIFEST.sha256"

    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        throw "Missing snapshot metadata: $metadataPath"
    }

    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Missing snapshot manifest: $manifestPath"
    }

    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    if ([string]$metadata.workshopId -ne $snapshotDirectory.Name) {
        throw "Workshop ID mismatch in $metadataPath"
    }

    $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($manifestHash -ne [string]$metadata.manifestSha256) {
        throw "Manifest digest mismatch for $($snapshotDirectory.Name)"
    }

    $manifestLines = @(Get-Content -LiteralPath $manifestPath)
    $actualFiles = @(
        Get-ChildItem -LiteralPath $snapshotDirectory.FullName -File -Recurse -Force |
            Where-Object { $_.Name -notin @("MANIFEST.sha256", "SNAPSHOT.json") }
    )
    $actualRelativePaths = [string[]]@(
        $actualFiles | ForEach-Object {
            $_.FullName.Substring($snapshotDirectory.FullName.Length + 1).Replace('\', '/')
        }
    )
    [Array]::Sort($actualRelativePaths, [System.StringComparer]::Ordinal)

    if ($manifestLines.Count -ne [int]$metadata.payloadFileCount) {
        throw "Manifest count mismatch for $($snapshotDirectory.Name)"
    }

    if ($actualFiles.Count -ne [int]$metadata.payloadFileCount) {
        throw "Payload count mismatch for $($snapshotDirectory.Name)"
    }

    $actualBytes = ($actualFiles | ForEach-Object { $_.Length } | Measure-Object -Sum).Sum
    if ([long]$actualBytes -ne [long]$metadata.payloadBytes) {
        throw "Payload byte count mismatch for $($snapshotDirectory.Name)"
    }

    for ($lineIndex = 0; $lineIndex -lt $manifestLines.Count; $lineIndex++) {
        $line = $manifestLines[$lineIndex]

        if ($line -notmatch '^([0-9a-f]{64})  (.+)$') {
            throw "Malformed manifest entry for $($snapshotDirectory.Name): $line"
        }

        $expectedHash = $Matches[1]
        $relativePath = $Matches[2]

        if ($relativePath -cne $actualRelativePaths[$lineIndex]) {
            throw "Manifest order/path mismatch for $($snapshotDirectory.Name): $relativePath"
        }

        $payloadPath = Join-Path $snapshotDirectory.FullName ($relativePath.Replace('/', '\'))

        if (-not (Test-Path -LiteralPath $payloadPath -PathType Leaf)) {
            throw "Missing payload file for $($snapshotDirectory.Name): $relativePath"
        }

        $actualHash = (Get-FileHash -LiteralPath $payloadPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "Payload digest mismatch for $($snapshotDirectory.Name): $relativePath"
        }
    }

    Write-Host "Verified $($snapshotDirectory.Name): $($actualFiles.Count) files, $actualBytes bytes"
}
