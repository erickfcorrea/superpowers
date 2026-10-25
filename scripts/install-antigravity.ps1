<#
.SYNOPSIS
Installs or updates Superpowers as a global Antigravity plugin and workflow.

.DESCRIPTION
Copies skills, manifest, rules, and global slash command workflow to ~/.gemini/config/
making Superpowers immediately accessible across any project in Antigravity IDE.
#>

[CmdletBinding()]
param(
    [string]$ConfigDir = "$env:USERPROFILE\.gemini\config"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Installing Superpowers for Antigravity IDE ===" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

$TargetPluginDir = Join-Path $ConfigDir "plugins\superpowers"
$TargetWorkflowDir = Join-Path $ConfigDir "global_workflows"

# 1. Ensure plugin directory
if (-not (Test-Path $TargetPluginDir)) {
    New-Item -ItemType Directory -Force -Path $TargetPluginDir | Out-Null
}

# 2. Copy manifest
$ManifestSource = Join-Path $RepoRoot ".antigravity-plugin\plugin.json"
$ManifestDest = Join-Path $TargetPluginDir "plugin.json"
Copy-Item -Force -Path $ManifestSource -Destination $ManifestDest
Write-Host "[OK] Plugin manifest installed -> $ManifestDest" -ForegroundColor Green

# 3. Copy skills
$SkillsSource = Join-Path $RepoRoot "skills"
$SkillsDest = Join-Path $TargetPluginDir "skills"
if (Test-Path $SkillsDest) {
    Remove-Item -Recurse -Force -Path $SkillsDest
}
Copy-Item -Recurse -Force -Path $SkillsSource -Destination $SkillsDest
Write-Host "[OK] Skills synchronized -> $SkillsDest" -ForegroundColor Green

# 4. Copy rules
$RulesSource = Join-Path $RepoRoot ".agents\rules"
$RulesDest = Join-Path $TargetPluginDir "rules"
if (Test-Path $RulesSource) {
    if (Test-Path $RulesDest) {
        Remove-Item -Recurse -Force -Path $RulesDest
    }
    Copy-Item -Recurse -Force -Path $RulesSource -Destination $RulesDest
    Write-Host "[OK] Rules synchronized -> $RulesDest" -ForegroundColor Green
}

# 5. Register global workflow (/superpowers)
$WorkflowSource = Join-Path $RepoRoot ".agents\workflows\superpowers.md"
if (Test-Path $WorkflowSource) {
    if (-not (Test-Path $TargetWorkflowDir)) {
        New-Item -ItemType Directory -Force -Path $TargetWorkflowDir | Out-Null
    }
    $WorkflowDest = Join-Path $TargetWorkflowDir "superpowers.md"
    Copy-Item -Force -Path $WorkflowSource -Destination $WorkflowDest
    Write-Host "[OK] Global slash command registered -> /superpowers" -ForegroundColor Green
}

Write-Host "`nSuperpowers is now globally active in Antigravity IDE!" -ForegroundColor Cyan
Write-Host "You can use it at any time in chat by typing '/superpowers' or starting tasks." -ForegroundColor Yellow
