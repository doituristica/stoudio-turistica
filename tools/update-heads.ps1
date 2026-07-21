# Rewrites the <head> font/CSS block of every page: drops the Google Fonts CDN in
# favour of the self-hosted copy and preloads the two woff2 files plus the hero image.
# Idempotent - safe to run repeatedly.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$site = Join-Path $root 'site'

$files = Get-ChildItem $site -Recurse -File -Filter '*.html'
$changed = 0

foreach ($f in $files) {
  $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
  $orig = $text

  # depth prefix: pages in site\en\ need ../
  $rel = $f.DirectoryName.Substring($site.Length).TrimStart('\')
  $prefix = if ($rel) { '../' } else { '' }

  # 1. strip the Google Fonts links (preconnect + stylesheet)
  $text = [regex]::Replace($text,
    '(?m)^\s*<link[^>]*fonts\.(?:googleapis|gstatic)\.com[^>]*>\s*\r?\n', '')

  # 2. make sure fonts.css is linked right before style.css
  if ($text -notmatch 'css/fonts\.css') {
    $text = $text -replace [regex]::Escape("<link rel=`"stylesheet`" href=`"${prefix}assets/css/style.css`">"),
      ("<link rel=`"preload`" href=`"${prefix}assets/fonts/noto-sans-latin.woff2`" as=`"font`" type=`"font/woff2`" crossorigin>`r`n" +
       "<link rel=`"preload`" href=`"${prefix}assets/fonts/noto-sans-latin-ext.woff2`" as=`"font`" type=`"font/woff2`" crossorigin>`r`n" +
       "<link rel=`"stylesheet`" href=`"${prefix}assets/css/fonts.css`">`r`n" +
       "<link rel=`"stylesheet`" href=`"${prefix}assets/css/style.css`">")
  }

  # 3. preload the hero background so it is not discovered late via CSS
  if ($text -match "background-image:url\('([^']+)'\)" -and $text -notmatch 'as="image"') {
    $hero = $Matches[1]
    $text = $text -replace [regex]::Escape("<link rel=`"stylesheet`" href=`"${prefix}assets/css/fonts.css`">"),
      ("<link rel=`"preload`" href=`"$hero`" as=`"image`" fetchpriority=`"high`">`r`n" +
       "<link rel=`"stylesheet`" href=`"${prefix}assets/css/fonts.css`">")
  }

  if ($text -ne $orig) {
    [System.IO.File]::WriteAllText($f.FullName, $text, (New-Object System.Text.UTF8Encoding($false)))
    $changed++
    "updated: $($f.FullName.Substring($site.Length).TrimStart('\'))"
  }
}
"OK  $changed / $($files.Count) pages updated"
