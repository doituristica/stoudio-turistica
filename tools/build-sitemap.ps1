# Generates site\sitemap.xml for both language versions, with hreflang alternates.
#   .\tools\build-sitemap.ps1 -BaseUrl https://stoudio.turistica.si
param([string]$BaseUrl = 'https://stoudio.turistica.si')

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$site = Join-Path $root 'site'
$BaseUrl = $BaseUrl.TrimEnd('/')

# sl page -> en page
$pairs = [ordered]@{
  ''               = 'en/'
  'pogovori.html'  = 'en/talks.html'
  'zmenki.html'    = 'en/dates.html'
  'izleti.html'    = 'en/trips.html'
  'projekti.html'  = 'en/projects.html'
  'vikendi.html'   = 'en/weekends.html'
  'startaupi.html' = 'en/startups.html'
  'arhiv.html'     = 'en/archive.html'
  'o-nas.html'     = 'en/about.html'
}

$acts = Get-Content (Join-Path $site 'data\activities-index.json') -Raw -Encoding utf8 | ConvertFrom-Json

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$sb.AppendLine('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">')

function Add-Pair([string]$sl, [string]$en) {
  $slUrl = "$BaseUrl/$sl"
  $enUrl = "$BaseUrl/$en"
  foreach ($u in @($slUrl, $enUrl)) {
    [void]$script:sb.AppendLine('  <url>')
    [void]$script:sb.AppendLine("    <loc>$u</loc>")
    [void]$script:sb.AppendLine("    <xhtml:link rel=`"alternate`" hreflang=`"sl`" href=`"$slUrl`"/>")
    [void]$script:sb.AppendLine("    <xhtml:link rel=`"alternate`" hreflang=`"en`" href=`"$enUrl`"/>")
    [void]$script:sb.AppendLine('    <changefreq>yearly</changefreq>')
    [void]$script:sb.AppendLine('  </url>')
  }
}

foreach ($sl in $pairs.Keys) { Add-Pair $sl $pairs[$sl] }
foreach ($a in $acts) { Add-Pair "aktivnost.html?id=$($a.id)" "en/activity.html?id=$($a.id)" }

[void]$sb.AppendLine('</urlset>')
[System.IO.File]::WriteAllText((Join-Path $site 'sitemap.xml'), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

$n = ($pairs.Count + $acts.Count) * 2
"OK  sitemap.xml: $n URLs (sl + en)"
