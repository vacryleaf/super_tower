@echo off
setlocal
cd /d "%~dp0.."
where pyw.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    start "" pyw.exe "%~dp0catalog_browser.py"
    exit /b 0
)
where pythonw.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    start "" pythonw.exe "%~dp0catalog_browser.py"
    exit /b 0
)
where python.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    start "" python.exe "%~dp0catalog_browser.py"
    exit /b 0
)
echo Python 3 was not found. Please install Python 3 and try again.
pause
