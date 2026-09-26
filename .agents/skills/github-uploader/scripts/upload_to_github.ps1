param(
  [string]$Owner = "paulahbowbow",
  [string]$Repo = "nasa-eyes-web",
  [string]$Branch = "main",
  [Parameter(Mandatory=$true)]
  [string]$FilePath,
  [string]$RemotePath = "",
  [string]$CommitMessage = "Update via Antigravity GitHub Uploader",
  [string]$Token = ""
)

$ErrorActionPreference = "Stop"

# Resolve target file
if (-not (Test-Path $FilePath)) {
  Write-Error "Local file not found: $FilePath"
  exit 1
}

if ([string]::IsNullOrWhiteSpace($RemotePath)) {
  $RemotePath = Split-Path $FilePath -Leaf
}

# Resolve GitHub Token
$tokenFile = "C:\Users\Paul Cheng\.gemini\config\github_token.txt"
if ([string]::IsNullOrWhiteSpace($Token)) {
  if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    $Token = $env:GITHUB_TOKEN
  } elseif (Test-Path $tokenFile) {
    $Token = (Get-Content $tokenFile -Raw).Trim()
  }
}

if ([string]::IsNullOrWhiteSpace($Token)) {
  Write-Warning "GitHub Personal Access Token (PAT) not found."
  Write-Host "Please provide a token with 'repo' scope via -Token parameter, or save it to: $tokenFile"
  Write-Host "Generate token here: https://github.com/settings/tokens?scopes=repo"
  exit 2
}

$headers = @{
  "Authorization" = "Bearer $Token"
  "Accept"        = "application/vnd.github.v3+json"
  "User-Agent"    = "Antigravity-GitHub-Uploader"
}

# 1. Check if file already exists on GitHub to obtain its SHA
$sha = $null
$apiUrl = "https://api.github.com/repos/$Owner/$Repo/contents/$RemotePath?ref=$Branch"

try {
  $existing = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers -ErrorAction SilentlyContinue
  if ($existing -and $existing.sha) {
    $sha = $existing.sha
    Write-Host "[Info] Existing file found on GitHub with SHA: $sha (Will update file)"
  }
} catch {
  Write-Host "[Info] File does not exist yet on remote. (Will create new file)"
}

# 2. Encode local file bytes to Base64
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $FilePath).Path)
$base64Content = [Convert]::ToBase64String($bytes)

# 3. Prepare payload
$bodyObj = @{
  message = $CommitMessage
  content = $base64Content
  branch  = $Branch
}

if ($sha) {
  $bodyObj["sha"] = $sha
}

$jsonBody = $bodyObj | ConvertTo-Json -Compress

# 4. Upload to GitHub via REST API
Write-Host "[Uploading] $FilePath -> github.com/$Owner/$Repo/blob/$Branch/$RemotePath ..."
try {
  $putUrl = "https://api.github.com/repos/$Owner/$Repo/contents/$RemotePath"
  $response = Invoke-RestMethod -Uri $putUrl -Method Put -Headers $headers -Body $jsonBody -ContentType "application/json; charset=utf-8"

  Write-Host "[SUCCESS] Successfully uploaded to GitHub!" -ForegroundColor Green
  Write-Host "Commit SHA : $($response.commit.sha)"
  Write-Host "Commit URL : $($response.commit.html_url)"
  Write-Host "File URL   : $($response.content.html_url)"
  Write-Host "Pages URL  : https://$Owner.github.io/$Repo/" -ForegroundColor Cyan
} catch {
  Write-Error "Failed to upload file to GitHub: $_"
  exit 1
}
