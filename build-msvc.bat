@echo off
setlocal enabledelayedexpansion

for /f "delims=" %%A in ('where MSBuild') do set "MSBUILD_PATH=%%A"

if defined MSBUILD_PATH (
    echo Already in MSVC build environment
    goto :InBuildEnv
)

set "VS32_DIR=%ProgramFiles(x86)%\Microsoft Visual Studio\2022"
set "VS_DIR=%ProgramFiles%\Microsoft Visual Studio\2022"

for %%B in ("%VS32_DIR%" "%VS_DIR%") do (
    for %%E in (BuildTools Community Enterprise Professional) do (
        set "VCVARS64=%%~B\%%E\VC\Auxiliary\Build\vcvars64.bat"
        if exist "!VCVARS64!" (
            goto :VcvarsFound
        )
    )
)

echo Couldn't find vcvars64
exit /b 1

:VcvarsFound

echo Calling vcvars64
call "%VCVARS64%"

:InBuildEnv

if defined VAPOURSYNTH_LIB_DIR (
    set "VAPOURSYNTH_INCLUDE_DIR=%VAPOURSYNTH_LIB_DIR%\..\include"
)
if not defined VAPOURSYNTH_LIB_DIR (
    for /f "delims=" %%A in ('where vsrepo.py') do (
        set "VAPOURSYNTH_INCLUDE_DIR=%%dpA\..\sdk\include"
        set "VAPOURSYNTH_LIB_DIR=%%dpA\..\sdk\lib64"
    )
)

if not defined VAPOURSYNTH_INCLUDE_DIR (
    echo Couldn't find Vapoursynth SDK, please set VAPOURSYNTH_LIB_DIR or make sure vsrepo is accessible by PATH
    exit /b 1
)

for %%X in (AVX AVX2 AVX512) do (
    MSBuild .\msvc\Bilateral.vcxproj /t:Clean;Build /p:Configuration=Release-%%X /p:IncludePath="%VAPOURSYNTH_INCLUDE_DIR%"
)
