[CmdletBinding()]
param(
    [string]$Root
)

$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$map = Join-Path $repo '.github\p360-knowledge\P360-SOURCE-MAP.md'
$guide = Join-Path $repo '.github\p360-knowledge\P360-RETRIEVAL-GUIDE.md'
$agent = Join-Path $repo '.github\agents\informatica-p360-expert.agent.md'
$indexer = Join-Path $repo '.github\p360-knowledge\scripts\index-p360-corpus.ps1'
$candidates = @()
if ($Root) { $candidates += $Root }
if ($env:OneDriveCommercial) { $candidates += (Join-Path $env:OneDriveCommercial 'P360 Knowledge\PIMDocs') }
$candidates += @('C:\Users\PrasadA\OneDrive - IBM\P360 Knowledge\PIMDocs','C:\McCain\PIMDocs')
$resolved = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -First 1
if (-not $resolved) { throw 'FAIL: synchronized P360 corpus is not readable' }
$allRelative = @(Get-ChildItem -LiteralPath $resolved -Recurse -File | ForEach-Object { $_.FullName.Substring($resolved.Length).TrimStart('\') })

$cases = [ordered]@{
    'product-model' = @('44762027.html','136612419.html')
    'hierarchy-export' = @('126595250.html','242295630.html','46277751.html')
    'rest-integration' = @('158011330.html','ServiceAPI_en.pdf','ListAPI.postman_collection.json')
    'import-dq' = @('DQ Rules with Product 360.pdf','487621725.html')
    'media-manager' = @('MediaManagerUserManualNativ_en.pdf','MediaManagerUserManualWeb_en.pdf')
    'security-permissions' = @('Display_Rights','ConfigurationManual_en.pdf')
    'ha-performance' = @('SizingManual_en.pdf','Product_360_Grafana_Dashboard.json')
    'upgrade-hotfix' = @('ReleaseNotes_en.pdf','MigrationManual_en.pdf')
    'failed-export' = @('46277751.html','180461299.html','124127944.html')
    'end-to-end' = @('ConfigurationManual_en.pdf','OperationManual_en.pdf','ServiceAPI_en.pdf')
}

$mapText = Get-Content -LiteralPath $map -Raw
$guideText = Get-Content -LiteralPath $guide -Raw
$matrix = Join-Path $repo '.github\p360-knowledge\P360-ACCEPTANCE-TEST-MATRIX.md'
$matrixText = Get-Content -LiteralPath $matrix -Raw
$agentText = Get-Content -LiteralPath $agent -Raw
if ($agentText -notmatch 'OneDriveCommercial' -or $agentText -notmatch 'hydrated') { throw 'FAIL: cross-device source contract missing' }
if ($guideText -notmatch 'official.*documentation' -or $guideText -notmatch 'Knowledge Base') { throw 'FAIL: retrieval guide source contract missing' }
$mermaidCount = ([regex]::Matches($guideText + $agentText + $matrixText, '```mermaid')).Count
if ($mermaidCount -lt 4) { throw "FAIL: expected at least 4 Mermaid diagrams, found $mermaidCount" }
foreach ($case in $cases.Keys) {
    foreach ($needle in $cases[$case]) {
        if (-not ($allRelative | Where-Object { $_.Contains($needle) })) {
            throw "FAIL: $case missing retrieval anchor '$needle'"
        }
    }
}
if (-not (Test-Path -LiteralPath $indexer)) { throw 'FAIL: indexer missing' }
if (-not (Select-String -LiteralPath $indexer -Pattern 'OneDriveCommercial' -SimpleMatch)) { throw 'FAIL: indexer does not resolve enterprise OneDrive' }
Write-Output "PASS: corpus root=$resolved"
Write-Output "PASS: cases=$($cases.Count)"
Write-Output "PASS: Mermaid diagrams=$mermaidCount"
Write-Output 'PASS: map, guide, agent, and indexer contracts present'
