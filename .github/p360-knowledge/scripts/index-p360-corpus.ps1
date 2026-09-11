[CmdletBinding()]
param(
    [string]$Root
)

$ErrorActionPreference = 'Stop'
$candidates = @()
if ($Root) { $candidates += $Root }
if ($env:OneDriveCommercial) { $candidates += (Join-Path $env:OneDriveCommercial 'P360 Knowledge\PIMDocs') }
$candidates += @(
    'C:\Users\PrasadA\OneDrive - IBM\P360 Knowledge\PIMDocs',
    'C:\McCain\PIMDocs'
)
$resolvedRoot = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -First 1
if (-not $resolvedRoot) { throw 'No readable P360 corpus found; sync OneDrive or pass -Root.' }

$assetExtensions = @('.png','.jpg','.jpeg','.gif','.svg','.css','.js','.woff','.woff2','.ttf','.ico','.map','.webp')
$archiveExtensions = @('.zip','.rar','.7z','.tar','.gz')
$documentExtensions = @('.html','.htm','.pdf','.pptx','.docx','.txt','.md','.json','.xml','.sql','.bpr')
$domainRules = [ordered]@{
    'architecture/platform' = @('platform','architecture','overview','pim_core')
    'data model/product hierarchy' = @('product paradigm','product','variant','item','hierarch','repository')
    'desktop/web UI' = @('desktop','web user','web ui','web client','user manual')
    'imports/exports' = @('import','export','multichannel','data provider')
    'REST/API' = @('rest','serviceapi','listapi','objectapi','api','postman')
    'workflow/process' = @('workflow','activity','contribution','process','task')
    'data quality' = @('data quality',' dq','idq','quality rule')
    'Media Manager' = @('media manager','media')
    'configuration/customizing' = @('configuration','customiz','configur','extension','plugin')
    'installation/operations' = @('installation','operation','migration','maintenance','sizing')
    'security/permissions' = @('security','permission','rights','saml','authentication','authorization')
    'performance/monitoring' = @('performance','sizing','monitor','grafana','metrics','scal')
    'troubleshooting' = @('troubleshoot','diagnos','problem','error','support')
    'upgrades/hotfixes' = @('release note','hotfix','migration','upgrade','10.5')
    'accelerators' = @('accelerator','gdsn')
}

function Get-Title($file) {
    if ($file.Extension -in @('.html','.htm')) {
        $match = [regex]::Match((Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue), '<title>\s*(.*?)\s*</title>', 'IgnoreCase,Singleline')
        if ($match.Success) {
            $title = [System.Net.WebUtility]::HtmlDecode(($match.Groups[1].Value -replace '\s+', ' ').Trim())
            return (($title -replace '\s*-\s*Informatica MDM\s*-\s*Product 360\s*$', '') -replace '\|','\|').Trim()
        }
    }
    return (($file.BaseName -replace '[_-]+',' ').Trim() -replace '\|','\|')
}
function Get-Class($file) {
    if ($file.FullName -match '\\__MACOSX\\' -or $file.Name.StartsWith('._')) { return 'metadata/resource placeholder' }
    if ($archiveExtensions -contains $file.Extension.ToLowerInvariant()) { return 'archive' }
    if ($assetExtensions -contains $file.Extension.ToLowerInvariant()) { return 'metadata/resource asset' }
    if ($documentExtensions -contains $file.Extension.ToLowerInvariant()) { return 'substantive/document' }
    return 'other'
}
function Get-Domain($title, $path) {
    $text = "$title $path".ToLowerInvariant()
    if ($text -match 'data quality|\bidq\b|\bdq rules?\b') { return 'data quality' }
    if ($text -match 'security|permission|display rights|authorization|authentication|saml') { return 'security/permissions' }
    if ($text -match 'performance|grafana|metrics|monitoring|sizing|scalability') { return 'performance/monitoring' }
    if ($text -match 'troubleshoot|diagnos|error handling|known issue') { return 'troubleshooting' }
    if ($text -match 'release notes?|hotfix|upgrade|migration') { return 'upgrades/hotfixes' }
    $best = 'other/reference'; $bestScore = 0
    foreach ($domain in $domainRules.Keys) {
        $score = @($domainRules[$domain] | Where-Object { $text.Contains($_) }).Count
        if ($score -gt $bestScore) { $best = $domain; $bestScore = $score }
    }
    return $best
}
function Get-Version($path) {
    $match = [regex]::Match($path, '(?:P360|PIM)[_-]?(\d+(?:\.\d+){1,4}|(?:\d{3})(?:HF\d+)?(?:SP\d+)?|(?:\d{3}H\d+S\d+))', 'IgnoreCase')
    if ($match.Success) { return $match.Groups[1].Value }
    if ($path.Contains('10.5')) { return '10.5 (path/title clue)' }
    return 'Not explicit; verify source release'
}

$files = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File)
$classes = $files | ForEach-Object { Get-Class $_ } | Group-Object | ForEach-Object { @{($_.Name)=$_.Count} }
$docs = @($files | Where-Object { (Get-Class $_) -eq 'substantive/document' })
$groups = @{}
foreach ($file in $docs) {
    $title = Get-Title $file
    $domain = Get-Domain $title $file.FullName
    if (-not $groups.ContainsKey($domain)) { $groups[$domain] = @() }
    $groups[$domain] += [pscustomobject]@{
        Title=$title; Relative=($file.FullName.Substring($resolvedRoot.Length).TrimStart('\').Replace('\','/')); Version=(Get-Version $file.FullName)
    }
}

$output = Join-Path (Get-Location) '.github\p360-knowledge\P360-SOURCE-MAP.md'
$lines = @(
    '# P360 source and topic map', '',
    '> [!IMPORTANT]', '> This is a navigation index, not a copy of the licensed documentation. Verify every answer against the original readable source and the Informatica Knowledge Base.', '',
    "- **Corpus root used:** ``$resolvedRoot``",
    '- **Inventory date:** generated locally',
    "- **Total files:** $($files.Count.ToString('N0'))",
    "- **Substantive/document files indexed:** $($docs.Count.ToString('N0'))",
    "- **Archives excluded from deep text indexing:** $((@($files | Where-Object { (Get-Class $_) -eq 'archive' }).Count).ToString('N0'))",
    "- **Metadata/resource assets excluded:** $((@($files | Where-Object { (Get-Class $_) -eq 'metadata/resource asset' }).Count).ToString('N0'))",
    "- **MacOS metadata/resource placeholders excluded:** $((@($files | Where-Object { (Get-Class $_) -eq 'metadata/resource placeholder' }).Count).ToString('N0'))",
    "- **Other files excluded:** $((@($files | Where-Object { (Get-Class $_) -eq 'other' }).Count).ToString('N0'))",
    '- **Duplicate handling:** mirrored roots are treated as one corpus; archive members and assets are not expanded into this map.', '',
    '## Domain index', ''
)
foreach ($domain in ($groups.Keys | Sort-Object)) {
    $lines += "### $domain"; $lines += ''
    foreach ($entry in ($groups[$domain] | Sort-Object Title,Relative)) {
        $concept = "$($entry.Title); $domain"
        $lines += "- **$($entry.Title)** — ``$($entry.Relative)`` — scope: $($entry.Version) — concepts: $concept — confidence: Medium (title/path index; verify source)"
    }
    $lines += ''
}
$expectedDomains = @(
    'architecture/platform','data model/product hierarchy','desktop/web UI','imports/exports','REST/API',
    'workflow/process','data quality','Media Manager','configuration/customizing','installation/operations',
    'security/permissions','performance/monitoring','troubleshooting','upgrades/hotfixes','accelerators'
)
$lines += @('## Coverage domains', '', 'The following domains are required retrieval targets. A domain may have no dedicated heading when the corpus uses a cross-domain source; use the retrieval guide anchors and verify the original source.', '')
foreach ($domain in $expectedDomains) {
    $lines += "- **$domain** — retrieve through the domain heading above or the anchors in [the retrieval guide](./P360-RETRIEVAL-GUIDE.md)."
}
Set-Content -LiteralPath $output -Value ($lines -join "`n") -Encoding UTF8
Write-Output "root=$resolvedRoot"
Write-Output "files=$($files.Count)"
Write-Output "substantive=$($docs.Count)"
Write-Output "output=$output"
