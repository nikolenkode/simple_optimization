@echo off
chcp 65001 >nul
title Optimization PC

:: ============================================================
::  Optimization PC - maintenance menu for Windows 10/11
::  Run as Administrator. Full documentation: README.md
::
::  Files created next to this script:
::    optimize.log                 - log of performed actions
::    optimize_power_backup.txt    - saved power plan (for undo)
:: ============================================================

:: --- Admin mode check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Open .bat by admin mode
    pause
    exit /b
)

:: --- Settings ---
set "HP=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
set "BACKUP=%~dp0optimize_power_backup.txt"
set "LOG=%~dp0optimize.log"
call :log "=== Session started ==="

:menu
cls
echo                   Optimization PC
echo ------------------------------------------------------
echo  Optimization
echo   1. Clear temporary files
echo   2. Clear Windows updates cache
echo   3. Clear the Recycle Bin (asks for confirmation)
echo   4. Clear DNS cache
echo   5. ON HIGH PERFORMANCE Power Mode (undo: 10)
echo   6. Optimization C: (SSD, HDD)
echo   7. Check system files (sfc + DISM, takes a long time)
echo   8. Do 1-7 (creates a restore point first)
echo.
echo  Safety / Undo
echo   9. Create a restore point
echo  10. Restore the previous power plan
echo  11. Open System Restore (rstrui)
echo.
echo   0. Exit
echo ======================================================
set "choice="
set /p choice=Make a choice: 

if "%choice%"=="1" call :temp & goto done
if "%choice%"=="2" call :wu & goto done
if "%choice%"=="3" call :bin & goto done
if "%choice%"=="4" call :dns & goto done
if "%choice%"=="5" call :power & goto done
if "%choice%"=="6" call :disk & goto done
if "%choice%"=="7" call :sfc & goto done
if "%choice%"=="8" (
    call :restorepoint
    call :temp
    call :wu
    call :bin
    call :dns
    call :power
    call :disk
    call :sfc
    goto done
)
if "%choice%"=="9" call :restorepoint & goto done
if "%choice%"=="10" call :power_restore & goto done
if "%choice%"=="11" start "" rstrui.exe & goto menu
if "%choice%"=="0" exit /b
goto menu

:done
echo.
echo Ready
pause
goto menu

:: ============================================================
::  Functions
:: ============================================================

:log
>>"%LOG%" echo %date% %time% - %~1
exit /b

:temp
echo [*] Cleaning Up Temporary Files...
del /q /f /s "%TEMP%\*" >nul 2>&1
for /d %%i in ("%TEMP%\*") do rd /s /q "%%i" >nul 2>&1
del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%i in ("%SystemRoot%\Temp\*") do rd /s /q "%%i" >nul 2>&1
call :log "Temporary files cleaned"
exit /b

:wu
echo [*] Clearing Up Windows Update cache...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /q /f /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
call :log "Windows Update cache cleaned"
exit /b

:bin
set "ans="
set /p ans=Empty the Recycle Bin? This CANNOT be undone (Y/N): 
if /i not "%ans%"=="Y" (
    echo [-] Recycle Bin step skipped.
    call :log "Recycle Bin step skipped by user"
    exit /b
)
echo [*] Clearing Up the Recycle Bin...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
call :log "Recycle Bin emptied"
exit /b

:dns
echo [*] Clearing Up DNS cache...
ipconfig /flushdns
call :log "DNS cache flushed"
exit /b

:power
echo [*] Enabling the HIGH PERFORMANCE Mode...
set "OLDPLAN="
for /f "tokens=2 delims=:" %%a in ('powercfg /getactivescheme') do for /f %%b in ("%%a") do set "OLDPLAN=%%b"
if not defined OLDPLAN (
    echo [!] Could not read the current power plan. Step aborted.
    call :log "Power plan step FAILED: cannot read current plan"
    exit /b
)
:: Save the original plan once (not if High Performance is already active)
if not exist "%BACKUP%" if /i not "%OLDPLAN%"=="%HP%" >"%BACKUP%" echo %OLDPLAN%
powercfg /setactive %HP% >nul 2>&1
if errorlevel 1 call :power_create
call :log "High Performance requested, previous plan: %OLDPLAN%"
exit /b

:power_create
echo [i] High Performance plan is hidden on this PC, creating it...
for /f "tokens=2 delims=:" %%a in ('powercfg /duplicatescheme %HP%') do for /f %%b in ("%%a") do powercfg /setactive %%b
exit /b

:power_restore
if not exist "%BACKUP%" (
    echo [!] No saved power plan found. Nothing to restore.
    exit /b
)
set "OLD="
set /p OLD=<"%BACKUP%"
powercfg /setactive %OLD% >nul 2>&1
if errorlevel 1 (
    echo [!] Could not restore plan %OLD%. It may have been deleted.
    call :log "Power plan restore FAILED"
    exit /b
)
del /q "%BACKUP%"
echo [+] Previous power plan restored.
call :log "Power plan restored to %OLD%"
exit /b

:restorepoint
echo [*] Creating a restore point...
powershell -NoProfile -Command "try { Checkpoint-Computer -Description 'Optimization PC' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [!] Restore point was NOT created. System Protection may be disabled for C:
    call :log "Restore point FAILED"
    exit /b
)
echo [+] Restore point step finished. Windows may skip it if one was made in the last 24 h.
call :log "Restore point requested"
exit /b

:disk
echo [*] Optimization C:...
defrag C: /O
call :log "Disk C: optimized"
exit /b

:sfc
echo [*] Checking Up the system files...
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
call :log "sfc + DISM finished"
exit /b