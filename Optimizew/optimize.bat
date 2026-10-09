@echo off
chcp 65001 >nul
title Optimization PC

:: ?Admin mode

net session >nul 2>&1
IF %errorlevel% neq 0 (
    echo [!] Open .bat by admin mode
    pause
    exit /b
)

:menu
cls
echo                   Optimization PC
echo ------------------------------------------------------
echo 1. Clear temporary files
echo 2. Clear Windows updates cache
echo 3. Clear the Recycle Bin
echo 4. Clear DNS cache
echo 5. ON HIGH PERFORMANCE Power Mode 
echo 6. Optimization C: (SSD, HDD)
echo 7. Check system files (sfc + DISM, takes a long time)
echo 8. Do 1-6
echo 0. exit
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
    call :temp
    call :wu
    call :bin
    call :dns
    call :power
    call :disk
    goto done
)
if "%choice%"=="0" exit /b
goto menu

:done 
echo.
echo Ready
pause
goto menu

:: Functions

:temp 
echo [*] Cleaning Up Temporary Files...
del /q /f /s "%TEMP%\*" >nul 2>&1
for /d %%i in ("%TEMP%\*") do rd /s /q "%%i" >nul 2>&1
del /q /f /s "%SystemRoot%\TEMP\*" >nul 2>&1
for /d %%i in ("%SystemRoot%\Temp\*") do rd /s /q "%%i" >nul 2>&1
exit /b

:wu
echo [*] Clearing Up Windows Update cache...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /q /f /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
exit /b

:bin
echo [*] Clearing Up the Recycle Bin...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
exit /b

:dns 
echo [*] Clearing Up DNS cache...
ipconfig /flushdns
exit /b

:power
echo [*] Enabling the HIGH PERFORMANCE Mode
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
exit /b

:disk
echo [*] Optimization C:...
defrag C: /O
exit /b

:sfc
echo [*] Checking Up the system files...
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
exit /b