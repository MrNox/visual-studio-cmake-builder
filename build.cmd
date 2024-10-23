@echo off 
setlocal enableextensions enabledelayedexpansion

set _CC=cl.exe
set _CXX=cl.exe

if not exist "vs_paths.txt" (
    where /R %SYSTEMDRIVE%\ devenv.exe > vs_paths.txt
)

set current_dir=%~dp0
set build_dir=%current_dir%out\build
set install_dir=%current_dir%out\install

del /S /F /Q %build_dir%

set /A count=0
for /F "delims=" %%a in (vs_paths.txt) do (
    set /A count+=1
    set array[!count!]=%%a
)

set /A vs_chosen=1
if %count% gtr 1 (
    echo Some Visual Studio paths are found, please choose following:
    for /L %%i in (1,1,%count%) do call echo [%%i] !array[%%i]!

    set /p id=Enter ID: 
    set /A vs_chosen=!id!+0

    if !vs_chosen! == 0 (
        echo The ID was wrong, exiting...
        exit /b 0
    )
    
    if !vs_chosen! gtr %count% (
        echo The ID was wrong, exiting...
        exit /b 0
    )
)

set vs_binary_path="!array[%vs_chosen%]!"
for %%a in (%vs_binary_path%) do for %%b in ("%%~dpa..\..\") do set vs_sub_path=%%~dpb

set vsbat_path=%vs_sub_path%VC\Auxiliary\Build
set vsbatx86_path="%vsbat_path%\vcvars32.bat"
set vsbatx64_path="%vsbat_path%\vcvars64.bat"
set cmake_path="%vs_sub_path%Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
set ninja_path="%vs_sub_path%Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"

echo Choose options to build
echo [1] x86
echo [2] x64
echo [3] x86 and x64
set /p id=Enter a ID: 

set /A vsbat_chosen=!id!+0
if !vsbat_chosen! == 0 (
    echo The ID was wrong, exiting...
    exit /b 0
)
if !vsbat_chosen! gtr 3 (
    echo The ID was wrong, exiting...
    exit /b 0
)

if !vsbat_chosen! == 1 (
    if not exist %vsbatx86_path% (
        echo %vsbatx86_path% doesn't found
        exit /b 0
    )
    call :making_x86
    call :building_x86
)

if !vsbat_chosen! == 2 (
    if not exist %vsbatx64_path% (
        echo %vsbatx64_path% doesn't found
        exit /b 0
    )
    call :making_x64
    call :building_x64
)

if !vsbat_chosen! == 3 (
    if not exist %vsbatx86_path% (
        echo %vsbatx86_path% doesn't found
        exit /b 0
    )
    call :making_x86
    call :building_x86
    
    if not exist %vsbatx64_path% (
        echo %vsbatx64_path% doesn't found
        exit /b 0
    )
    call :making_x64
    call :building_x64

)

goto :EOF

:making_x86
    set making_dir="%build_dir%\x86-release"
    if not exist %making_dir% (
        mkdir %making_dir%
    )

    pushd %making_dir%
    cmd.exe /c "%vsbatx86_path% &&  %cmake_path%  -G "Ninja"  -DCMAKE_C_COMPILER:STRING="%_CC%" -DCMAKE_CXX_COMPILER:STRING="%_CXX%" -DCMAKE_BUILD_TYPE:STRING="Release" -DCMAKE_INSTALL_PREFIX:PATH=%install_dir%\x86-release  -DCMAKE_MAKE_PROGRAM=%ninja_path% %current_dir% 2>&1"
    popd
    exit /b
    
:making_x64
    set making_dir="%build_dir%\x64-release"
    if not exist %making_dir% (
        mkdir %making_dir%
    )

    pushd %making_dir%
    cmd.exe /c "%vsbatx64_path% && %cmake_path%  -G "Ninja"  -DCMAKE_C_COMPILER:STRING="%_CC%" -DCMAKE_CXX_COMPILER:STRING="%_CXX%" -DCMAKE_BUILD_TYPE:STRING="Release" -DCMAKE_INSTALL_PREFIX:PATH=%install_dir%\x64-release  -DCMAKE_MAKE_PROGRAM=%ninja_path% %current_dir% 2>&1"
    popd

    exit /b

:building_x86
    cmd.exe /c "%vsbatx86_path% && %cmake_path% --build "%build_dir%/x86-release" --clean-first  --config Release"
    exit /b

:building_x64
    cmd /c "%vsbatx64_path% && %cmake_path% --build "%build_dir%/x64-release" --clean-first  --config Release"
    exit /b
    
:EOF
