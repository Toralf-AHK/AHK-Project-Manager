;AHK Project Manager
  Name = AHK Project Manager
  Version = 0.2

  #NoEnv
  SetBatchLines -1
  SetWorkingDir %A_ScriptDir%
  FileEncoding, UTF-8
  
  global oProject, oData, oSetting, oStdOut, debug := false
  
  Settings("Read")
  BuildGui()
  SetHotkeys()
  DefaultStartUp()
  ReadTools()
Return

DefaultStartUp(){
  If debug
    ReadProjectFile("C:\........ahkp")
  ;when previously projects had been used
  Else If oSetting["RecentProjects"].Count() {
    ;check if the project file exists
    For k, File in oSetting["RecentProjects"]
      If FileExist(File){
        ;and open the first one that is found. Should usually be the last one that was open
        ReadProjectFile(File)
        Break
      }
  }
  oStdOut := new StdOutStream("StdOut_Handler")
  BtnList()
}

ReadTools(){
  Gui, ListView, LvTools
  Loop, Files, %A_ScriptDir%\Tools\*, F
    LV_Add(,A_LoopFileName)
}

GuiClose(Reload := False){
  SaveProjectFile()
  Settings("Write")
  If (Reload = True)
    Reload
  Else
    ExitApp
}

; ##::
; ToolTip test
; Return

;Read and Write Settings of the AHK Project Manager
Settings(Mode){
  Static FilePath := SubStr(A_ScriptFullPath,1,-4) ".config"
  global hGui
  
  If (Mode = "Read"){
    ;predefine Settings
    oSetting := {	 "AHK_Exec":     "C:\LokaleDaten\Apps\AutoHotkey\AutoHotkey.exe"
                 , "AHK2EXE_Exec": "C:\LokaleDaten\Apps\AutoHotkey\Compiler\Ahk2Exe.exe"
                 , "Npp_Exec":     "C:\LokaleDaten\Apps\Notepad++\notepad++.exe"
                 , "Npp_Title":    " - Notepad++"
                 , "Git_Exec":     "C:\LokaleDaten\Apps\SmartGit\bin\smartgit.exe"
                 , "Git_Title":    " - SmartGit 18.2.4"
                 , "Find_HK":         "F2"  
                 , "List_HK":        "+F2"  

                 , "Run_HK":          "F9"  
                 , "Compile_HK":     "^F9"  
                 , "Debug_HK":       "+F9"  
                 , "Kill_HK":        "+ESC" 
                 , "Run_Current_HK": "+F9"  
                 , "Align_Code_HK":  "!q"  

                 ; , "Tools_HK":    "#{#}" ;#T shows Toolbar by default  ; ## would be possible; does the Hotkey handling in Gui work?
                 , "ShowToolTips": 1 
                 , "Icons":{"Folder":{"Exists":    {"File":"C:\Windows\System32\shell32.dll","Icon":4} 
                                     ,"NoExist":   {"File":"C:\Windows\System32\shell32.dll","Icon":67} }
                           ,"File":{"Main": {"Exists":   {"File":"C:\LokaleDaten\Apps\AutoHotkey\AutoHotkey.exe","Icon":1}
                                            ,"NoExist": {"File":"C:\Windows\System32\shell32.dll","Icon":78}}
                                   ,"AHK":  {"Exists":  {"File":"C:\LokaleDaten\Apps\AutoHotkey\AutoHotkey.exe","Icon":2}
                                            ,"NoExist": {"File":"C:\Windows\System32\shell32.dll","Icon":78}}
                                   ,"BIN":  {"Exists":  {"File":"C:\Windows\System32\shell32.dll","Icon":73}
                                            ,"NoExist": {"File":"C:\Windows\System32\shell32.dll","Icon":78}}
                                   ,"Rest": {"Exists":      {"File":"C:\Windows\System32\shell32.dll","Icon":71} 
                                            ,"NoExist":     {"File":"C:\Windows\System32\shell32.dll","Icon":78} } }}}
    ;read Settings from file and override the predefined
    FileRead, FileContent, %FilePath% 
    For k,v in JSON.Load(FileContent)
      oSetting[k] := v
    TrackRecentProjects("")
  }Else If (Mode = "Write"){
    FileDelete, %FilePath%
    WinGetPos, X, Y, Width, Height, ahk_id %hGui%
    oSetting["Last_Gui_Position"] := [X,Y,Width,Height]
    FileAppend, % JSON.Dump(oSetting), %FilePath%
  }
}

#Include inc
#Include GUI.ahk
#Include Project.ahk
#Include Hotkeys.ahk
#Include Files.ahk
#Include Search.ahk
#Include List.ahk
#Include GuiControlTips.ahk
#Include Edit.ahk

#Include ParseAHK_V2.ahk
#Include StdOutStream.ahk
#Include isBinFile.ahk
#Include NPPM.ahk
#Include TVX.ahk
#Include JSON.ahk  ;from C:\LokaleDaten\Privat\Code\PMI Analysis\src
#Include AutoXYWH.ahk  ;from C:\LokaleDaten\Privat\Code\Toleranz Vergleichsblatt\Skripte
#Include ObjTree.ahk   ;from C:\LokaleDaten\Privat\Code\Toleranz Vergleichsblatt\Skripte
#Include Attach.ahk    ;from C:\LokaleDaten\Privat\Code\Toleranz Vergleichsblatt\Skripte

/* Notes
- find similarities in search and list code
- show hotkeys in menus
- Hotkey to show tools tab
- extend EdtStdOut() to go to specific column if error/specific explains where the problem is.

- create ONE file from main file (including the #includes)

- ReplaceVars() only replaces vars known to compiler. Maybe change this to search actively for vars in the string and replace all 
Percent signs which are not part of a valid variable reference are interpreted literally. All built-in variables are valid, except for ErrorLevel, A_Args and the numbered variables. Prior to [v1.1.28], only %A_ScriptDir%, %A_AppData%, %A_AppDataCommon% and [in v1.1.11+] %A_LineFile% were supported.
Known limitation: When compiling a script, variables are evaluated by the compiler and may differ from what the script would return when it is finally executed. Ahk2Exe v1.1.30.00 and earlier only support the four variables listed above. [v1.1.30.01+]: The following variables are also supported: A_AhkPath, A_AhkVersion, A_ComputerName, A_ComSpec, A_Desktop, A_DesktopCommon, A_IsCompiled, A_IsUnicode, A_MyDocuments, A_ProgramFiles, A_Programs, A_ProgramsCommon, A_PtrSize, A_ScriptFullPath, A_ScriptName, A_Space, A_StartMenu, A_StartMenuCommon, A_Startup, A_StartupCommon, A_Tab, A_Temp, A_UserName, A_WinDir.


- find lib files/functions
%A_ScriptDir%\Lib\  ; Local library - requires [v1.0.90+].
%A_MyDocuments%\AutoHotkey\Lib\  ; User library.
directory-of-the-currently-running-AutoHotkey.exe\Lib\  ; Standard library.

- external references? AutoXYWH, XL, XLC, ObjectTree, ZIPFile, ParseAHK, ...

- "Update" a folder content (incl sub folder)
-- keep main file 
-- via context menu
-- auto-update at interval or with OnMessage
-- via context menu (checkbox)

AutoErweiterung für bisher nicht verwendete Befehle inkl. Parameter paste/vorschlag
Hotkey um var in %% einzuklammern
Hotstrings für code blöcke
Hotkey für Tidy code
Hotkeys für Run/compile/debug(mit start von DBGp)

use StrQ()

- Icons for settings/options/buttons/Menu
- Watch hard drive folder and add files automatically 
- roll up effect (hotkey to show?)
- Store all files relatively to project file (ease to move project around)
- delete non existing Files from recent project list?
- Settings
		○ Behavior 
			§ Roll up
		○ AHK executable 
			§ Choose AHK Version (ANSI, U32, U64, V2)
- revamp TVX to allow MOVE
- Menu Items:	
  - Change path (move/copy)
  	○ Clone Project (needs to adjust relative paths)
		○ Change file/path (needs to adjust relative paths)
- Start other scripts/tools
		○ autocomplete scripts
		○ Snippet lib
		○ Context help
		○ Autotidy
- Search for files
		○ Edit box above the TV
		○ Button to remove content (x)
		○ Button next 
		○ Button previous
- Search in files
		○ Radio/ddl for search options
			§ In current/main/includes/library/project/open files
- be able to start AHK Project Manager with specific project by double click on ahkp file
- be able to update #include tree on demand
*/


; F7::  ;Tests for NPPM
  ; MsgBox %    "path= " NPPM_GETFULLCURRENTPATH()
          ; . "`ndir= " NPPM_GETCURRENTDIRECTORY()
          ; . "`nSCINTILLA= " NPPM_GETCURRENTSCINTILLA()
          ; . "`nsave= " NPPM_SAVECURRENTFILE()
          ; . "`nview= " NPPM_GETCURRENTVIEW()
          ; . "`nword= " NPPM_GETCURRENTWORD()
          ; . "`nline= " NPPM_GETCURRENTLINE()
          ; . "`ncolumn= " NPPM_GETCURRENTCOLUMN()
; Return

