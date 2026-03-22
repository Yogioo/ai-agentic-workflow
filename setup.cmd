@echo off
setlocal

set "ADAPTER=%~1"
if /I "%ADAPTER%"=="help" goto help
if /I "%ADAPTER%"=="--help" goto help
if /I "%ADAPTER%"=="-h" goto help
if /I "%ADAPTER%"=="opencode" goto opencode
if /I "%ADAPTER%"=="claude" goto claude
if /I "%ADAPTER%"=="claude-code" goto claude

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

:help
echo ========================================
echo   AI Agentic Workflow Setup Help
echo ========================================
echo.
echo Usage:
echo   setup.cmd
echo   setup.cmd opencode [args]
echo   setup.cmd claude-code [args]
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
