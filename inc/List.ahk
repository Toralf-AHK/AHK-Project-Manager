LvList(){
  ; DoubleClick: The user has double-clicked within the control. The variable A_EventInfo contains the focused row number. LV_GetNext() can be used to instead get the first selected row number, which is 0 if the user double-clicked on empty space.
  If (A_GuiEvent = "DoubleClick"){
    Gui, ListView, LvList
    If !(Row := LV_GetNext())
		Return	
    LV_GetText(Line, Row , 1)
    LV_GetText(File, Row , 4)
    LV_GetText(Dir, Row , 5) 
    NPPM_SAVEALLFILES()
    NPPM_DOOPEN(Dir "\" File)
    SCI_GotoLine(Line)
	LOS := SCI_LINESONSCREEN()
	SCI_SETFIRSTVISIBLELINE(Line - LOS//2)
	WinActivate, % "ahk_id " NPPM_Hwnd()
  }
}

BtnGetList(){
  GuiControl, , EdtListFilter, % NPPM_GETCURRENTWORD()
  BtnList()
  GuiControl, Choose, Tab, |3
  Gui, Show
}

BtnList(){
  global ChkClasses, ChkMethods, ChkProperties, ChkHotKeys, ChkHotStrings, ChkDllCalls    
       , ChkFunctions, ChkLabels, ChkGlobals, ChkNotes, EdtNotes, EdtListFilter
  
  Gui, ListView, LvList
  LV_Delete()
  MainAHKFile := oData[oProject["MainAHKFileItem"], "Path"] "\" oData[oProject["MainAHKFileItem"], "File"]
  If (MainAHKFile = "\" OR !FileExist(MainAHKFile)){
    LV_Add(,,,"Set a file as Main AHK file")
    LV_ModifyCol()
    TvInc_Fill("")
    BtnSearch()
    Return
  }
  ;get latest data
  Gui, Submit, NoHide
  
  List := {"Classes": ChkClasses, "Method": ChkMethods, "Property": ChkProperties
         , "HotKeys": ChkHotKeys, "HotStrings": ChkHotStrings, "DllCalls": ChkDllCalls    
         , "Functions": ChkFunctions, "Labels": ChkLabels
         , "GlobalVars": ChkGlobals, "Notes": ChkNotes}
  ; ot(List)
  NPPM_SAVEALLFILES()  
  GuiControl, -Redraw, LvList 
  
  MainAHKFile := oData[oProject["MainAHKFileItem"], "Path"] "\" oData[oProject["MainAHKFileItem"], "File"]
  FileStructure := ScanFiles(MainAHKFile, EdtNotes, EdtListFilter, List)
  LV_ModifyCol()
  GuiControl, +Redraw, LvList 
  TvInc_Fill(FileStructure)
}

ListClass(k,l,OutFileName, OutDir, Filter, List){
  LabelInsideFunc:
  If (Filter = "" Or InStr(OutDir, Filter) OR InStr(OutFileName, Filter) OR InStr(l.Name, Filter))
    LV_Add(,k,"C",l.Name,OutFileName, OutDir)
  For i,j in l.Inside {
    ; MsgBox % j.type " = " List[j.Type]
    If (List[j.Type])  
      If (Filter = "" Or InStr(OutDir, Filter) OR InStr(OutFileName, Filter) OR InStr(j.Name, Filter))
        LV_Add(,i,SubStr(j.Type,1,1),j.Name,OutFileName, OutDir)
    If (j.Type = "Class")
      ListClass(i,j,OutFileName, OutDir, Filter, List)
    If (j.Type = "Method" AND List.Labels)
      For m,n in j.Inside
        If (Filter = "" Or InStr(OutDir, Filter) OR InStr(OutFileName, Filter) OR InStr(n, Filter))
          LV_Add(,m,"L",n,OutFileName, OutDir)
  }
}

ScanFiles(File, DocComment, Filter, List){
  ; Local IncludeDir
  ; Static CurrentOutDir

  FileRead, FileContent, %File%
  Result := ParseAHK(FileContent,,DocComment)
  SplitPath, File, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
  CurrentOutDir := OutDir ? OutDir : CurrentOutDir

  For Type, Check in List
    If Check
      For k,l in Result[Type] {
        If (Type = "Classes"){
          ListClass(k,l,OutFileName, CurrentOutDir, Filter, List)
        }
        Else If (Type = "Functions"){
          If (Filter = "" Or InStr(CurrentOutDir, Filter) OR InStr(OutFileName, Filter) OR InStr(l.Name, Filter)) 
           LV_Add(,k,SubStr(Type,1,1),l.Name,OutFileName, CurrentOutDir)
          ; ot(List)
          ; MsgBox % l.NAme " = " List["Labels"] " - " List.Labels
          If (List.Labels){
            For i,j in l.Inside
              If (Filter = "" Or InStr(CurrentOutDir, Filter) OR InStr(OutFileName, Filter) OR InStr(j, Filter)) 
               LV_Add(,i,"L", j,OutFileName, CurrentOutDir)
          }
        }
        Else If (Filter = "" Or InStr(CurrentOutDir, Filter) OR InStr(OutFileName, Filter) OR InStr(l, Filter)) 
          LV_Add(,k,SubStr(Type,1,1),l,OutFileName, CurrentOutDir)
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
        FileStructure.IncludeFiles.Push(ScanFiles(v, DocComment, Filter, List))
      Else If FileExist(IncludeDir "\" v) 
        FileStructure.IncludeFiles.Push(ScanFiles(IncludeDir "\" v, DocComment, Filter, List))
    }
  } 
  Return FileStructure                    
  ; ot(Result)
}

