# Server statico locale per l'anteprima: powershell -File scripts\serve.ps1 [porta]
param([int]$Port = 8080)
if ($env:PORT) { $Port = [int]$env:PORT }
$root = Split-Path $PSScriptRoot -Parent
$types = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.json'='application/json; charset=utf-8'; '.css'='text/css' }
$l = [Net.HttpListener]::new()
$l.Prefixes.Add("http://localhost:$Port/")
$l.Start()
Write-Host "Mappa Lodi su http://localhost:$Port/"
while ($l.IsListening) {
  $c = $l.GetContext()
  $rel = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath.TrimStart('/'))
  # Salvataggio file dagli script di build (solo cartella data\, solo in locale)
  if ($rel -eq '__save' -and $c.Request.HttpMethod -eq 'POST') {
    $dest = Join-Path $root ($c.Request.QueryString['f'] -replace '/', '\')
    if ($dest.StartsWith((Join-Path $root 'data\'))) {
      $sr = [IO.StreamReader]::new($c.Request.InputStream, [Text.Encoding]::UTF8)
      [IO.File]::WriteAllText($dest, $sr.ReadToEnd(), [Text.UTF8Encoding]::new($false))
      $c.Response.StatusCode = 200
    } else { $c.Response.StatusCode = 403 }
    $c.Response.Close(); continue
  }
  if ($rel -eq '') { $rel = 'index.html' }
  $f = Join-Path $root $rel
  if ((Test-Path $f -PathType Leaf) -and $f.StartsWith($root)) {
    $b = [IO.File]::ReadAllBytes($f)
    $c.Response.ContentType = $types[[IO.Path]::GetExtension($f)]
    $c.Response.OutputStream.Write($b, 0, $b.Length)
  } else { $c.Response.StatusCode = 404 }
  $c.Response.Close()
}
