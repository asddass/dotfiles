param(
    [Parameter(Mandatory)]
    [int]$IssueNumber,

    [string]$OutputPath = ".temp\issue-$IssueNumber.json"
)

$ErrorActionPreference = "Stop"

$parentDir = Split-Path -Parent $OutputPath
if ($parentDir) {
    New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
}

$repo = gh repo view --json nameWithOwner --jq .nameWithOwner

function Get-IssuePayload([int]$Number) {
    gh issue view $Number --json number,title,body,labels,state,comments,url |
        ConvertFrom-Json
}

function Get-SubIssueNumbers([int]$Number) {
    $raw = gh api "repos/$repo/issues/$Number/sub_issues" --paginate
    if ([string]::IsNullOrWhiteSpace($raw) -or $raw -eq "[]") { return @() }
    @($raw | ConvertFrom-Json) | ForEach-Object { $_.number }
}

function Get-IssueTree([int]$Number) {
    $issue = Get-IssuePayload $Number
    $children = @(foreach ($n in (Get-SubIssueNumbers $Number)) { Get-IssueTree $n })
    [pscustomobject]@{
        number     = $issue.number
        title      = $issue.title
        state      = $issue.state
        url        = $issue.url
        labels     = @($issue.labels)
        body       = $issue.body
        comments   = @($issue.comments)
        sub_issues = $children
    }
}

$resolvedPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path (Get-Location) $OutputPath
}

[System.IO.File]::WriteAllText(
    $resolvedPath,
    ((Get-IssueTree $IssueNumber) | ConvertTo-Json -Depth 100),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Wrote $resolvedPath"