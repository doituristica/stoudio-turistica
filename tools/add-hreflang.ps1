# Adds <link rel="alternate" hreflang="..."> pairs to the Slovenian pages so search
# engines know each page has an English twin. The English pages already carry them.
# Idempotent.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$site = Join-Path $root 'site'

$pairs = @{
  'index.html'     = 'en/index.html'
  'pogovori.html'  = 'en/talks.html'
  'zmenki.html'    = 'en/dates.html'
  'izleti.html'    = 'en/trips.html'
  'projekti.html'  = 'en/projects.html'
  'vikendi.html'   = 'en/weekends.html'
  'startaupi.html' = 'en/startups.html'
  'arhiv.html'     = 'en/archive.html'
  'o-nas.html'     = 'en/about.html'
  'aktivnost.html' = 'en/activity.html'
}

$n = 0
foreach ($sl in $pairs.Keys) {
  $path = Join-Path $site $sl
  if (-not (Test-Path $path)) { continue }
  $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  if ($text -match 'hreflang=') { continue }

  $block = "<link rel=`"alternate`" hreflang=`"sl`" href=`"$sl`">`r`n" +
           "<link rel=`"alternate`" hreflang=`"en`" href=`"$($pairs[$sl])`">`r`n"
  # There are two font preload lines - insert before the first one only.
  $rx = New-Object System.Text.RegularExpressions.Regex '(?m)^<link rel="preload" href="assets/fonts/'
  $text = $rx.Replace($text, ($block + '<link rel="preload" href="assets/fonts/'), 1)

  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
  $n++
}
"OK  hreflang added to $n Slovenian pages"
