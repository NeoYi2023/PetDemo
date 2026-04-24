$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$root = $PSScriptRoot
$path = Join-Path $root 'SPEC_GAME.md'
$c = [System.IO.File]::ReadAllText($path, $utf8)
$anchor = '### B.5 Hotfix Notes (v1.35)'
$s0 = $c.IndexOf($anchor)
if ($s0 -lt 0) { throw 'B.5 anchor missing' }
$s = $c.IndexOf('- System design:', $s0)
if ($s -lt 0) { throw '- System design after B.5 missing' }
$e = $c.IndexOf('### B.7 Feature Notes', $s)
if ($e -lt 0) { throw 'B.7 anchor missing' }
$new = [System.IO.File]::ReadAllText((Join-Path $root 'fix_spec_b5_b6_utf8.md'), $utf8)
$c = $c.Remove($s, $e - $s).Insert($s, $new)
[System.IO.File]::WriteAllText($path, $c, $utf8)
Write-Host 'B.5+B.6 block replaced from UTF-8 file.'
