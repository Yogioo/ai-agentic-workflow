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

foreach ($required in @("framework", "templates", "agents", "commands")) {
  if (-not (Test-Path (Join-Path $workflowDir $required))) {
    throw "Invalid workflow directory: missing '$required' folder at $workflowDir"
  }
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
  $opencodeDir = Join-Path $targetRoot ".opencode"
  $agentTargetDir = Join-Path $opencodeDir "agents"
  $commandTargetDir = Join-Path $opencodeDir "commands"

  New-DirectoryIfMissing -Path $opencodeDir -DryRun $DryRun.IsPresent
  New-DirectoryIfMissing -Path $agentTargetDir -DryRun $DryRun.IsPresent
  New-DirectoryIfMissing -Path $commandTargetDir -DryRun $DryRun.IsPresent

  $config = @{
    '$schema' = 'https://opencode.ai/config.json'
    default_agent = 'main-agent'
    instructions = @(
      "$WorkflowDirName/framework/总览入口.md",
      "$WorkflowDirName/framework/文档目录规范.md"
    )
  } | ConvertTo-Json -Depth 5

  Write-TextFile -Path (Join-Path $opencodeDir "opencode.json") -Content $config -DryRun $DryRun.IsPresent -Force $Force.IsPresent

  Install-TemplateFiles -DirectEntries @(
    @{
      SourcePath = (Join-Path $workflowDir "framework/AGENTS.template.md")
      DestinationPath = (Join-Path $targetRoot "AGENTS.md")
    }
  ) -DirectoryEntries @(
    @{
      SourceDir = (Join-Path $workflowDir "agents")
      DestinationDir = $agentTargetDir
      Filter = "*.md"
    },
    @{
      SourceDir = (Join-Path $workflowDir "commands")
      DestinationDir = $commandTargetDir
      Filter = "*.md"
    }
  ) -Variables $variables -DryRun $DryRun.IsPresent -Force $Force.IsPresent
}

Write-BootstrapDocuments -TargetRoot $targetRoot -TemplateDir $bootstrapTemplateDir -Variables $variables -IncludeHooks $IncludeHooks.IsPresent -IncludeGitHooks $IncludeGitHooks.IsPresent -DryRun $DryRun.IsPresent -Force $Force.IsPresent

$adapterArtifacts = if ($SkipAdapter) {
  @()
} else {
  @("AGENTS.md", ".opencode/opencode.json", ".opencode/agents/*.md", ".opencode/commands/*.md")
}

Show-InitializationSummary -AdapterName "OpenCode" -TargetRoot $targetRoot -AdapterArtifacts $adapterArtifacts -IncludeHooks $IncludeHooks.IsPresent -IncludeGitHooks $IncludeGitHooks.IsPresent -DryRun $DryRun.IsPresent
