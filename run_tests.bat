@echo off
setlocal

set "ROOT=%~dp0"
set "PROJECT=%ROOT%GameProject"
set "TEST_HOME=%TEMP%\super_tower_test_home_%RANDOM%_%RANDOM%"
set "TEST_APPDATA=%TEST_HOME%\AppData\Roaming"
set "TEST_LOCALAPPDATA=%TEST_HOME%\AppData\Local"
mkdir "%TEST_APPDATA%" >nul 2>nul
mkdir "%TEST_LOCALAPPDATA%" >nul 2>nul
set "HOME=%TEST_HOME%"
set "USERPROFILE=%TEST_HOME%"
set "APPDATA=%TEST_APPDATA%"
set "LOCALAPPDATA=%TEST_LOCALAPPDATA%"
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
call :run_test tutorial_and_floors_test
if not "%ERRORLEVEL%"=="0" exit /b %ERRORLEVEL%
call :run_test pre_run_ui_smoke_test
if not "%ERRORLEVEL%"=="0" exit /b %ERRORLEVEL%
call :run_test ui_click_smoke_test
if not "%ERRORLEVEL%"=="0" exit /b %ERRORLEVEL%

echo ALL TESTS PASSED
exit /b 0

:run_test
set "TEST_NAME=%~1"
set "TEST_LOG=%TEMP%\super_tower_tests_%RANDOM%.log"
set "GODOT_LOG=%TEMP%\super_tower_godot_%RANDOM%.log"
"%GODOT%" --headless --quiet --no-header --log-file "%GODOT_LOG%" --path "%PROJECT%" --script "res://scripts/tests/%TEST_NAME%.gd" > "%TEST_LOG%" 2>&1
set "STATUS=%ERRORLEVEL%"
type "%GODOT_LOG%" >> "%TEST_LOG%"
type "%TEST_LOG%"
findstr /C:"Failed to load script" /C:"Compilation failed" /C:"SCRIPT ERROR" "%TEST_LOG%" >nul
if %ERRORLEVEL% EQU 0 set "STATUS=1"
del /q "%TEST_LOG%" >nul 2>nul
del /q "%GODOT_LOG%" >nul 2>nul
exit /b %STATUS%
