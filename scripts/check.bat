@echo off
setlocal
pushd "%~dp0.."
if errorlevel 1 exit /b 1

if not exist "env.bat" goto environment
call "env.bat"
if errorlevel 1 goto failed
:environment
if exist "%CD%\.tools\flutter\bin\flutter.bat" set "PATH=%CD%\.tools\flutter\bin;%PATH%"
if not defined JAVA_HOME if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" set "JAVA_HOME=%ProgramFiles%\Android\Android Studio\jbr"
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"
if not defined FIREBASE_EMULATORS_PATH set "FIREBASE_EMULATORS_PATH=%CD%\.tools\firebase-emulators"
where flutter >nul 2>&1
if errorlevel 1 goto missing
where dart >nul 2>&1
if errorlevel 1 goto missing
where npm >nul 2>&1
if errorlevel 1 goto missing
where java >nul 2>&1
if errorlevel 1 goto missing

echo [1/5] Flutter analyze
call flutter analyze --no-pub
if errorlevel 1 goto failed
echo [2/5] Flutter tests
call flutter test --no-pub
if errorlevel 1 goto failed
call :ranking
if errorlevel 1 goto failed
echo [5/5] Firebase Emulator tests - demo project only
call npm run test:rules
if errorlevel 1 goto failed
echo PASS: all checks completed. Device testing is separate.
popd
exit /b 0

:ranking
pushd "packages\tutor_ranking"
if errorlevel 1 exit /b 1
echo [3/5] Ranking analyze
call dart analyze
if errorlevel 1 goto ranking_failed
echo [4/5] Ranking tests
call dart test
if errorlevel 1 goto ranking_failed
popd
exit /b 0
:ranking_failed
popd
exit /b 1

:missing
echo ERROR: Flutter, Dart, Node/npm and Java must be installed. See AGENTS.md.
:failed
echo FAIL: checks stopped. Fix the reported error before handing off.
popd
exit /b 1
