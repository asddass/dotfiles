<#
.SYNOPSIS
    Scans subdirectories and shows which repos have uncommitted changes.

.DESCRIPTION
    Runs git status on every direct subfolder in the target directory.
    Clean repos are hidden by default so you can focus on what needs attention.
    Only direct subdirectories are scanned, not nested ones.

.PARAMETER Path
    Directory to scan. Defaults to the current directory.

.PARAMETER All
    Include clean repos in the output.

.PARAMETER Help
    Show detailed help.

.EXAMPLE
    .\Get-GitStatus.ps1
    Scans the current directory.

.EXAMPLE
    .\Get-GitStatus.ps1 C:\repos
    Scans a specific directory.

.EXAMPLE
    .\Get-GitStatus.ps1 -All
    Includes clean repos alongside dirty ones.
#>

param(
    [string]$Path = (Get-Location),
    [switch]$All,
    [switch]$Help
)

if ($Help) { Get-Help $PSCommandPath -Detailed; return }
if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path" -ForegroundColor Red; return }

Get-ChildItem -Path $Path -Directory | ForEach-Object {
    $status = git -C $_.FullName -c color.status=always status --short 2>$null
    if ($status -or $All) {
        Write-Host "`n=== $($_.Name) ===" -ForegroundColor Cyan
        if ($status) { $status } else { Write-Host "  clean" -ForegroundColor DarkGray }
    }
}