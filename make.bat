@echo off
set argC=0
for %%x in (%*) do Set /A argC+=1
if %argC% neq 1 goto invalidArgs
if %1==help goto help
if %1==build goto build
if %1==deps goto deps
if %1==format goto format
if %1==lint goto lint
if %1==test-unit goto test-unit
if %1==test-integration goto test-integration
if %1==clean goto clean

:invalidArgs
echo invalid args, please check command
call :help
goto end
 
:help
echo ---- Project: Ptt-backend ----
echo  Usage: ./make.bash COMMAND
echo. 
echo  Management Commands:
echo   build              Build project
echo   deps               Ensures fresh go.mod and go.sum for dependencies
echo   format             Formats Go code
echo   lint               Run golangci-lint check
echo   test-unit          Run all unit tests
echo   test-integration   Run all integration and unit tests
echo   clean              Remove object files, ./bin, .out files
echo.
goto end

:build
FOR /F "tokens=*" %%g IN ('"git rev-parse --short HEAD"') do set GITSHA=%%g
set Tag=""
FOR /F %%i IN ('"git rev-list --tags --max-count 1"') do set Tag=%%i
IF NOT %Tag%=="" (
    FOR /F %%j IN ('"git describe --tags %Tag%"') DO set VERSION=%%j
) ELSE (
    set VERSION=git-%GITSHA%
 )

for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x
Set Second=0%Second%
Set Second=%Second:~-2%
Set Minute=0%Minute%
Set Minute=%Minute:~-2%
Set Hour=0%Hour%
Set Hour=%Hour:~-2%
Set Day=0%Day%
Set Day=%Day:~-2%
Set Month=0%Month%
Set Month=%Month:~-2%
set BUILDTIME=%Year%-%Month%-%Day%T%Hour%:%Minute%:%Second%Z

set GOFLAGS=-trimpath
set LDFLAGS="-X main/version.version=%VERSION% -X main/version.commit=%GITSHA% -X main/version.buildTime=%BUILDTIME%"
mkdir bin 2>nul
echo VERSION: %VERSION%
echo GITSHA: %GITSHA%
echo binary file output into .\bin
go build %GOFLAGS% -ldflags %LDFLAGS% -o .\bin .\...
goto end

:deps
go mod tidy
go mod verify
goto end

:format
go fmt .\...
goto end

:lint
set "GOBIN=%GOPATH%\bin"
if not exist "%GOBIN%\golangci-lint.exe" (
    go get github.com/golangci/golangci-lint/cmd/golangci-lint@v1.35.2
)
%GOBIN%\golangci-lint run ./...
goto end

:test-unit
setlocal
    set CGO_ENABLED=1 && go test -v -coverprofile=coverage.out -cover -race
endlocal
goto end

:test-integration
setlocal
    set CGO_ENABLED=1 && go test -race -tags=integration -covermode=atomic -coverprofile=coverage.tmp
    DEL "*.tmp"
endlocal
goto end

:clean
go clean -i -x
echo delete bin, clean out files
rmdir /S /Q "bin" 2>nul
DEL /Q /F /S "*.out" 2>nul
goto end

:end