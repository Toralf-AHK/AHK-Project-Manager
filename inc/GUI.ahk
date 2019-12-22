BuildGui(){
  global
  local Width, wd, ws, Options, ILID, Check, oldDetectHiddenWindows
  Gui, +Resize +MinSize +HwndhGui +OwnDialogs ;+ToolWindow
  TT := New GuiControlTips(hGui)
  TT.SetDelayTimes(1000, 3000, -1)
  ; Gui, Add, Button, Default vBtnProject, OK
  
  Width = 250
  wd := Width - 63
  Gui, Add, Edit, r1 w%wd% vEdtProject Disabled -WantReturn , Project Name
  Gui, Add, Button, x+0 yp-1 vBtnOpenGit gOpen_Git, Git
  Gui, Add, Button, x+0 vBtnOpenNPP gOpen_NPP, NPP
  
  Gui, Add, Tab2, Section r26 xm w%Width% vTab gTabChange, Files|Search|Lists|Tools|Settings
    Gui, Tab, Files,, Exact  
      wd := Width - 20
      ILID := IL_TvPrj()
      Gui, Add, TreeView, HwndhTvPrj r21 w%wd% vTvPrj gTvPrj ImageList%ILID% AltSubmit, 
      TT.Attach(hTvPrj, "Tree of files and folders that belong to the project`ndoubleclick to open")
      Gui, Add, TreeView, HwndhTvInc r8 w%wd% vTvInc gTvInc AltSubmit, 
      TT.Attach(hTvInc, "Tree of include files that belong to main file`ndoubleclick to open")
    Gui, Tab, Search,, Exact  
      ws := wd/2 - 10
      Gui, Add, Button, xs+10 ys+25 r1 HwndhBtnGetSearch vBtnGetSearch gBtnGetSearch, ->
      Gui, Add, Edit, x+5 yp+2 r1 w%ws% HwndhEdtSearch vEdtSearch, 
      Gui, Add, Button, x+5 yp-2 r1 HwndhBtnSearch vBtnSearch gBtnSearch Default, Go
      Gui, Add, ListView, xs+10 y+5 w%wd% r25 HwndhLvSearch vLvSearch gLvSearch, #|Code|File|Path
      TT.Attach(hBtnGetSearch, "use the current word in editor for search`nor press " oSetting.Find_HK)
      TT.Attach(hEdtSearch, "Specify a regex needle to search for")
      TT.Attach(hBtnSearch, "Search Main file and all included files")
      TT.Attach(hLvSearch, "Search results; doubleclick to jump to them")
    Gui, Tab, Lists,, Exact  
      Gui, Add, Checkbox, xs+10 ys+25 r1 HwndhChkClasses    vChkClasses    gBtnList ,C
      Gui, Add, Checkbox, x+5            HwndhChkMethods    vChkMethods    gBtnList ,M
      Gui, Add, Checkbox, x+5            HwndhChkProperties vChkProperties gBtnList ,P
      Gui, Add, Checkbox, x+5            HwndhChkHotKeys    vChkHotKeys    gBtnList ,Hk
      Gui, Add, Checkbox, x+5            HwndhChkHotStrings vChkHotStrings gBtnList ,Hs
      Gui, Add, Checkbox, x+5            HwndhChkDllCalls   vChkDllCalls   gBtnList ,D
      Gui, Add, Checkbox, xs+10 y+5      HwndhChkFunctions  vChkFunctions  gBtnList Checked,F
      Gui, Add, Checkbox, x+5            HwndhChkLabels     vChkLabels     gBtnList Checked,L
      Gui, Add, Checkbox, x+5            HwndhChkGlobals    vChkGlobals    gBtnList ,G
      Gui, Add, Checkbox, x+5            HwndhChkNotes      vChkNotes      gBtnList ,N:
      TT.Attach(hChkClasses   , "Classes")
      TT.Attach(hChkMethods   , "Methods")
      TT.Attach(hChkProperties, "Properties")
      TT.Attach(hChkHotKeys   , "Hotkeys")
      TT.Attach(hChkHotStrings, "HotStrings")
      TT.Attach(hChkDllCalls  , "DllCalls")
      TT.Attach(hChkFunctions , "Functions")
      TT.Attach(hChkLabels    , "Labels")
      TT.Attach(hChkGlobals   , "Global Variabels")
      TT.Attach(hChkNotes     , "DocComments/Notes")

      Gui, Add, Edit, x+0 yp-4 w40 HwndhEdtNotes vEdtNotes, ???
      Gui, Add, Button, x+5 r1 HwndhBtnList vBtnList gBtnList Default, Ud
      Gui, Add, Text,xs+10 y+5 , Filter: 
      Gui, Add, Edit, x+0 yp-4 w%ws% HwndhEdtListFilter vEdtListFilter gBtnList,
      Gui, Add, ListView, xs+10 y+5 w%wd% r23 HwndhLvList vLvList gLvList, #|-|Code|File|Path
      TT.Attach(hEdtNotes, "String that represents DocComments/Notes")
      TT.Attach(hBtnList, "Search Main file and all included files")
      TT.Attach(hEdtListFilter, "Filter the search results")
      TT.Attach(hLvList, "Search results; doubleclick to jump to them")
    Gui, Tab, Tools,, Exact  
      Gui, Add, ListView, xs+10 ys+27 w%wd% r27 HwndhLvTools vLvTools gLvTools , Place tool or link in subfolder "Tools"
      TT.Attach(hLvTools, "Available Tools; doubleclick to exectute")
    Gui, Tab, Settings,, Exact  
      Gui, Add, Text, xs+10 ys+25 r1, AHK Exe:
      Gui, Add, Edit, xs+10 y+5 w%wd% r2 vEdtAHK_Exec, % oSetting.AHK_Exec
      Gui, Add, Text, xs+10 y+5, AHK Compiler:
      Gui, Add, Edit, xs+10 y+5 w%wd% r2 vEdtAHK2EXE_Exec, % oSetting.AHK2EXE_Exec
      Gui, Add, Text, xs+10 y+5, NPP Exe:
      Gui, Add, Edit, xs+10 y+5 w%wd% r2 vEdtNpp_Exec, % oSetting.Npp_Exec
      
      wd := Width-100
      Gui, Add, Text, xs+10 y+5, NPP Title:%A_Tab%
      Gui, Add, Edit, x+0 yp-4 w%wd% r1 vEdtNPP_Title, % oSetting.Npp_Title

      wd := Width - 20
      Gui, Add, Text, xs+10 y+5, Git Client Exe:
      Gui, Add, Edit, xs+10 y+5 w%wd% r2 vEdtGit_Exec, % oSetting.Git_Exec
      
      wd := Width-100
      Gui, Add, Text, xs+10 y+5, Git Client Title:%A_Tab%
      Gui, Add, Edit, x+0 yp-4 w%wd% r1 vEdtGit_Title, % oSetting.Git_Title
      
      wd := Width-145

      Gui, Add, Text, xs+10 y+5, `n==== Hotkeys ====
            
      Gui, Add, Text, xs+10 y+5, Search Text:%A_Tab%
      Check := WinKey(oSetting.Find_HK).HasKey
      Gui, Add, Checkbox, x+0 yp-0 r1 Checked%Check% HwndhChkFind_HK vChkFind_HK, Win+
      TT.Attach(hChkFind_HK, "Check to add Windows key as modifier")
      Gui, Add, Hotkey, x+0 yp-3 w%wd% r1 vHtkFind_HK, % WinKey(oSetting.Find_HK).CleanHtKy

      Gui, Add, Text, xs+10 y+5, List Items:%A_Tab%
      Check := WinKey(oSetting.List_HK).HasKey
      Gui, Add, Checkbox, x+0 yp-0 r1 Checked%Check% HwndhChkList_HK vChkList_HK, Win+
      TT.Attach(hChkList_HK, "Check to add Windows key as modifier")
      Gui, Add, Hotkey, x+0 yp-3 w%wd% r1 vHtkList_HK, % WinKey(oSetting.List_HK).CleanHtKy

      Gui, Add, Text, xs+10 y+5, Run Main:%A_Tab%
      Check := WinKey(oSetting.Run_HK).HasKey
      Gui, Add, Checkbox, x+0 yp-0 r1 Checked%Check% HwndhChkRun_HK vChkRun_HK, Win+
      TT.Attach(hChkRun_HK, "Check to add Windows key as modifier")
      Gui, Add, Hotkey, x+0 yp-3 w%wd% r1 vHtkRun_HK, % WinKey(oSetting.Run_HK).CleanHtKy

      Gui, Add, Text, xs+10 y+5, Debug Main:%A_Tab%
      Check := WinKey(oSetting.Debug_HK).HasKey
      Gui, Add, Checkbox, x+0 yp-0 r1 Checked%Check% HwndhChkDebug_HK vChkDebug_HK, Win+
      TT.Attach(hChkDebug_HK, "Check to add Windows key as modifier")
      Gui, Add, Hotkey, x+0 yp-3 w%wd% r1 vHtkDebug_HK, % WinKey(oSetting.Debug_HK).CleanHtKy

      Gui, Add, Text, xs+10 y+5, Compile Main:%A_Tab%
      Check := WinKey(oSetting.Compile_HK).HasKey
      Gui, Add, Checkbox, x+0 yp-0 r1 Checked%Check% HwndhChkCompile_HK vChkCompile_HK, Win+
      TT.Attach(hChkCompile_HK, "Check to add Windows key as modifier")
      Gui, Add, Hotkey, x+0 yp-3 w%wd% r1 vHtkCompile_HK, % WinKey(oSetting.Compile_HK).CleanHtKy

      Gui, Add, Text, xs+10 y+5, Kill Main:%A_Tab%
      Check := WinKey(oSetting.Kill_HK).HasKey
      Gui, Add, Checkbox, x+0 yp-0 r1 Checked%Check% HwndhChkKill_HK vChkKill_HK, Win+
      TT.Attach(hChkKill_HK, "Check to add Windows key as modifier")
      Gui, Add, Hotkey, x+0 yp-3 w%wd% r1 vHtkKill_HK, % WinKey(oSetting.Kill_HK).CleanHtKy
      
      Gui, Add, Text, xs+10 y+5, Run Current:%A_Tab%
      Check := WinKey(oSetting.Run_Current_HK).HasKey
      Gui, Add, Checkbox, x+0 yp-0 r1 Checked%Check% HwndhChkRun_Current_HK vChkRun_Current_HK, Win+
      TT.Attach(hChkRun_Current_HK, "Check to add Windows key as modifier")
      Gui, Add, Hotkey, x+0 yp-3 w%wd% r1 vHtkRun_Current_HK, % WinKey(oSetting.Run_Current_HK).CleanHtKy
      
      Gui, Add, Text, xs+10 y+5, Align Code:%A_Tab%
      Check := WinKey(oSetting.Align_Code_HK).HasKey
      Gui, Add, Checkbox, x+0 yp-0 r1 Checked%Check% HwndhChkAlign_Code_HK vChkAlign_Code_HK, Win+
      TT.Attach(hChkAlign_Code_HK, "Check to add Windows key as modifier")
      Gui, Add, Hotkey, x+0 yp-3 w%wd% r1 vHtkAlign_Code_HK, % WinKey(oSetting.Align_Code_HK).CleanHtKy

      If !(Check := oSetting.ShowToolTips)
        TT.Suspend(True)
      Gui, Add, Checkbox, xs+10 y+5 r1 Checked%Check% vChkShowToolTips, Show ToolTips

      Gui, Add, Button, xs+10 y+5 r1 vBtnSave gBtnSave Default, Save && &Reload
  Gui, Tab
  
  Gui, Add, Edit, HwndhEdtStdOut r6 xm ym+562 w%Width% vEdtStdOut gEdtStdOut,
  TT.Attach(hEdtStdOut, "Shows StdOut and StdErr when mainfile gets run, debug or compiled")
  
  Gui, Show, Hide, %Name% - %Version%            ;first Show: Create Gui and activate GuiSize with AutoXYWH
  oldDetectHiddenWindows := A_DetectHiddenWindows                   ;position and size hidden window
  DetectHiddenWindows, On
  
  Position := EnsureGuiIsOnScreen(oSetting.Last_Gui_Position)
  WinMove, ahk_id %hGui%, , Position.1 , Position.2 
                          , Position.3 , Position.4
  DetectHiddenWindows, %oldDetectHiddenWindows%
  Gui, Show                                      ;second Show: show Gui in previous position and size
}

EnsureGuiIsOnScreen(previousPosition){
  X := previousPosition.1
  Y := previousPosition.2
  W := previousPosition.3
  H := previousPosition.4
  
  ;how many monitors exist
  SysGet, MonitorCount, MonitorCount
  MinimalMovement := 10000000000000
  ;for each monitor
  Loop, %MonitorCount%                                          
  {
      ;get its workarea
      SysGet, MonitorWorkArea, MonitorWorkArea, %A_Index%       
      
      ;shortcut, if Gui fits nicely on one of the monitors, just return the previous Position
      If ((X > MonitorWorkAreaLeft) AND (X+W < MonitorWorkAreaRight) AND (Y > MonitorWorkAreaTop) AND (Y+H < MonitorWorkAreaBottom))
          Return [X,Y,W,H]

      ;calculate new position and size
      ;adjust gui width if it is larger then screen width
      newW := (W > MonitorWorkAreaRight - MonitorWorkAreaLeft) ? MonitorWorkAreaRight - MonitorWorkAreaLeft : W
      ;move gui left when part of gui is off screen on the right
      newX := (X+W > MonitorWorkAreaRight) ? MonitorWorkAreaRight - W : X
      ;move gui right when part of gui is off screen on the left
      newX := (newX < MonitorWorkAreaLeft) ? MonitorWorkAreaLeft : newX

      ;adjust gui height if it is larger then screen hight
      newH := (H > MonitorWorkAreaBottom - MonitorWorkAreaTop) ? MonitorWorkAreaBottom - MonitorWorkAreaTop : H
      ;move gui up when part of gui is off screen on the bottom
      newY := (Y+H > MonitorWorkAreaBottom) ? MonitorWorkAreaBottom - H : Y
      ;move gui down when part of gui is off screen at the top
      newY := (newY < MonitorWorkAreaTop) ? MonitorWorkAreaTop : newY

      ;calculate "Movement vector length"
      Movement := (newX-X)**2 + (newY-Y)**2 + (newW-W)**2 + (newH-H)**2
      
      ;store new position when movement is minimal
      If (Movement < MinimalMovement){
        newPosition := [newX, newY, newW, newH]
        MinimalMovement := Movement
      }
  }
  Return newPosition
}

WinKey(HtKy){
  ;when # is last char in HtKy it is the key "#"; not the modifier "Win"
  ;thus if HtKy is "##" it is "Win + #" 
  If (HasKey := InStr(HtKy,"#", , -1) ? 1 : 0)
    HtKy := StrReplace(HtKy, "#", , Count, 1)
  Return Result := {"HasKey":HasKey, "CleanHtKy": HtKy}
}

; f7::
; EdtStdOutErr()
; Return

EdtStdOut(){
  GuiControlGet, Output, ,EdtStdOut
  Needle = Om)(?P<File>.*?) \((?P<Line>\d+?)\) : ==>  
  Loop, Parse, Output, `n
    If RegExMatch(A_LoopField,Needle,Match){
        NPPM_DOOPEN(Match.File)
        SCI_GotoLine(Match.Line)
		LOS := SCI_LINESONSCREEN()
		SCI_SETFIRSTVISIBLELINE(Match.Line - LOS//2)
        WinActivate, % "ahk_id " NPPM_Hwnd()
        Break
    }
}


LvTools(){
  If (A_GuiEvent = "DoubleClick" And A_EventInfo){
    LV_GetText(Tool, A_EventInfo)
    Run, "%A_ScriptDir%\Tools\%Tool%"
  }
}

BtnSave(){
  global EdtAHK_Exec ,EdtAHK2EXE_Exec ,EdtNpp_Exec ,EdtNpp_Title ,EdtGit_Exec ,EdtGit_Title
       , HtkFind_HK ,HtkList_HK ,HtkRun_HK ,HtkDebug_HK ,HtkKill_HK ,HtkCompile_HK, HtkRun_Current_HK, HtkAlign_Code_HK
       , ChkFind_HK ,ChkList_HK ,ChkRun_HK ,ChkDebug_HK ,ChkKill_HK ,ChkCompile_HK, ChkRun_Current_HK, ChkAlign_Code_HK
       , ChkShowToolTips
  Fields := ["EdtAHK_Exec" ,"EdtAHK2EXE_Exec" ,"EdtNpp_Exec" ,"EdtNpp_Title" ,"EdtGit_Exec" ,"EdtGit_Title"
       , "HtkFind_HK", "HtkList_HK" ,"HtkRun_HK" ,"HtkDebug_HK" ,"HtkKill_HK" ,"HtkCompile_HK", "HtkRun_Current_HK", "HtkAlign_Code_HK", "ChkShowToolTips"]
  Gui, Submit, NoHide
  For k,v in Fields{
    ChkName := "Chk" SubStr(v,4)
    WinModifier := %ChkName% ? "#" : ""
    oSetting[SubStr(v,4)]:= WinModifier %v%
    ; MsgBox % v "`n" ChkName "`n" %ChkName% "`n" WinModifier "`n" %v% "`n" oSetting[SubStr(v,4)]
  }
  GuiClose(Reload := True)
}

TabChange(){
  GuiControlGet, CurrentTab , , Tab
  If (CurrentTab = "Files"){
    ;nothing to do
  } Else If (CurrentTab = "Search"){
    GuiControl, +Default, BtnSearch
  } Else If (CurrentTab = "Lists"){
    GuiControl, +Default, BtnList
  } Else If (CurrentTab = "Tools"){
    ;nothing to do
  } Else If (CurrentTab = "Settings"){
    GuiControl, +Default, BtnSave
  } 
}

IL_TvPrj(){
  ILID := IL_Create(10)  
  For Status,Data in oSetting.Icons.Folder
    Data["ID"] := IL_Add(ILID, Data.File, Data.Icon)
  For FileType,StatusData in oSetting.Icons.File
    For Status,Data in StatusData
      Data["ID"] := IL_Add(ILID, Data.File, Data.Icon)
  Return ILID
}

GuiSize(){
  AutoXYWH("x", "BtnSearch", "BtnOpenGit", "BtnOpenNPP")
  AutoXYWH("w", "EdtProject", "EdtSearch", "EdtAHK_Exec" ,"EdtAHK2EXE_Exec" ,"EdtNpp_Exec" ,"EdtNpp_Title"
              , "HtkFind_HK" ,"HtkList_HK" ,"HtkRun_HK" ,"HtkDebug_HK" ,"HtkKill_HK" ,"HtkCompile_HK", "HtkRun_Current_HK", "HtkAlign_Code_HK")
  AutoXYWH("wh", "Tab", "LVSearch", "LvList", "LvTools")
  AutoXYWH("wh0.5", "TvPrj")
  AutoXYWH("y0.5wh0.5", "TvInc")
  AutoXYWH("wy", "EdtStdOut")
}

TvPrj(){
  ; ToolTip %A_GuiEvent%`n%A_EventInfo%
  If (A_GuiEvent = "Normal" And A_EventInfo = 0)
    TV_Modify(0 , "Select")
  Else If (A_GuiEvent = "DoubleClick" And A_EventInfo)
    OpenInEditor()
	Else If (A_GuiEvent = "K" And A_EventInfo = 46)
    Remove()
	; Else If (A_GuiEvent = "K")
		; ToolTip %A_EventInfo%
}

TvInc(){
  ; ToolTip %A_GuiEvent%`n%A_EventInfo%
  If (A_GuiEvent = "Normal" And A_EventInfo = 0)
    TV_Modify(0 , "Select")
  Else If (A_GuiEvent = "DoubleClick" And A_EventInfo){
    TV_GetText(Text, A_EventInfo)
    Array := StrSplit(Text, "->")
    OpenFile(Trim(Array.2) "\" Trim(Array.1))
  }
}

GuiDropFiles(){
  If (A_EventInfo < 1)
    Return
  Gui, TreeView, TvPrj
  SelectedItem := TV_GetSelection()
  AddFilesToTV(SelectedItem, A_GuiEvent)
}

GuiContextMenu(GuiHwnd, CtrlHwnd, EventInfo, IsRightClick, X, Y){
  Global hTvPrj
  ; Global hGui, hTvPrj
  RenameProject(True)
  ;If no project open or not in treeview show project menu
  If (CtrlHwnd <> hTvPrj OR !isObject(oProject)){ 
    ShowProjektMenu(X, Y)
    Return
  }
  ;otherwise select and show file menu
  Gui, TreeView, TvPrj
  TV_Modify(EventInfo, "Select")
  ShowFileMenu(X, Y)
}

ShowProjektMenu(X, Y){
  local MenuItems := [ [0, "New project"                      , "MenuHandler", 0]
                     ; , [1, "Clone project"                    , "MenuHandler", 1]
                     , [1, "Rename project"                   , "MenuHandler", 1]
                     ; , [1, "Change file/path"                 , "MenuHandler", 1]
                     , [0, "Open project"                     , "MenuHandler", 0]
                     , [0, "Recent projects"                  , "MenuHandler", 0]
                     , [0]
                     , [1, "Close project"                    , "MenuHandler", 1]
                     , [1, "Close & Delete whole project file", "CloseDeleteWholeProjectFile", 1]
                     , [0, "Exit"                             , "GuiClose"    , 0]]
  ShowMenu(X,Y,"ProjectMenu",MenuItems)
}

ShowFileMenu(X, Y){
  local MenuItems := [ [0, "Open`tDoubleClick"                    , "MenuHandler", 0] ; ??? grey out when no file selected
                     , [0, "Add current file in editor to project", "MenuHandler", 0]
                     , [0, "Add files to project ..."             , "AddFilesToProject", 0]
                     , [0, "Add files of a folder to project ..." , "AddFilesOfAFolderToProject", 0]
                     , [0, "Create folder"                        , "MenuHandler", 0]
                     , [0, "Rename`tF2"                           , "MenuHandler", 0]  ;grey out when no selection
                     ; , [0, "Modify file path"                     , "MenuHandler", 0]
                     ; , [0]
                     , [0, "Remove`tDelete"                       , "MenuHandler", 0, "+BarBreak"]  ;??? gey out when no selection
                     , [0, "Set as Main AHK file"                 , "MenuHandler", 0]  ;??? grey out when not ahk file?
                     , [0, "Run Main file`t" oSetting.Run_HK      , "RunAHK", 0] 
                     , [0, "Debug Main file`t" oSetting.Debug_HK  , "MenuHandler", 0]
                     , [0, "Compile Main file`t" oSetting.Compile_HK , "MenuHandler", 0]
                     ; , [0, "Move up`t(shift up)"                   , "MenuHandler", 0]
                     ; , [0, "Move down`t(shift down)"               , "MenuHandler", 0]
                     , [0, "Open explorer here"                   , "OpenHere", 0]   ;??? grey out when nothing selected
                     , [0, "Open console here"                    , "OpenHere", 0]   ;??? grey out when nothing selected
                     , [0, "Copy file with path"                  , "HandleFilepath", 0]
                     , [0, "Insert file at current caret location", "HandleFilepath", 0]]
  ShowMenu(X,Y,"FileMenu",MenuItems)
}

ShowMenu(X,Y,Menu,MenuItems){
  static Init := {}
  
  ;when menu is called the first time, initialize it
  If !(Init.HasKey(Menu)){
    For k,v in MenuItems 
      Menu, %Menu%, Add, % v.2 , % v.3, % v.5
    Init[Menu] := True
  }
  
  ;check if a project is open and de-/activate menu items
  ProjIsOpen := (isObject(oProject) ? "Enable" : "Disable")
  For k,v in MenuItems 
     If v.1
        Menu, %Menu%, %ProjIsOpen%, % v.2
        
  ;for project menu update the recent project list
  If (Menu = "ProjectMenu")
    CreateRecentProjectMenu()
  
  Menu %Menu%, Show, %X%, %Y%
}

CreateRecentProjectMenu(){
  ;clear previous menu
  ;add a dummy item, so that deleteall always has an item to delete
  Menu, RecentProject, Add, OpenRecentProject  
  Menu, RecentProject, DeleteAll
  
  ;add recent projects if the files are available
  For i,ProjectFile in oSetting.RecentProjects {
    If !FileExist(ProjectFile)
      Continue
    SplitPath, ProjectFile, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive 
    Menu, RecentProject, Add, %i%) %OutFileName%%A_Tab%%OutDir%, OpenRecentProject
  }
  Menu, ProjectMenu, Add, Recent projects, :RecentProject
}
OpenRecentProject(ItemName, ItemPos, MenuName){
  ReadProjectFile(oSetting.RecentProjects[ItemPos])
}

;User has selected a menu
;Calls the Menu (without spaces and (text)) as function
;or tells if the function is not implemented yet.
;??? could be replaced with direct function names, as Menu supports it.
MenuHandler(ItemName, ItemPos, MenuName){
  FuncName := ItemName
  If (Pos := InStr(FuncName,A_Tab))
    FuncName := SubStr(FuncName, 1, Pos - 1)
  FuncName := RegExReplace(FuncName," ")
  If IsFunc(FuncName)
    %FuncName%()
  Else
    ToolTip, Not implemented yet: %FuncName%
}
