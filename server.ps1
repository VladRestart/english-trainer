# Local server for the English app: serves index.html on http://localhost:8765 so the microphone works in Chrome/Edge.
param([switch]$NoBrowser)
$port = 8765
$url = "http://localhost:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try { $listener.Start() } catch {
  # Already running: just open the page.
  if (-not $NoBrowser) { Start-Process $url }
  exit
}
if (-not $NoBrowser) { Start-Process $url }
$head = '<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"></head><body>'
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    if ($ctx.Request.Url.AbsolutePath -eq '/') {
      $page = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'index.html'), [Text.Encoding]::UTF8)
      $bytes = [Text.Encoding]::UTF8.GetBytes($head + $page + '</body></html>')
      $ctx.Response.ContentType = 'text/html; charset=utf-8'
      $ctx.Response.Headers.Add('Cache-Control', 'no-store')
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } elseif ($ctx.Request.Url.AbsolutePath -match '^/audio/([a-z0-9-]+\.mp3)$') {
      $file = Join-Path (Join-Path $PSScriptRoot 'audio') $Matches[1]
      if (Test-Path $file -PathType Leaf) {
        $bytes = [IO.File]::ReadAllBytes($file)
        $ctx.Response.ContentType = 'audio/mpeg'
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      } else { $ctx.Response.StatusCode = 404 }
    } else {
      $ctx.Response.StatusCode = 404
    }
  } finally { $ctx.Response.Close() }
}
