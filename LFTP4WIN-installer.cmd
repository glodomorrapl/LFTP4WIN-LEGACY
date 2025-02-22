@echo off
::
:: Copyright 2022 by glodomorrapl
:: Copyright 2019 by userdocs and contributors for LFTP4WIN installer derived from https://github.com/vegardit/cygwin-portable-installer
:: Copyright 2017-2019 by Vegard IT GmbH (https://vegardit.com) and the cygwin-portable-installer contributors.
::
:: SPDX-License-Identifier: Apache-2.0
::
:: LFTP4WIN-LEGACY installer derived from LFTP4WIN installer by userdocs
:: @author glodomorrapl
:: @contributors
::
:: LFTPWIN installer derived from cygwin-portable-installer
:: @author userdocs
:: @contributors
::
:: cygwin-portable-installer
:: @author Sebastian Thomschke, Vegard IT GmbH
:: @contributor userdocs bofhbug xnum
::
:: ABOUT
:: =====
:: LFTP4WIN-LEGACY installer is the modified version of the LFTP4WIN installer, adjusted for 32-bit support on older operating systems. Description below refers to the original project.
::
:: A heavily modified and re-targeted version of this project https://github.com/vegardit/cygwin-portable-installer
:: Original code has been 1: removed where not relevant 2: Modified to work with LFTP4WIN CORE 3: Unmodified where applicable.
:: It installs a portable Cygwin installation to be used specifically with the https://github.com/userdocs/LFTP4WIN-CORE skeleton.
:: The LFTP4WIN-CORE is applied to the Cygwin installation with minimal modification to the Cygwin environment or core files.
:: This provides a a fully functional Cygwin portable platform for use with the LFTP4WIN project.
:: Environment customization is no longer designed to be fully self contained and is partially provided via the LFTP4WIN-CORE
:: There are still some critical configuration options available below for the installation.

:: ============================================================================================================
:: CONFIG CUSTOMIZATION START
:: ============================================================================================================

:: You can customize the following variables to your needs before running the batch file:

:: Choose a user name that will be used to configure Cygwin. This user will be a clone of the account running the installation script renamed as the setting chosen.
set LFTP4WIN_USERNAME=LFTP4WIN

:: Show the packet manager if you need to specify a program version during installation instead of using the current release (default), like openssh 7.9 instead of 8.0 for Lftp.
set CYGWIN_PACKET_MANAGER=

:: Select the packages to be installed automatically - required packages for LFTP4WIN:bsdtar,bash-completion,curl,lftp,ssh-pageant,openssh
set CYGWIN_PACKAGES=wget,ca-certificates,gnupg,bsdtar,bash-completion,curl,lftp,ssh-pageant,openssh,openssl,sshpass,procps-ng

:: Install the LFTP4WIN Skeleton files to use lftp via WinSCP and Conemu. Installs Conemu, kitty, WinSCP, notepad++ and makes a few minor modifications to the default cygin installation.
set INSTALL_LFTP4WIN_CORE=yes

:: This is a mirror provided by the Cygwin Time Machine project, do not change unless you know what you're doing
set CYGWIN_MIRROR=http://ctm.crouchingtigerhiddenfruitbat.org/pub/cygwin/circa/2022/11/23/063457

:: add more path if required, but at the cost of runtime performance (e.g. slower forks)
set CYGWIN_PATH=""

:: if set to 'yes' the local package cache created by cygwin setup will be deleted after installation/update
set DELETE_CYGWIN_PACKAGE_CACHE=yes

:: ============================================================================================================
:: CONFIG CUSTOMIZATION END
:: ============================================================================================================

echo.
echo ###########################################################
echo # Installing [Cygwin Portable]...
echo ###########################################################
echo.

set LFTP4WIN_BASE=%~dp0
set LFTP4WIN_ROOT=%~dp0system
set INSTALL_TEMP=%~dp0system\tmp

set USERNAME=%LFTP4WIN_USERNAME%
set GROUP=None
set GRP=
set SHELL=/bin/bash

if not exist "%INSTALL_TEMP%" (
    md "%LFTP4WIN_ROOT%"
    md "%LFTP4WIN_ROOT%\etc"
    md "%INSTALL_TEMP%"
)

:: download the last available version of Cygwin 32 
set CYGWIN_SETUP=setup-2.924.x86.exe

if exist "%INSTALL_TEMP%\%CYGWIN_SETUP%" (
    del "%INSTALL_TEMP%\%CYGWIN_SETUP%" || goto :fail
)

if "%CYGWIN_PACKET_MANAGER%" == "yes" (
   set CYGWIN_PACKET_MANAGER=--package-manager
)

echo Downloading some files, it can take a minute or two...
echo.

bitsadmin /transfer cygwin /download /priority FOREGROUND /DYNAMIC "https://cygwin.org/%CYGWIN_SETUP%" "%INSTALL_TEMP%\%CYGWIN_SETUP%" > NUL || goto :fail

if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
    bitsadmin /transfer lftp4win /download /priority FOREGROUND /DYNAMIC "https://github.com/userdocs/LFTP4WIN-CORE/archive/master.zip" "%INSTALL_TEMP%\lftp4win.zip" > NUL || goto :fail
)

echo Running Cygwin setup...
echo.

"%INSTALL_TEMP%\%CYGWIN_SETUP%" --no-admin --allow-unsupported-windows option ^
 --site "%CYGWIN_MIRROR%" ^
 --root "%LFTP4WIN_ROOT%" ^
 --local-package-dir "%LFTP4WIN_ROOT%\.pkg-cache" ^
 --no-shortcuts ^
 --no-desktop ^
 --delete-orphans ^
 --upgrade-also ^
 --no-replaceonreboot ^
 --quiet-mode ^
 --packages %CYGWIN_PACKAGES% %CYGWIN_PACKET_MANAGER% || goto :fail

if "%DELETE_CYGWIN_PACKAGE_CACHE%" == "yes" (
    rd /s /q "%LFTP4WIN_ROOT%\.pkg-cache"
)

(
    echo # /etc/fstab
    echo # IMPORTANT: this files is recreated on each start by LFTP4WIN-terminal.cmd
    echo #
    echo #    This file is read once by the first process in a Cygwin process tree.
    echo #    To pick up changes, restart all Cygwin processes.  For a description
    echo #    see https://cygwin.com/cygwin-ug-net/using.html#mount-table
    echo #
    echo none /cygdrive cygdrive binary,noacl,posix=0,sparse,user 0 0
) > "%LFTP4WIN_ROOT%\etc\fstab"

:: Configure our Cygwin Environment
"%LFTP4WIN_ROOT%\bin\mkgroup.exe" -c > system/etc/group || goto :fail
"%LFTP4WIN_ROOT%\bin\bash.exe" -c "echo ""$USERNAME:*:1001:$(system/bin/mkpasswd -c | system/bin/cut -d':' -f 4):$(system/bin/mkpasswd -c | system/bin/cut -d':' -f 5):$(system/bin/cygpath.exe -u ""%~dp0home""):/bin/bash""" > system/etc/passwd || goto :fail
:: Fix a symlink bug in Cygwin
"%LFTP4WIN_ROOT%\bin\ln.exe" -fsn '../usr/share/terminfo' '/lib/terminfo' || goto :fail

if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
    "%LFTP4WIN_ROOT%\bin\bsdtar.exe" -xmf "%INSTALL_TEMP%\lftp4win.zip" --strip-components=1 -C "%LFTP4WIN_BASE%\" || goto :fail
    "%LFTP4WIN_ROOT%\bin\touch.exe" "%LFTP4WIN_ROOT%\.core-installed"
)

set Init_sh=%LFTP4WIN_ROOT%\portable-init.sh
echo Creating [%Init_sh%]...
echo.
(
    echo #!/usr/bin/env bash
    echo #
    echo ## Map Current Windows User to root user
    echo #
	echo unset HISTFILE
	echo #
    echo USER_SID="$(mkpasswd -c | cut -d':' -f 5)"
    echo echo "Mapping Windows user '$USER_SID' to cygwin '$USERNAME' in /etc/passwd..."
    echo mkgroup -c ^> /etc/group
    echo echo "$USERNAME:*:1001:$(mkpasswd -c | cut -d':' -f 4):$(mkpasswd -c | cut -d':' -f 5):$HOME:/bin/bash" ^> /etc/passwd
    echo #
    echo ## Create required directories
    echo #
    echo mkdir -p ~/bin
    echo #
    echo ## Adjust the Cygwin packages cache path
    echo #
    echo pkg_cache_dir=$(cygpath -w "$LFTP4WIN_ROOT/.pkg-cache"^)
    echo #
    echo sed -ri 's#(.*^)\.pkg-cache$#'"\t${pkg_cache_dir//\\/\\\\}"'#' /etc/setup/setup.rc
    if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
        echo #
        echo lftp4win_core=$(cygpath -m "$LFTP4WIN_ROOT/../"^)
        echo #
        echo if [[ -f /.core-installed ^&^& $CORE_UPDATE = 'yes' ]]; then
        echo     echo "*******************************************************************************"
        echo     echo "* Updating LFTP4WIN CORE..."
        echo     echo "*******************************************************************************"
        echo     lftp4win_core_url="https://github.com/userdocs/LFTP4WIN-CORE/archive/master.zip"
        echo     echo "Download URL=$lftp4win_core_url"
        echo     curl -sL "$lftp4win_core_url" -o "lftp4win_core.zip"
        echo     bsdtar -X '/.core-update-excludes' -xmf "lftp4win_core.zip" --strip-components=1 -C "$lftp4win_core"
        echo     [[ -d /applications ]] ^&^& touch /.core-installed
        echo     rm -f 'lftp4win_core.zip' '.gitattributes' 'LICENSE.txt' 'README.md'
        echo fi
        echo #
        echo source "/.core-cleanup"
    )
    echo #
    echo ## Installing apt-cyg package manager to home folder ~/bin
    echo #
    echo curl -sL https://raw.githubusercontent.com/kou1okada/apt-cyg/master/apt-cyg ^> ~/bin/apt-cyg
    echo #
	echo set HISTFILE
) > "%Init_sh%" || goto :fail

"%LFTP4WIN_ROOT%\bin\sed" -i 's/\r$//' "%Init_sh%" || goto :fail

set Start_cmd=%LFTP4WIN_BASE%LFTP4WIN-terminal.cmd
echo Creating launcher [%Start_cmd%]...
echo.
(
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo.
    echo set LFTP4WIN_BASE=%%~dp0
    echo set LFTP4WIN_ROOT=%%~dp0system
    echo.
    echo set PATH=%%LFTP4WIN_ROOT%%\bin
    echo set USERNAME=%LFTP4WIN_USERNAME%
    echo set HOME=%%LFTP4WIN_BASE%%home
    echo set GROUP=None
    echo set GRP=
    echo set SHELL=/bin/bash
    echo.
    echo set TERMINAL=mintty
    echo.
    echo ^(
    echo     echo # /etc/fstab
    echo     echo # IMPORTANT: this files is recreated on each start by LFTP4WIN-terminal.cmd
    echo     echo #
    echo     echo #    This file is read once by the first process in a Cygwin process tree.
    echo     echo #    To pick up changes, restart all Cygwin processes.  For a description
    echo     echo #    see https://cygwin.com/cygwin-ug-net/using.html#mount-table
    echo     echo #
    echo     echo none /cygdrive cygdrive binary,noacl,posix=0,sparse,user 0 0
    echo ^) ^> "%%LFTP4WIN_ROOT%%\etc\fstab"
    echo.
    echo IF EXIST "%%LFTP4WIN_ROOT%%\etc\fstab" "%%LFTP4WIN_ROOT%%\bin\sed" -i 's/\r$//' "%%LFTP4WIN_ROOT%%\etc\fstab"
    echo.
    echo IF EXIST "%%LFTP4WIN_ROOT%%\portable-init.sh" "%%LFTP4WIN_ROOT%%\bin\bash" -li "%%LFTP4WIN_ROOT%%\portable-init.sh"
    echo.
    echo set LIST=
    echo for %%%%x in ^("%%LFTP4WIN_BASE%%keys\*.ppk"^) do set LIST=!LIST! "%%%%x"
    echo IF exist "%%LFTP4WIN_BASE%%keys\*.ppk" ^(
    echo start "" "%%LFTP4WIN_ROOT%%\applications\kitty\kageant.exe" %%LIST:~1%%
    echo ^)
    echo.
    if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
    echo if "%%TERMINAL%%" == "conemu" ^(
         echo   start "" "%%LFTP4WIN_ROOT%%\applications\conemu\ConEmu.exe" -cmd {Bash::bash}
    echo ^)
    )
    echo.
    echo if "%%TERMINAL%%" == "mintty" ^(
    echo   start "" "%%LFTP4WIN_ROOT%%\bin\mintty.exe" --nopin --title LFTP4WIN -e /bin/bash -li
    echo ^)
) > "%Start_cmd%" || goto :fail

echo ###########################################################
echo # Installing [LFTP4WIN Portable] succeeded.
echo ###########################################################
echo.
echo Use [%Start_cmd%] to launch LFTP4WIN Portable.
echo.

del /q "%INSTALL_TEMP%\%CYGWIN_SETUP%" "%LFTP4WIN_ROOT%\Cygwin.bat" "%LFTP4WIN_ROOT%\Cygwin.ico" "%LFTP4WIN_ROOT%\Cygwin-Terminal.ico"

if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
    DEL /Q "%LFTP4WIN_BASE%\.gitattributes" "%LFTP4WIN_BASE%\README.md" "%LFTP4WIN_BASE%\LICENSE.txt" "%INSTALL_TEMP%\lftp4win.zip"
    RMDIR /S /Q "%LFTP4WIN_BASE%\docs"
)

timeout /T 60
goto :eof

:fail
    if exist "%DOWNLOADER%" (
        del "%DOWNLOADER%"
    )
    echo.
    echo ###########################################################
    echo # Installing [LFTP4WIN Portable] FAILED!
    echo ###########################################################
    echo.
    timeout /T 60
    exit /b 1
