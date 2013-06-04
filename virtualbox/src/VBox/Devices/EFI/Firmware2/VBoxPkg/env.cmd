@echo off

REM $Id $
REM /*
REM  * Environment Setup Script for VBoxPkg + EDK2.
REM  */

REM /*
REM Copyright (C) 2009 Oracle Corporation
REM
REM This file is part of VirtualBox Open Source Edition (OSE), as
REM available from http://www.virtualbox.org. This file is free software;
REM you can redistribute it and/or modify it under the terms of the GNU
REM General Public License (GPL) as published by the Free Software
REM Foundation, in version 2 as it comes in the "COPYING" file of the
REM VirtualBox OSE distribution. VirtualBox OSE is distributed in the
REM hope that it will be useful, but WITHOUT ANY WARRANTY of any kind.
REM
REM */

rem
rem Figure where the VBox tools are, i.e. that tools/env.cmd has been execute.
rem
if not "%KBUILD_DEVTOOLS%"=="" goto kbuild_devtools_set
if "%PATH_DEVTOOLS%"=="" goto error_devtools
set KBUILD_DEVTOOLS=%PATH_DEVTOOLS%
:kbuild_devtools_set

rem
rem Check that all the tools we need are there.
rem
set MY_MISSING=
if not exist "%KBUILD_DEVTOOLS%\win.x86\vcc\v8sp1\bin\cl.exe" echo env.cmd: missing v8sp1.
if not exist "%KBUILD_DEVTOOLS%\win.x86\vcc\v8sp1\bin\cl.exe" set MY_MISSING=1
if not exist "%KBUILD_DEVTOOLS%\win.x86\vcc\v8sp1\env-x86.cmd" set MY_MISSING=1
if not exist "%KBUILD_DEVTOOLS%\win.x86\ddk\6000\bin\x86\nmake.exe" echo env.cmd: missing ddk/6001.
if not exist "%KBUILD_DEVTOOLS%\win.x86\ddk\6000\bin\x86\nmake.exe" set MY_MISSING=1
if not exist "%KBUILD_DEVTOOLS%\win.x86\sdk\200504\env-x86.cmd" echo env.cmd: missing sdk/200504.
if not exist "%KBUILD_DEVTOOLS%\win.x86\sdk\200504\env-x86.cmd" set MY_MISSING=1
if "%MY_MISSING%"=="" goto devtools_ok
echo env.cmd: Please run kmk -C %KBUILD_DEVTOOLS% KBUILD_TARGET_ARCH=amd64 to fetch the missing tools
set MY_MISSING=
exit /b1
:devtools_ok

rem
rem Figure out where the EDK2 checkout is.
rem
if "%CD%"=="" goto error_cd_not_set
pushd .
cd %~dp0
cd ..
set WORKSPACE=%CD%
popd
if exist "%WORKSPACE%\VBoxPkg\VBoxPkg.dsc" goto found_edk2
set WORKSPACE=%CD%
if exist "%WORKSPACE%\VBoxPkg\VBoxPkg.dsc" goto found_edk2
set WORKSPACE=%CD%\..
if exist "%WORKSPACE%\VBoxPkg\VBoxPkg.dsc" goto found_edk2
set WORKSPACE=%CD%\..\..
if exist "%WORKSPACE%\VBoxPkg\VBoxPkg.dsc" goto found_edk2
set WORKSPACE=
echo env.cmd: Cannot find EDK2. Please enter the VBoxPkg directory in your EDK2 checkout and re-run this script.
exit /b 1
:found_edk2

rem
rem Config the workspace.
rem
if exist "%WORKSPACE%\Conf\target.txt" goto reconfig
echo env.cmd: Configuring the workspace...

echo # Edited by VBoxPkg/env.cmd (%DATE% %TIME%)>       "%WORKSPACE%\Conf\tools_def.txt"
echo # > tmp_vbox_env.sed
echo s,C:\\Program Files\\Microsoft Visual Studio \.NET 2003\\Vc7,%KBUILD_DEVTOOLS%/win.x86/vcc/v7,>>               tmp_vbox_env.sed
echo s,C:\\Program Files\\Microsoft Visual Studio \.NET 2003\\Common7\\IDE,%KBUILD_DEVTOOLS%/win.x86/vcc/v7/bin,>>  tmp_vbox_env.sed
echo s,C:\\Program Files\\Microsoft Visual Studio 8\\Vc,%KBUILD_DEVTOOLS%/win.x86/vcc/v8sp1,>>                      tmp_vbox_env.sed
echo s,C:\\Program Files\\Microsoft Visual Studio 8\\Common7\\IDE,%KBUILD_DEVTOOLS%/win.x86/vcc/v8sp1/bin,>>        tmp_vbox_env.sed
echo s,C:\\Program Files (x86)\\Microsoft Visual Studio 8\\Vc,%KBUILD_DEVTOOLS%/win.x86/vcc/v8sp1,>>                tmp_vbox_env.sed
echo s,C:\\Program Files (x86)\\Microsoft Visual Studio 8\\Common7\\IDE,%KBUILD_DEVTOOLS%/win.x86/vcc/v8sp1/bin,>>  tmp_vbox_env.sed
echo s,C:\\WINDDK\\3790.1830,%KBUILD_DEVTOOLS%/win.x86/ddk/6001,>>      tmp_vbox_env.sed
echo s,C:\ASL,%KBUILD_DEVTOOLS%/win.x86/bin,>>                          tmp_vbox_env.sed
echo s,c:/cygwin,c:/no-cygwin-please,>>                                 tmp_vbox_env.sed
kmk_sed -f tmp_vbox_env.sed --append "%WORKSPACE%\Conf\tools_def.txt" "%WORKSPACE%\BaseTools\Conf\tools_def.template"
if not errorlevel 0 goto error_sed
del tmp_vbox_env.sed

copy "%WORKSPACE%\BaseTools\Conf\build_rule.template"   "%WORKSPACE%\Conf\build_rule.txt"
if not errorlevel 0 goto error_copy

rem must come last
echo # Generated by VBoxPkg/env.cmd (%DATE% %TIME%)>    "%WORKSPACE%\Conf\target.txt"
echo ACTIVE_PLATFORM=VBoxPkg/VBoxPkg.dsc>>              "%WORKSPACE%\Conf\target.txt"
echo TARGET=DEBUG>>                                     "%WORKSPACE%\Conf\target.txt"
echo TARGET_ARCH=IA32>>                                 "%WORKSPACE%\Conf\target.txt"
echo TOOL_CHAIN_CONF=Conf/tools_def.txt>>               "%WORKSPACE%\Conf\target.txt"
echo TOOL_CHAIN_TAG=MYTOOLS>>                           "%WORKSPACE%\Conf\target.txt"
echo MAX_CONCURRENT_THREAD_NUMBER=%NUMBER_OF_PROCESSORS% >> "%WORKSPACE%\Conf\target.txt"
echo BUID_RULE_CONF=Conf/build_rule.txt>>               "%WORKSPACE%\Conf\target.txt"

goto configured
:reconfig
echo env.cmd: Already configured.
echo env.cmd: If you want to reconfigure delete the following files and
echo env.cmd: re-run VBoxPkg\env.cmd:
echo env.cmd:    %WORKSPACE%\Conf\target.txt
echo env.cmd:    %WORKSPACE%\Conf\tools_def.txt
echo env.cmd:    %WORKSPACE%\Conf\build_rule.txt
:configured

rem
rem Make sure ComSpec is pointing to the standard Windows shell.
rem 4NT and other replacements may cause trouble.
rem
if "%ComSpec%"=="%SystemRoot%\system32\cmd.exe" goto comspec_ok
echo env.cmd: ComSpec does not seem to point at %SystemRoot%\system32\cmd.exe, fixing.
echo env.cmd: (ComSpec=%ComSpec%)
if not exist "%ComSpec%" echo env.cmd: Huh?? %SystemRoot%\system32\cmd.exe does not exist!
if not exist "%ComSpec%" exit /b 1
set ComSpec=%SystemRoot%\system32\cmd.exe
:comspec_ok

rem
rem Load the environment.
rem
echo env.cmd: Loading the environment...
call "%KBUILD_DEVTOOLS%\win.x86\sdk\200504\env-x86.cmd"
if not errorlevel 0 goto error_sdk_env

call "%KBUILD_DEVTOOLS%\win.x86\vcc\v8sp1\env-x86.cmd"
if not errorlevel 0 goto error_vcc_env

set EDK_TOOLS_PATH=%WORKSPACE%\BaseTools
call "%WORKSPACE%\BaseTools\toolsetup.bat"
if not errorlevel 0 goto error_edk2_toolsetup

echo env.cmd: Done.
exit /b 0


rem
rem Error messages.
rem
:error_devtools
echo env.cmd: Cannot find the VirtualBox devtools. Did you remember run tools/env.cmd in the VirtualBox tree first?
exit /b 1

:error_sdk_env
echo env.cmd: the SDK env script failed.
exit /b 1

:error_vcc_env
echo env.cmd: the Visual C++ env script failed.
exit /b 1

:error_edk2_toolsetup
echo env.cmd: the EDK2 env script failed.
exit /b 1

:error_cd_not_set
echo env.cmd: the internal CD variable isn't set. Complain to bird.
exit /b 1

:error_sed
echo env.cmd: kmk_sed failed, see above error messages(s).
exit /b 1

:error_copy
echo env.cmd: copy fails, see above error message(s).
del tmp_vbox_env.sed
exit /b 1
