@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: CI/CD build.bat for Windows CMD
:: Build, push and generate deploy commands for backend/frontend
:: ============================================================

set REGISTRY=docker.io/barsukforever5
set BACKEND_IMAGE=react-backend-image
set FRONTEND_IMAGE=react-frontend-image

set NAMESPACE=dev-1
set BACKEND_DEPLOYMENT=react-backend-app
set FRONTEND_DEPLOYMENT=react-frontend-app
set BACKEND_CONTAINER=react-backend-container
set FRONTEND_CONTAINER=react-frontend-container

set BACKEND_VER_FILE=.version.backend
set FRONTEND_VER_FILE=.version.frontend

set FRONTEND_URL=https://react.barsukforever.dev/react-frontend-app/

:: --- defaults ---
set SKIP_BUILD=false
set SKIP_PUSH=false
set SKIP_DEPLOY=false
set BACKEND_ONLY=false
set FRONTEND_ONLY=false
set BACKEND_VERSION=
set FRONTEND_VERSION=

:: --- parse args ---
:parse
if "%~1"=="" goto :done_parse
if /I "%~1"=="-v" (
    call :strip_v "%~2"
    set BACKEND_VERSION=v!RESULT!
    set FRONTEND_VERSION=v!RESULT!
    shift
    shift
    goto :parse
)
if /I "%~1"=="--version" (
    call :strip_v "%~2"
    set BACKEND_VERSION=v!RESULT!
    set FRONTEND_VERSION=v!RESULT!
    shift
    shift
    goto :parse
)
if /I "%~1"=="--backend-version" (
    call :strip_v "%~2"
    set BACKEND_VERSION=v!RESULT!
    set BACKEND_ONLY=true
    shift
    shift
    goto :parse
)
if /I "%~1"=="--frontend-version" (
    call :strip_v "%~2"
    set FRONTEND_VERSION=v!RESULT!
    set FRONTEND_ONLY=true
    shift
    shift
    goto :parse
)
if /I "%~1"=="--skip-build" (
    set SKIP_BUILD=true
    shift
    goto :parse
)
if /I "%~1"=="--skip-push" (
    set SKIP_PUSH=true
    shift
    goto :parse
)
if /I "%~1"=="--skip-deploy" (
    set SKIP_DEPLOY=true
    shift
    goto :parse
)
if /I "%~1"=="--backend-only" (
    set BACKEND_ONLY=true
    shift
    goto :parse
)
if /I "%~1"=="--frontend-only" (
    set FRONTEND_ONLY=true
    shift
    goto :parse
)
if /I "%~1"=="-h" goto :help
if /I "%~1"=="--help" goto :help
echo Unknown argument: %~1
goto :help

:done_parse

if "%BACKEND_ONLY%"=="true" if "%FRONTEND_ONLY%"=="true" (
    echo ERROR: --backend-only and --frontend-only cannot be used together
    exit /b 1
)

:: --- calculate versions ---
if "%BACKEND_VERSION%"=="" (
    call :next_version "%BACKEND_VER_FILE%"
    set BACKEND_VERSION=v!RESULT!
    echo [INFO] Backend version ^(auto^): !BACKEND_VERSION!
) else (
    echo [INFO] Backend version ^(manual^): %BACKEND_VERSION%
)

if "%FRONTEND_VERSION%"=="" (
    call :next_version "%FRONTEND_VER_FILE%"
    set FRONTEND_VERSION=v!RESULT!
    echo [INFO] Frontend version ^(auto^): !FRONTEND_VERSION!
) else (
    echo [INFO] Frontend version ^(manual^): %FRONTEND_VERSION%
)

set BACKEND_FULL=%REGISTRY%/%BACKEND_IMAGE%:%BACKEND_VERSION%
set FRONTEND_FULL=%REGISTRY%/%FRONTEND_IMAGE%:%FRONTEND_VERSION%

echo [INFO] Backend  -^> %BACKEND_FULL%
echo [INFO] Frontend -^> %FRONTEND_FULL%

:: --- pipeline ---
if "%SKIP_BUILD%"=="false" (
    if "%FRONTEND_ONLY%"=="false" call :backend_build
    if "%BACKEND_ONLY%"=="false"  call :frontend_build
) else (
    echo [WARN] Build skipped (--skip-build)
)

if "%SKIP_PUSH%"=="false" (
    if "%FRONTEND_ONLY%"=="false" call :backend_push
    if "%BACKEND_ONLY%"=="false"  call :frontend_push
) else (
    echo [WARN] Push skipped (--skip-push)
)

if "%SKIP_DEPLOY%"=="false" (
    echo.
    echo ===========================================
    echo  COPY-PASTE commands on your K8s server
    echo ===========================================
    if "%FRONTEND_ONLY%"=="false" call :backend_deploy
    if "%BACKEND_ONLY%"=="false"  call :frontend_deploy
    echo.
    if "%BACKEND_ONLY%"=="false" echo Check frontend: %FRONTEND_URL%
    echo.
) else (
    echo [WARN] Deploy skipped (--skip-deploy)
)

:: save versions
if "%FRONTEND_ONLY%"=="false" (
    call :strip_v "%BACKEND_VERSION%"
    echo !RESULT!>%BACKEND_VER_FILE%
)
if "%BACKEND_ONLY%"=="false" (
    call :strip_v "%FRONTEND_VERSION%"
    echo !RESULT!>%FRONTEND_VER_FILE%
)

echo [OK] Pipeline finished!
goto :eof

:: ========== SUBROUTINES ==========

:help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   -v, --version X       Common version ^(vX^)
echo   --backend-version X   Backend version only
echo   --frontend-version X  Frontend version only
echo   --skip-build          Skip mvn/npm and podman build
echo   --skip-push           Skip podman push
echo   --skip-deploy         Skip deploy commands
echo   --backend-only        Only backend
echo   --frontend-only       Only frontend
echo   -h, --help            This help
echo.
echo Examples:
echo   %~nx0
echo   %~nx0 -v 6
echo   %~nx0 --backend-only
echo   %~nx0 --skip-build --skip-push
exit /b 0

:next_version
set FILENAME=%~1
if exist "%FILENAME%" (
    set /p CUR=<%FILENAME%
    set CUR=!CUR:v=!
    set CUR=!CUR: =!
    set CUR=!CUR:\r=!
    set /a NEXT=!CUR!+1
    set RESULT=!NEXT!
) else (
    set RESULT=1
)
exit /b 0

:strip_v
set VAL=%~1
set VAL=!VAL:v=!
set RESULT=!VAL!
exit /b 0

:backend_build
echo [INFO] === BACKEND: mvn build ===
call mvn clean package -DskipTests
if errorlevel 1 exit /b 1

echo [INFO] === BACKEND: podman build ===
podman build -t %BACKEND_IMAGE%:%BACKEND_VERSION% -f Dockerfile .
podman tag %BACKEND_IMAGE%:%BACKEND_VERSION% %BACKEND_FULL%
echo [OK] Backend image: %BACKEND_FULL%
exit /b 0

:backend_push
echo [INFO] Backend: podman push -^> %BACKEND_FULL%
podman push %BACKEND_FULL%
exit /b 0

:backend_deploy
echo.
echo === BACKEND DEPLOY COMMAND ===
echo kubectl set image deployment/%BACKEND_DEPLOYMENT% %BACKEND_CONTAINER%=%BACKEND_FULL% -n %NAMESPACE%
echo [OK] Backend deployment command ready: %BACKEND_DEPLOYMENT%
exit /b 0

:frontend_build
    echo [INFO] === FRONTEND: npm ci + npm run build ===
cd frontend
npm ci
if errorlevel 1 (
    cd ..
    exit /b 1
)
npm run build
if errorlevel 1 (
    cd ..
    exit /b 1
)
cd ..

echo [INFO] === FRONTEND: podman build ===
podman build -t %FRONTEND_IMAGE%:%FRONTEND_VERSION% -f frontend\Dockerfile .\frontend
podman tag %FRONTEND_IMAGE%:%FRONTEND_VERSION% %FRONTEND_FULL%
echo [OK] Frontend image: %FRONTEND_FULL%
exit /b 0

:frontend_push
echo [INFO] Frontend: podman push -^> %FRONTEND_FULL%
podman push %FRONTEND_FULL%
exit /b 0

:frontend_deploy
echo.
echo === FRONTEND DEPLOY COMMAND ===
echo kubectl set image deployment/%FRONTEND_DEPLOYMENT% %FRONTEND_CONTAINER%=%FRONTEND_FULL% -n %NAMESPACE%
echo [OK] Frontend deployment command ready: %FRONTEND_DEPLOYMENT%
exit /b 0
