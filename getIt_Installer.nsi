;    GetIt - "Makes installing windows software simple."
;
;    Copyright © 2011 Puchisoft, Inc.
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;    Contact, email: Robin.Gersabeck@gmail.com
;    ----------------------------------------------------------------
;    Please note: Win-Get, which is included only as a binary in this 
;    distribution, was created by Ryan Proctor.
;
;    This code may use various code samples avaliable in the NSIS
;    documentation, which were written by their respective authors.
;    ----------------------------------------------------------------

; HM NIS Edit Wizard helper defines ; Script generated (partially) by the HM NIS Edit Script Wizard.


;!define PRODUCT_VERSION "DEBUG"
!include installer_includes.nsh

!define PRODUCT_NAME "GetIt"
!define PRODUCT_PUBLISHER "Puchisoft, Inc"
!define PRODUCT_WEB_SITE "http://www.puchisoft.com"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\getit.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

brandingtext "Puchisoft Dispatcher" 

SetCompressor /SOLID lzma

Function .onInstSuccess
FunctionEnd

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "..\GetIt_Setup.exe"
LoadLanguageFile "${NSISDIR}\Contrib\Language files\English.nlf"
InstallDir "$PROGRAMFILES\Puchisoft\GetIt"
Icon "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
UninstallIcon "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
LicenseText "If you accept all the terms of the agreement, choose I Agree to continue. You must accept the agreement to install $(^Name)."
LicenseData "gpl-3.0.txt"
ShowInstDetails show
ShowUnInstDetails show

Section "MainSection" SEC01
  KillProcDLL::KillProc "getit.exe"
  KillProcDLL::KillProc "getit_gui.exe"

  SetOverwrite on
  strcpy $INSTDIR "$PROGRAMFILES\Puchisoft\GetIt"
  SetOutPath "$INSTDIR\Examples"
  
  File "Examples\AddRepositories_example.git"

  File "Examples\Repository_example.ini"  
  SetOutPath "$INSTDIR\Engine"

  File "Engine\appupdater.ini"

  File "Engine\appsnap.ini"

  File "Engine\win-get.ini"
  SetOutPath "$INSTDIR\WinGet"

  File "WinGet\wget.exe"

  File "WinGet\win-get.exe"

  File "WinGet\winGetRep.bat"
  
  ;Now with more OpenSource
  SetOutPath "$INSTDIR\src"

  File "gpl-3.0.txt"

  File "src_info.txt"

  File "getIt_Installer.nsi"

  File "getit.nsi"
  
  File "MakeDataInclude.nsi"

  File "gui.mfa"

  SetOutPath "$INSTDIR"

  File "getengines.bat"

  File "${NSISDIR}\..\Puchisoft\GetIt\GetIt.exe"

  File "${NSISDIR}\..\Puchisoft\GetIt\GetIt_GUI.exe"

  File "readme.txt"

  File "versionHistory.txt"

  File "updatedb.bat"
  File "..\DispatcherProj\Release\Updater*.*"  ;Generated with Puchisoft Dispatcher
  SetOverwrite off

  File "repositories.txt"
  
  CreateDirectory "$SMPROGRAMS\GetIt"
  CreateShortCut "$SMPROGRAMS\GetIt\GetIt GUI.lnk" "$INSTDIR\getit_gui.exe"
  CreateShortCut "$SMPROGRAMS\GetIt\GetIt - Update Repositories.lnk" "$INSTDIR\getit.exe" "update"
  
  ;Associate protocol
  WriteRegStr HKCR "getit" "" "URL:GetIt"
  WriteRegStr HKCR "getit" "URL Protocol" ""
  WriteRegStr HKCR "getit\DefaultIcon" "" "$INSTDIR\ao.ico"
  WriteRegStr HKCR "getit\shell\open\command" "" '$INSTDIR\getit.exe url "%1"'
  
  ;Set up some stuff
  ;ifsilent setupsilently
  hidewindow ; avoid installer being in front of getengines message boxes (especially: Want to Download?)
  execwait '"$INSTDIR\getit.exe" getengines'
  
  ;MessageBox MB_YESNO "Run GetIt GUI now?" /SD IDNO IDNO zend
  ifSilent zend
   exec "$INSTDIR\getit_gui.exe"
  zend:
  SetAutoClose true
SectionEnd

Section -AdditionalIcons
  SetOutPath $INSTDIR
  WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
  CreateShortCut "$SMPROGRAMS\GetIt\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\GetIt\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\getit.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\getit.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd


Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  Delete "$INSTDIR\${PRODUCT_NAME}.url"
  Delete "$INSTDIR\uninst.exe"
  Delete "$INSTDIR\WinGet\winGetRep.bat"
  Delete "$INSTDIR\WinGet\win-get.exe"
  Delete "$INSTDIR\WinGet\wget.exe"
  Delete "$INSTDIR\updatedb.bat"
  Delete "$INSTDIR\readme.txt"
  Delete "$INSTDIR\getit_gui.exe"
  Delete "$INSTDIR\getit.exe"
  Delete "$INSTDIR\getengines.bat"
  Delete "$INSTDIR\Engine\win-get.ini"
  Delete "$INSTDIR\Engine\appsnap.ini"

  Delete "$SMPROGRAMS\GetIt\Uninstall.lnk"
  Delete "$SMPROGRAMS\GetIt\Website.lnk"
  Delete "$SMPROGRAMS\GetIt\GetIt GUI.lnk"

  RMDir "$SMPROGRAMS\GetIt"
  RMDir "$INSTDIR\WinGet"
  RMDir "$INSTDIR\Engine"
  RMDir /r "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd