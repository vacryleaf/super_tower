@echo off
setlocal

set "ROOT=%~dp0"
set "PROJECT=%ROOT%GameProject"
set "GODOT_DEFAULT=C:\Program Files (x86)\Godot\godot.exe"
set "TEST_LOG=%TEMP%\super_tower_tests_%RANDOM%.log"

if exist "%GODOT_DEFAULT%" (
    set "GODOT=%GODOT_DEFAULT%"
    goto run_tests
)

where godot.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set "GODOT=godot.exe"
    goto run_tests
)

echo Godot executable was not found.
echo Checked:
echo   %GODOT_DEFAULT%
echo   PATH: godot.exe
exit /b 1

:run_tests
"%GODOT%" --headless --quiet --no-header --path "%PROJECT%" --script "res://scripts/tests/tutorial_and_floors_test.gd" > "%TEST_LOG%" 2>&1
set "STATUS=%ERRORLEVEL%"
type "%TEST_LOG%"
findstr /C:"Failed to load script" /C:"Compilation failed" /C:"SCRIPT ERROR" "%TEST_LOG%" >nul
if %ERRORLEVEL% EQU 0 set "STATUS=1"
del /q "%TEST_LOG%" >nul 2>nul
if not "%STATUS%"=="0" exit /b %STATUS%

echo ALL TESTS PASSED
exit /b 0
