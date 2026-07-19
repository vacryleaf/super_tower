@echo off
setlocal

set "ROOT=%~dp0"
set "PROJECT=%ROOT%GameProject"

set "GODOT_471=C:\Program Files (x86)\Godot\Godot_v4.7.1\Godot_v4.7.1-stable_win64.exe"
set "GODOT_DEFAULT=C:\Program Files (x86)\Godot\godot.exe"

if exist "%GODOT_471%" (
    start "" "%GODOT_471%" --path "%PROJECT%"
    exit /b 0
)

if exist "%GODOT_DEFAULT%" (
    start "" "%GODOT_DEFAULT%" --path "%PROJECT%"
    exit /b 0
)

where godot.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    start "" godot.exe --path "%PROJECT%"
    exit /b 0
)

echo Godot executable was not found.
echo Checked:
echo   %GODOT_471%
echo   %GODOT_DEFAULT%
echo   PATH: godot.exe
echo.
echo Please install Godot or update this script with your Godot executable path.
pause
exit /b 1
