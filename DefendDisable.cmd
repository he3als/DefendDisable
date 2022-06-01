@echo off
set version=v1.1
:: Use UTF-8 encoding
chcp 65001 >nul 2>&1
title DefendDisable %version% - @he3als
color 0c

:elevation_check
:: Checks if a user is system or not
whoami /user | find /i "S-1-5-18" >nul 2>&1
if %errorlevel%==0 (
	goto defender_check
) else (goto nsudo_dir)

:nsudo_dir
:: Get correct NSudo version
set ArchDir=Win32
if %PROCESSOR_ARCHITECTURE%==AMD64 set ArchDir=x64
if %PROCESSOR_ARCHITECTURE%==ARM set ArchDir=ARM
if %PROCESSOR_ARCHITECTURE%==ARM64 set ArchDir=ARM64
cd "%~dp0%ArchDir%" >nul 2>&1
if exist NSudoLG.exe (
	nsudolg.exe -U:T -P:E "%~dpnx0" && exit
	goto nsudo_path_check
) else (goto nsudo_path)

:nsudo_path
:: Some people have NSudo in PATH as nsudo.exe and nsudolg.exe, this detects both
where /q nsudo.exe >nul 2>&1
if %ERRORLEVEL%==0 (set nsudoexe=nsudo.exe)
where /q nsudolg.exe >nul 2>&1
if %ERRORLEVEL%==0 (set nsudoexe=nsudolg.exe) else (goto nsudo_fail)
%nsudoexe% -U:T -P:E "%~dpnx0" && exit
:: Something must of went wrong if the script did not exit
echo Something went wrong with self-elevation!
pause

:nsudo_fail
echo You need to run this script as SYSTEM, NSudoLG was not found.
echo Make sure that NSudoLG is in the script directory or in PATH.
echo Alternatively, get PowerRun and drag the script into the exe and accept the UAC prompt.
pause
exit /b

:defender_check
:: Check if the WinDefend service exists, if not then I automatically assume that you are using a custom ISO and that you have stripped Defender
sc query WinDefend1 | find /i "does not exist as an installed service" >nul 2>&1
if %errorlevel%==0 (
	echo WinDefend service is not present, you are most likely using a custom Windows ISO with stripped Defender.
	echo You can not continue, this script does not have the ability to reinstall and reintegrate Defender into Windows.
	pause
	exit /b
) else (goto main)


:main
mode con:cols=53 lines=21
cls
echo  ╔═════════════════════════════════════════════════╗
echo  ║ Toggling Windows Defender                       ║
echo  ╠═════════════════════════════════════════════════╣
echo  ║ This script allows you to disable or enable     ║
echo  ║ Windows Defender with its services and drivers. ║
echo  ║ Only use this if you really know what you are   ║
echo  ║ doing, security will be worsened. SmartScreen   ║
echo  ║ is also disabled. Created by @he3als on GitHub. ║
echo  ╟─────────────────────────────────────────────────╢
echo  ║ I am not responsible for any damage that is     ║
echo  ║ caused from using this script!                  ║
echo  ╟─────────────────────────────────────────────────╢
echo  ║ You need to disable tamper protection before    ║
echo  ║ using this script!                              ║
echo  ╟─────────────────────────────────────────────────╢
echo  ║ 1) Disable Defender                             ║
echo  ║ 2) Enable Defender                              ║
echo  ║ 3) Exit                                         ║
echo  ╚═════════════════════════════════════════════════╝
:: Fix for choice not respecting spaces/padding at the start of the CHOICE.exe message
:: Credit to Mathieu#4291 in the server.bat Discord server
pushd "%~dp0"
for /f %%A in ('forfiles /m "%~nx0" /c "cmd /c echo(0x08"') do (
    set "\B=%%A"
)

CHOICE /N /C:123 /M ".%\B% Type 1 or 2 or 3 ->"
IF %ERRORLEVEL%==1 goto disable_confirm
IF %ERRORLEVEL%==2 goto enable_confirm
IF %ERRORLEVEL%==3 goto exit
goto menu

:enable_confirm
cls
:: Maximise the window
powershell -NonInteractive -NoProfile -window maximized -command ""
echo This will enable Defender, improving security but also reducing performance and causing more annoyances.
echo I highly recommend to configure the Windows Security app after restarting.
echo Windows Defender policies will be cleared. Continue?
timeout /t 5 /nobreak
pause
goto enable

:enable
color 0f
echo]
echo Closing the Security app if open...
taskkill /f /im SecHealthUI.exe >nul 2>&1
taskkill /f /im SecHealthUI.exe >nul 2>&1
echo]
echo Configuring Windows Defender...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager" /f > nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center" /f > nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /f > nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /f > nul
reg delete "HKCU\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter" /f > nul
reg delete "HKLM\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter" /f > nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f > nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v "Enabled" /f > nul
echo]
echo Enabling services/drivers related to Windows Defender...
reg add "HKLM\SYSTEM\ControlSet001\Services\SgrmAgent" /v "Start" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\ControlSet001\Services\SgrmBroker" /v "Start" /t REG_DWORD /d "2" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wdboot" /v "Start" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wdfilter" /v "Start" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v "Start" /t REG_DWORD /d "2" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wdnisdrv" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mssecflt" /v "Start" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Sense" /v "Start" /t REG_DWORD /d "3" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wscsvc" /v "Start" /t REG_DWORD /d "2" /f
echo]
echo Enabling tasks...
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable > nul
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable > nul
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable > nul
echo]
echo Enabling context menu to scan files, folders and drives...
reg query "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\EPP" | find /i "ERROR" >nul 2>&1
if %ERRORLEVEL%==1 (
	reg copy "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\DefenderDisabled\EPP" "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\EPP" > nul
	reg delete "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\DefenderDisabled" /f >nul 2>&1
)
reg query "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\EPP" | find /i "ERROR" >nul 2>&1
if %ERRORLEVEL%==1 (
	reg copy "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\DefenderDisabled\EPP" "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\EPP" > nul
	reg delete "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\DefenderDisabled" /f >nul 2>&1
)
reg query "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\EPP" | find /i "ERROR" >nul 2>&1
if %ERRORLEVEL%==1 (
	reg copy "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\DefenderDisabled\EPP" "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\EPP" > nul
	reg delete "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\DefenderDisabled" /f >nul 2>&1
)
echo]
echo Renaming Windows Defender folders back to default...
if not exist "C:\ProgramData\Microsoft\Windows Defender\Platform" (
	cd /d "C:\ProgramData\Microsoft\Windows Defender" > nul
	ren "Platform1" "Platform" > nul
)
if not exist "C:\Program Files\Windows Defender" (
	cd /d "C:\Program Files" > nul
	ren "Windows Defender1" "Windows Defender" > nul
)
echo]
color 0a
echo Enabled Defender. Your computer will be restarted!
echo Note: There's no error detection, look above to check if there's errors. If there is, then you should restart and re-run the script until there's no errors.
echo There also could just simply be an issue with the script or you could of done other modifications to your Windows install that caused an error.
shutdown.exe /r /t 30 /c "Enabling Defender - Shutting down in 30 secs.
timeout /t 3 /nobreak
pause
exit /b

:disable_confirm
cls
:: Maximise window
powershell -NonInteractive -NoProfile -window maximized -command ""
echo WARNING: Security of your computer will be worsened and there could be potential issues with updating Windows. I am not responsible for any damage as you have been warned!
echo Your computer will be restarted once after Defender is disabled, so please save everything you need to save!
echo Ensure that you have no Windows Updates pending, fully update your system before you run this script!
echo SmartScreen and some other features will also be disabled, edit the script for details.
timeout /t 10 /nobreak
pause
echo]
:: Tamper protection will certainly prevent the script from doing any major changes, it needs to be disabled
echo Just to make sure...
CHOICE /N /M "DO YOU HAVE TAMPER PROTECTION ENABLED? [Y/N]"
if %errorlevel%==1 goto tamper
if %errorlevel%==2 goto disable
echo]
:: Just in case any updates could revert the changes done by the script
echo Just to make sure...
CHOICE /N /M "DO YOU HAVE ANY PENDING WINDOWS UPDATES? [Y/N]"
if %errorlevel%==1 goto update
if %errorlevel%==2 goto disable
goto disable

:disable
color 0f
echo]
echo Closing the Security app if open...
taskkill /f /im SecHealthUI.exe >nul 2>&1
taskkill /f /im SecHealthUI.exe >nul 2>&1
echo]
echo Configuring Windows Defender...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRealtimeMonitoring" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "PUAProtection" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v "ConfigureAppInstallControlEnabled" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v "ConfigureAppInstallControl" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v "EnableSmartScreen" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\SpyNet" /v "SpyNetReporting" /t REG_DWORD /d "0" /f > nul
:: reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotification" /t REG_DWORD /d "1" /f > nul
:: reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoToastApplicationNotificationOnLockScreen" /t REG_DWORD /d "1" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v "Enabled" /t REG_DWORD /d "0" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v "DefaultFileTypeRisk" /t REG_DWORD /d "1808" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d "1" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v "LowRiskFileTypes" /t REG_SZ /d ".avi;.bat;.com;.cmd;.exe;.htm;.html;.lnk;.mpg;.mpeg;.mov;.mp3;.msi;.m3u;.rar;.reg;.txt;.vbs;.wav;.zip;" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v "ModRiskFileTypes" /t REG_SZ /d ".bat;.exe;.reg;.vbs;.chm;.msi;.js;.cmd" /f > nul
reg add "HKCU\Software\Microsoft\Edge\SmartScreenEnabled" /t REG_DWORD /d "0" /f > nul
reg add "HKCU\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter" /v "EnabledV9" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter" /v "EnabledV9" /t REG_DWORD /d "0" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d "0" /f > nul
echo]
echo Disabling services/drivers related to Windows Defender...
reg add "HKLM\SYSTEM\ControlSet001\Services\SgrmAgent" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\ControlSet001\Services\SgrmBroker" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wdboot" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wdfilter" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wdnisdrv" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mssecflt" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Sense" /v "Start" /t REG_DWORD /d "4" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wscsvc" /v "Start" /t REG_DWORD /d "4" /f > nul
:: Couleur had this weird asf driver on startup but I think it is fine if I don't touch it
:: reg add "HKLM\SYSTEM\CurrentControlSet\Services\MpKsl251b8453" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
echo]
echo Disabling tasks...
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable > nul
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable > nul
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable > nul
echo]
echo Disabling context menu to scan files, folders and drives...
reg query "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\EPP" | find /i "ERROR" >nul 2>&1
if %ERRORLEVEL%==0 (
	reg delete "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\DefenderDisabled\EPP" /f >nul 2>&1
	reg copy "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\EPP" "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\DefenderDisabled\EPP" > nul
)
reg query "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\EPP" | find /i "ERROR" >nul 2>&1
if %ERRORLEVEL%==0 (
	reg delete "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\DefenderDisabled\EPP" /f >nul 2>&1
	reg copy "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\EPP" "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\DefenderDisabled\EPP" > nul
)
reg query "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\EPP" | find /i "ERROR" >nul 2>&1
if %ERRORLEVEL%==0 (
	reg delete "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\DefenderDisabled\EPP" /f >nul 2>&1
	reg copy "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\EPP" "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\DefenderDisabled\EPP" > nul
)
echo]
echo Renaming Windows Defender folders to prevent it from enabling it self...
:: Aetopia said that this fixed Defender from re-enabling it self, he also said that it works fine with updates
:: Doesn't seem to negatively effect anything
:: Most likely will fail here, you need to re-run the script again after a restart
if not exist "C:\ProgramData\Microsoft\Windows Defender\Platform1" (
	cd /d "C:\ProgramData\Microsoft\Windows Defender" > nul
	ren "Platform" "Platform1" > nul
)
if not exist "C:\Program Files\Windows Defender1" (
	cd /d "C:\Program Files" > nul
	ren "Windows Defender" "Windows Defender1" > nul
)
echo]
color 0a
echo Disabled Defender. Your computer will be restarted!
echo Note: There's no error detection, look above to check if there's errors. If there is, then you should restart and re-run the script until there's no errors.
echo There also could just simply be an issue with the script or you could of done other modifications to your Windows install that caused an error.
shutdown.exe /r /t 30 /c "Disabling Defender - Shutting down in 30 secs.
timeout /t 3 /nobreak
pause
exit /b

:tamper
echo]
echo You NEED to disable tamper protection to use this script. Disabling tamper protection also means that you aknowledge the security risks with disabling Defender.
pause
cd /d C:\Program Files\WindowsApps\
cd Microsoft.SecHealthUI_*\
start SecHealthUI.exe
exit /b

:update
echo]
echo You need to update Windows.
pause
cd /d "C:\Windows\ImmersiveControlPanel"
start SystemSettings.exe
exit /b