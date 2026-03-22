<#
Shared helpers for workflow initialization scripts.
- file and directory creation with DryRun/Force behavior
- template rendering for direct files, directories, and bootstrap docs
- consistent final summary output for different adapters
#>

function New-DirectoryIfMissing {
  param(
    [string]$Path,
    [bool]$DryRun
  )

  if ($DryRun) {
    Write-Host "[DryRun] Ensure directory: $Path"
    return
  }

  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Write-TextFile {
  param(
    [string]$Path,
    [string]$Content,
    [bool]$DryRun,
    [bool]$Force
  )

  if ((Test-Path $Path) -and -not $Force) {
    Write-Host "Skip existing: $Path"
    return
  }

  if ($DryRun) {
    $action = if (Test-Path $Path) { "Overwrite" } else { "Write" }
    Write-Host "[DryRun] $action file: $Path"
    return
  }

  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
  Write-Host "Wrote: $Path"
}

function Get-RenderedTemplate {
  param(
    [string]$SourcePath,
    [hashtable]$Variables
  )

  $content = Get-Content -Path $SourcePath -Raw -Encoding UTF8
  foreach ($key in $Variables.Keys) {
    $content = $content.Replace($key, $Variables[$key])
  }

  return $content
}

function Write-RenderedFiles {
  param(
    [array]$Entries,
    [hashtable]$Variables,
    [bool]$DryRun,
    [bool]$Force
  )

  foreach ($entry in $Entries) {
    $content = Get-RenderedTemplate -SourcePath $entry.SourcePath -Variables $Variables
    Write-TextFile -Path $entry.DestinationPath -Content $content -DryRun $DryRun -Force $Force
  }
}

function Get-DirectoryRenderEntries {
  param(
    [string]$SourceDir,
    [string]$DestinationDir,
    [string]$Filter = "*"
  )

  return Get-ChildItem -Path $SourceDir -File -Filter $Filter | ForEach-Object {
    @{
      SourcePath = $_.FullName
      DestinationPath = (Join-Path $DestinationDir $_.Name)
    }
  }
}

function Install-TemplateFiles {
  param(
    [array]$DirectEntries,
    [array]$DirectoryEntries,
    [hashtable]$Variables,
    [bool]$DryRun,
    [bool]$Force
  )

  $renderEntries = @()

  if ($DirectEntries) {
    $renderEntries += $DirectEntries
  }

  foreach ($entry in ($DirectoryEntries | Where-Object { $null -ne $_ })) {
    $renderEntries += Get-DirectoryRenderEntries -SourceDir $entry.SourceDir -DestinationDir $entry.DestinationDir -Filter $entry.Filter
  }

  if ($renderEntries.Count -gt 0) {
    Write-RenderedFiles -Entries $renderEntries -Variables $Variables -DryRun $DryRun -Force $Force
  }
}

function Write-BootstrapDocuments {
  param(
    [string]$TargetRoot,
    [string]$TemplateDir,
    [hashtable]$Variables,
    [bool]$IncludeHooks,
    [bool]$IncludeGitHooks,
    [bool]$DryRun,
    [bool]$Force
  )

  $bootstrapEntries = @(
    @{ Path = (Join-Path $TargetRoot "当前PRD.md"); Template = "当前PRD.md" },
    @{ Path = (Join-Path $TargetRoot "当前RoadMap.md"); Template = "当前RoadMap.md" },
    @{ Path = (Join-Path $TargetRoot "BUG追踪.md"); Template = "BUG追踪.md" },
    @{ Path = (Join-Path $TargetRoot "当前阶段Kanban.md"); Template = "当前阶段Kanban.md" },
    @{ Path = (Join-Path $TargetRoot "当前状态快照.md"); Template = "当前状态快照.md" }
  )

  $renderEntries = foreach ($entry in $bootstrapEntries) {
    @{
      SourcePath = (Join-Path $TemplateDir $entry.Template)
      DestinationPath = $entry.Path
    }
  }

  Write-RenderedFiles -Entries $renderEntries -Variables $Variables -DryRun $DryRun -Force $Force

  if ($IncludeHooks) {
    $hooksTemplateName = if ($IncludeGitHooks) { "当前Hooks.git.md" } else { "当前Hooks.default.md" }
    Write-RenderedFiles -Entries @(
      @{
        SourcePath = (Join-Path $TemplateDir $hooksTemplateName)
        DestinationPath = (Join-Path $TargetRoot "当前Hooks.md")
      }
    ) -Variables $Variables -DryRun $DryRun -Force $Force
  }
}

function Show-InitializationSummary {
  param(
    [string]$AdapterName,
    [string]$TargetRoot,
    [array]$AdapterArtifacts,
    [bool]$IncludeHooks,
    [bool]$IncludeGitHooks,
    [bool]$DryRun
  )

  Write-Host ""
  Write-Host "$AdapterName project initialized at: $TargetRoot"
  Write-Host "Created or preserved:"

  foreach ($artifact in ($AdapterArtifacts | Where-Object { $null -ne $_ })) {
    Write-Host "- $artifact"
  }

  foreach ($artifact in @("当前PRD.md", "当前RoadMap.md", "BUG追踪.md", "当前阶段Kanban.md", "当前状态快照.md")) {
    Write-Host "- $artifact"
  }

  if ($IncludeHooks) {
    Write-Host "- 当前Hooks.md"
    if ($IncludeGitHooks) {
      Write-Host "  - Included Git hook template"
    }
  }

  if ($DryRun) {
    Write-Host "Dry run only: no files were changed."
  }
}

Export-ModuleMember -Function New-DirectoryIfMissing, Write-TextFile, Get-RenderedTemplate, Write-RenderedFiles, Get-DirectoryRenderEntries, Install-TemplateFiles, Write-BootstrapDocuments, Show-InitializationSummary
