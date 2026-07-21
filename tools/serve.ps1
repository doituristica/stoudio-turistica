# Minimal static file server for local preview of .\site (Windows PowerShell 5.1).
# Usage: powershell -ExecutionPolicy Bypass -File tools\serve.ps1 [-Port 8080]
param([int]$Port = 8080)

$ErrorActionPreference = 'Stop'
$root = Join-Path (Split-Path $PSScriptRoot -Parent) 'site'
if (-not (Test-Path $root)) { throw "Missing site folder: $root" }

$mime = @{
  '.html'='text/html; charset=utf-8'; '.css'='text/css; charset=utf-8'
  '.js'='application/javascript; charset=utf-8'; '.json'='application/json; charset=utf-8'
  '.svg'='image/svg+xml'; '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'
  '.gif'='image/gif'; '.webp'='image/webp'; '.ico'='image/x-icon'; '.txt'='text/plain; charset=utf-8'
  '.xml'='application/xml; charset=utf-8'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/  (Ctrl+C to stop)"

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request; $res = $ctx.Response
    try {
      $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath).TrimStart('/')
      if ($rel -eq '') { $rel = 'index.html' }
      $path = Join-Path $root ($rel -replace '/', '\')

      # extensionless clean URLs, like Netlify / Cloudflare Pages
      if (-not (Test-Path $path -PathType Leaf) -and (Test-Path "$path.html" -PathType Leaf)) {
        $path = "$path.html"
      }
      if ((Test-Path $path -PathType Container)) { $path = Join-Path $path 'index.html' }

      # keep requests inside the site root
      $full = [System.IO.Path]::GetFullPath($path)
      if (-not $full.StartsWith([System.IO.Path]::GetFullPath($root), [StringComparison]::OrdinalIgnoreCase)) {
        $res.StatusCode = 403; $res.Close(); continue
      }

      if (-not (Test-Path $full -PathType Leaf)) {
        $res.StatusCode = 404
        $nf = Join-Path $root '404.html'
        if (Test-Path $nf) { $full = $nf } else { $res.Close(); continue }
      }

      $ext = [System.IO.Path]::GetExtension($full).ToLowerInvariant()
      $res.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
      $res.AddHeader('Cache-Control', 'no-store')
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      Write-Host ("{0} {1} -> {2}" -f $res.StatusCode, $req.Url.AbsolutePath, (Split-Path $full -Leaf))
    } catch {
      Write-Warning $_.Exception.Message
      try { $res.StatusCode = 500 } catch {}
    } finally {
      try { $res.Close() } catch {}
    }
  }
} finally {
  $listener.Stop(); $listener.Close()
}
