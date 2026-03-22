param(
  [string]$TargetDir = "..",
  [string]$Adapter = "",
  [ValidateSet("safe", "guided", "force-system")]
  [string]$Mode = "guided",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $scriptDir "workflow-init.psm1") -Force
$workflowDir = Resolve-Path (Join-Path $scriptDir "..")
$workflowName = Split-Path $workflowDir -Leaf
$targetRoot = [System.IO.Path]::GetFullPath((Join-Path $workflowDir $TargetDir))

$metadata = Read-WorkflowMetadata -TargetRoot $targetRoot
if (-not $metadata) {
  throw "Missing .ai-agentic-workflow-meta.json in target project: $targetRoot"
}

if ([string]::IsNullOrWhiteSpace($Adapter)) {
  $Adapter = $metadata.adapter
}

if ([string]::IsNullOrWhiteSpace($Adapter)) {
  throw "Unable to determine adapter. Please pass -Adapter opencode or -Adapter claude-code."
}

$workflowDirName = if ([string]::IsNullOrWhiteSpace($metadata.workflowDirName)) { Split-Path $workflowDir -Leaf } else { $metadata.workflowDirName }
$projectName = if ([string]::IsNullOrWhiteSpace($metadata.projectName)) { Split-Path $targetRoot -Leaf } else { $metadata.projectName }

$variables = @{
  "{{WORKFLOW_DIR}}" = $workflowDirName
  "{{PROJECT_NAME}}" = $projectName
  "{{TODAY}}" = (Get-Date -Format "yyyy-MM-dd")
}

$entries = Get-ManagedEntriesForAdapter -Adapter $Adapter -WorkflowDir $workflowDir -WorkflowDirName $workflowDirName -TargetRoot $targetRoot -Variables $variables -IncludeHooks ([bool]$metadata.includeHooks) -IncludeGitHooks ([bool]$metadata.includeGitHooks)
$targetVersion = Get-WorkflowVersion -WorkflowDir $workflowDir

Invoke-WorkflowUpgrade -TargetRoot $targetRoot -WorkflowName $workflowName -InstalledVersion $metadata.installedVersion -TargetVersion $targetVersion -WorkflowDirName $workflowDirName -ProjectName $projectName -Adapter $Adapter -IncludeHooks ([bool]$metadata.includeHooks) -IncludeGitHooks ([bool]$metadata.includeGitHooks) -Entries $entries -ExistingMetadata $metadata -Mode $Mode -DryRun $DryRun.IsPresent
