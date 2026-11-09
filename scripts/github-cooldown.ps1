<#
.SYNOPSIS
    Prints the tag of the newest stable GitHub release that is at least a
    given number of days old.

.DESCRIPTION
    Used from a manifest's checkver script so the bucket only picks up a
    release once it has been out for a while. Drafts and pre-releases are
    ignored, and only tags matching -TagPattern are considered.

    Manifests call it relative to their own path, which checkver exposes
    as $file, and pass checkver's $GitHubToken so the
    'scoop config gh_token' setting is used when it is set:

        "checkver": {
            "script": "& \"$(Split-Path $file)\\..\\scripts\\github-cooldown.ps1\" -Repo 'owner/name' -Token $GitHubToken",
            "regex": "^v([\\d.]+)$"
        }

    Prints nothing if no release is old enough, which checkver reports as
    a failed match for that app.

    When the cooldown is holding back a newer release, a notice naming it
    and the days left is written with Write-Host, which checkver does not
    capture, so the version it matches is unaffected. Under GitHub Actions
    the notice uses the ::notice:: workflow command so it shows on the
    run's summary page; elsewhere it is a plain coloured line.

    Run from a terminal, it then asks whether to take the held release
    now. A yes returns that release's tag instead, so checkver -Update
    writes it into the manifest; without -Update the answer only changes
    the version checkver reports. The question is skipped, and the answer
    taken as no, under CI, when input is redirected, or when the session
    cannot prompt.

.PARAMETER Repo
    GitHub repository as owner/name.

.PARAMETER Days
    Minimum age of a release in days. Defaults to 7.

.PARAMETER TagPattern
    Regex a tag must match to be considered. Defaults to plain v-prefixed
    version tags such as v1.2.3.

.PARAMETER Token
    GitHub token. Falls back to SCOOP_GH_TOKEN, GH_TOKEN, then GITHUB_TOKEN.
    Without one, GitHub allows 60 API requests an hour.
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $Repo,
    [int] $Days = 7,
    [string] $TagPattern = '^v[\d.]+$',
    [string] $Token
)

$now = [DateTime]::UtcNow
$cutoff = $now.AddDays(-$Days)

# Authenticate when a token is available, to avoid the anonymous rate limit
$headers = @{ 'User-Agent' = 'scoop-checkver' }
if (-not $Token) {
    $Token = $env:SCOOP_GH_TOKEN, $env:GH_TOKEN, $env:GITHUB_TOKEN | Where-Object { $_ } | Select-Object -First 1
}
if ($Token) { $headers.Authorization = "Bearer $Token" }

$releases = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$Repo/releases?per_page=50"

# Stable releases with a matching tag, newest first
$stable = @(
    $releases |
        Where-Object { -not $_.draft -and -not $_.prerelease -and $_.tag_name -match $TagPattern } |
        Sort-Object { [DateTimeOffset]$_.published_at } -Descending
)

# The newest of those that has served its cooldown
$picked = $stable |
    Where-Object { ([DateTimeOffset]$_.published_at).UtcDateTime -lt $cutoff } |
    Select-Object -First 1

# Report a newer release that the cooldown is holding back
$newest = $stable | Select-Object -First 1
if ($newest -and $newest.tag_name -ne $picked.tag_name) {
    $published = ([DateTimeOffset]$newest.published_at).UtcDateTime
    $remaining = [int][Math]::Ceiling(($published.AddDays($Days) - $now).TotalDays)
    $dayWord = if ($remaining -eq 1) { 'day' } else { 'days' }
    $current = if ($picked) { "staying on $($picked.tag_name)" } else { 'no release is old enough yet' }
    $message = "$($newest.tag_name) (published $($published.ToString('yyyy-MM-dd'))) is held for $remaining more $dayWord, $current"

    if ($env:GITHUB_ACTIONS -eq 'true') {
        Write-Host "::notice title=$Repo cooldown::$message"
    } else {
        Write-Host "${Repo}: $message" -ForegroundColor Yellow

        # Offer to skip the cooldown only when someone is there to answer
        $canPrompt = -not $env:CI -and
            [Environment]::UserInteractive -and
            -not [Console]::IsInputRedirected
        if ($canPrompt) {
            try {
                $answer = Read-Host "Take $($newest.tag_name) now, skipping the cooldown? [y/N]"
            } catch {
                $answer = ''
            }
            if ($answer -match '^\s*y(es)?\s*$') { $picked = $newest }
        }
    }
}

if ($picked) { $picked.tag_name }
