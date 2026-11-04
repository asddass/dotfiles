$Dotfiles = $PSScriptRoot

$gitBin = "C:\Program Files\Git\usr\bin"
if ($env:Path -notlike "*$gitBin*") { $env:Path += ";$gitBin" }

[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding']    = 'utf-8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf-8'
$env:PYTHONIOENCODING     = "utf-8"
$env:VIRTUAL_ENV_DISABLE_PROMPT = $true

function GitStatus {
    $script = "$Dotfiles\scripts\Get-GitStatus.ps1"
    if (-not (Test-Path $script)) { throw "Missing: $script" }
    & $script @args
}

function Export-GitHubIssueTree {
    $script = "$Dotfiles\scripts\Export-GitHubIssueTree.ps1"
    if (-not (Test-Path $script)) { throw "Missing: $script" }
    & $script @args
}

# Line prefix
function prompt {
    $venv = if ($env:VIRTUAL_ENV) {
        $leaf = Split-Path $env:VIRTUAL_ENV -Leaf
        if ($leaf -match '^\.?(venv|env)$') {
            $leaf = Split-Path (Split-Path $env:VIRTUAL_ENV -Parent) -Leaf
        }
        "($leaf) "
    } else { "" }

    $current = Split-Path $pwd -Leaf
    $parent  = Split-Path (Split-Path $pwd -Parent) -Leaf
    $path    = if ($parent) { "$parent\$current" } else { $current }

    return "$([char]0x2502) ${venv}${path} > "
}

function Edit-Profile   { notepad "$Dotfiles\Microsoft.PowerShell_profile.ps1" }
function Reload-Profile { . $PROFILE; Write-Host "Profile reloaded successfully." -ForegroundColor Green }
function ll { Get-ChildItem -Force @args }

try {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineOption -PredictionSource History
} catch {}
