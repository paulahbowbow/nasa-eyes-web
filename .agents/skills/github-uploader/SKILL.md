---
name: github-uploader
description: >-
  Uploads, updates, or pushes code and files to a GitHub repository.
  Activate this skill whenever the user asks to "upload code to GitHub", "push to GitHub",
  "deploy to GitHub Pages", or update their repository (e.g. paulahbowbow/nasa-eyes-web).
---

# GitHub Uploader Skill

This skill allows the agent to automatically upload, commit, and push files from local workspace projects to remote GitHub repositories, enabling zero-friction GitHub Pages deployments and version control updates.

## Supported Upload Methods

### Method A: Direct GitHub REST API (No Git Installation Required)
Use this method when Git is not installed locally on Windows, or when fast single-file/multi-file upload directly to a branch is desired.

#### Script
Execute the helper PowerShell script located at:
`./scripts/upload_to_github.ps1`

Syntax:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Paul Cheng\.gemini\config\skills\github-uploader\scripts\upload_to_github.ps1" `
  -Owner "paulahbowbow" `
  -Repo "nasa-eyes-web" `
  -Branch "main" `
  -FilePath "c:\Users\Paul Cheng\Documents\Beetle Web\index.html" `
  -CommitMessage "Update NASA Eyes web application"
```

The script:
1. Checks for GitHub token in `$env:GITHUB_TOKEN` or prompts for user Personal Access Token (PAT).
2. Reads the file as UTF-8 / binary and converts to Base64.
3. Retrieves current remote file SHA if updating an existing file.
4. Executes a `PUT /repos/:owner/:repo/contents/:path` request.
5. Verifies HTTP 200/201 response and reports commit URL.

### Method B: Git CLI Workflow (When Git is Installed)
If `git` command is available:
1. Verify repository remote:
   `git remote -v`
   If not initialized:
   `git init`
   `git remote add origin https://github.com/paulahbowbow/nasa-eyes-web.git`
2. Stage and commit:
   `git add .`
   `git commit -m "Update NASA Eyes 3D dashboard"`
3. Push to branch:
   `git push origin main`

## Verification & Deployment
After uploading:
1. Check the GitHub Pages deployment status.
2. Confirm the live URL: `https://<owner>.github.io/<repo>/` (e.g. `https://paulahbowbow.github.io/nasa-eyes-web/`).
