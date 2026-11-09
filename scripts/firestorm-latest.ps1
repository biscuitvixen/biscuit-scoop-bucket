<#
.SYNOPSIS
    Prints the newest Firestorm version for a channel whose installer is
    on the download host and, for stable, has been tagged for at least a
    given number of days.

.DESCRIPTION
    The Firestorm website sits behind a Cloudflare challenge, so the
    version is read from the tags of FirestormViewer/phoenix-firestorm
    instead: every public build is tagged Firestorm_Release_x.y.z.build or
    Firestorm_Beta_x.y.z.build. The tags are lightweight, so the tagged
    commit's committer date stands in for the release date.

    A tag alone is not enough. The installer is uploaded separately, the
    preview host keeps only the newest beta, and a build can be pulled, so
    each candidate's installer URL is checked with a HEAD request and
    tags without one are skipped. Only the five newest tags are
    considered, which bounds the API calls per run.

    Manifests call it relative to their own path, which checkver exposes
    as $file, and pass checkver's $GitHubToken:

        "checkver": {
            "script": "& \"$(Split-Path $file)\..\scripts\firestorm-latest.ps1\" -Channel Release -Days 7 -Token $GitHubToken",
            "regex": "^([\d.]+)$"
        }

    Prints nothing if no version qualifies, which checkver reports as a
    failed match for that app. Skipped tags are reported with Write-Host,
    which checkver does not capture: as ::notice:: workflow commands
    under GitHub Actions, otherwise as plain coloured lines.

.PARAMETER Channel
    Release or Beta. Selects the tag prefix, the download host folder and
    the installer file name.

.PARAMETER Days
    Minimum age of the tagged commit in days. Defaults to 7; 0 disables
    the cooldown.

.PARAMETER Token
    GitHub token. Falls back to SCOOP_GH_TOKEN, GH_TOKEN, then GITHUB_TOKEN.
    Without one, GitHub allows 60 API requests an hour.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Release', 'Beta')]
    [string] $Channel,
    [int] $Days = 7,
    [string] $Token
)

$repo = 'FirestormViewer/phoenix-firestorm'
$prefix = "Firestorm_${Channel}_"
$folder = @{ Release = 'release'; Beta = 'preview' }[$Channel]
$now = [DateTime]::UtcNow
$cutoff = $now.AddDays(-$Days)

# Authenticate when a token is available, to avoid the anonymous rate limit
$headers = @{ 'User-Agent' = 'scoop-checkver' }
if (-not $Token) {
    $Token = $env:SCOOP_GH_TOKEN, $env:GH_TOKEN, $env:GITHUB_TOKEN | Where-Object { $_ } | Select-Object -First 1
}
if ($Token) { $headers.Authorization = "Bearer $Token" }

function Write-Skipped([string] $message) {
    if ($env:GITHUB_ACTIONS -eq 'true') {
        Write-Host "::notice title=Firestorm $Channel::$message"
    } else {
        Write-Host "Firestorm ${Channel}: $message" -ForegroundColor Yellow
    }
}

# Version tags for the channel, newest first. [version] sorts the four
# numeric parts properly, where a string sort would not.
$refs = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$repo/git/matching-refs/tags/$prefix"
$candidates = @(
    $refs |
        ForEach-Object {
            if ($_.ref -match "^refs/tags/$prefix(\d+\.\d+\.\d+\.\d+)$") {
                [pscustomobject]@{ Version = [version]$Matches[1]; Ref = $_ }
            }
        } |
        Sort-Object Version -Descending |
        Select-Object -First 5
)

foreach ($candidate in $candidates) {
    $version = $candidate.Version.ToString()

    # Cooldown: the tag points straight at a commit, whose committer date
    # is the closest thing to a release date
    if ($Days -gt 0) {
        $commit = Invoke-RestMethod -Headers $headers -Uri $candidate.Ref.object.url
        $tagged = ([DateTimeOffset]$commit.committer.date).UtcDateTime
        if ($tagged -ge $cutoff) {
            $remaining = [int][Math]::Ceiling(($tagged.AddDays($Days) - $now).TotalDays)
            $dayWord = if ($remaining -eq 1) { 'day' } else { 'days' }
            Write-Skipped "$version (tagged $($tagged.ToString('yyyy-MM-dd'))) is held for $remaining more $dayWord"
            continue
        }
    }

    # The installer must be on the download host before the version is
    # offered, otherwise the tag is ahead of the upload or the build was
    # pulled
    $dashed = $version -replace '\.', '-'
    $url = "https://downloads.firestormviewer.org/$folder/windows/Phoenix-Firestorm-${Channel}x64_AVX2-${dashed}_Setup.exe"
    try {
        $response = Invoke-WebRequest -Method Head -Uri $url -UseBasicParsing
        $status = [int]$response.StatusCode
    } catch {
        $status = [int]$_.Exception.Response.StatusCode
    }
    if ($status -ne 200) {
        Write-Skipped "$version is tagged but its installer is not on the download host (HTTP $status)"
        continue
    }

    $version
    return
}
