param(
    [string]$Path = (Join-Path $PSScriptRoot 'SPEC_GAME.md'),
    [switch]$ForceWrite
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Get-TextHealth {
    param([string]$Text, [byte[]]$Bytes)
    return @{
        length = $Text.Length
        questionMarkCount = ([regex]::Matches($Text, '\?')).Count
        cjkCount = ([regex]::Matches($Text, '[\p{IsCJKUnifiedIdeographs}]')).Count
        startsWithUtf8Bom = ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191)
    }
}

function Update-BoundedSection {
    param(
        [string]$Content,
        [string]$BeginMarker,
        [string]$EndMarker,
        [string]$Replacement
    )
    $s = $Content.IndexOf($BeginMarker)
    if ($s -lt 0) { throw "Begin marker not found: $BeginMarker" }
    $e = $Content.IndexOf($EndMarker, $s)
    if ($e -lt 0) { throw "End marker not found after begin: $EndMarker" }
    return $Content.Remove($s, $e - $s).Insert($s, $Replacement)
}

function Update-B5B6Section {
    param(
        [string]$Content,
        [string]$Replacement
    )
    $endMarker = '### B.7 Feature Notes (v1.37)'
    $beginMarker = '### B.5 Hotfix Notes (v1.35)'

    $s = $Content.IndexOf($beginMarker)
    if ($s -lt 0) {
        # B.5 标题在部分污染版本中已丢失，回退到 B.6 前的结构化起点
        $fallback = '- System design:'
        $b6 = $Content.IndexOf('### B.6 Hotfix Notes (v1.36)')
        if ($b6 -lt 0) { throw 'Cannot locate B.6 marker for fallback replace.' }
        $s = $Content.LastIndexOf($fallback, $b6)
        if ($s -lt 0) { throw 'Cannot locate fallback start before B.6.' }
    }

    $e = $Content.IndexOf($endMarker, $s)
    if ($e -lt 0) { throw "End marker not found after B5/B6 section: $endMarker" }

    return $Content.Remove($s, $e - $s).Insert($s, $Replacement)
}

$originalBytes = [System.IO.File]::ReadAllBytes($Path)
$originalText = [System.IO.File]::ReadAllText($Path, $utf8)
$before = Get-TextHealth -Text $originalText -Bytes $originalBytes

$b5b6Path = Join-Path $PSScriptRoot 'fix_spec_b5_b6_utf8.md'
$b7to21Path = Join-Path $PSScriptRoot 'fix_spec_chunk_b7_to_21.md'
$b5b6 = [System.IO.File]::ReadAllText($b5b6Path, $utf8)
$b7to21 = [System.IO.File]::ReadAllText($b7to21Path, $utf8)

if (([regex]::Matches($b5b6, '[\p{IsCJKUnifiedIdeographs}]')).Count -eq 0) { throw 'fix_spec_b5_b6_utf8.md has no CJK content, abort.' }
if (([regex]::Matches($b7to21, '[\p{IsCJKUnifiedIdeographs}]')).Count -eq 0) { throw 'fix_spec_chunk_b7_to_21.md has no CJK content, abort.' }

if (-not $ForceWrite -and $before.cjkCount -eq 0 -and $before.questionMarkCount -gt 1000) {
    throw 'Pollution guard: target appears fully polluted. Re-run with -ForceWrite to apply bounded restore safely.'
}

$content = $originalText
$content = Update-B5B6Section -Content $content -Replacement $b5b6
$content = Update-BoundedSection -Content $content -BeginMarker '### B.7 Feature Notes (v1.37)' -EndMarker '### 2.5' -Replacement $b7to21

$backupPath = "$Path.pre_fix.bak"
[System.IO.File]::WriteAllText($backupPath, $originalText, $utf8)
[System.IO.File]::WriteAllText($Path, $content, $utf8)
Write-Host "OK: bounded restore applied. backup=$backupPath"
