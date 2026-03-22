param(
  [string]$TargetDir = "..",
  [string]$ProjectName = "",
  [string]$WorkflowDirName = "",
  [switch]$IncludeHooks,
  [switch]$IncludeGitHooks,
  [switch]$SkipAdapter,
  [switch]$DryRun,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $scriptDir "workflow-init.psm1") -Force
$workflowDir = Resolve-Path (Join-Path $scriptDir "..")
$workflowName = Split-Path $workflowDir -Leaf
$targetRoot = [System.IO.Path]::GetFullPath((Join-Path $workflowDir $TargetDir))

if ([string]::IsNullOrWhiteSpace($WorkflowDirName)) {
  $WorkflowDirName = $workflowName
}

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  $ProjectName = Split-Path $targetRoot -Leaf
}

foreach ($required in @("framework", "templates", "claude")) {
  if (-not (Test-Path (Join-Path $workflowDir $required))) {
    throw "Invalid workflow directory: missing '$required' folder at $workflowDir"
  }
}

if (-not (Test-Path (Join-Path $workflowDir "claude/agents"))) {
  throw "Invalid workflow directory: missing 'claude/agents' folder at $workflowDir"
}

if (-not (Test-Path (Join-Path $workflowDir "claude/commands"))) {
  throw "Invalid workflow directory: missing 'claude/commands' folder at $workflowDir"
}

if ($targetRoot -eq $workflowDir.Path) {
  throw "Target directory cannot be the workflow directory itself: $targetRoot"
}

$variables = @{
  "{{WORKFLOW_DIR}}" = $WorkflowDirName
  "{{PROJECT_NAME}}" = $ProjectName
  "{{TODAY}}" = (Get-Date -Format "yyyy-MM-dd")
}

$bootstrapTemplateDir = Join-Path $workflowDir "templates/bootstrap"

New-DirectoryIfMissing -Path $targetRoot -DryRun $DryRun.IsPresent

if (-not $SkipAdapter) {
  $claudeDir = Join-Path $targetRoot ".claude"
  $agentTargetDir = Join-Path $claudeDir "agents"
  $commandTargetDir = Join-Path $claudeDir "commands"

  New-DirectoryIfMissing -Path $claudeDir -DryRun $DryRun.IsPresent
  New-DirectoryIfMissing -Path $agentTargetDir -DryRun $DryRun.IsPresent
  New-DirectoryIfMissing -Path $commandTargetDir -DryRun $DryRun.IsPresent

  Install-TemplateFiles -DirectEntries @(
    @{
      SourcePath = (Join-Path $workflowDir "claude/CLAUDE.template.md")
      DestinationPath = (Join-Path $targetRoot "CLAUDE.md")
    },
    @{
      SourcePath = (Join-Path $workflowDir "claude/settings.template.json")
      DestinationPath = (Join-Path $claudeDir "settings.json")
    }
  ) -DirectoryEntries @(
    @{
      SourceDir = (Join-Path $workflowDir "claude/agents")
      DestinationDir = $agentTargetDir
      Filter = "*.md"
    },
    @{
      SourceDir = (Join-Path $workflowDir "claude/commands")
      DestinationDir = $commandTargetDir
      Filter = "*.md"
    }
  ) -Variables $variables -DryRun $DryRun.IsPresent -Force $Force.IsPresent
}

Write-BootstrapDocuments -TargetRoot $targetRoot -TemplateDir $bootstrapTemplateDir -Variables $variables -IncludeHooks $IncludeHooks.IsPresent -IncludeGitHooks $IncludeGitHooks.IsPresent -DryRun $DryRun.IsPresent -Force $Force.IsPresent

$adapterArtifacts = if ($SkipAdapter) {
  @()
} else {
  @("CLAUDE.md", ".claude/settings.json", ".claude/agents/*.md", ".claude/commands/*.md")
}

Show-InitializationSummary -AdapterName "Claude Code" -TargetRoot $targetRoot -AdapterArtifacts $adapterArtifacts -IncludeHooks $IncludeHooks.IsPresent -IncludeGitHooks $IncludeGitHooks.IsPresent -DryRun $DryRun.IsPresent
