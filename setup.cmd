@echo off
setlocal

set "ADAPTER=%~1"
if /I "%ADAPTER%"=="help" goto help
if /I "%ADAPTER%"=="--help" goto help
if /I "%ADAPTER%"=="-h" goto help
if /I "%ADAPTER%"=="upgrade" goto upgrade
if /I "%ADAPTER%"=="opencode" goto opencode
if /I "%ADAPTER%"=="claude" goto claude
if /I "%ADAPTER%"=="claude-code" goto claude

call :detect_upgrade_candidate
if /I "%UPGRADE_AVAILABLE%"=="1" goto upgrade_prompt
if /I "%UPGRADE_STATUS%"=="current" goto current_prompt
if /I "%UPGRADE_STATUS%"=="downgrade" goto downgrade_prompt

echo ========================================
echo   AI Agentic Workflow Setup
echo ========================================
echo.
echo Select adapter:
echo   1. OpenCode
echo   2. Claude Code
echo.

choice /c 12 /n /m "Enter choice [1/2]: "
if errorlevel 2 goto claude
if errorlevel 1 goto opencode

echo Invalid choice.
exit /b 1

:detect_upgrade_candidate
set "UPGRADE_AVAILABLE=0"
set "UPGRADE_STATUS=unmanaged"
set "MANAGED_TARGET=%~dp0.."
set "META_PATH=%MANAGED_TARGET%\.ai-agentic-workflow-meta.json"
set "VERSION_PATH=%~dp0VERSION"
set "INSTALLED_VERSION="
set "CURRENT_VERSION="
set "MANAGED_ADAPTER="

if not exist "%META_PATH%" goto :eof
if not exist "%VERSION_PATH%" goto :eof

set "UPGRADE_STATUS=managed"

for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$meta = Get-Content -Path '%META_PATH%' -Raw -Encoding UTF8 | ConvertFrom-Json; [Console]::WriteLine($meta.installedVersion); [Console]::WriteLine($meta.adapter)"`) do (
  if not defined INSTALLED_VERSION (
    set "INSTALLED_VERSION=%%i"
  ) else if not defined MANAGED_ADAPTER (
    set "MANAGED_ADAPTER=%%i"
  )
)

for /f "usebackq delims=" %%i in ("%VERSION_PATH%") do set "CURRENT_VERSION=%%i"

if not defined INSTALLED_VERSION goto :eof
if not defined CURRENT_VERSION goto :eof

for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $installed = [version]'%INSTALLED_VERSION%'; $current = [version]'%CURRENT_VERSION%'; if ($current -gt $installed) { 'upgrade' } elseif ($current -eq $installed) { 'current' } else { 'downgrade' } } catch { 'managed' }"`) do set "UPGRADE_STATUS=%%i"
if /I "%UPGRADE_STATUS%"=="upgrade" set "UPGRADE_AVAILABLE=1"
goto :eof

:upgrade_prompt
echo ========================================
echo   AI Agentic Workflow Setup
echo ========================================
echo.
echo Detected managed project at: %MANAGED_TARGET%
echo Installed workflow version: %INSTALLED_VERSION%
echo Current workflow version:   %CURRENT_VERSION%
echo Managed adapter:            %MANAGED_ADAPTER%
echo.
echo Select action:
echo   1. OpenCode initialization
echo   2. Claude Code initialization
echo   3. Upgrade existing managed project
echo   4. Skip upgrade and exit
echo.
choice /c 1234 /n /m "Enter choice [1/2/3/4]: "
if errorlevel 4 exit /b 0
if errorlevel 3 goto upgrade
if errorlevel 2 goto claude
if errorlevel 1 goto opencode

echo Invalid choice.
exit /b 1

:current_prompt
echo ========================================
echo   AI Agentic Workflow Setup
echo ========================================
echo.
echo Detected managed project at: %MANAGED_TARGET%
echo Installed workflow version: %INSTALLED_VERSION%
echo Current workflow version:   %CURRENT_VERSION%
echo Managed adapter:            %MANAGED_ADAPTER%
echo.
echo Current project is already on the latest workflow version.
echo No upgrade is needed right now.
echo.
echo Select action:
echo   1. OpenCode initialization
echo   2. Claude Code initialization
echo   3. Exit
echo.
choice /c 123 /n /m "Enter choice [1/2/3]: "
if errorlevel 3 exit /b 0
if errorlevel 2 goto claude
if errorlevel 1 goto opencode

echo Invalid choice.
exit /b 1

:downgrade_prompt
echo ========================================
echo   AI Agentic Workflow Setup
echo ========================================
echo.
echo Detected managed project at: %MANAGED_TARGET%
echo Installed workflow version: %INSTALLED_VERSION%
echo Current workflow version:   %CURRENT_VERSION%
echo Managed adapter:            %MANAGED_ADAPTER%
echo.
echo Warning: the project is managed by a newer workflow version.
echo Upgrade is not offered because the current workflow directory looks older.
echo.
echo Select action:
echo   1. OpenCode initialization
echo   2. Claude Code initialization
echo   3. Exit
echo.
choice /c 123 /n /m "Enter choice [1/2/3]: "
if errorlevel 3 exit /b 0
if errorlevel 2 goto claude
if errorlevel 1 goto opencode

echo Invalid choice.
exit /b 1

:help
echo ========================================
echo   AI Agentic Workflow Setup Help
echo ========================================
echo.
echo Usage:
echo   setup.cmd
echo   setup.cmd opencode [args]
echo   setup.cmd claude-code [args]
echo   setup.cmd upgrade [args]
echo.
echo When run without args, setup.cmd first checks whether the parent project
echo is already managed and compares the installed version with VERSION.
echo If an upgrade is available, it offers an upgrade menu; if already current,
echo it shows a no-upgrade-needed message. It never auto-upgrades by default.
echo.
echo Adapters:
echo   1. OpenCode
echo   2. Claude Code
echo.
echo Common args passed through to setup scripts:
echo   -TargetDir PATH
echo   -ProjectName NAME
echo   -WorkflowDirName NAME
echo   -IncludeHooks
echo   -IncludeGitHooks
echo   -DryRun
echo   -SkipAdapter
echo   -Force
echo.
echo Upgrade args:
echo   -TargetDir PATH
echo   -Adapter opencode^|claude-code
echo   -Mode safe^|guided^|force-system
echo   -DryRun
echo.
echo Interactive hook setup:
echo   1. Do not create 当前Hooks.md
echo   2. Create 当前Hooks.md with empty default template
echo   3. Create 当前Hooks.md with Git hook template
echo.
echo Recommended usage after initialization:
echo   1. Use start for first-time analysis and planning
echo   2. Use next for daily progress
echo   3. Use advanced commands only when needed
echo.
echo Example commands after initialization:
echo   /start I want to build a small team task manager
echo   /next
echo   /kanban
echo   /hooks
echo   /dispatch-dev
echo.
exit /b 0

:upgrade
echo.
echo Selected action: Upgrade existing project workflow files
echo.
if /I "%~1"=="upgrade" shift
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\upgrade.ps1" %*
goto done

:opencode
echo.
echo Selected adapter: OpenCode
echo.
echo This will initialize the parent project with OpenCode files and project docs.
echo.

if not "%~2"=="" goto opencode_run_no_prompt

 set "HOOK_ARGS="
 echo Hook setup:
 echo   1. Do not create 当前Hooks.md
 echo   2. Create 当前Hooks.md with empty default template
 echo   3. Create 当前Hooks.md with Git hook template
 choice /c 123 /n /m "Enter choice [1/2/3]: "
 if errorlevel 3 set "HOOK_ARGS=-IncludeHooks -IncludeGitHooks" & goto opencode_run
 if errorlevel 2 set "HOOK_ARGS=-IncludeHooks" & goto opencode_run
 if errorlevel 1 goto opencode_nohooks

:opencode_run

if /I "%~1"=="opencode" shift
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\opencode.ps1" %HOOK_ARGS% %*
goto done

:opencode_nohooks
if /I "%~1"=="opencode" shift
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\opencode.ps1" %*
goto done

:opencode_run_no_prompt
if /I "%~1"=="opencode" shift
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\opencode.ps1" %*
goto done

:claude
echo.
echo Selected adapter: Claude Code
echo.
echo This will initialize the parent project with Claude Code files and project docs.
echo.

if not "%~2"=="" goto claude_run_no_prompt

 set "HOOK_ARGS="
 echo Hook setup:
 echo   1. Do not create 当前Hooks.md
 echo   2. Create 当前Hooks.md with empty default template
 echo   3. Create 当前Hooks.md with Git hook template
 choice /c 123 /n /m "Enter choice [1/2/3]: "
 if errorlevel 3 set "HOOK_ARGS=-IncludeHooks -IncludeGitHooks" & goto claude_run
 if errorlevel 2 set "HOOK_ARGS=-IncludeHooks" & goto claude_run
 if errorlevel 1 goto claude_nohooks

:claude_run

if /I "%~1"=="claude" shift
if /I "%~1"=="claude-code" shift
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\claude-code.ps1" %HOOK_ARGS% %*
goto done

:claude_nohooks
if /I "%~1"=="claude" shift
if /I "%~1"=="claude-code" shift
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\claude-code.ps1" %*
goto done

:claude_run_no_prompt
if /I "%~1"=="claude" shift
if /I "%~1"=="claude-code" shift
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\claude-code.ps1" %*
goto done

:done
if errorlevel 1 (
  echo.
  echo Setup failed.
  exit /b 1
)

echo.
echo Setup completed successfully.
exit /b 0
