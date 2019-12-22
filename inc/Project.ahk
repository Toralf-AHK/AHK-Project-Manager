;when closing a project, save it and clean up 
CloseProject(){
  SaveProjectFile()
  oProject := ""  
  oData := ""
  Gui, TreeView, TvPrj
  TV_Delete()
  Gui, TreeView, TvInc
  TV_Delete()
  GuiControl,,EdtProject, 
  BtnList()
}

CloseDeleteWholeProjectFile(){
  FilePath := oProject["Path"] . "\" oProject["File"]
  CloseProject()
  FileDelete, %FilePath%
}

SaveProjectFile(){
  global EdtProject
  
  ;only when a project is open
  If !isObject(oProject)
    Return
  
  ;get latest data
  Gui, Submit, NoHide
  
  ;always write project file new
  FilePath := oProject["Path"] . "\" oProject["File"]
  FileDelete, %FilePath%
  
  ;remove items from oProject that should not be saved
  tmpProject := {}
  OmitKeys := {"Path":1, "File":1, "MainAHKFileItem":1}
  For k,v in oProject {
    If OmitKeys[k]
      Continue
    tmpProject[k] := v
  }
  
  ;add project name and write project data to file
  tmpProject["ProjectName"] := EdtProject
  FileAppend, % JSON.Dump(tmpProject) "`n", %FilePath%
  
  ;add information from TvPrj to file
  SaveProjectFile_Handler(FilePath)
  Gui, TreeView, TvPrj
  TVX_Walk("SaveProjectFile_Handler")
}
;handler gets called from TVX_Walk for each item in TvPrj
SaveProjectFile_Handler(oTV){
  static FilePath   
  If isObject(oTV){  ;got called from TVX_Walk 
    
    ;remove unwanted items from array
    tmpTV := {}
    For k,v in oTV {
      If (k = "hwnd")
        Continue
      tmpTV[k] := v
    }
    
    ;combine information of item from TvPrj and its information from oData
    Data := {TV:tmpTV , Data:oData[oTV.hwnd]}
    
    ;write it as a individual line to file
    FileAppend, % JSON.Dump(Data) "`n", %FilePath%
  }Else              ;got called with oTV just being a FileName
    FilePath := oTV  ;remember the FileName for later calls form TVX_Walk
}

OpenProject(){
  FileSelectFile, FileName, % 2 + 8 , %A_WorkingDir%
      , Select a AHK project file to open:
      , AHK Projects (*.ahkp)
  If ErrorLevel
    Return
  If FileExist(FileName)
    ReadProjectFile(FileName)
  Else
    CreateNewProjekt(FileName)
  BtnList()
}

NewProject(){
  FileSelectFile, FileName, % "S" 2 + 16, %A_WorkingDir%
      , Specify a file that the project should be saved in:
      , AHK Projects (*.ahkp)
  If ErrorLevel
    Return
  CreateNewProjekt(FileName) 
}  

CreateNewProjekt(FileName){
  SplitPath, FileName, OutFileName, OutDir, OutExtension, OutNameNoExt

  ;User forgot to add an extension, use .ahkp as a default
  If !(OutExtension){
    FileName .= ".ahkp"
    OutFileName .= ".ahkp"
    
    ;check if this project file already exists
    If FileExist(FileName)
    MsgBox,% 4+32+256+4096,,File exists. Overwrite?
    IfMsgBox No
      Return
  }
  
  ;close/save previous open project and start fresh
  CloseProject()
  oProject := {}
  oData := {}
  TrackRecentProjects(FileName)
  oProject["File"] := OutFileName
  oProject["Path"] := OutDir
  GuiControl,,EdtProject, %OutNameNoExt%
  If FileExist(FileName)  ;??? potentionally not needed, since SaveProjectFile() removes file anyway
    FileDelete, %FileName%
  SaveProjectFile()
}

ReadProjectFile(FileName){
  CloseProject()
  oProject := {}
  oData := {}
  ParentForLevel := []
  TrackRecentProjects(FileName)
  SplitPath, FileName, OutFileName, OutDir, OutExtension, OutNameNoExt
  FileRead, FileContent, %FileName%   ;instead of "Loop,Read", since "Loop,Read" can only read lines up to 65,534 characters long
  ; ID = 0
  GuiControl, -Redraw, TvPrj 
  Loop, Parse, FileContent, `n, `r 
  {
    If !A_LoopField 
      Break
    If (A_Index = 1){
      oProject := JSON.Load(A_LoopField)
      oProject["File"] := OutFileName
      oProject["Path"] := OutDir
      GuiControl,,EdtProject, % oProject["ProjectName"]
    }Else{
      Data := JSON.Load(A_LoopField) 
      oTV := Data.TV
      Options := "Expand" oTV.expand " Check" oTV.check (oTV.bold ? " Bold" : "")
      Gui, TreeView, TvPrj
      hwnd := TV_Add(oTV.text, ParentForLevel[oTV.indentLvl], Options)
      If (oTV.type = "Parent")
        ParentForLevel[oTV.indentLvl + 1] := hwnd
      If (oTV.bold)
        oProject["MainAHKFileItem"] := hwnd
      oData[hwnd] := Data.Data
      AdjustIconTvPrj(Hwnd)
    }
  }
  GuiControl, +Redraw, TvPrj 

  BtnList()
}

TrackRecentProjects(FilePath){
  If !isObject(oSetting.RecentProjects)
    oSetting["RecentProjects"] := []
  If (FileExist(FilePath) AND FilePath)
    oSetting.RecentProjects.InsertAt(1, FilePath)

  ;delete non existing projects from list
  ListOfID := []
  For i,ProjectFile in oSetting.RecentProjects
    If !FileExist(ProjectFile)
      ListOfID.push(i)
  While (i := ListOfID.pop())
    oSetting.RecentProjects.RemoveAt(i)
  
  oSetting["RecentProjects"] := RemoveDuplicatesFromArray(oSetting["RecentProjects"])
  
  If ( (m := oSetting.RecentProjects.MaxIndex()) > 10) 
    oSetting.RecentProjects.RemoveAt(11, m - 10)
}

RemoveDuplicatesFromArray(Array){
  tmpArray := []
  Loop % Array.Length()
  {
    value:=Array.RemoveAt(1) ; otherwise Object.Pop() would work from right to left
    Loop % tmpArray.Length()
      If (value = tmpArray[A_Index])
          Continue 2 ; jump to the top of the outer loop, we found a duplicate, discard it and move on
    tmpArray.Push(value)
  } 
  Return tmpArray
}


;the edit field for project name is disabled.
;to rename it it has to enabled.
;but it is diffcult to identify when user is done. Hidden Default Button on Gui didn't work.
;currently edit state is removed on next gui context menu
RenameProject(Close := 0){
  static State
  ;the edit control is enabled and it should be disabled -> disable it
  If (State AND Close){ 
    GuiControl,Disable,EdtProject
    State := False
    SaveProjectFile()   
  }  
  ;the edit control is disabled and it should be enabled -> enable it
  Else If (!State AND !Close){
    State := True
    GuiControl,Enable,EdtProject   
  }
}


