:: UTF-8 BOM guard ────────────────────────────────────────────
@echo off & setlocal EnableExtensions
title "Lucid EQ Toggle v1.0"
chcp 65001 >nul

:: ── elevation helper ────────────────────────────────────────
if /I "%~1"=="-elevated" (shift) else (
  net session >nul 2>&1 || (
    powershell -WindowStyle Minimized -NoP ^
      "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList -elevated"
    exit /b
  )
)

:: UI timers
set "WAIT_OK=5"
set "WAIT_FAIL=8"

echo ==========================================================
echo             Lucid Competitive EQ Toggle – v1.0
echo ==========================================================
echo.

:: ── keep audio services alive ───────────────────────────────
for %%S in (Audiosrv AudioEndpointBuilder) do (
  sc query %%S | find "RUNNING" >nul || net start %%S >nul 2>&1
)

:: ── locate Equalizer APO (Editor OR Configurator = present) ─
setlocal EnableDelayedExpansion
set "EAPO="

for %%K in ("HKLM\SOFTWARE\EqualizerAPO" "HKLM\SOFTWARE\WOW6432Node\EqualizerAPO") do (
  for /f "tokens=2,*" %%A in ('reg query %%~K /v InstallDir 2^>nul ^| find /i "InstallDir"') do (
        set "DIR=%%B"
        if not "!DIR:~-1!"=="\" set "DIR=!DIR!\" 
        if exist "!DIR!Editor.exe"           set "EAPO=!DIR!"
        if exist "!DIR!Configurator.exe"      set "EAPO=!DIR!"
  )
)

if not defined EAPO (
  if exist "%ProgramFiles%\Equalizer APO\Editor.exe" (
        set "EAPO=%ProgramFiles%\Equalizer APO\"
  ) else if exist "%ProgramFiles%\Equalizer APO\Configurator.exe" (
        set "EAPO=%ProgramFiles%\Equalizer APO\"
  )
)

:: fallback scan
if not defined EAPO (
  for /r "%ProgramFiles%" %%F in (Configurator.exe Editor.exe) do (
        for %%P in ("%%~dpF") do set "EAPO=%%~fP" & goto :foundApo
  )
)
:foundApo
endlocal & set "EAPO=%EAPO%"

:: ── install on first run if missing ─────────────────────────
if not defined EAPO call :initInstaller

:: ── toggle Lucid preset (same as before) ────────────────────
set "CFG_DIR=%EAPO%\config"
set "CFG=%CFG_DIR%\config.txt"
set "PRESET=%CFG_DIR%\lucid_temp.txt"
if not exist "%CFG_DIR%" md "%CFG_DIR%" >nul

if exist "%CFG%" if not exist "%CFG_DIR%\config_backup_preLucid.txt" (
  copy "%CFG%" "%CFG_DIR%\config_backup_preLucid.txt" >nul
)

> "%PRESET%" (
  echo Preamp: -4 dB
  echo Filter: ON PK Fc 70 Hz   Gain -1.9 dB  Q 0.90
  echo Filter: ON PK Fc 110 Hz  Gain -1.1 dB  Q 1.20
  echo Filter: ON PK Fc 180 Hz  Gain -0.6 dB  Q 1.00
  echo Filter: ON PK Fc 200 Hz  Gain -0.7 dB  Q 1.40
  echo Filter: ON PK Fc 300 Hz  Gain -0.8 dB  Q 2.00
  echo Filter: ON PK Fc 1000 Hz Gain -0.6 dB  Q 1.20
  echo Filter: ON PK Fc 1300 Hz Gain -1.2 dB  Q 3.50
  echo Filter: ON PK Fc 3000 Hz Gain -1.2 dB  Q 2.00
  echo Filter: ON PK Fc 3500 Hz Gain -0.3 dB  Q 3.00
  echo Filter: ON PK Fc 4800 Hz Gain -0.5 dB  Q 2.80
  echo Filter: ON PK Fc 5050 Hz Gain -0.8 dB  Q 3.00
  echo Filter: ON PK Fc 6200 Hz Gain -3.0 dB  Q 4.00
  echo Filter: ON PK Fc 8600 Hz Gain +3.4 dB  Q 0.90
  echo Filter: ON PK Fc 11100 Hz Gain -1.3 dB Q 6.00
  echo Filter: ON HS Fc 12000 Hz Gain +0.5 dB Q 0.60
  echo Filter: ON PK Fc 17300 Hz Gain -5.0 dB Q 6.00
)

taskkill /f /im Peace.exe 2>nul

type "%CFG%" | find /I "Include: lucid_temp.txt" >nul
if not exist "%CFG%" echo ;>"%CFG%"

if errorlevel 1 (
  echo Activating Competitive Lucid EQ, please wait...
  (echo Include: lucid_temp.txt & echo ; end) >"%CFG%"
  set "STATE=ON"
) else (
  echo Deactivating Competitive Lucid EQ, please wait...
  echo ;>"%CFG%"
  set "STATE=OFF"
)

net stop Audiosrv >nul 2>&1 & ping 127.0.0.1 -n 2 >nul & net start Audiosrv >nul
echo Competitive Lucid EQ is now %STATE%.
timeout /t %WAIT_OK% /nobreak
exit /b 0


:: ===============  :initInstaller (64-bit only)  ===============
:initInstaller
echo First-time initialization, please wait...
echo.

setlocal EnableDelayedExpansion
set "BARLEN=50" & set "TOTAL=5" & set "STEP=0"

:draw
set /a FILLED=STEP*BARLEN/TOTAL
set "BAR="
for /L %%i in (1 1 !BARLEN!) do if %%i LEQ !FILLED! (set "BAR=!BAR!#") else set "BAR=!BAR!."
echo Progress: [!BAR!] !STEP!*20%%  –  "!MSG!"
goto :eof

:: 1 ► 7z.exe
set /a STEP=1 & set "MSG=Downloading 7z.exe" & call :draw
set "WORK=%TEMP%\LucidEQ_%RANDOM%"
md "%WORK%" 2>nul
curl -L --retry 3 "https://raw.githubusercontent.com/tekkusai/Lucid/main/7z.exe" -o "%WORK%\7z.exe" || goto :fail
for %%S in ("%WORK%\7z.exe") do if %%~zS LSS 500000 goto :fail

:: 2 ► 7z.dll
set /a STEP=2 & set "MSG=Downloading 7z.dll" & call :draw
curl -L --retry 3 "https://raw.githubusercontent.com/tekkusai/Lucid/main/7z.dll" -o "%WORK%\7z.dll" || goto :fail
for %%S in ("%WORK%\7z.dll") do if %%~zS LSS 500000 goto :fail
set "PATH=%WORK%;%PATH%"

:: 3 ► Equalizer APO
set /a STEP=3 & set "MSG=Downloading Equalizer APO" & call :draw
set "APO=%WORK%\EqualizerAPO-x64-1.4.2.exe"
curl -L --retry 3 "https://raw.githubusercontent.com/tekkusai/Lucid/main/EqualizerAPO-x64-1.4.2.exe" -o "%APO%" || goto :fail
for %%S in ("%APO%") do if %%~zS LSS 9000000 goto :fail

:: 4 ► extract & copy
set /a STEP=4 & set "MSG=Extracting installer" & call :draw
7z x "%APO%" -o"%WORK%\x" -y >nul || goto :fail

set "SRC="
for /r "%WORK%\x" %%F in (Configurator.exe Editor.exe) do (
    for %%P in ("%%~dpF") do set "SRC=%%~fP" & goto found
)
:found
if not defined SRC goto :fail
for %%P in ("%SRC%..") do set "SRC=%%~fP"

set "MSG=Copying files" & call :draw
set "DEST=%ProgramFiles%\Equalizer APO"
rd /s /q "%DEST%" 2>nul
robocopy "%SRC%" "%DEST%" /e /nfl /ndl /njh >nul
if %errorlevel% GEQ 8 goto :fail

:: 5 ► bind
set /a STEP=5 & set "MSG=Binding APO" & call :draw
if exist "%DEST%\Configurator.exe" (
     "%DEST%\Configurator.exe" /install=all /silent
) else if exist "%DEST%\Editor.exe" (
     "%DEST%\Editor.exe" /install=all /silent
) else goto :fail

endlocal & set "EAPO=%DEST%\" & exit /b 0

:fail
echo Initialization failed. Aborting...
timeout /t %WAIT_FAIL% /nobreak
endlocal & exit /b 1
