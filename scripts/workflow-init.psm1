<#
Shared helpers for workflow initialization and upgrade scripts.
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

function Get-NormalizedRelativePath {
  param(
    [string]$Path
  )

  return ($Path -replace "\\", "/")
}

function Get-WorkflowVersion {
  param(
    [string]$WorkflowDir
  )

  $versionPath = Join-Path $WorkflowDir "VERSION"
  if (-not (Test-Path $versionPath)) {
    return "0.0.0"
  }

  return (Get-Content -Path $versionPath -Raw -Encoding UTF8).Trim()
}

function Get-StringHash {
  param(
    [string]$Content
  )

  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hash = $sha.ComputeHash($bytes)
    return "sha256:{0}" -f ([System.BitConverter]::ToString($hash).Replace("-", "").ToLowerInvariant())
  }
  finally {
    $sha.Dispose()
  }
}

function Get-FileHashString {
  param(
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    return $null
  }

  $hash = Get-FileHash -Algorithm SHA256 -Path $Path
  return "sha256:{0}" -f $hash.Hash.ToLowerInvariant()
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
    return $false
  }

  if ($DryRun) {
    $action = if (Test-Path $Path) { "Overwrite" } else { "Write" }
    Write-Host "[DryRun] $action file: $Path"
    return $true
  }

  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
  Write-Host "Wrote: $Path"
  return $true
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

function New-ManagedTemplateEntry {
  param(
    [string]$Path,
    [string]$SourceRelativePath,
    [string]$SourcePath,
    [string]$Category,
    [string]$Strategy,
    [hashtable]$Variables
  )

  $content = Get-RenderedTemplate -SourcePath $SourcePath -Variables $Variables
  return [pscustomobject]@{
    Path = (Get-NormalizedRelativePath -Path $Path)
    Source = (Get-NormalizedRelativePath -Path $SourceRelativePath)
    SourcePath = $SourcePath
    Category = $Category
    Strategy = $Strategy
    Content = $content
    TemplateHash = (Get-StringHash -Content $content)
  }
}

function New-ManagedContentEntry {
  param(
    [string]$Path,
    [string]$Source,
    [string]$Category,
    [string]$Strategy,
    [string]$Content
  )

  return [pscustomobject]@{
    Path = (Get-NormalizedRelativePath -Path $Path)
    Source = $Source
    SourcePath = $null
    Category = $Category
    Strategy = $Strategy
    Content = $Content
    TemplateHash = (Get-StringHash -Content $Content)
  }
}

function Get-ManagedEntriesForAdapter {
  param(
    [string]$Adapter,
    [string]$WorkflowDir,
    [string]$WorkflowDirName,
    [string]$TargetRoot,
    [hashtable]$Variables,
    [bool]$IncludeHooks,
    [bool]$IncludeGitHooks
  )

  $entries = @()
  $bootstrapTemplateDir = Join-Path $WorkflowDir "templates/bootstrap"

  switch ($Adapter) {
    "opencode" {
      $config = @{
        '$schema' = 'https://opencode.ai/config.json'
        default_agent = 'main-agent'
        instructions = @(
          "$WorkflowDirName/framework/总览入口.md",
          "$WorkflowDirName/framework/文档目录规范.md"
        )
      } | ConvertTo-Json -Depth 5

      $entries += New-ManagedTemplateEntry -Path "AGENTS.md" -SourceRelativePath "framework/AGENTS.template.md" -SourcePath (Join-Path $WorkflowDir "framework/AGENTS.template.md") -Category "system" -Strategy "replace-if-unmodified" -Variables $Variables
      $entries += New-ManagedContentEntry -Path ".opencode/opencode.json" -Source "[generated]/opencode.json" -Category "system" -Strategy "replace-if-unmodified" -Content $config

      foreach ($file in Get-ChildItem -Path (Join-Path $WorkflowDir "agents") -File -Filter "*.md") {
        $entries += New-ManagedTemplateEntry -Path (".opencode/agents/{0}" -f $file.Name) -SourceRelativePath ("agents/{0}" -f $file.Name) -SourcePath $file.FullName -Category "system" -Strategy "replace-if-unmodified" -Variables $Variables
      }

      foreach ($file in Get-ChildItem -Path (Join-Path $WorkflowDir "commands") -File -Filter "*.md") {
        $entries += New-ManagedTemplateEntry -Path (".opencode/commands/{0}" -f $file.Name) -SourceRelativePath ("commands/{0}" -f $file.Name) -SourcePath $file.FullName -Category "system" -Strategy "replace-if-unmodified" -Variables $Variables
      }
    }
    "claude-code" {
      $entries += New-ManagedTemplateEntry -Path "CLAUDE.md" -SourceRelativePath "claude/CLAUDE.template.md" -SourcePath (Join-Path $WorkflowDir "claude/CLAUDE.template.md") -Category "system" -Strategy "replace-if-unmodified" -Variables $Variables
      $entries += New-ManagedTemplateEntry -Path ".claude/settings.json" -SourceRelativePath "claude/settings.template.json" -SourcePath (Join-Path $WorkflowDir "claude/settings.template.json") -Category "system" -Strategy "replace-if-unmodified" -Variables $Variables

      foreach ($file in Get-ChildItem -Path (Join-Path $WorkflowDir "claude/agents") -File -Filter "*.md") {
        $entries += New-ManagedTemplateEntry -Path (".claude/agents/{0}" -f $file.Name) -SourceRelativePath ("claude/agents/{0}" -f $file.Name) -SourcePath $file.FullName -Category "system" -Strategy "replace-if-unmodified" -Variables $Variables
      }

      foreach ($file in Get-ChildItem -Path (Join-Path $WorkflowDir "claude/commands") -File -Filter "*.md") {
        $entries += New-ManagedTemplateEntry -Path (".claude/commands/{0}" -f $file.Name) -SourceRelativePath ("claude/commands/{0}" -f $file.Name) -SourcePath $file.FullName -Category "system" -Strategy "replace-if-unmodified" -Variables $Variables
      }
    }
    default {
      throw "Unsupported adapter: $Adapter"
    }
  }

  foreach ($fileName in @("当前PRD.md", "当前RoadMap.md", "BUG追踪.md", "当前阶段Kanban.md")) {
    $entries += New-ManagedTemplateEntry -Path $fileName -SourceRelativePath ("templates/bootstrap/{0}" -f $fileName) -SourcePath (Join-Path $bootstrapTemplateDir $fileName) -Category "state" -Strategy "never-overwrite" -Variables $Variables
  }

  $entries += New-ManagedTemplateEntry -Path "当前状态快照.md" -SourceRelativePath "templates/bootstrap/当前状态快照.md" -SourcePath (Join-Path $bootstrapTemplateDir "当前状态快照.md") -Category "cache" -Strategy "rebuild" -Variables $Variables

  if ($IncludeHooks) {
    $hooksTemplateName = if ($IncludeGitHooks) { "当前Hooks.git.md" } else { "当前Hooks.default.md" }
    $entries += New-ManagedTemplateEntry -Path "当前Hooks.md" -SourceRelativePath ("templates/bootstrap/{0}" -f $hooksTemplateName) -SourcePath (Join-Path $bootstrapTemplateDir $hooksTemplateName) -Category "local-extension" -Strategy "preserve-local" -Variables $Variables
  }

  return $entries
}

function Install-ManagedEntries {
  param(
    [array]$Entries,
    [string]$TargetRoot,
    [bool]$DryRun,
    [bool]$Force
  )

  foreach ($entry in $Entries) {
    $destinationPath = Join-Path $TargetRoot $entry.Path
    Write-TextFile -Path $destinationPath -Content $entry.Content -DryRun $DryRun -Force $Force | Out-Null
  }
}

function Get-MetadataPath {
  param(
    [string]$TargetRoot
  )

  return (Join-Path $TargetRoot ".ai-agentic-workflow-meta.json")
}

function Read-WorkflowMetadata {
  param(
    [string]$TargetRoot
  )

  $metadataPath = Get-MetadataPath -TargetRoot $TargetRoot
  if (-not (Test-Path $metadataPath)) {
    return $null
  }

  return Get-Content -Path $metadataPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-WorkflowMetadata {
  param(
    [string]$TargetRoot,
    [string]$WorkflowName,
    [string]$InstalledVersion,
    [string]$WorkflowDirName,
    [string]$ProjectName,
    [string]$Adapter,
    [bool]$IncludeHooks,
    [bool]$IncludeGitHooks,
    [array]$Entries,
    [bool]$DryRun
  )

  $metadata = [ordered]@{
    workflowName = $WorkflowName
    installedVersion = $InstalledVersion
    workflowDirName = $WorkflowDirName
    projectName = $ProjectName
    adapter = $Adapter
    includeHooks = $IncludeHooks
    includeGitHooks = $IncludeGitHooks
    updatedAt = [DateTime]::UtcNow.ToString("o")
    files = @()
  }

  foreach ($entry in $Entries) {
    $path = Join-Path $TargetRoot $entry.Path
    $metadata.files += [ordered]@{
      path = $entry.Path
      category = $entry.Category
      strategy = $entry.Strategy
      source = $entry.Source
      templateHash = $entry.TemplateHash
      installedHash = (Get-FileHashString -Path $path)
    }
  }

  $json = $metadata | ConvertTo-Json -Depth 6
  Write-TextFile -Path (Get-MetadataPath -TargetRoot $TargetRoot) -Content $json -DryRun $DryRun -Force $true | Out-Null
}

function Write-UpgradeReport {
  param(
    [string]$TargetRoot,
    [string]$InstalledVersion,
    [string]$TargetVersion,
    [array]$Lines,
    [bool]$DryRun
  )

  $contentLines = @(
    "# Workflow Upgrade Report",
    "",
    "- Previous version: $InstalledVersion",
    "- Target version: $TargetVersion",
    "- Generated at: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))",
    ""
  ) + $Lines

  $content = ($contentLines -join [Environment]::NewLine) + [Environment]::NewLine
  Write-TextFile -Path (Join-Path $TargetRoot "workflow-upgrade-report.md") -Content $content -DryRun $DryRun -Force $true | Out-Null
}

function Show-InitializationSummary {
  param(
    [string]$AdapterName,
    [string]$TargetRoot,
    [array]$Entries,
    [bool]$DryRun
  )

  Write-Host ""
  Write-Host "$AdapterName project initialized at: $TargetRoot"
  Write-Host "Created or preserved:"

  foreach ($entry in $Entries) {
    Write-Host "- $($entry.Path) [$($entry.Category)]"
  }

  Write-Host "- .ai-agentic-workflow-meta.json [system]"

  if ($DryRun) {
    Write-Host "Dry run only: no files were changed."
  }
}

function Show-UpgradeSummary {
  param(
    [string]$TargetRoot,
    [string]$InstalledVersion,
    [string]$TargetVersion,
    [hashtable]$Summary,
    [bool]$DryRun
  )

  Write-Host ""
  Write-Host "Workflow upgraded at: $TargetRoot"
  Write-Host "Version: $InstalledVersion -> $TargetVersion"

  foreach ($key in @("updated", "created", "refreshed", "preserved", "conflicts")) {
    $items = @($Summary[$key])
    if ($items.Count -gt 0) {
      Write-Host ("- {0}: {1}" -f $key, ($items -join ", "))
    }
  }

  Write-Host "- report: workflow-upgrade-report.md"

  if ($DryRun) {
    Write-Host "Dry run only: no files were changed."
  }
}

function Invoke-WorkflowUpgrade {
  param(
    [string]$TargetRoot,
    [string]$WorkflowName,
    [string]$InstalledVersion,
    [string]$TargetVersion,
    [string]$WorkflowDirName,
    [string]$ProjectName,
    [string]$Adapter,
    [bool]$IncludeHooks,
    [bool]$IncludeGitHooks,
    [array]$Entries,
    [object]$ExistingMetadata,
    [string]$Mode,
    [bool]$DryRun
  )

  $oldFileMap = @{}
  if ($ExistingMetadata -and $ExistingMetadata.files) {
    foreach ($file in $ExistingMetadata.files) {
      $oldFileMap[$file.path] = $file
    }
  }

  $summary = @{
    updated = New-Object System.Collections.ArrayList
    created = New-Object System.Collections.ArrayList
    refreshed = New-Object System.Collections.ArrayList
    preserved = New-Object System.Collections.ArrayList
    conflicts = New-Object System.Collections.ArrayList
  }
  $reportLines = New-Object System.Collections.ArrayList

  foreach ($entry in $Entries) {
    $destinationPath = Join-Path $TargetRoot $entry.Path
    $currentExists = Test-Path $destinationPath
    $currentHash = Get-FileHashString -Path $destinationPath
    $previous = $oldFileMap[$entry.Path]

    switch ($entry.Category) {
      "system" {
        if (-not $currentExists) {
          Write-TextFile -Path $destinationPath -Content $entry.Content -DryRun $DryRun -Force $true | Out-Null
          [void]$summary.created.Add($entry.Path)
          [void]$reportLines.Add("- Created missing system file: $($entry.Path)")
          continue
        }

        if ($Mode -eq "force-system" -or ($previous -and $currentHash -eq $previous.templateHash)) {
          Write-TextFile -Path $destinationPath -Content $entry.Content -DryRun $DryRun -Force $true | Out-Null
          [void]$summary.updated.Add($entry.Path)
          [void]$reportLines.Add("- Updated system file: $($entry.Path)")
          continue
        }

        if ($previous -and $entry.TemplateHash -eq $previous.templateHash) {
          [void]$summary.preserved.Add($entry.Path)
          [void]$reportLines.Add("- Preserved modified system file with unchanged template: $($entry.Path)")
          continue
        }

        $conflictPath = "$destinationPath.workflow-new"
        if ($Mode -eq "guided") {
          Write-TextFile -Path $conflictPath -Content $entry.Content -DryRun $DryRun -Force $true | Out-Null
        }
        [void]$summary.conflicts.Add($entry.Path)
        [void]$reportLines.Add("- Conflict on system file: $($entry.Path); review $($entry.Path).workflow-new")
      }
      "state" {
        if (-not $currentExists) {
          Write-TextFile -Path $destinationPath -Content $entry.Content -DryRun $DryRun -Force $true | Out-Null
          [void]$summary.created.Add($entry.Path)
          [void]$reportLines.Add("- Created missing state file: $($entry.Path)")
          continue
        }

        if ($previous -and $entry.TemplateHash -ne $previous.templateHash -and $Mode -eq "guided") {
          $templatePath = "$destinationPath.upgrade-template"
          Write-TextFile -Path $templatePath -Content $entry.Content -DryRun $DryRun -Force $true | Out-Null
          [void]$reportLines.Add("- State template changed: $($entry.Path); review $($entry.Path).upgrade-template")
        }

        [void]$summary.preserved.Add($entry.Path)
      }
      "cache" {
        Write-TextFile -Path $destinationPath -Content $entry.Content -DryRun $DryRun -Force $true | Out-Null
        [void]$summary.refreshed.Add($entry.Path)
        [void]$reportLines.Add("- Refreshed cache file: $($entry.Path)")
      }
      "local-extension" {
        if (-not $currentExists) {
          Write-TextFile -Path $destinationPath -Content $entry.Content -DryRun $DryRun -Force $true | Out-Null
          [void]$summary.created.Add($entry.Path)
          [void]$reportLines.Add("- Created missing local extension file: $($entry.Path)")
          continue
        }

        if ($previous -and $entry.TemplateHash -ne $previous.templateHash -and $Mode -eq "guided") {
          $templatePath = "$destinationPath.workflow-new"
          Write-TextFile -Path $templatePath -Content $entry.Content -DryRun $DryRun -Force $true | Out-Null
          [void]$reportLines.Add("- Local extension template changed: $($entry.Path); review $($entry.Path).workflow-new")
        }

        [void]$summary.preserved.Add($entry.Path)
      }
    }
  }

  Write-WorkflowMetadata -TargetRoot $TargetRoot -WorkflowName $WorkflowName -InstalledVersion $TargetVersion -WorkflowDirName $WorkflowDirName -ProjectName $ProjectName -Adapter $Adapter -IncludeHooks $IncludeHooks -IncludeGitHooks $IncludeGitHooks -Entries $Entries -DryRun $DryRun
  Write-UpgradeReport -TargetRoot $TargetRoot -InstalledVersion $InstalledVersion -TargetVersion $TargetVersion -Lines $reportLines -DryRun $DryRun
  Show-UpgradeSummary -TargetRoot $TargetRoot -InstalledVersion $InstalledVersion -TargetVersion $TargetVersion -Summary $summary -DryRun $DryRun
}

Export-ModuleMember -Function New-DirectoryIfMissing, Get-NormalizedRelativePath, Get-WorkflowVersion, Get-StringHash, Get-FileHashString, Write-TextFile, Get-RenderedTemplate, New-ManagedTemplateEntry, New-ManagedContentEntry, Get-ManagedEntriesForAdapter, Install-ManagedEntries, Get-MetadataPath, Read-WorkflowMetadata, Write-WorkflowMetadata, Write-UpgradeReport, Show-InitializationSummary, Show-UpgradeSummary, Invoke-WorkflowUpgrade
