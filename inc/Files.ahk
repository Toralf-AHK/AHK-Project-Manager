SetAsMainAHKfile(){
  Gui, TreeView, TvPrj
  If !(SelectedItem := TV_GetSelection())
    Return
  If (oData[SelectedItem, "Type"] = "Folder")
    Return
  If (oData[SelectedItem, "Extension"] <> "ahk")
    Return
  oProject["MainAHKFileItem"] := SelectedItem
  RemoveAllBoldFomTV()
  TV_Modify(SelectedItem, "Bold")
  AdjustIconTvPrj(SelectedItem)
  SaveProjectFile()
  BtnList()
  Gui, ListView, LvSearch
  LV_Delete()
}
RemoveAllBoldFomTV(){
  Item = 0
  Gui, TreeView, TvPrj
  GuiControl, -Redraw, TvPrj 
  While (Item := TV_GetNext(Item, "Full"))
    If TV_Get(Item, "Bold"){
      TV_Modify(Item, "-Bold")
      AdjustIconTvPrj(Item)
    }
  GuiControl, +Redraw, TvPrj 
}

AdjustIconTvPrj(Hwnd){
  FilePath := oData[Hwnd, "Path"] "\" oData[Hwnd, "File"]
  Status := FilePath = "\" ? "NoExist" : (FileExist( FilePath ) ? "Exists" : "NoExist")
  If (oData[Hwnd, "Type"] = "Folder"){
    Gui, TreeView, TvPrj
    TV_Modify(Hwnd, "Icon" oSetting.Icons.Folder[Status].ID)
    Return
  }
  Type := "Rest"
  If isBinFile(FilePath)
    Type := "BIN"
  Else If (oProject["MainAHKFileItem"] = Hwnd)
    Type := "Main"
  Else If (oData[Hwnd, "Extension"] = "ahk")
    Type := "AHK"
  Gui, TreeView, TvPrj
  TV_Modify(Hwnd, "Icon" oSetting.Icons.File[Type, Status].ID)
}

AddFilesToProject(){
  Gui, TreeView, TvPrj
  SelectedItem := TV_GetSelection()    ;after FileSelectFile somehow the first item gets selected, thus get selection now.
  FileSelectFile, FileNames, M1, %A_WorkingDir%
      , Select files that shoud be added:
      ; , All Files (*.*)
  If (ErrorLevel OR FileNames = "")
    return
  Loop, parse, FileNames, `n
    If (A_Index = 1)
      Path := A_LoopField
    Else
      FileNames_temp .= Path "\" A_LoopField "`n"
  AddFilesToTV(SelectedItem, FileNames_temp)
}
AddFilesToTV(SelectedItem, FileNames){
  Gui, TreeView, TvPrj
  Parent := (oData[SelectedItem, "Type"] = "Folder") ? SelectedItem : TV_GetParent(SelectedItem)
  GuiControl, -Redraw, TvPrj 
  Loop, Parse, FileNames, `n
  {
    If !A_LoopField
      Continue
    If (Instr(FileExist(A_LoopField),"D"))
      AddFoldertoTV(Parent, A_LoopField)
    Else
      AddItemToTV(Parent, A_LoopField)
  }
  GuiControl, +Redraw, TvPrj 
  SaveProjectFile()
}
AddFilesOfAFolderToProject(){
  MouseGetPos, MouseX, MouseY
  oSetting["MenuCoord"] := "X" MouseX " Y" MouseY
  Gui, TreeView, TvPrj
  SelectedItem := TV_GetSelection()
  FileSelectFolder, FolderName, *%A_WorkingDir%, % 1+2+4
                  , Select a folder to add it and it's files to the project.
  If (ErrorLevel OR FolderName = "")
    return
  Parent := (oData[SelectedItem, "Type"] = "Folder") ? SelectedItem : TV_GetParent(SelectedItem)
  GuiControl, -Redraw, TvPrj 
  AddFoldertoTV(Parent, FolderName)
  GuiControl, +Redraw, TvPrj 
  SaveProjectFile()
}

AddFoldertoTV(Parent, FolderName){
  ListHwnd := {}
  ; SplitPath, FolderName, OutFileName, OutDir, OutExtension
  ListHwnd[FolderName] := AddItemToTV(Parent, FolderName)
  
  MenuCoord := oSetting.MenuCoord
  Progress, B2 M C00 h80 %MenuCoord% Hide, , Adding files of a folder to the project 
  Loop, Files, %FolderName%\* , DR
  {
    If (Mod(A_Index, 100) = 0){
      Progress, Show
      Status := Mod(A_Index/10, 100)
      Progress, %Status%, processing %A_Index%th folder
    }
    SplitPath, A_LoopFileLongPath, OutFileName, OutDir, OutExtension
    ListHwnd[A_LoopFileLongPath] := AddItemToTV(ListHwnd[OutDir], A_LoopFileLongPath)
  }

  Progress, B2 M C00 h80 %MenuCoord% Hide, , Adding files of a folder to the project 
  Loop, Files, %FolderName%\* , FR
  {
    If (Mod(A_Index, 100) = 0){
      Progress, Show
      Status := Mod(A_Index/10, 100)
      Progress, %Status%, adding %A_Index%th file
    }
    SplitPath, A_LoopFileLongPath, OutFileName, OutDir, OutExtension
    AddItemToTV(ListHwnd[OutDir], A_LoopFileLongPath)
  }
  Progress, Off
}

Remove(){
  Gui, TreeView, TvPrj
  If !(SelectedItem := TV_GetSelection())
    Return
  TV_GetText(TextS, SelectedItem)
  IsFolder := (oData[SelectedItem, "Type"] = "Folder") ? "and all its files" : ""
  MsgBox,% 4+32+256+4096,,Are you sure to delete "%TextS%" %IsFolder% from the project treeview ? The file(s) and folders will still exist on harddrive.
  IfMsgBox Yes
  {
    TVX_Walk("Remove_WalkHandlerFunc", SelectedItem, OnlySubItemsOfFirstItem := True)
    Gui, TreeView, TvPrj
    TV_Delete(SelectedItem)
    SaveProjectFile()
  }
}
Remove_WalkHandlerFunc(oTV){
  If (oTV.hwnd = oProject["MainAHKFileItem"]){
    oProject["MainAHKFileItem"] := ""
    BtnList()
  }
  oData.Delete(oTV.hwnd)
}

CreateFolder(){
  Gui, TreeView, TvPrj
  SelectedItem := TV_GetSelection()
  Parent := (oData[SelectedItem, "Type"] = "Folder") ? SelectedItem : TV_GetParent(SelectedItem)
  Hwnd := TV_Add("Folder", Parent, "Sort Select")
  oData[Hwnd, "Type"] := "Folder" 
  AdjustIconTvPrj(Hwnd)
  Send, {F2}
}

AddItemToTV(Parent, Path){
  Gui, TreeView, TvPrj
  SplitPath, Path, OutFileName, OutDir, OutExtension
  Hwnd := TV_Add(OutFileName, Parent, "Sort Vis Expand")
  If (Instr(FileExist(Path),"D"))
    oData[Hwnd, "Type"] := "Folder" 
  Else {
    oData[Hwnd, "Type"] := "File"
    oData[Hwnd, "Extension"] := OutExtension
  }
  oData[Hwnd, "File"] := OutFileName 
  oData[Hwnd, "Path"] := OutDir
  AdjustIconTvPrj(Hwnd)
  Return Hwnd
}

OpenInEditor(){
  Gui, TreeView, TvPrj
  If !(SelectedItem := TV_GetSelection())
    Return
  If (oData[SelectedItem, "Type"] = "Folder")
    Return
  Else
    FilePath := oData[SelectedItem, "Path"] "\" oData[SelectedItem, "File"]
  OpenFile(FilePath)
}

OpenFile(FilePath){
  If (FilePath = "\")
    Return
  If !FileExist(FilePath)
    Return
  If isBinFile(FilePath)
    Run, %FilePath%
  Else If !(Nppm_PID()){
    Npp_Exec := oSetting.Npp_Exec
    Run, "%Npp_Exec%" "%FilePath%"
  }Else
    NPPM_DOOPEN(FilePath)
  WinActivate, % "ahk_id " Nppm_HWND()
}

Open_NPP(){
  If (HWND := Nppm_HWND())
    WinActivate, ahk_id %HWND%
  Else {
    Npp_Exec := oSetting.Npp_Exec
    Run, "%Npp_Exec%" 
  }
}

Open_Git(){
  old_TitleMatchMode := A_TitleMatchMode 
  SetTitleMatchMode, 2
  If (HWND := WinExist(oSetting.Git_Title))
    WinActivate, ahk_id %HWND%
  Else {
    Git_Exec := oSetting.Git_Exec
    Run, "%Git_Exec%" 
  }
  SetTitleMatchMode, %old_TitleMatchMode%
} 

HandleFilepath(ItemName, ItemPos, MenuName){
  Gui, TreeView, TvPrj
  If !(SelectedItem := TV_GetSelection())
    Return
  FilePath := oData[SelectedItem, "Path"] "\" oData[SelectedItem, "File"]
  If !FileExist(FilePath)
    ToolTip Path does not exist:`n%FilePath%
  Else If Instr(ItemName, "Copy")
    Clipboard :=  FilePath
  Else If Instr(ItemName, "Insert")
    ToolTip Not yet implemented
}

OpenHere(ItemName, ItemPos, MenuName){
  Gui, TreeView, TvPrj
  If !(SelectedItem := TV_GetSelection())
    Return
  If (oData[SelectedItem, "Type"] = "Folder")
    FilePath := oData[SelectedItem, "Path"] "\" oData[SelectedItem, "File"]
  Else
    FilePath := oData[SelectedItem, "Path"]  
  If !FileExist(FilePath)
    ToolTip Path does not exist:`n%FilePath%
  Else If Instr(ItemName, "Explorer")
    Run, explorer "%FilePath%"   
  Else If Instr(ItemName, "console")
    Run, cmd , %FilePath%
}

AddCurrentFileInEditorToProject(){
  Gui, TreeView, TvPrj
  SelectedItem := TV_GetSelection()
  Parent := (oData[SelectedItem, "Type"] = "Folder") ? SelectedItem : TV_GetParent(SelectedItem)
  If !(FilePath := NPPM_GETFULLCURRENTPATH())
    Return
  hwnd := AddItemToTV(Parent, FilePath)
  TV_Modify(hwnd, "Select")
  SaveProjectFile()
}
CompileAHK(){
  If oStdOut.Exists(){
    MsgBox A Script is currently running. You can't compile right now.
    Return
  }
  GuiControl,,EdtStdOut
  MainAHKFile := oData[oProject["MainAHKFileItem"], "Path"] "\" oData[oProject["MainAHKFileItem"], "File"]
  If (MainAHKFile = "\" or !FileExist(MainAHKFile)){
    StdOut_Handler("No Mainfile set or doesn't exist, nothing to compile`r`n")
    Return
  }
  SplitPath, MainAHKFile, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
  StartTime := A_TickCount
  StdOut_Handler("Compiling:" OutFileName "`r`n")
  
  NPPM_SAVEALLFILES()
  MainExeFile = %OutDir%\%OutNameNoExt%.exe
  AHK2EXE := oSetting["AHK2EXE_Exec"]
  Target = "%AHK2EXE%" /in "%MainAHKFile%" /out "%MainExeFile%"
  RunWait, %Target% , %OutDir% ;, Max|Min|Hide|UseErrorLevel, OutputVarPID
  ;??? Potentially switch RunWait to oStdOut, but then it has to wait to finish. Hence a new or changed method() for oStdOut
  
  SplitPath, MainExeFile, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
  StdOut_Handler("Compiled:" OutFileName "`r`nin " A_TickCount - StartTime " ms`r`n")
}
DebugAHK(){
  WinMenuSelectItem, % "ahk_id " GetNPPHwnd(), , Plugins, DBGp, Debugger
  If (ErrorLevel){
    MsgBox Debugger not available`n(Menu: Plugins->DBGp->Debugger)
    Return
  }
  RunAHK("Debug")
}
RunAHK(Mode = "Run"){
  If oStdOut.Exists(){
    MsgBox A Script is currently running. You can't start another one.
    Return
  }
  GuiControl,,EdtStdOut
  MainAHKPath := oData[oProject["MainAHKFileItem"], "Path"] "\" 
  MainAHKFile := MainAHKPath oData[oProject["MainAHKFileItem"], "File"]
  If (MainAHKFile = "\" or !FileExist(MainAHKFile)){
    StdOut_Handler("No Mainfile set or doesn't exist, nothing to run`r`n")
    Return
  }
  NPPM_SAVEALLFILES()

  Arguments = /ErrorStdOut
  If (Mode = "Debug")
    Arguments .= " /Debug"
  
  AHK_Exec := oSetting["AHK_Exec"]
  
  cmd = %AHK_Exec% %Arguments% "%MainAHKFile%"
  oStdOut.Run( cmd , MainAHKPath)
}
RunCurrentAHK(){
  If oStdOut.Exists(){
    MsgBox A Script is currently running. You can't start another one.
    Return
  }
  NPPM_SAVECURRENTFILE()
  GuiControl,,EdtStdOut
  Arguments = /ErrorStdOut
  CurrentPath := NPPM_GETCURRENTDIRECTORY() "\" 
  CurrentFileName := NPPM_GETFILENAME()

  AHK_Exec := oSetting["AHK_Exec"]
  
  cmd = %AHK_Exec% %Arguments% "%CurrentPath%%CurrentFileName%"
  oStdOut.Run( cmd , CurrentPath)
}

KillAHK(){
  If oStdOut.Exists()
    oStdOut.Kill(), StdOut_Handler("Script Terminated by Kill Hotkey`r`n")
}
StdOut_Handler(Line){
  global hEdtStdOut
	SendMessage, 0x000E, 0, 0,, ahk_id %hEdtStdOut% ; WM_GETTEXTLENGTH
	SendMessage, 0x00B1, %ErrorLevel%, %ErrorLevel%,, ahk_id %hEdtStdOut% ; EM_SETSEL
	SendMessage, 0x00C2, 0, &Line,, ahk_id %hEdtStdOut% ; EM_REPLACESEL
}
