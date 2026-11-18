# escape=`

# Inspired by https://github.com/eddex/aseprite-windows-docker-build
# This Dockerfile sets up a build environment and then builds Aseprite for Windows

FROM mcr.microsoft.com/windows/servercore:ltsc2025

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# 1. Install Chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install Visual Studio Build Tools + Windows SDK
RUN choco install visualstudio2022buildtools -y --no-progress `
        --package-parameters "'--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.Windows11SDK.26100'"

# 3. Install Git, Ninja, CMake
RUN choco install git ninja cmake -y --no-progress --installargs 'ADD_CMAKE_TO_PATH=System';
RUN git config --global --add safe.directory *; `
    git config --global advice.detachedHead false

# 4. Download & Extract Skia m124
RUN Invoke-WebRequest -Uri 'https://github.com/aseprite/skia/releases/download/m124-08a5439a6b/Skia-Windows-Release-x64.zip' -OutFile 'C:\skia.zip'; `
    Expand-Archive -Path 'C:\skia.zip' -DestinationPath 'C:\deps\skia' -Force; `
    Remove-Item 'C:\skia.zip' -Force

# 5. Clone Aseprite (fast shallow clone with parallel submodules)
ARG ASEPRITE_TAG=v1.3.18.6
WORKDIR C:\
RUN git clone --depth 1 --shallow-submodules --recurse-submodules --jobs 8 --single-branch --no-tags --branch $env:ASEPRITE_TAG https://github.com/aseprite/aseprite.git C:\aseprite

# 6. Build Aseprite
WORKDIR C:\aseprite\build
SHELL ["cmd", "/S", "/C"]
RUN call "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" -arch=x64 `
    && cmake -Wno-author -Wno-policy -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUPDATE_VERSION_WITH_GIT=ON -DLAF_BACKEND=skia -DSKIA_DIR=C:\deps\skia -DSKIA_LIBRARY_DIR=C:\deps\skia\out\Release-x64 -DSKIA_LIBRARY=C:\deps\skia\out\Release-x64\skia.lib -G Ninja .. `
    && ninja aseprite
