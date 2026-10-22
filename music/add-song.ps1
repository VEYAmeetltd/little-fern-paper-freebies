param(
    [Parameter(Mandatory = $true)][string]$AudioPath,
    [Parameter(Mandatory = $true)][string]$Title,
    [string]$Description = 'A little song to listen to together.',
    [string]$Tag = 'LITTLE MUSIC CORNER',
    [switch]$Publish
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$music = Join-Path $PSScriptRoot 'v1'
$manifestPath = Join-Path $music 'songs.json'
$trackDir = Join-Path $music 'tracks'
$source = (Resolve-Path -LiteralPath $AudioPath -ErrorAction Stop).Path
$file = Get-Item -LiteralPath $source
if ($file.Extension.ToLowerInvariant() -ne '.mp3') { throw 'Choose an MP3 file.' }
if ($file.Length -lt 1000 -or $file.Length -gt 20000000) { throw 'MP3 must be between 1 KB and 20 MB.' }
if ($Title.Trim().Length -lt 1 -or $Title.Length -gt 100) { throw 'Title must be 1 to 100 characters.' }
if ($Description.Length -gt 180 -or $Tag.Length -gt 40) { throw 'Description or tag is too long.' }
$slug = ($Title.Trim().ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
if (-not $slug -or $slug.Length -gt 80) { throw 'Title needs Latin letters or digits and a shorter song name.' }

$bytes = [byte[]]::new(3)
$stream = [System.IO.File]::OpenRead($source)
try { [void]$stream.Read($bytes, 0, 3) } finally { $stream.Dispose() }
if (-not (($bytes[0] -eq 73 -and $bytes[1] -eq 68 -and $bytes[2] -eq 51) -or ($bytes[0] -eq 255 -and ($bytes[1] -band 224) -eq 224))) {
    throw 'The file does not appear to be MP3 audio.'
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.schema -ne 1 -or -not $manifest.songs) { throw 'Song list is invalid.' }
$existing = @($manifest.songs | Where-Object { $_.id -eq $slug })
if (-not $existing -and @($manifest.songs).Count -ge 30) { throw 'Song list is full.' }
New-Item -ItemType Directory -Force -Path $trackDir | Out-Null
$target = Join-Path $trackDir "$slug.mp3"
if ($existing) {
    if ($existing.Count -ne 1 -or $existing[0].title -ne $Title.Trim() -or $existing[0].description -ne $Description.Trim() -or $existing[0].tag -ne $Tag.Trim().ToUpperInvariant()) {
        throw "Song '$slug' exists with different details. Edit the manifest deliberately to change it."
    }
    if (-not (Test-Path -LiteralPath $target) -or (Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
        throw "Song '$slug' exists with different audio."
    }
} else {
    if (Test-Path -LiteralPath $target) { throw "The audio file '$slug.mp3' already exists." }
    Copy-Item -LiteralPath $source -Destination $target
    $manifest.songs += [pscustomobject]@{
        id = $slug
        title = $Title.Trim()
        description = $Description.Trim()
        tag = $Tag.Trim().ToUpperInvariant()
        audio = "tracks/$slug.mp3"
    }
    [System.IO.File]::WriteAllText($manifestPath, (($manifest | ConvertTo-Json -Depth 5) + "`n"), [System.Text.UTF8Encoding]::new($false))
}
Write-Host "Song '$Title' is ready in the local public song list."
if ($Publish) {
    Push-Location $root
    try {
        if ((git branch --show-current) -ne 'main') { throw 'Switch this site to its main branch before publishing.' }
        git add -- "music/v1/tracks/$slug.mp3" 'music/v1/songs.json'
        if ($LASTEXITCODE -ne 0) { throw 'Git staging failed.' }
        $staged = git diff --cached --name-only -- "music/v1/tracks/$slug.mp3" 'music/v1/songs.json'
        if ($staged) {
            git commit -m "Add Lovely Little Days song: $slug" -- "music/v1/tracks/$slug.mp3" 'music/v1/songs.json'
            if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
        }
        git push origin main
        if ($LASTEXITCODE -ne 0) { throw 'Git push failed. The files remain saved locally.' }
        Write-Host "Published. The app will show the new song after GitHub Pages updates and listeners reopen the music screen."
    } finally { Pop-Location }
} else {
    Write-Host "Run with -Publish to publish it to the existing song host when it is ready."
}
