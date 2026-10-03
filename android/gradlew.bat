@echo off
setlocal
set GRADLE_VERSION=8.10.2
set CACHE=%USERPROFILE%\.gradle\insideyourcomputer-bootstrap
set DIST=%CACHE%\gradle-%GRADLE_VERSION%
set ZIP=%CACHE%\gradle-%GRADLE_VERSION%-bin.zip

if not exist "%DIST%\bin\gradle.bat" (
  if not exist "%CACHE%" mkdir "%CACHE%"
  if not exist "%ZIP%" (
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-bin.zip' -OutFile '%ZIP%'"
  )
  powershell -NoProfile -Command "Expand-Archive -Force '%ZIP%' '%CACHE%'"
)

call "%DIST%\bin\gradle.bat" -p "%~dp0" %*
