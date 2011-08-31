
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
!define PRODUCT_NAME "GetIt"
!system "MakeDataIncl.exe"
!include "installer_includes.nsh"
!define VERSION_INT 70
Caption "${PRODUCT_NAME} ${PRODUCT_VERSION}"
SubCaption 3 " " ;Gets rid of stupid "Installing..." addon title
SubCaption 4 " " ;Gets rid of stupid "Installing..." addon title
BrandingText "www.puchisoft.com"
OutFile "${NSISDIR}\..\Puchisoft\GetIt\getit.exe"
;AutoCloseWindow True
InstallDir "$EXEDIR"
Icon "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
RequestExecutionLevel admin
!include "WordFunc.nsh" ;aka. String parser ;)
!insertmacro WordFind
!include "FileFunc.nsh" ;only for GetTime
!insertmacro GetTime

!macro CREATESMINSTALLSC PROG_NAME
    ;Create shortcut to Install this .git in Start Menu
    CreateDirectory "$SMPROGRAMS\GetIt\Install Software"
    CreateShortCut "$SMPROGRAMS\GetIt\Install Software\Install ${PROG_NAME}.lnk" "$EXEDIR\Installs\${PROG_NAME}.git"
!macroend

;!include "WinMessages.nsh"
;Page directory
;Page instfiles

var allparams
var preferenceFile
var curEngineName
var curEngineEXEName
var curEngineFile
var curEnginePath
var curDBFile
var curDBFilePath
var curDBLine
var curAppName
var curAppFilePath
;
var repositoriesFile
var curRepositoryURL
var curRepositoryFilePath
var curRepositoryFile
var curVictimRepositoryFile
;
var resultStr

var param_first
Function .onInit
 ;setsilent silent
 SetAutoClose true
 initpluginsdir

 Call GetParameters
 Pop $allparams
 
 ;MessageBox MB_OK "$allparams"
 createdirectory "$EXEDIR\Installs"
 delete "$EXEDIR\Installs\*.exe" ;silly installers sometimes end up in there

 ${WordFind} $allparams " " "+1" $param_first
 StrCmp $param_first "getengines" param_getengines
 StrCmp $param_first "getenginesall" param_getengines ; all
 StrCmp $param_first "help" param_help
 ;database aquisition
 StrCmp $param_first "update" param_updatedb
 StrCmp $param_first "updatedb" param_updatedb
 StrCmp $param_first "upgrade" param_upgrade
 StrCmp $param_first "importDBappupdater" param_importDBappupdater
 StrCmp $param_first "importDBappsnap" param_importDBappsnap
 StrCmp $param_first "importDBwinget" param_importDBwinget
 ;showing
 StrCmp $param_first "show" param_show
 StrCmp $param_first "showfromfile" param_showfromfile
 ;portable
 StrCmp $param_first "makeportable" param_makeportable
 ;installing
 StrCmp $param_first "install" param_install
 StrCmp $param_first "installfromfile" param_installfromfile
 ;url (getit://)
  StrCmp $param_first "url" param_url
 
 ;git was used to directly open a file, no options
 strcpy $1 $param_first 1 ; first char
 StrCmp $1 '"' param_opengitfile ;default to opening the file
 goto nocmdln
 
 param_help:
 execshell "open" "readme.txt"
 goto zend

 nocmdln:
 MessageBox MB_OK "Hello! Looks like you are exploring. Yes, you can call GetIt directly. Look at the ReadMe for some useful parameters.$\n$\n${PRODUCT_NAME} by Puchisoft, Inc. $\nVisit http://www.puchisoft.com"
 goto zend
 
 param_url:
  initpluginsdir
  ${WordFind} $allparams '"' "+2" $curRepositoryURL ;URL
  StrCpy $curRepositoryURL "$curRepositoryURL" "" 8 ;trim off the getit:// beginning
    delete "$pluginsdir\cur.git"
    strcpy $curRepositoryFilePath "$pluginsdir\cur.git"
    inetc::get /CAPTION "Downloading..." /BANNER "Downloading..." "$curRepositoryURL" "$curRepositoryFilePath"
     Pop $R0 ;Get the return value
     StrCmp $R0 "OK" +3
      MessageBox MB_OK "Failed to download: $curRepositoryURL"
      goto zend
  strcpy $allparams '"$curRepositoryFilePath"'
  goto param_opengitfile
 
 param_opengitfile: ;execWAITs on gui, because when downloading via URL, we don't want to delete the GIT until the gui got it
   ;MessageBox MB_OK $allparams
   ${WordFind} $allparams '"' "+1" $curAppFilePath ;App GIT Path
   readinistr $1 $curAppFilePath "GIT" "MinVer"
   IntCmp ${VERSION_INT} $1 +3 0 +3 ;if we are less than the git file, problem
    MessageBox MB_OK "A new version of GetIt is required to understand this git file: $curAppFilePath"
    goto zend
   readinistr $0 $curAppFilePath "GIT" "Type"
    
   strcmp $0 "AppPointer" +3
    execwait '"$exedir\getit_gui.exe" /F"$curAppFilePath"' ;let the gui deal with non-installs
    goto zend
   ;check that git file is in Installs folder in the next group
   ;Windows likes to give us the folder in BS format, so we need to check if both locations are the same
   ;To do this, we are going to modify the file being opened, and read it from where we WISH it were
   ;If the value comes back the same, it must be the same place
    ${WordFind} $curAppFilePath '\' "-1{" $8 ;App GIT Folder
    ${WordFind} $curAppFilePath '\' "-1}" $9 ;App Git FileName
    
    ${GetTime} "" "LS" $0 $1 $2 $3 $4 $5 $6
    strcpy $7 "$0 $1 $2 $3 $4 $5 $6" ;put timeStamp into 7
    writeinistr "$8\$9" "GIT" "LastInstallAttempt" "$7" ;write Stamp into file from parameter
    readinistr $6 "$EXEDIR\Installs\$9" "GIT" "LastInstallAttempt" ;read Stamp back from Proper location (ideally the Same)
    
    strcmp "$6" "$7" +3 ;MessageBox MB_OK 'Error! For security reasons, installations may only be directly triggered via .git files located in: $EXEDIR\Installs\ $\nNot: $8'
     execwait '"$exedir\getit_gui.exe" /F"$curAppFilePath"' ;Don't bore user with security concern. If it might be risky, ASK the user :)
     goto zend
   strcpy $allparams 'installfromfile $allparams' ;turn parameter into expected format
   goto param_installfromfile
 goto zend
 
 param_getengines: ; get them ready
  iffileexists "$exedir\portable" 0 +4
    nxs::Destroy
    messagebox mb_ok "WARNING: Running getengines from a portable GetIt makes it no longer portable. Aborting... If you really want to make this copy of GetIt unportable, please delete the file named 'portable' first."
    goto zend
 
  strcpy $resultStr ""
  nxs::Show /NOUNLOAD `${PRODUCT_NAME}` /top `Setting up your Application Getter engines.$\r$\nPlease wait...` /sub `$\r$\n$\r$\n Preparing...` /h 0 /pos 0 /max 100 /can 0 /end

   clearerrors
   FileOpen $preferenceFile "$EXEDIR\preference.txt" w ;deletes contents and start writing
   iferrors badPreferenceFile

;;AppSnap
   getengines_appsnap_start:
   ;SKIP AppSnap unless StrCmp $param_first "getenginesall" was used
   StrCmp $param_first "getenginesall" 0 getengines_appsnap_done 
   nxs::Update /NOUNLOAD /sub "$\r$\n$\r$\n Looking for App-Snap..." /pos 1 /end
   ;check if AppSnap is installed
   ;LOCAL MACHINE\Software\Mircosoft\Windows\CurrentVersionn\Uninstall\Appsnap\ UninstallString
   ;C:\Program Files\AppSnap\uninst.exe
   ReadRegStr $curEnginePath HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AppSnap" "UninstallString"
    strcmp $curEnginePath "" getengines_NoAppsnap ;if not installed
     ${WordFind} $curEnginePath '\' "-1{" $curEnginePath ; path is now actually the path
     writeinistr "$EXEDIR\Engine\AppSnap.ini" "General" "InstallPath" "$curEnginePath"
     FileWrite $preferenceFile "AppSnap$\r$\n"
     strcpy $resultStr "$resultStrAppSnap$\r$\n" ;result += AppSnap+NewLine
     ;make batch file in AppSnap dir for easying post-app Pausing
     clearerrors
     FileOpen $7 "$curEnginePath\git_appsnap.bat" w ;overwrite, make AppSnap Booter ;cd /d %~dp0
     ;FileWrite $7 '@ECHO OFF$\r$\nECHO Running AppSnap.exe %* ...$\r$\ncd "$curEnginePath"$\r$\nappsnap.exe %*$\r$\nPAUSE'
     FileWrite $7 '@ECHO OFF$\r$\nECHO Running AppSnap.exe %* ...$\r$\ncd /d %~dp0$\r$\nappsnap.exe %*$\r$\nPAUSE'
     FileClose $7
     FileOpen $7 "$curEnginePath\git_appsnap_nopause.bat" w ;overwrite, make AppSnap Booter; used for update
     FileWrite $7 '@ECHO OFF$\r$\nECHO Running AppSnap.exe %* ...$\r$\ncd /d %~dp0$\r$\nappsnap.exe %*$\r$\n'
     FileClose $7
     FileOpen $7 "$curEnginePath\git_appsnap_installChain.bat" w ;overwrite, make AppSnap Booter; used for update
     FileWrite $7 '@ECHO OFF$\r$\nECHO Running AppSnap.exe %* ...$\r$\ncd /d %~dp0$\r$\nappsnap.exe %*$\r$\n  > getit_result.txt'
     FileClose $7
     iferrors badGenericFile
    goto getengines_appsnap_done
   
    getengines_NoAppsnap:
     nxs::destroy
     ;MessageBox MB_OKCANCEL "You don't have AppSnap installed! Until you install it, 3rd party Repositories will not work, and your choice of applications will be limited.$\r$\n$\r$\nDownload and silently install AppSnap now?$\r$\nOtherwise, please re-run 'GetIt getengines' after you install AppSnap." IDCANCEL getengines_appsnap_done
     inetc::get /CAPTION "Downloading AppSnap..." /BANNER "Downloading AppSnap..." /RESUME "Download failed. Try to resume?" "http://puchisoft.com/GetIt/appsnap-latest.exe" "$PLUGINSDIR\appsnap-latest.exe"
     Pop $R0 ;Get the return value
      StrCmp $R0 "OK" +3
       MessageBox MB_RETRYCANCEL "Failed to download ($R0)" IDCANCEL getengines_appsnap_done
       goto getengines_NoAppsnap 
     nxs::Show /NOUNLOAD `${PRODUCT_NAME}` /top `Installing...` /sub `$\r$\n$\r$\n Installing AppSnap...` /h 0 /pos 0 /max 100 /can 0 /end
     ;Execshell "open" "http://appsnap.genotrance.com/#Download"
     execwait '"$PLUGINSDIR\appsnap-latest.exe" /S'
     sleep 500
     KillProcDLL::KillProc "appsnapgui.exe" ;the installer always makes the gui come up, even if silent, let's insta-kill it
     goto getengines_appsnap_start ;check if it worked or not
   
   getengines_appsnap_done: 
                  
;;Appupdater
   getengines_appupdater_start:
   nxs::Update /NOUNLOAD /sub "$\r$\n$\r$\n Looking for Appupdater..." /pos 1 /end
   ;check if Appupdater is installed
   ;C:\Program Files\AppSnap\uninst.exe
   ReadRegStr $curEnginePath HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Appupdater" "InstallLocation"
    strcmp $curEnginePath "" getengines_NoAppupdater ;if not installed
     ${WordFind} $curEnginePath '"' "+1" $curEnginePath ; path is now actually the path
     writeinistr "$EXEDIR\Engine\Appupdater.ini" "General" "InstallPath" "$curEnginePath"
     FileWrite $preferenceFile "Appupdater$\r$\n"
     strcpy $resultStr "$resultStrAppupdater$\r$\n" ;result += Appupdater+NewLine
     ;make batch file in Appupdater dir for easying post-app Pausing
     clearerrors
     FileOpen $7 "$curEnginePath\git_appupdater_update.bat" w ;overwrite, make Appupdater Booter ;cd /d %~dp0
     ;FileWrite $7 '@ECHO OFF$\r$\nECHO Running Appupdater.exe --update -q ...$\r$\ncd "$curEnginePath"$\r$\nappupdater.exe --update -q$\r$\nappupdater.exe --available %% > applist.txt$\r$\n' ;PAUSE
     FileWrite $7 '@ECHO OFF$\r$\nECHO Running Appupdater.exe --update -q ...$\r$\ncd /d %~dp0$\r$\nappupdater.exe --update -q$\r$\nappupdater.exe --available %% > applist.txt$\r$\n' ;PAUSE
     FileClose $7
     FileOpen $8 "$curEnginePath\git_appupdater_install.bat" w ;overwrite, make Appupdater Booter
     FileWrite $8 '@ECHO OFF$\r$\nECHO Running Appupdater.exe --install=%* ...$\r$\ncd /d %~dp0$\r$\nappupdater.exe --install=%*$\r$\nPAUSE'
     FileClose $8
     FileOpen $8 "$curEnginePath\git_appupdater_installChain.bat" w ;overwrite, make Appupdater Booter
     FileWrite $8 '@ECHO OFF$\r$\nECHO Running Appupdater.exe --install=%* ...$\r$\ncd /d %~dp0$\r$\nappupdater.exe --install=%* > getit_result.txt'
     FileClose $8
     FileOpen $9 "$curEnginePath\git_appupdater_upgrade.bat" w ;overwrite, make Appupdater Booter
     FileWrite $9 '@ECHO OFF$\r$\nECHO Running Appupdater.exe --upgrade ...$\r$\ncd /d %~dp0$\r$\nappupdater.exe --update$\r$\nappupdater.exe --upgrade$\r$\nappupdater.exe --upgrade --no-silent$\r$\nPAUSE'
     FileClose $9
     iferrors badGenericFile
    goto getengines_appupdater_done

    getengines_NoAppupdater:
     nxs::destroy
     ;MessageBox MB_OKCANCEL "You don't have Appupdater installed! This severely limits your choice of applications.$\r$\n$\r$\nDownload and silently install Appupdater now?$\r$\nOtherwise, please re-run 'GetIt getengines' after you install Appupdater." IDCANCEL getengines_appupdater_done
     inetc::get /CAPTION "Downloading AppUpdater..." /BANNER "Downloading AppUpdater..." /RESUME "Download failed. Try to resume?" "http://puchisoft.com/GetIt/appupdater-latest.exe" "$PLUGINSDIR\appupdater-latest.exe"
      Pop $R0 ;Get the return value
      StrCmp $R0 "OK" +3
       MessageBox MB_RETRYCANCEL "Failed to download ($R0)" IDCANCEL getengines_appupdater_done
       goto getengines_NoAppupdater   
     nxs::Show /NOUNLOAD `${PRODUCT_NAME}` /top `Installing...` /sub `$\r$\n$\r$\n Installing Appupdater...` /h 0 /pos 0 /max 100 /can 0 /end
     ;Execshell "open" "http://www.nabber.org/projects/appupdater/"
     execwait '"$PLUGINSDIR\appupdater-latest.exe" /S'
     sleep 500
     goto getengines_appupdater_start ;try again, now that is should be installed

    getengines_appupdater_done:
     
   
;;Win-Get   
   ;set up win-get's location
   ;strcmp $9 "0" getengines_wingetFailed ;we know it failed to download
    writeinistr "$EXEDIR\Engine\win-get.ini" "General" "InstallPath" "$EXEDIR\WinGet"
    ;FileWrite $preferenceFile "Win-Get$\r$\n" ;REMOVED WIN-GET as a default app-engine
    ;strcpy $resultStr "$resultStrWin-Get$\r$\n" ;REMOVED WIN-GET as a default app-engine
     clearerrors
     FileOpen $7 "$EXEDIR\WinGet\git_win-get.bat" w ;overwrite, make AppSnap Booter
     FileWrite $7 '@ECHO OFF$\r$\nECHO Running Win-Get.exe %* ...$\r$\ncd "$EXEDIR\WinGet"$\r$\nwin-get.exe %*$\r$\nPAUSE'
     FileClose $7
     iferrors badGenericFile
   FileClose $preferenceFile
   
   ;Look for FARRv2 and set that up
   ReadRegStr $curEnginePath HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Find and Run Robot_is1" "InstallLocation"
    strcmp $curEnginePath "" getengines_NoFARR ;if not installed
    File "/oname=$curEnginePath\AliasGroups\Installed\GetIt.alias" GetIt.alias
    strcpy $resultStr '$resultStr$\r$\nInstalled Alias into Find And Run Robot. You may have to restart FARR before you can use the "install" keyword.$\r$\n'
    goto getengines_alldone
   
   getengines_NoFARR:
    strcpy $resultStr "$resultStr$\r$\nFind And Run Robot wasn't found. Run this again if get it later.$\r$\n"
    goto getengines_alldone
   
   getengines_alldone:
    nxs::destroy
    ;MessageBox MB_OK "GetIt found and will use these engines:$\r$\n$resultStr $\r$\n Feel free to change the order of engines in the preference.txt file. The repositories will now be updated."
  goto param_updatedb ;App-Getting engines just changed, you basically need to update the DB, so let's
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Data Base Aquisition ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 param_updatedb:
;;look for update to GetIt
  InitPluginsDir
  
  execwait '"$EXEDIR\Updater.exe"'  
 
  param_updatedb_go:
;;start updating stuff
  nxs::Show /NOUNLOAD `${PRODUCT_NAME}` /top `Updating repository databases.$\r$\nPlease wait...` /sub `$\r$\n$\r$\n Preparing...` /h 0 /pos 0 /max 50 /can 0 /end
  ;;;;;;;;;;;;;;;
  ;;;;;;;;UpdateDB - Part1 - Update GetIt's repositories (currently just put into AppSnap's userdb.ini)
  ;;;;;;;;;;;;;;;
  initpluginsdir
  delete "$EXEDIR\Installs\*.*"
;  curEnginePath = AppSnap's path
  readinistr $curEnginePath "$EXEDIR\Engine\appsnap.ini" "General" "InstallPath"
      Push $curEnginePath ;"String to do replacement in (haystack)"
      Push "%GetItFolder%" ;"String to replace (needle)"
      Push "$exedir" ;"Replacement"
      Call StrRep
      Pop $curEnginePath ;result
     
  readinistr $0 "$curEnginePath\config.ini" "user" "install_dir" ;just to see if AppSnap is installed THERE ;;!! Questionable method
  strcmp $0 "" param_updatedb_part1_done ;no AppSnap=no need to bother updating OUR repositories
  delete "$curEnginePath\userdb.ini.bup" ;make up to one backup, and clear userdb
  rename "$curEnginePath\userdb.ini" "$curEnginePath\userdb.ini.bup"
  ;delete "$curEnginePath\userdb.ini" ;no need, will be killed via W
  
  FileOpen $curVictimRepositoryFile "$curEnginePath\userdb.ini" w
  
  FileOpen $repositoriesFile "$EXEDIR\repositories.txt" r
  updatedb_rep_nextRep:
   filewrite $curVictimRepositoryFile "$\r$\n" ;some repositories may not end with a new line, so make one
   fileclose $curRepositoryFile
   
   clearerrors
   FileRead $repositoriesFile $0
   strcpy $0 $0 -2 ;trim the newLine from end (yes, this means we need a blank line at the end)
   IfErrors param_updatedb_part1_done ;end of file

   ${WordFind} $0 '"' "+1" $curEngineName
   ${WordFind} $0 '"' "+2" $curRepositoryURL
   ;MessageBox MB_OK 'Rep: $curEngineName _ $curRepositoryURL'
   strcmp $curEngineName "AppSnap" +3 ;only AppSnap is supported right now
    MessageBox MB_OK 'Repository [$0] not of supported type. :('
    goto updatedb_rep_nextRep
    ;ok type
    StrCpy $1 $curRepositoryURL 4
    strcmp $1 "http" updatedb_rep_timeToDownloadRep
    strcmp $1 "ftp:" updatedb_rep_timeToDownloadRep

    strcpy $curRepositoryFilePath $curRepositoryURL ;no need to download if local
    nxs::Update /NOUNLOAD /sub "$\r$\n$\r$\n Injecting Local Repository: $curRepositoryFilePath" /pos 1 /end
    goto updatedb_rep_LocalRepIsReady
   
   updatedb_rep_timeToDownloadRep:
   nxs::Update /NOUNLOAD /sub "$\r$\nDownloading Repository: $curRepositoryURL" /pos 1 /end
    delete "$pluginsdir\curRep.ini"
    strcpy $curRepositoryFilePath "$pluginsdir\curRep.ini"
    inetc::get "$curRepositoryURL" "$curRepositoryFilePath"
     Pop $R0 ;Get the return value
     StrCmp $R0 "OK" +3
      MessageBox MB_OK "Failed to download: $curRepositoryURL"
      goto updatedb_rep_nextRep
    
   
   updatedb_rep_LocalRepIsReady:
    nxs::Update /NOUNLOAD /sub "$\r$\n$\r$\n Injecting Repository..." /pos 1 /end
    clearerrors
    fileopen $curRepositoryFile $curRepositoryFilePath r
    iferrors 0 +3
      MessageBox MB_OK "Can't open file: $curRepositoryFilePath"
      goto updatedb_rep_nextRep

   updatedb_rep_lookForGroup: ;ignore anything that's not a group
    clearerrors
    FileRead $curRepositoryFile $2
    strcpy $2 $2 -2 ;trim the newLine from end (yes, this means we need a blank line at the end)
    strcpy $3 $2 1 ;we are just checking if the first char is something
     iferrors updatedb_rep_nextRep ;eof, means time to look at next Rep
    strcmp $3 "[" 0 updatedb_rep_lookForGroup ;if it's a group, yay, otherwise try again
    
   updatedb_rep_foundAGroup:
    strcpy $2 $2 -1 ;trim ] from group
    ${WordFind} $2 '[' "-1" $curAppName ;get AppName
    ;MessageBox MB_OK 'repFoundApp: =$curAppName='
    ;make sure AppName wasn't injected already (since first rep has priority
    readinistr $4 "$EXEDIR\Installs\$curAppName.git" "$curEngineName" "FromRepository"
    strcmp $4 "" 0 updatedb_rep_lookForGroup ;if not blank, ignore this app...it's already been injected
    writeinistr "$EXEDIR\Installs\$curAppName.git" "$curEngineName" "FromRepository" "$curRepositoryURL"
    
    !insertmacro CREATESMINSTALLSC $curAppName  
    
     ;THIS is where you want to actually copy shit over
     ;copy over the group
      FileWrite $curVictimRepositoryFile "[$curAppName]$\r$\n"
     ;Copy over things under the group
     updatedb_rep_CopyNLookForGroup: ;Copy anything that's not a group
      clearerrors
      FileRead $curRepositoryFile $1
      strcpy $2 $1 -2 ;trim the newLine from end (yes, this means we need a blank line at the end)
      strcpy $3 $2 1 ;we are just checking if the first char is something
       iferrors updatedb_rep_nextRep ;eof, means time to look at next Rep
      strcmp $3 "[" updatedb_rep_foundAGroup ;if it's a group, yay, otherwise: copy
       FileWrite $curVictimRepositoryFile "$1"
       goto updatedb_rep_CopyNLookForGroup
      
      

  
  param_updatedb_part1_done:
  ;MessageBox MB_OK 'Rep: rep man part done'
  FileClose $curVictimRepositoryFile
  FileClose $repositoriesFile
  
  ;;;;;;;;;;;;;;;
  ;;;;;;;;UpdateDB - Part2 - Update other App-Getter's own repositories, index all;;;
  ;;;;;;;;;;;;;;;
  clearerrors
  FileOpen $preferenceFile "$EXEDIR\preference.txt" r
   IfErrors badPreferenceFile
   updatedb_nextEngine: ;preference file is just a list of Engines, so we will read in a line, do stuff, and repeat until at the end of the file
   clearerrors
   FileRead $preferenceFile $curEngineName
   strcpy $curEngineName $curEngineName -2 ;trim the newLine from end (yes, this means we need a blank line at the end)
   ;MessageBox MB_OK 'curEng: $curEngineName'
    IfErrors updatedb_done ;end of file
    strcpy $curEngineFile "$EXEDIR\Engine\$curEngineName.ini"
     ;Do actual stuff for each engine begins here
     readinistr $curEnginePath $curEngineFile "General" "InstallPath"
      Push $curEnginePath ;"String to do replacement in (haystack)"
      Push "%GetItFolder%" ;"String to replace (needle)"
      Push "$exedir" ;"Replacement"
      Call StrRep
      Pop $curEnginePath ;result
     readinistr $3 $curEngineFile "UpdateDB" "Run" ;3 is Run
     readinistr $4 $curEngineFile "UpdateDB" "Param" ;4 is Run
     ;MessageBox MB_OK '"$curEnginePath$3" $4'
     nxs::Update /NOUNLOAD /sub "$\r$\n$\r$\n Updating $curEngineName's Master Repository..." /pos 1 /end
     ExecWait '"$curEnginePath$3" $4' ;run the engine - hopefully it will do the right thing
     
     ;Now the current engine's new DB should be ready - import it
     nxs::Update /NOUNLOAD /sub "$\r$\n$\r$\n Importing $curEngineName's Repository..." /pos 1 /end
     strcmp $curEngineName "Appupdater" updatedb_importAppupdater
     strcmp $curEngineName "AppSnap" updatedb_importAppSnap
     strcmp $curEngineName "Win-Get" updatedb_importWinGet
     goto updatedb_nextEngine
     
     updatedb_importAppupdater:
       ExecWait '"$EXEPATH" importDBappupdater "$curEnginePath\applist.txt"'
       goto updatedb_nextEngine
     
     updatedb_importAppSnap:
       ExecWait '"$EXEPATH" importDBappsnap "$curEnginePath\db.ini"'
       ExecWait '"$EXEPATH" importDBappsnap "$curEnginePath\userdb.ini"' ;This is the addon file. Might not exist, but this is where we will inject PackageManager stuff in the future
       goto updatedb_nextEngine
     
     updatedb_importWinGet:
       ExecWait '"$EXEPATH" importDBwinget "$EXEDIR\WinGet\applist.txt"'
       goto updatedb_nextEngine
     
     ;END OF: Do actual stuff for each engine begins here
    goto updatedb_nextEngine
  updatedb_done:
  FileClose $preferenceFile
  goto zend
  
 param_importDBappsnap:
  ${WordFind} $allparams '"' "+2" $curDBFilePath
  ;MessageBox MB_OK 'appsnap $curDBFile'
  FileOpen $curDBFile "$curDBFilePath" r
  iferrors param_importDBappsnap_done ;who cares...might not even be there: UserDB.ini
   param_importDBappsnap_next: ;new line
    clearerrors
    FileRead $curDBFile $curDBLine
    iferrors param_importDBappsnap_done
     strcpy $4 $curDBLine 1 ;get first character (only iniGroup names are Apps, so starts with "[")
     strcmp $4 "[" 0 param_importDBappsnap_next ;not a group, then: next line
     strcpy $curDBLine $curDBLine "" 1 ;skip first char 
     ${WordFind} $curDBLine ']' "+1" $curDBLine ;extract AppName
     ;MessageBox MB_OK 'appSnap app[$curDBLine]'
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "GIT" "MinVer" "${VERSION_INT}"
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "GIT" "Type" "AppPointer"
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "AppSnap" "Name" "$curDBLine"
     !insertmacro CREATESMINSTALLSC $curDBLine
     
     goto param_importDBappsnap_next
  
  param_importDBappsnap_done:
   FileClose $curDBFile
   goto zend
  
  
 param_importDBwinget:
  ${WordFind} $allparams '"' "+2" $curDBFilePath
  ;MessageBox MB_OK 'winget $curDBFile'
  FileOpen $curDBFile "$curDBFilePath" r
  iferrors param_importDBwinget_done ;who cares...might not even be there: UserDB.ini
   FileRead $curDBFile $0 ;first 5 files are useless
   FileRead $curDBFile $0
   FileRead $curDBFile $0
   FileRead $curDBFile $0
   FileRead $curDBFile $0
   param_importDBwinget_next: ;new line
    clearerrors
    FileRead $curDBFile $curDBLine
    iferrors param_importDBwinget_done
     ${WordFind} $curDBLine ' ' "+1" $curDBLine ;get the first thing before all the space bull
     ;MessageBox MB_OK 'winget app[$curDBLine]'
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "GIT" "MinVer" "${VERSION_INT}"
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "GIT" "Type" "AppPointer"
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "Win-Get" "Name" "$curDBLine"
     !insertmacro CREATESMINSTALLSC $curDBLine
     goto param_importDBwinget_next

  param_importDBwinget_done:
   FileClose $curDBFile
   goto zend
   
 param_importDBappupdater:
  ${WordFind} $allparams '"' "+2" $curDBFilePath
  ;MessageBox MB_OK 'winget $curDBFile'
  FileOpen $curDBFile "$curDBFilePath" r
  iferrors param_importDBappupdater_done ;who cares...might not even be there: UserDB.ini
   FileRead $curDBFile $0 ;first 3 lines are useless
   FileRead $curDBFile $0
   FileRead $curDBFile $0
   param_importDBappupdater_next: ;new line
    clearerrors
    FileRead $curDBFile $curDBLine
    iferrors param_importDBappupdater_done
     ${WordFind} $curDBLine '  ' "+1" $curDBLine ;get the first thing before all the space bull
     strcpy $1 $curDBLine 1 ;first char, if *, --no-silent param must be used
     strcpy $curDBLine $curDBLine 9999 1 ;trim the initial bs char, either space or *
     ;MessageBox MB_OK 'winget app[$curDBLine]'
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "GIT" "MinVer" "${VERSION_INT}"
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "GIT" "Type" "AppPointer"
     writeinistr "$EXEDIR\Installs\$curDBLine.git" "Appupdater" "Name" "$curDBLine"
     strcmp $1 "*" 0 +2
            writeinistr "$EXEDIR\Installs\$curDBLine.git" "Appupdater" "ExtraParam" "--no-silent"
     !insertmacro CREATESMINSTALLSC $curDBLine
     goto param_importDBappupdater_next

  param_importDBappupdater_done:
   FileClose $curDBFile
   goto zend
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; App Show ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  param_show:
   ${WordFind} $allparams " " "+2" $curAppName ;AppName
   Exec '"$EXEDIR\getit_gui.exe" /F"$EXEDIR\Installs\$curAppName.git"'
   goto zend

  param_showfromfile:
   ${WordFind} $allparams '"' "+2" $curAppFilePath ;AppPath
   Exec '"$EXEDIR\getit_gui.exe" /F"$curAppFilePath"'
   goto zend
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Make GetIt Portable ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  param_makeportable:
  ${WordFind} $allparams " " "+1}" $0
  messagebox mb_ok "hi $0"
  nxs::Show /NOUNLOAD `${PRODUCT_NAME}` /top `Making GetIt Portable ...` /sub `$\r$\n$\r$\n To: $0...` /h 0 /pos 0 /max 50 /can 0 /end

  copyfiles "$exedir\*" "$0\"
  fileopen $1 "$0\portable" w ;write down the fact that this is portable (used by getEngines param to warn user that he is about to make GetIt Unportable)
  fileclose $1
  FileOpen $preferenceFile "$EXEDIR\preference.txt" r
   IfErrors badPreferenceFile
   makeportable_nextEngine:
    clearerrors
    FileRead $preferenceFile $curEngineName
    strcpy $curEngineName $curEngineName -2 ;trim the newLine from end
     iferrors param_makeportable_done
    strcpy $curEngineFile "$EXEDIR\Engine\$curEngineName.ini"
    readinistr $curEnginePath $curEngineFile "General" "InstallPath"
           Push $curEnginePath ;"String to do replacement in (haystack)"
           Push "%GetItFolder%" ;"String to replace (needle)"
           Push "$exedir" ;"Replacement"
           Call StrRep
           Pop $curEnginePath ;result
    copyfiles "$curEnginePath\*" "$0\Engine\$curEngineName\"
    writeinistr "$0\Engine\$curEngineName.ini" "General" "InstallPath" "%GetItFolder%\Engine\$curEngineName"
    goto makeportable_nextEngine
    
  param_makeportable_done:
    nxs::Destroy
    messagebox mb_ok "GetIt has been made portable to $0. All currently set up engines have been included at $0\Engine\."
    goto zend
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; App Installation ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  param_install:
   ${WordFind} $allparams " " "+1}" $curAppName ;AppName
   ;Exec '"$EXEPATH" installfromfile "$EXEDIR\Installs\$curAppName.git"' ;Why restart the exe, when you don't have to, and when doing so would break chaining support? :P
   strcpy $allparams 'installfromfile "$EXEDIR\Installs\$curAppName.git"'
   goto param_installfromfile
  
  
  param_installfromfile:
   ${WordFind} $allparams '"' "+2" $curAppFilePath ;App GIT Path
   ;loop through Preference.txt ...pick first we like and exists
   nxs::Show /NOUNLOAD `${PRODUCT_NAME}` /top `Waiting to Install application from $curAppFilePath ...` /sub `$\r$\n$\r$\n Preparing...` /h 0 /pos 0 /max 50 /can 0 /end   
   FileOpen $preferenceFile "$EXEDIR\preference.txt" r
    IfErrors badPreferenceFile
    installfromfile_nextEngine: ;preference file is just a list of Engines, so we will read in a line, do stuff, and repeat until at the end of the file
    clearerrors
    FileRead $preferenceFile $curEngineName
    strcpy $curEngineName $curEngineName -2 ;trim the newLine from end (yes, this means we need a blank line at the end)
    IfErrors installfromfile_noGood ;end of file
     ;MessageBox MB_OK 'curEng: $curEngineName'
      ;Do some stuff with the current engine
      readinistr $curAppName $curAppFilePath "$curEngineName" "Name" ;retrieve Engine's AppName - if this engine has install info, it won't be blank
      readinistr $5 $curAppFilePath "$curEngineName" "ExtraParam" ;created for appupdater, sometimes needs extra param --no-silent to install apps properly
      strcmp $curAppName "" installfromfile_nextEngine ; if it's bank, try the next engine
      ;all is good, 
      ;...time to install
      strcpy $curEngineFile "$EXEDIR\Engine\$curEngineName.ini"
      readinistr $curEnginePath $curEngineFile "General" "InstallPath"
           Push $curEnginePath ;"String to do replacement in (haystack)"
           Push "%GetItFolder%" ;"String to replace (needle)"
           Push "$exedir" ;"Replacement"
           Call StrRep
           Pop $curEnginePath ;result
      readinistr $curEngineEXEName $curEngineFile "General" "EXEName" ;Don't run this directly! we need to fix the path with .bats; This is just used to wait to close GetIt until that other prog is gone      
      readinistr $3             $curEngineFile "Install" "Run" ;3 is Run
      readinistr $4             $curEngineFile "Install" "Param" ;4 is Param, with "$AppName" needs to be replaced
      strcpy $4 "$4 $5" ;full parameters

      Push $3 ;"String to do replacement in (haystack)"
      Push "%GetItFolder%" ;"String to replace (needle)"
      Push "$exedir" ;"Replacement"
      Call StrRep
      Pop $3 ;result

      Push $4 ;"String to do replacement in (haystack)"
      Push "%AppName%" ;"String to replace (needle)"
      Push "$curAppName" ;"Replacement"
      Call StrRep
      Pop $4 ;result

      ;MessageBox MB_OK 'install: "$curEnginePath$3" $4'   
      call WaitForCurEnglineToNotBeRunning ; make sure this engine isn't already running
      nxs::Update /NOUNLOAD /top "Installing application from $curAppFilePath ..." /sub "$\r$\n Launching $curEngineEXEName..." /pos 1 /end   
      Exec '"$curEnginePath$3" $4'
      sleep 3000
      call WaitForCurEnglineToNotBeRunning ; wait until it's done running before closing getit.exe (this way getit.exe can be chained / runWaited on)
       goto installfromfile_done
       
   installfromfile_noGood:
     nxs::Destroy
     MessageBox MB_OK 'None of your preferred Application Getters support this application: $curAppFilePath'
   
   installfromfile_done:
    FileClose $preferenceFile
    goto zend


;;;;;;;;;;;;
;;;;;Upgrade
param_upgrade: ;;Known bug: currently only upgrades using the first supported app-getter

  nxs::Show /NOUNLOAD `${PRODUCT_NAME}` /top `Upgrading applications $\r$\nPlease wait...` /sub `$\r$\n$\r$\n Preparing...` /h 0 /pos 0 /max 50 /can 0 /end
   FileOpen $preferenceFile "$EXEDIR\preference.txt" r
    IfErrors badPreferenceFile
    upgrade_nextEngine: ;preference file is just a list of Engines, so we will read in a line, do stuff, and repeat until at the end of the file
    clearerrors
    FileRead $preferenceFile $curEngineName
    strcpy $curEngineName $curEngineName -2 ;trim the newLine from end (yes, this means we need a blank line at the end)
    IfErrors upgrade_noGood ;end of file
     ;MessageBox MB_OK 'curEng: $curEngineName'
      strcpy $curEngineFile "$EXEDIR\Engine\$curEngineName.ini"
      readinistr $curEnginePath $curEngineFile "General" "InstallPath"
      readinistr $3             $curEngineFile "Upgrade" "Run" ;3 is Run
      readinistr $4             $curEngineFile "Upgrade" "Param" ;4 is Param, with "$AppName" needs to be replaced
      
      strcmp $3 "" upgrade_nextEngine ; if it's bank, try the next engine
      ;all is good,
      ;...time to upgrade
      ;MessageBox MB_OK 'install: "$curEnginePath$3" $4'
      nxs::Destroy ;no need to waste TaskBar space
      Execwait '"$curEnginePath$3" $4' ;MUST WAIT - otherwise getit won't close properly
       goto upgrade_done

   upgrade_noGood:
     nxs::Destroy
     MessageBox MB_OK 'None of your preferred Application Getters support upgrading your applications. Try installing Appupdater.'

   upgrade_done:
    FileClose $preferenceFile
    goto zend

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Error Messages ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 badGenericFile:
  MessageBox MB_OK "Can't seem to write to a Program Files related file. :("
  goto zend

 badPreferenceFile:
  ;MessageBox MB_OK "Can't seem to read the Preference.txt file. :("
  goto zend

 zend:
 ;MessageBox MB_OK 'Z End!'
 nxs::Destroy ;Don't do this and getit.exe will never close!
 Quit
FunctionEnd

Section
  MessageBox MB_OK "If you're seeing this, the developered messed up. Feel free to yell at him."
SectionEnd


Function WaitForCurEnglineToNotBeRunning
nxs::Update /NOUNLOAD /sub "$\r$\n Waiting for $curEngineEXEName to close..." /pos 1 /end 
 keepWaiting:
   FindProcDLL::FindProc "$curEngineEXEName"   
   strcmp $R0 "1" 0 stopWaiting ;if running     
     sleep 500
     goto keepWaiting
 stopWaiting:  
FunctionEnd

; GetParameters
 ; input, none
 ; output, top of stack (replaces, with e.g. whatever)
 ; modifies no other variables.

 Function GetParameters

   Push $R0
   Push $R1
   Push $R2
   Push $R3

   StrCpy $R2 1
   StrLen $R3 $CMDLINE

   ;Check for quote or space
   StrCpy $R0 $CMDLINE $R2
   StrCmp $R0 '"' 0 +3
     StrCpy $R1 '"'
     Goto loop
   StrCpy $R1 " "

   loop:
     IntOp $R2 $R2 + 1
     StrCpy $R0 $CMDLINE 1 $R2
     StrCmp $R0 $R1 get
     StrCmp $R2 $R3 get
     Goto loop

   get:
     IntOp $R2 $R2 + 1
     StrCpy $R0 $CMDLINE 1 $R2
     StrCmp $R0 " " get
     StrCpy $R0 $CMDLINE "" $R2

   Pop $R3
   Pop $R2
   Pop $R1
   Exch $R0

 FunctionEnd
 
 Function StrRep
  Exch $R4 ; $R4 = Replacement String
  Exch
  Exch $R3 ; $R3 = String to replace (needle)
  Exch 2
  Exch $R1 ; $R1 = String to do replacement in (haystack)
  Push $R2 ; Replaced haystack
  Push $R5 ; Len (needle)
  Push $R6 ; len (haystack)
  Push $R7 ; Scratch reg
  StrCpy $R2 ""
  StrLen $R5 $R3
  StrLen $R6 $R1
loop:
  StrCpy $R7 $R1 $R5
  StrCmp $R7 $R3 found
  StrCpy $R7 $R1 1 ; - optimization can be removed if U know len needle=1
  StrCpy $R2 "$R2$R7"
  StrCpy $R1 $R1 $R6 1
  StrCmp $R1 "" done loop
found:
  StrCpy $R2 "$R2$R4"
  StrCpy $R1 $R1 $R6 $R5
  StrCmp $R1 "" done loop
done:
  StrCpy $R3 $R2
  Pop $R7
  Pop $R6
  Pop $R5
  Pop $R2
  Pop $R1
  Pop $R4
  Exch $R3
FunctionEnd
