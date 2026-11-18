@echo off
setlocal

echo [1/4] Building Aseprite Docker image...
docker build -m 8GB -t aseprite-builder .
if %errorlevel% neq 0 (
    echo Docker build failed!
    exit /b %errorlevel%
)

echo [2/4] Creating temporary container for extraction...
docker rm -f temp-extract >nul 2>&1
docker create --name temp-extract aseprite-builder

echo [3/4] Copying build artifacts to .\build-output...
if exist ".\build-output" rmdir /s /q ".\build-output"
docker cp temp-extract:C:\aseprite\build\bin .\build-output

echo [4/4] Cleaning up container...
docker rm temp-extract

echo Done! Aseprite binaries are in .\build-output