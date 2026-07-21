# Downloads Noto Sans locally so the site does not depend on Google Fonts.
#
#   .\tools\fetch-fonts.ps1           subset to the characters the site actually uses (default)
#   .\tools\fetch-fonts.ps1 -Full     download the complete latin + latin-ext subsets
#
# Why self-host: removes two cross-origin round trips (DNS + TLS to fonts.googleapis.com
# and fonts.gstatic.com) before any text can render, and avoids sending visitor IPs to
# Google - which matters for a public university site under GDPR.
#
# Why subset: the stock latin-ext file is 164 KB and this site needs five extra letters
# from it (c/s/z-caron and friends). Asking Google for exactly the glyphs used cuts the
# font payload by roughly 90%. The character set is collected from the built pages and
# activities.json, so re-run this whenever the content changes. Any glyph that somehow
# escapes the scan degrades to the system font for that one character - never a blank.
param([switch]$Full)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$site = Join-Path $root 'site'
$dir  = Join-Path $site 'assets\fonts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# A modern UA is required or Google serves legacy .ttf instead of .woff2.
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

function Get-SiteCharacters {
  $chars = New-Object 'System.Collections.Generic.HashSet[char]'
  # printable ASCII always, so numbers/punctuation survive any content edit
  32..126 | ForEach-Object { [void]$chars.Add([char]$_) }

  $sources = @()
  $sources += Get-ChildItem $site -Recurse -File -Include '*.html', '*.json'
  foreach ($f in $sources) {
    $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    foreach ($c in $text.ToCharArray()) {
      # Skip surrogate halves - they are emoji, which Noto Sans does not carry anyway,
      # and a lone surrogate cannot be URL-encoded into the text= parameter.
      if ([int]$c -ge 32 -and -not [char]::IsSurrogate($c)) { [void]$chars.Add($c) }
    }
  }
  # Typographic characters the JS injects that may not appear in any source file.
  # Written as code points because this file must stay ASCII: Windows PowerShell 5.1
  # reads a .ps1 without a BOM as ANSI and would mangle literal en dashes here.
  $extra = 0x2013, 0x2014, 0x2026, 0x00AB, 0x00BB, 0x201E, 0x201C, 0x201D,
           0x2018, 0x2019, 0x00D7, 0x2192, 0x2190, 0x00A9, 0x00A0,
           0x2039, 0x203A, 0x00D7
  foreach ($cp in $extra) { [void]$chars.Add([char]$cp) }
  return -join ($chars | Sort-Object)
}

if ($Full) {
  $css = 'https://fonts.googleapis.com/css2?family=Noto+Sans:wght@300..700&display=swap'
  $label = 'full latin + latin-ext'
} else {
  $text = Get-SiteCharacters
  # Strip characters Google's text= parameter cannot carry in a query string.
  $text = ($text.ToCharArray() | Where-Object { [int]$_ -ne 38 -and [int]$_ -ne 35 }) -join ''
  $css = 'https://fonts.googleapis.com/css2?family=Noto+Sans:wght@300..700&display=swap&text=' +
         [System.Uri]::EscapeDataString($text)
  $label = "subset of $($text.Length) characters"
}

$cssText = (Invoke-WebRequest -Uri $css -UserAgent $ua -UseBasicParsing).Content

# Subsetted responses point at https://fonts.gstatic.com/l/font?kit=... with no file
# extension, so match on format('woff2') rather than on the URL ending in .woff2.
$faces = [regex]::Matches($cssText,
  "@font-face\s*\{[^}]*?src:\s*url\((https://[^)]+)\)\s*format\('woff2'\)[^}]*?\}")
if ($faces.Count -eq 0) { throw 'Could not parse the Google Fonts CSS.' }

# Named subsets only appear in the full response; a text= response is one unnamed face.
$named = [regex]::Matches($cssText, '/\*\s*([a-z0-9\-]+)\s*\*/\s*@font-face')
$rangeMap = @{}
foreach ($m in [regex]::Matches($cssText, '/\*\s*([a-z0-9\-]+)\s*\*/\s*@font-face\s*\{[^}]*?unicode-range:\s*([^;]+);')) {
  $rangeMap[$m.Groups[1].Value] = $m.Groups[2].Value.Trim()
}

Get-ChildItem $dir -File -Filter 'noto-sans*.woff2' | Remove-Item -Force -Confirm:$false

$saved = @()
for ($i = 0; $i -lt $faces.Count; $i++) {
  $subset = if ($named.Count -eq $faces.Count) { $named[$i].Groups[1].Value } else { 'subset' }
  if ($named.Count -eq $faces.Count -and $subset -notin 'latin', 'latin-ext') { continue }
  $name = "noto-sans-$subset.woff2"
  Invoke-WebRequest -Uri $faces[$i].Groups[1].Value -OutFile (Join-Path $dir $name) -UseBasicParsing -TimeoutSec 90
  $saved += [pscustomobject]@{ File = $name; Subset = $subset }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('/* Self-hosted Noto Sans (variable, 300-700).')
[void]$sb.AppendLine("   $label")
[void]$sb.AppendLine('   Do not edit by hand - regenerate with tools\fetch-fonts.ps1 */')
foreach ($s in $saved) {
  [void]$sb.AppendLine('@font-face {')
  [void]$sb.AppendLine('  font-family: "Noto Sans";')
  [void]$sb.AppendLine('  font-style: normal;')
  [void]$sb.AppendLine('  font-weight: 300 700;')
  [void]$sb.AppendLine('  font-display: swap;')
  [void]$sb.AppendLine("  src: url(`"../fonts/$($s.File)`") format(`"woff2`");")
  if ($rangeMap[$s.Subset]) { [void]$sb.AppendLine("  unicode-range: $($rangeMap[$s.Subset]);") }
  [void]$sb.AppendLine('}')
}
[System.IO.File]::WriteAllText((Join-Path $site 'assets\css\fonts.css'),
  $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# --- keep the <link rel="preload"> tags in sync with what we just saved -----
# Otherwise every page preloads a filename that no longer exists.
$pages = Get-ChildItem $site -Recurse -File -Filter '*.html'
$patched = 0
foreach ($p in $pages) {
  $text = [System.IO.File]::ReadAllText($p.FullName, [System.Text.Encoding]::UTF8)
  if ($text -notmatch 'rel="preload"[^>]*assets/fonts/') { continue }

  # depth prefix: pages in site\en\ need ../, the 404 page uses absolute paths
  $rel = $p.DirectoryName.Substring($site.Length).TrimStart('\')
  $prefix = if ($text -match 'href="/assets/fonts/') { '/' } elseif ($rel) { '../' } else { '' }

  $block = ($saved | ForEach-Object {
    "<link rel=`"preload`" href=`"$prefix" + "assets/fonts/$($_.File)`" as=`"font`" type=`"font/woff2`" crossorigin>"
  }) -join "`r`n"

  $rx = New-Object System.Text.RegularExpressions.Regex '(?m)^<link rel="preload"[^>]*assets/fonts/[^>]*>\r?\n'
  $first = $true
  $out = $rx.Replace($text, {
    param($m)
    if ($script:first) { $script:first = $false; return $block + "`r`n" }
    return ''
  })
  if ($out -ne $text) {
    [System.IO.File]::WriteAllText($p.FullName, $out, (New-Object System.Text.UTF8Encoding($false)))
    $patched++
  }
}

"OK  $label"
Get-ChildItem $dir -File | ForEach-Object { "    {0,-30} {1:N0} KB" -f $_.Name, ($_.Length/1KB) }
"    total {0:N0} KB" -f ((Get-ChildItem $dir -File | Measure-Object Length -Sum).Sum/1KB)
"    preload links updated in $patched pages"
