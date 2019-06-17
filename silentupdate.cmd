@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 ECHO Unable to enable extensions
	
set killThis=SVPManager.exe
set silentSwitches=-v --silentUpdate
set regApp={84d53064-d9b0-4084-abb8-e3f844c2279a}
set regPath=Microsoft\Windows\CurrentVersion\Uninstall\

REM  --> Check for updates
find "found updates" %APPDATA%\SVP4\logs\active.log >nul 2>&1 
if %ERRORLEVEL% EQU 1 goto noUpdates

REM  --> Check for permissions
WHOAMI /Groups | FIND "12288" >NUL
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto :UACPrompt
) else ( goto :gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
	
REM  --> If regHive is unset, first found from list is used
set regHive=
for %%R IN (HKLM\Software\ HKCU\Software\ HKLM\Software\Wow6432Node\ HKCU\Software\Wow6432Node\) DO (
REG QUERY %%R%regPath%%regApp% >nul 2>&1 && set regHive=%%R
)
if NOT DEFINED regHive (
    echo Not Found
	goto Done
)
for /F "usebackq tokens=3*" %%A IN (`REG QUERY %regHive%%regPath%%regApp% /v UninstallString`) DO ( 
set INSTALLER=%%A %%B
) 

for /f "tokens=2 delims=," %%I in (
    'wmic process where "name='%killThis%'" get ExecutablePath^,Handle /format:csv 2^>^>nul ^| find /i "%killThis%" '
) do set "RELAUNCH=%%~I"
if DEFINED RELAUNCH taskkill /F /IM %killThis% >nul 2>&1
"%INSTALLER%" %silentSwitches%
goto :Done
:noUpdates
echo No Updates
:Done
if DEFINED RELAUNCH "%RELAUNCH%" &