
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Query,

    [Parameter(Position = 1)]
    [string]$Path = ".",

    [ValidateRange(0, 100)]
    [int]$Context = 1,

    [ValidateRange(0, [int]::MaxValue)]
    [int]$MaxResults = 0,

    [string[]]$ExcludeDirectory = @()
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
$rootPrefix = $root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar

$total = 0
$shown = 0
$stopped = $false

$files = Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue

foreach ($file in $files) {
    if ($ExcludeDirectory.Count -gt 0) {
        $relative = $file.FullName.Substring($rootPrefix.Length)
        $parts = $relative -split '[/\\]'

        $excluded = $false

        foreach ($part in $parts[0..($parts.Count - 2)]) {
            if ($ExcludeDirectory -contains $part) {
                $excluded = $true
                break
            }
        }

        if ($excluded) { continue }
    }

    $matches = @(
        Select-String -LiteralPath $file.FullName `
            -SimpleMatch `
            -Pattern $Query `
            -Context $Context, $Context `
            -ErrorAction SilentlyContinue
    )

    if ($matches.Count -eq 0) { continue }

    $relativePath = $file.FullName.Substring($rootPrefix.Length)
    Write-Host $relativePath -ForegroundColor Green

    foreach ($match in $matches) {
        $total++

        if ($MaxResults -gt 0 -and $shown -ge $MaxResults) {
            $stopped = $true
            break
        }

        foreach ($line in $match.Context.PreContext) {
            Write-Host "        $line" -ForegroundColor DarkGray
        }

        Write-Host ("        {0,5}: " -f $match.LineNumber) `
            -ForegroundColor DarkGray -NoNewline

        $line = $match.Line
        $index = 0

        while (($index = $line.IndexOf(
            $Query,
            $index,
            [StringComparison]::OrdinalIgnoreCase
        )) -ge 0) {
            if ($index -gt 0) {
                Write-Host $line.Substring(0, $index) -NoNewline
            }

            Write-Host $line.Substring($index, $Query.Length) `
                -ForegroundColor Yellow -NoNewline

            $line = $line.Substring($index + $Query.Length)
            $index = 0
        }

        Write-Host $line

        foreach ($contextLine in $match.Context.PostContext) {
            Write-Host "        $contextLine" -ForegroundColor DarkGray
        }

        $shown++
    }

    if ($stopped) { break }

    Write-Host ""
}

Write-Host ""

if ($stopped) {
    Write-Host "Showing first $shown results (limit reached)" -ForegroundColor Cyan
}
else {
    Write-Host "Showing $shown of $total results" -ForegroundColor Cyan
}

Write-Host ""
