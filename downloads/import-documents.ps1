[CmdletBinding()]
param([string]$Workspace = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
$sourceDir = Join-Path $Workspace 'input\original'
$targetDir = Join-Path $Workspace 'input\markdown'
New-Item -ItemType Directory -Force -Path $sourceDir,$targetDir | Out-Null

foreach ($command in 'pandoc','tesseract','pdftotext','pdftoppm') {
  if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Missing $command." }
}
$languages = (& tesseract --list-langs 2>&1) -join "`n"
if ($languages -notmatch '(?m)^tha$' -or $languages -notmatch '(?m)^eng$') {
  throw 'Tesseract Thai and English language data are required.'
}

$count = 0
Get-ChildItem -LiteralPath $sourceDir -File | Sort-Object Name | ForEach-Object {
  $source = $_
  $target = Join-Path $targetDir ($source.Name + '.md')
  $temporary = Join-Path ([IO.Path]::GetTempPath()) ("ai-research-import-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Force -Path $temporary | Out-Null
  $extracted = Join-Path $temporary 'extracted.txt'
  try {
    switch ($source.Extension.ToLowerInvariant()) {
      '.md'   { Copy-Item -LiteralPath $source.FullName -Destination $extracted }
      '.txt'  { Copy-Item -LiteralPath $source.FullName -Destination $extracted }
      '.docx' { & pandoc $source.FullName -t gfm -o $extracted }
      '.odt'  { & pandoc $source.FullName -t gfm -o $extracted }
      '.rtf'  { & pandoc $source.FullName -t gfm -o $extracted }
      '.html' { & pandoc $source.FullName -t gfm -o $extracted }
      '.htm'  { & pandoc $source.FullName -t gfm -o $extracted }
      '.pdf'  {
        & pdftotext -layout $source.FullName $extracted
        $text = if (Test-Path $extracted) { Get-Content -Raw $extracted } else { '' }
        if ([string]::IsNullOrWhiteSpace($text)) {
          Set-Content -Encoding utf8 $extracted ''
          & pdftoppm -png -r 300 $source.FullName (Join-Path $temporary 'page') | Out-Null
          Get-ChildItem $temporary -Filter 'page-*.png' | Sort-Object Name | ForEach-Object {
            (& tesseract $_.FullName stdout -l tha+eng 2>$null) | Add-Content -Encoding utf8 $extracted
            Add-Content -Encoding utf8 $extracted "`n"
          }
        }
      }
      { $_ -in '.png','.jpg','.jpeg','.tif','.tiff','.bmp','.webp' } {
        (& tesseract $source.FullName stdout -l tha+eng 2>$null) | Set-Content -Encoding utf8 $extracted
      }
      default { Write-Host "SKIP unsupported: $($source.Name)"; return }
    }
    @(
      "# $($source.BaseName)",
      '',
      "> Source: ``$($source.Name)``  ",
      '> Imported automatically. Compare important claims with the original file.',
      '',
      (Get-Content -Raw $extracted)
    ) | Set-Content -Encoding utf8 $target
    Write-Host "CREATED input/markdown/$($source.Name).md"
    $count++
  }
  finally { Remove-Item -Recurse -Force $temporary -ErrorAction SilentlyContinue }
}
Write-Host "IMPORT_RESULT files=$count output=input/markdown"
