$ErrorActionPreference = "Stop"

$Dotfiles = $PSScriptRoot

# 1. Profile stub setup
$realProfile = Join-Path $Dotfiles "Microsoft.PowerShell_profile.ps1"
if (-not (Test-Path $realProfile)) { throw "Missing: $realProfile" }

$stub = @"
`$dotfilesProfile = '$realProfile'
if (-not (Test-Path `$dotfilesProfile)) { throw "Missing: `$dotfilesProfile" }
. `$dotfilesProfile
"@

$docsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$targets = @(
    (Join-Path $docsPath "PowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $docsPath "WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
)

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

foreach ($target in $targets) {
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    [System.IO.File]::WriteAllText($target, $stub, $utf8NoBom)
    Write-Host "Wrote $target"
}

# 2. Dynamic .wslconfig setup
$totalRamGB = [math]::Floor((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

# RAM allocation: <=16GB -> 40% (min 6GB) | >16GB -> 60% (max 24GB)
$wslRam = if ($totalRamGB -le 16) {
    [math]::Min([math]::Max(6, [math]::Round($totalRamGB * 0.4)), [math]::Floor($totalRamGB * 0.6))
} else {
    [math]::Min(24, [math]::Round($totalRamGB * 0.6))
}

$wslConfigContent = @"
[wsl2]
memory=${wslRam}GB
swap=8GB
networkingMode=mirrored
dnsTunneling=true
autoProxy=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
"@

$wslConfigTarget = Join-Path $env:USERPROFILE ".wslconfig"
$backup = "$wslConfigTarget.bak"
if ((Test-Path $wslConfigTarget) -and -not (Test-Path $backup)) {
    Copy-Item $wslConfigTarget $backup
    Write-Host "Backed up existing config to $backup"
}
[System.IO.File]::WriteAllText($wslConfigTarget, $wslConfigContent, $utf8NoBom)
Write-Host "Wrote $wslConfigTarget ($wslRam GB RAM allocated)"
