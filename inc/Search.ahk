LvSearch(){
  ; DoubleClick: The user has double-clicked within the control. The variable A_EventInfo contains the focused row number. LV_GetNext() can be used to instead get the first selected row number, which is 0 if the user double-clicked on empty space.
  If (A_GuiEvent = "DoubleClick"){
    Gui, ListView, LvSearch
    Row := LV_GetNext()
    If !(Row := LV_GetNext())
		Return	
    LV_GetText(Line, Row , 1)
    LV_GetText(File, Row , 3)
    LV_GetText(Dir, Row , 4) 
    NPPM_SAVEALLFILES()
    NPPM_DOOPEN(Dir "\" File)
    SCI_GotoLine(Line)
	LOS := SCI_LINESONSCREEN()
	SCI_SETFIRSTVISIBLELINE(Line - LOS//2)
    WinActivate, % "ahk_id " NPPM_Hwnd()
  }
}

BtnGetSearch(){
  GuiControl, , EdtSearch, % "i)\Q" NPPM_GETCURRENTWORD() "\E"
  BtnSearch()
  GuiControl, Choose, Tab, |2
  Gui, Show
}

BtnSearch(){
  global EdtSearch

  Gui, ListView, LvSearch
  LV_Delete()
  MainAHKFile := oData[oProject["MainAHKFileItem"], "Path"] "\" oData[oProject["MainAHKFileItem"], "File"]
  If (MainAHKFile = "\" OR !FileExist(MainAHKFile)){
    LV_Add(,,,"Set a file as Main AHK file")
    LV_ModifyCol()
    Return
  }
  ;get latest data
  Gui, Submit, NoHide

  NPPM_SAVEALLFILES()  
  GuiControl, -Redraw, LvSearch 
  
  ; StartTime := A_TickCount
  FileStructure := SearchFiles(MainAHKFile, EdtSearch)
  ; ToolTip % A_TickCount - StartTime
  LV_ModifyCol()
  GuiControl, +Redraw, LvSearch 
  TvInc_Fill(FileStructure)
}

SearchFiles(File, SearchRE){
  ; Static CurrentOutDir
  
  FileRead, FileContent, %File%
  Result := ParseAHK_SearchOnly(FileContent, SearchRE)
  SplitPath, File, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
  
  CurrentOutDir := OutDir ? OutDir : CurrentOutDir
  For k,v in Result.SearchResults {
    LV_Add(,k,v,OutFileName, CurrentOutDir)
  } 
  
  FileStructure := {"File":OutFileName, "Path": CurrentOutDir, "IncludeFiles":[]}
  For k,v in Result.Includes {
    v := ReplaceVars(v, OutFileName, CurrentOutDir)
    If InStr(FileExist(CurrentOutDir "\" v),"D")
      IncludeDir := CurrentOutDir "\" v
    Else If InStr(FileExist(v),"D")
      IncludeDir := v
    Else {
      If FileExist(v) 
        FileStructure.IncludeFiles.Push(SearchFiles(v, SearchRE))
      Else If FileExist(IncludeDir "\" v) 
        FileStructure.IncludeFiles.Push(SearchFiles(IncludeDir "\" v, SearchRE))
    }
  } 
  Return FileStructure
  ; ot(Result)
}

ReplaceVars(v, OutFileName, CurrentOutDir){
  AHKVars := {"%A_AhkPath%":         A_AhkPath
            , "%A_AhkVersion%":      A_AhkVersion
            , "%A_ComputerName%":    A_ComputerName
            , "%A_ComSpec%":         A_ComSpec
            , "%A_Desktop%":         A_Desktop
            , "%A_DesktopCommon%":   A_DesktopCommon
            , "%A_IsCompiled%":      A_IsCompiled
            , "%A_IsUnicode%":       A_IsUnicode
            , "%A_MyDocuments%":     A_MyDocuments
            , "%A_ProgramFiles%":    A_ProgramFiles
            , "%A_Programs%":        A_Programs
            , "%A_ProgramsCommon%":  A_ProgramsCommon
            , "%A_PtrSize%":         A_PtrSize
            , "%A_ScriptFullPath%":    CurrentOutDir "\" OutFileName
            , "%A_LineFile%":          CurrentOutDir "\" OutFileName
            , "%A_ScriptDir%":         CurrentOutDir
            , "%A_ScriptName%":        OutFileName
            , "%A_Space%":           A_Space
            , "%A_StartMenu%":       A_StartMenu
            , "%A_StartMenuCommon%": A_StartMenuCommon
            , "%A_Startup%":         A_Startup
            , "%A_StartupCommon%":   A_StartupCommon
            , "%A_Tab%":             A_Tab
            , "%A_Temp%":            A_Temp
            , "%A_UserName%":        A_UserName
            , "%A_WinDir%":          A_WinDir }

  For var,value in AHKVars
    v := StrReplace(v, var, value) 
  Return v  
}

TvInc_Fill(FileStructure){
  Gui, TreeView, TvInc
  TV_Delete()
  If isObject(FileStructure)
    TvInc_Fill_Recursive(FileStructure, 0)
  If !TV_GetNext() {
    TV_Add("Set a file as Main AHK file", 0, "Expand")
  }
}
TvInc_Fill_Recursive(FileStructure, p){
  p := TV_Add(FileStructure.File "    ->  " FileStructure.Path, p, "Expand")
  For k,InclFile in FileStructure.IncludeFiles
    TvInc_Fill_Recursive(InclFile, p)
}

ParseAHK_SearchOnly(FileContent, SearchRE) {
  static IncludeRE :="
             ( Join LTrim Comment
                    OiS)(*UCP)                 ;case insensitive
                    ^#Include                 ;the text '#Include' at the start of line
                    \s+                       ;at least one whitespace
                    (\*i\s)?                  ;maybe the option "*i" and at least a single whitespace
                    \s*                       ;potentially more whitespaces
                    (?P<File>.*)              ;rest of the line
              )"
  oResult := {"Includes":[],"SearchResults":[]}
  Lines := StrSplit(FileContent, "`n", "`r")
  TotalNumberOfLine := Lines.MaxIndex()
  For PhysicalLineNum, Line In Lines {
    Line := Trim(Line)        ;remove leading/trailing whitespaces
    If RegExMatch(Line, SearchRE)
      oResult.SearchResults[PhysicalLineNum] := Line
    If (InCommentSection){
      If (SubStr(Line, 1, 2) = "*/"){
        InCommentSection := False
        Line := Trim(SubStr(Line, 3))   ;remove the /* from the beginning of the line and continue checking
      }Else
        Continue                        ;discard this line, it is in a Comment Section
    }Else If (SubStr(Line, 1, 2) = "/*") {
      InCommentSection := True
      Continue
    }
    If (!Line := RemoveComments(Line))
      Continue
    If RegExMatch(Line, IncludeRE, Match)
        oResult.Includes[PhysicalLineNum] := Match.File
   }
  Return oResult
}
