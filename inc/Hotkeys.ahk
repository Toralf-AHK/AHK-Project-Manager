GetNPPHwnd(){
  old := A_TitleMatchMode 
  SetTitleMatchMode, 2   ;?? RegEx could be used instead to be more robust
  WinGet, Hwnd, ID, % oSetting.Npp_Title
  SetTitleMatchMode, %old%
  Return Hwnd
}
 ; 
/*
from help file on Function Hotkeys:
get path from SciTE and Notepad++:
RegExMatch(path, "\*?\K(.*)\\[^\\]+(?= [-*] )", path)

\*?         zero or one star
\K          the previous matched characters will not be included in the final matched sequence
(.*)        any string sequence (that will be put in path)
\\          a backslash (the last; not included in path)
[^\\]+      not one or more backslash
(?= [-*] )  look-ahead assertion of "space [dash or star] space"

*/

; HotKeyContext(t := "", s := "", hk := ""){  ;the last not given parameter is equal to A_ThisHotkey
HotKeyContext(){  ;the last not given parameter is equal to A_ThisHotkey
  global hGui
  GuiControlGet, SelectedTab, , Tab
  ; ToolTip test h: %A_ThisHotkey% - t: %t% - s: %s% - hk: %hk% - Tab: %SelectedTab%
  If (SelectedTab = "Settings" )
    Return 0
  Else If      (A_ThisHotkey = oSetting.Find_HK)
    Return (WinActive("ahk_id " GetNPPHwnd()) or WinActive("ahk_id " hGui))
  Else If      (A_ThisHotkey = oSetting.List_HK)
    Return (WinActive("ahk_id " GetNPPHwnd()) or WinActive("ahk_id " hGui))
  Else If (A_ThisHotkey = oSetting.Run_HK)
    Return (WinActive("ahk_id " GetNPPHwnd()) or WinActive("ahk_id " hGui))
  Else If (A_ThisHotkey = oSetting.Run_Current_HK)
    Return (WinActive("ahk_id " GetNPPHwnd()) or WinActive("ahk_id " hGui))
  Else If (A_ThisHotkey = oSetting.Compile_HK)
    Return (WinActive("ahk_id " GetNPPHwnd()) or WinActive("ahk_id " hGui))
  Else If (A_ThisHotkey = oSetting.Debug_HK)
    Return (WinActive("ahk_id " GetNPPHwnd()) or WinActive("ahk_id " hGui))
  Else If (A_ThisHotkey = oSetting.Align_Code_HK)
    Return (WinActive("ahk_id " GetNPPHwnd()) or WinActive("ahk_id " hGui))
  Else If (A_ThisHotkey = oSetting.Kill_HK)
    Return True
  Return False  
}

SetHotkeys(){
  ; Context := Func("HotKeyContext").Bind("param1", "param2")  
  Context := Func("HotKeyContext")  
  Hotkey, If, % Context
  Hotkey, % oSetting.Find_HK, BtnGetSearch
  Hotkey, % oSetting.List_HK, BtnGetList
  Hotkey, % oSetting.Run_HK, RunAHK
  Hotkey, % oSetting.Compile_HK, CompileAHK
  Hotkey, % oSetting.Debug_HK, DebugAHK
  Hotkey, % oSetting.Kill_HK, KillAHK
  Hotkey, % oSetting.Run_Current_HK, RunCurrentAHK
  Hotkey, % oSetting.Align_Code_HK, AlignCode
  Hotkey, If
}

GuiControlGetFocus(whichGUI:=1) { ; a function definition with one parameter here, optional since a default value - here 1 - is specified in case it is not passed to the caller upon call
	GuiControlGet, focusedControl, %whichGUI%:FocusV ; see GuiControlGet
return focusedControl ; return the associated variable of the control  which ha has input focus
}

; F7::
  ; KeyHistory
; Return

; https://autohotkey.com/boards/viewtopic.php?p=197540#p197540
; by A_AhkUser
#If (SubStr(GuiControlGetFocus(),1,3) = "Htk")
*space:: ; * - wildcard: the hotkey fires even if extra modifiers are being held down
*Escape::
; *LWin::
; *RWin::
  CatchSpecialHotkeys()
Return
#If

CatchSpecialHotkeys(){
  ; ToolTip %A_ThisHotkey%
  Mods := "" 
  Modifiers := {"Alt": "!", "Ctrl": "^", "Shift": "+", "LWin": "#", "RWin": "#"} 
  For Key, Symbol in Modifiers { 
    If (GetKeyState(Key))
      Mods .= Symbol 
  }
  Sleep, 100    ; the hotkey control will first catch special hotkey no matter here if it does not seem to first recognize them by dispalying them
  KeyWait, Alt  ; alt is a special key and must be first released
  GuiControl,, % GuiControlGetFocus(), % Mods . LTrim(A_ThisHotkey, "*") 
}
