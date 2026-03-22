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

$workflowVersion = Get-WorkflowVersion -WorkflowDir $workflowDir

New-DirectoryIfMissing -Path $targetRoot -DryRun $DryRun.IsPresent
$entries = Get-ManagedEntriesForAdapter -Adapter "claude-code" -WorkflowDir $workflowDir -WorkflowDirName $WorkflowDirName -TargetRoot $targetRoot -Variables $variables -IncludeHooks $IncludeHooks.IsPresent -IncludeGitHooks $IncludeGitHooks.IsPresent

if ($SkipAdapter) {
  $entries = @($entries | Where-Object { $_.Category -ne "system" })
}
else {
  foreach ($path in @(
    (Join-Path $targetRoot ".claude"),
    (Join-Path $targetRoot ".claude/agents"),
    (Join-Path $targetRoot ".claude/commands")
  )) {
    New-DirectoryIfMissing -Path $path -DryRun $DryRun.IsPresent
  }
}

Install-ManagedEntries -Entries $entries -TargetRoot $targetRoot -DryRun $DryRun.IsPresent -Force $Force.IsPresent
Write-WorkflowMetadata -TargetRoot $targetRoot -WorkflowName $workflowName -InstalledVersion $workflowVersion -WorkflowDirName $WorkflowDirName -ProjectName $ProjectName -Adapter "claude-code" -IncludeHooks $IncludeHooks.IsPresent -IncludeGitHooks $IncludeGitHooks.IsPresent -Entries $entries -DryRun $DryRun.IsPresent
Show-InitializationSummary -AdapterName "Claude Code" -TargetRoot $targetRoot -Entries $entries -DryRun $DryRun.IsPresent
