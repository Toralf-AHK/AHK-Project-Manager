; WinSpy - Window Information Tool

#SingleInstance Off
#NoEnv
#MaxMem 640
#NoTrayIcon
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows On
CoordMode Mouse, Screen
SetControlDelay -1
SetWinDelay -1
SetBatchLines -1
ListLines Off
#KeyHistory 0

Global AppName := "WinSpy"
, Version := "1.0.3"
, IniFile := AppName . ".ini"
, ResDir := A_ScriptDir . "\Resources"

, hFindTool
, Bitmap1 := ResDir . "\FindTool1.bmp"
, Bitmap2 := ResDir . "\FindTool2.bmp"
, hCrossHair := DllCall("LoadImage", "Int", 0
    , "Str", ResDir . "\CrossHair.cur"
    , "Int", 2 ; IMAGE_CURSOR
    , "Int", 32, "Int", 32
    , "UInt", 0x10, "Ptr") ; LR_LOADFROMFILE
, hOldCursor
, Dragging := False

, g_Borders := []
, g_hWnd
, hSpyWnd
, hTab
, hStylesTab
, hWindowsTab
, g_Style
, g_ExStyle
, g_ExtraStyle
, g_WinMsgs := ""
, hCbxMsg
, Cursors := {}
, oStyles := {}
, Workaround := True
, FindDlgExist := False
, MenuViewerExist := False
, hTreeWnd := 0
, TreeIcons := ResDir . "\TreeIcons.icl"
, ImageList
, g_TreeShowAll := False
, g_Minimized
, g_MouseCoordMode := "Screen"

, g_DetectHidden
, g_Minimize
, g_AlwaysOnTop

IniRead g_DetectHidden, %IniFile%, Settings, DetectHidden, 0
IniRead g_Minimize, %IniFile%, Settings, CompactMode, 0
IniRead g_AlwaysOnTop, %IniFile%, Settings, AlwaysOnTop, 0

IniRead g_ShowBorder, %IniFile%, Screenshot, ShowBorder, 1
IniRead g_BorderColor, %IniFile%, Screenshot, BorderColor, 0xFF0000
g_BorderColorTemp := g_BorderColor
IniRead g_BorderWidth, %IniFile%, Screenshot, BorderWidth, 4

Menu Tray, Icon, %ResDir%\WinSpy.ico

; Main window
Gui Spy: New, LabelSpy hWndhSpyWnd
SetWindowIcon(hSpyWnd, ResDir . "\WinSpy.ico", 1)

Gui Font, s9, Segoe UI

Gui Add, Picture, hWndhFindTool gFindToolHandler x10 y12 w31 h28, %Bitmap1%
Gui Add, Text, x48 y10 w198, Drag the Finder Tool over a window`nto select it, then release the mouse
Gui Add, CheckBox, gSetDHW x247 y8 Checked%g_DetectHidden%, &Detect Hidden Windows
Gui Add, CheckBox, vg_Minimize gSetMinimize x247 y28 Checked%g_Minimize%, Compact &Mode

Gui Add, Tab3, hWndhTab vTab gTabHandler x10 y50 w382 h373 AltSubmit -Wrap, General|Styles|Details|Messages|Extra|Windows|Process
; General
Gui Tab, 1
    Gui Add, Text, x28 y88 w62 h23 +0x200, Handle:
    Gui Add, Edit, vEdtHandle gSetHandle x109 y90 w180 h21
    Gui Add, Button, hWndhBtnCommands gShowCommandsMenu x297 y88 w83 h23, Commands
    Gui Add, Text, vTxtText x28 y119 w62 h21 +0x200, Text:
    Gui Add, Edit, vEdtText x109 y120 w180 h21
    Gui Add, Button, vBtnSetText gSetText x297 y118 w83 h23, Set Text

    Gui Add, Text, x28 y146 w62 h21 +0x200, Class:
    Gui Add, Edit, vEdtClass x109 y150 w270 h21 -E0x200 ReadOnly

    Gui Add, Text, x28 y176 w62 h21 +0x200, ClassNN:
    Gui Add, Edit, vEdtClassNN x109 y180 w270 h21 -E0x200 ReadOnly
    Gui Add, Text, x23 y209 w357 0x10

    Gui Add, Text, x28 y220 w62 h21 +0x200, Style:
    Gui Add, Edit, vEdtStyle x109 y224 w270 h21 -E0x200 ReadOnly
    Gui Add, Text, x28 y250 w62 h21 +0x200, Extended:
    Gui Add, Edit, vEdtExStyle x109 y254 w270 h21 -E0x200 ReadOnly
    Gui Add, Text, x23 y283 w357 0x10

    Gui Add, Text, x28 y294 w62 h21 +0x200, Position:
    Gui Add, Edit, vEdtPosition x109 y298 w180 h21 -E0x200 ReadOnly
    Gui Add, Button, gShowXYWHDlg x297 y294 w83 h23, Change...
    Gui Add, Text, x28 y324 w62 h21 +0x200, Size:
    Gui Add, Edit, vEdtSize x109 y328 w180 h21 -E0x200 ReadOnly
    Gui Add, Text, x23 y357 w357 0x10

    Gui Add, Text, x28 y368 w80 h21 +0x200, Cursor:
    Gui Add, Edit, vEdtCursor x109 y372 w180 h21 -E0x200 ReadOnly
    Gui Add, DropDownList, vMouseCoordMode gSetMouseCoordMode x297 y368 w83, Client|Window|Screen||

; Styles
Gui Tab, 2
    Gui Add, Custom, ClassSysTabControl32 hWndhStylesTab gStylesTabHandler x21 y85 w360 h230
    Tab_AddItem(hStylesTab, "Styles")
    Tab_AddItem(hStylesTab, "Extended Styles")

    ; ListBox style +0x108: no integral height and simplified multiple selection
    Gui Add, ListBox
        , hWndhLbxStyles vLbxStyles gLbxStylesHandler x28 y116 w344 h190 +0x108 -E0x200 T133
    Gui Add, ListBox
        , hWndhLbxExStyles vLbxExStyles gLbxStylesHandler x28 y116 w344 h190 +0x108 -E0x200 T133 Hidden
    Gui Add, ListBox
        , hWndhLbxExtraStyles vLbxExtraStyles gLbxStylesHandler x28 y116 w344 h190 +0x108 -E0x200 T133 Hidden

    Gui Add, GroupBox, vGrpDesc x21 y319 w268 h91, Description
    Gui Add, Text, vTxtDesc gShowDescription x32 y338 w245 h64 +0x80, Left/Right-click an item to see its description.

    Gui Add, Edit, vEdtStyleSum x297 y326 w83 h23, 0x00000000
    Gui Add, Edit, vEdtExStyleSum x297 y326 w83 h23 Hidden, 0x00000000
    Gui Add, Edit, vEdtExtraStyleSum x297 y326 w83 h23 Hidden, 0x00000000

    Gui Add, Button, gApplyStyle x297 y355 w83 h24, Apply
    Gui Add, Button, gResetStyle x297 y386 w83 h24, Reset

; Details
Gui Tab, 3
    Gui Add, ListView, hWndhClassInfo x21 y84 w360 h200 +LV0x14000, Property|Value
    LV_ModifyCol(1, 138)
    LV_ModifyCol(2, 201)

    Gui Add, Text, x21 y288 w360 h20, Window Properties:
    Gui Add, ListView, hWndhPropInfo x21 y306 w360 h104 +LV0x14000, Property|Data
    LV_ModifyCol(1, 238)
    LV_ModifyCol(2, 100)

; Messages
Gui Tab, 4
    Gui Add, Text, x30 y94 w63 h23 +0x200, Message:
    Gui Add, ComboBox, hWndhCbxMsg vCbxMessages x105 y94 w182
    SendMessage 0x1701, 20, 0,, ahk_id %hCbxMsg% ; CB_SETMINVISIBLE
    Gui Add, Link, gGoogleSearch x299 y97 w78 h23, <a>Google Search</a>
    Gui Add, Text, x30 y127 w63 h23 +0x200, wParam:
    Gui Add, Edit, vwParam x105 y127 w182 h23
    Gui Add, DropDownList, vwParamType x297 y126 w78, Number||String
    Gui Add, Text, x30 y161 w63 h23 +0x200, lParam:
    Gui Add, Edit, vlParam x105 y161 w182 h23
    Gui Add, DropDownList, vlParamType x297 y160 w78, Number||String
    Gui Add, Button, gSendMsg x97 y206 w99 h24, SendMessage
    Gui Add, Button, gPostMsg x203 y206 w99 h24, PostMessage
    Gui Add, GroupBox, x84 y242 w232 h51 Center, Result
    Gui Add, Edit, vResult x103 y264 w195 h21 Center -E0x200 ReadOnly
    Gui Add, Picture, x58 y390 w16 h16 +Icon2, user32.dll
    Gui Add, Text, x80 y390 w290 h23, Some messages may crash the target application.

; Extra
Gui Tab, 5
    Gui Add, ListView, hWndhExtraInfo x21 y84 w360 h261 +LV0x14000, Property|Value

    Gui Add, Button, hWndhBtnMenu gShowMenuViewer x21 y355 w83 h23, Menu...
    Gui Add, Button, gShowScrollBarInfo x21 y387 w83 h23, Scroll Bars...

; Windows
Gui Tab, 6
    Gui Add, Custom, ClassSysTabControl32 hWndhWindowsTab gWindowsTabHandler x21 y85 w360 h255
    Tab_AddItem(hWindowsTab, "Child Windows")
    Tab_AddItem(hWindowsTab, "Sibling Windows")

    Gui Add, ListView, hWndhChildList gChildListHandler x28 y116 w344 h214 -E0x200 +LV0x14000
    , Handle|Class Name|Window Text
    LV_ModifyCol(1, 76)
    LV_ModifyCol(2, 113)
    LV_ModifyCol(3, 136)
    Gui Add, ListView, hWndhSiblingList gSiblingListHandler x28 y116 w344 h214 -E0x200 +LV0x14000 Hidden
    , Handle|Class Name|Window Text
    LV_ModifyCol(1, 76)
    LV_ModifyCol(2, 113)
    LV_ModifyCol(3, 136)

    Gui Add, Text, x33 y352 w48 h23 +0x200, Parent:
    Gui Add, Link, vParentLink gLinkToHandle x87 y357 w300 h20, <a>0x00000000</a>
    Gui Add, Text, x33 y380 w48 h23 +0x200, Owner:
    Gui Add, Link, vOwnerLink gLinkToHandle x87 y385 w300 h20, <a>0x00000000</a>

; Process
Gui Tab, 7
    Gui Add, Picture, vProgIcon x21 y82 w32 h32 Icon3, shell32.dll
    Gui Add, Text, vProgName x60 y82 w180 h20, N/A
    Gui Add, Text, vProgVer x60 y96 w180 h20 +0x200
    Gui Add, ListView, hWndhProcInfo x21 y120 w360 h257 +LV0x14000, Property|Value
    LV_ModifyCol(1, 100)
    LV_ModifyCol(2, 256)
    Gui Add, Button, gEndProcess x21 y386 w83 h23, End Process
    Gui Add, Button, gOpenFolder x110 y386 w83 h23, Open Folder

Gui Tab
Gui Add, Button, hWndhBtnOpts gShowSettingsDlg x10 y432 w24 h24
Gui Add, Button, gShowFindDlg x39 y432 w84 h24, &Find...
Gui Add, Button, gShowTree x128 y432 w84 h24, &Tree...
Gui Add, Button, gCopyToClipboard x217 y432 w84 h24, &Copy
Gui Add, Button, gScreenshot x306 y432 w84 h24, &Screenshot

SetButtonIcon(hBtnOpts, ResDir . "\Settings.ico")

; Show main window
IniRead px, %IniFile%, Settings, x, Center
IniRead py, %IniFile%, Settings, y, Center
Gui Show, x%px% y%py% w400 h465 Hide, %AppName% ; Show main window
If (g_Minimize) {
    WinMove ahk_id %hSpyWnd%,,,,, 78
    g_Minimized := True
}
Gui Show

SetExplorerTheme(hClassInfo)
SetExplorerTheme(hPropInfo)
SetExplorerTheme(hExtraInfo)
SetExplorerTheme(hChildList)
SetExplorerTheme(hSiblingList)
SetExplorerTheme(hProcInfo)

; Commands menu
Menu CommandsMenu, Add, Visible, MenuHandler
Menu CommandsMenu, Add, Enabled, MenuHandler
Menu CommandsMenu, Add, Always on Top, MenuHandler
Menu CommandsMenu, Add
Menu CommandsMenu, Add, Redraw Window, MenuHandler
Menu CommandsMenu, Add
Menu CommandsMenu, Add, Close Window, MenuHandler
Global hCommandsMenu := MenuGetHandle("CommandsMenu")

RegRead Sep, HKEY_CURRENT_USER\Control Panel\International, sThousand
If (Sep == "") {
    Sep := "."
}

OnMessage(0x100, "OnWM_KEYDOWN")
OnMessage(0x112, "OnWM_SYSCOMMAND")
OnMessage(0x200, "OnWM_MOUSEMOVE")
OnMessage(0x202, "OnWM_LBUTTONUP")
OnMessage(0x204, "OnWM_RBUTTONDOWN")

LoadCursors()

hSysMenu := DllCall("GetSystemMenu", "Ptr", hSpyWnd, "Int", False, "Ptr")
DllCall("InsertMenu", "Ptr", hSysMenu, "UInt", 5, "UInt", 0x400, "UPtr", 0xC0DE, "Str", "About...")
DllCall("InsertMenu", "Ptr", hSysMenu, "UInt", 5, "UInt", 0xC00, "UPtr", 0, "Str", "") ; Separator

Return ; End of the auto-execute section

SpyEscape:
SpyClose:
    p := GetWindowPlacement(hSpyWnd)

    If (!FileExist(IniFile)) {
        FileAppend % "[Settings]`n`n[Screenshot]", %IniFile%, UTF-16
    }

    IniWrite % p.x, %IniFile%, Settings, x
    IniWrite % p.y, %IniFile%, Settings, y

    IniWrite %g_DetectHidden%, %IniFile%, Settings, DetectHidden
    IniWrite %g_Minimize%, %IniFile%, Settings, CompactMode
    IniWrite %g_AlwaysOnTop%, %IniFile%, Settings, AlwaysOnTop

    IniWrite %g_ShowBorder%, %IniFile%, Screenshot, ShowBorder
    IniWrite %g_BorderColor%, %IniFile%, Screenshot, BorderColor
    IniWrite %g_BorderWidth%, %IniFile%, Screenshot, BorderWidth

    ExitApp

IsChild(hWnd) {
    WinGet Style, Style, ahk_id %hWnd%
    Return Style & 0x40000000 ; WS_CHILD
}

ShowWindowInfo(ClassNN := "") {
    GuiControl -g, EdtHandle

    If (IsChild(g_hWnd)) {
        LoadControlInfo(ClassNN)
    } Else {
        LoadWindowInfo()
    }

    GuiControl +gSetHandle, EdtHandle

    GoSub LoadStyles
    GoSub LoadClassInfo
    GoSub LoadProperties
    GoSub LoadExtraInfo
    GoSub LoadWindowsTab

    GuiControlGet Tab,, Tab, %hTab%
    TabHandler(Tab)

    GoSub UpdateTitleBar
}

LoadWindowInfo() {
    Gui Spy: Default

    ; Handle
    GuiControl,, EdtHandle, % Format("0x{:X}", g_hWnd)

    ; Title
    WinGetTitle Title, ahk_id %g_hWnd%
    GuiControl,, EdtText, %Title%
    GuiControl,, TxtText, Title:
    GuiControl,, BtnSetText, Set Title

    ; Class
    WinGetClass Class, ahk_id %g_hWnd%
    GuiControl,, EdtClass, %Class%

    GuiControl,, EdtClassNN, N/A

    ; Style
    WinGet g_Style, Style, ahk_id %g_hWnd%
    If ((g_Style & 0x00FF0000) == 0xCF0000) {
        StyleInfo := " (overlapped window)"
    } Else If (g_Style & 0x80880000) {
        StyleInfo := " (popup window)"
    } Else {
        StyleInfo := ""
    }
    GuiControl,, EdtStyle, % Format("0x{:08X}", g_Style) . StyleInfo

    ; Extended style
    WinGet g_ExStyle, ExStyle, ahk_id %g_hWnd%
    GuiControl,, EdtExStyle, % Format("0x{:08X}", g_ExStyle)

    ; Position/size
    SetFormat Integer, D
    WinGetPos X, Y, W, H, ahk_id %g_hWnd%
    wi := GetWindowInfo(g_hWnd)
    GuiControl,, EdtPosition, % X . ", " . Y . " (" . wi.ClientX . ", " . wi.ClientY . ")"
    GuiControl,, EdtSize, % W . " x " . H . " (" . wi.ClientW . " x " . wi.ClientH . ")"
}

LoadControlInfo(ClassNN) {
    If (ClassNN == "") {
        ClassNN := GetClassNNEx(g_hWnd)
    }

    Gui Spy: Default
    SetFormat Integer, Hex

    ; Handle
    GuiControl,, EdtHandle, % Format("0x{:X}", g_hWnd)

    ; Class
    WinGetClass, Class, ahk_id %g_hWnd%
    GuiControl,, EdtClass, %Class%

    ; Control text
    ControlGetText Text,, ahk_id %g_hWnd%
    GuiControl,, EdtText, %Text%
    GuiControl,, TxtText, Text:
    GuiControl,, BtnSetText, Set Text

    ; ClassNN
    GuiControl,, EdtClassNN, %ClassNN%

    ; Style
    ControlGet g_Style, Style,,, ahk_id %g_hWnd%
    GuiControl,, EdtStyle, %g_Style%

    ; Extended style
    ControlGet g_ExStyle, ExStyle,,, ahk_id %g_hWnd%
    GuiControl,, EdtExStyle, %g_ExStyle%

    ; Position/Size
    SetFormat Integer, D
    GetWindowPos(g_hWnd, X, Y, W, H)
    wi := GetWindowInfo(g_hWnd)
    Pos := X . ", " . Y ; Relative to parent

    hParent := GetParent(g_hWnd)
    hAncestor := GetAncestor(g_hWnd)
    If (hParent != hAncestor) {
        VarSetCapacity(RECT, 16, 0)
        DllCall("GetWindowRect", "Ptr", g_hWnd, "Ptr", &RECT)
        DllCall("MapWindowPoints", "Ptr", 0, "Ptr", GetAncestor(g_hWnd), "Ptr", &RECT, "UInt", 1)
        AX := NumGet(RECT, 0, "Int")
        AY := NumGet(RECT, 4, "Int")
        Pos .= " (" . AX ", " . AY . ")" ; Relative to ancestor
    }

    GuiControl,, EdtPosition, %Pos%

    If (W != wi.ClientW || H != wi.ClientH) {
        GuiControl,, EdtSize, % W . " x " . H . " (" . wi.ClientW . " x " . wi.ClientH . ")"
    } Else {
        GuiControl,, EdtSize, %W% x %H%
    }

    g_ExtraStyle := GetExtraStyle(g_hWnd)
}

GetStatusBarText(hWnd) {
    SB_Text := ""
    hParentWnd := GetParent(hWnd)

    SendMessage 0x406, 0, 0,, ahk_id %hWnd% ; SB_GETPARTS
    Count := ErrorLevel
    If (Count != "FAIL") {
        Loop %Count% {
            StatusBarGetText PartText, %A_Index%, ahk_id %hParentWnd%
            SB_Text .= PartText . "|"
        }
    }

    Return SubStr(SB_Text, 1, -1)
}

TabHandler:
    Gui Spy: Submit, NoHide
    TabHandler(Tab)
Return

TabHandler(Tab) {
    If (Tab == 7) { ; Process
        GoSub LoadProcessProperties
    } Else If (Tab == 4) { ; Messages
        GoSub LoadMessages
        WinSet Redraw,, ahk_id %hCbxMsg%
    }
}

; Flag: GA_PARENT = 1, GA_ROOT = 2, GA_ROOTOWNER  = 3
GetAncestor(hWnd, Flag := 2) {
    Return DllCall("GetAncestor", "Ptr", hWnd, "UInt", Flag, "Ptr")
}

GetClassNNEx(hWnd) {
    hAncestor := GetAncestor(hWnd)
    If (!hAncestor) {
        Return
    }

    WinGetClass BaseClass, ahk_id %hWnd%
    NN := 0

    WinGet ControlList, ControlListHwnd, % "ahk_id " . hAncestor
    Loop Parse, ControlList, `n
    {
        WinGetClass Class, ahk_id %A_LoopField%
        If (Class == BaseClass) {
            NN++
            If (A_LoopField == hWnd) {
                Return Class . NN
            }
        }
    }
}

SetHandle:
    Gui Spy: Submit, NoHide

    If (!Dragging && WinExist("ahk_id " . EdtHandle)) {
        g_hWnd := EdtHandle
        ShowWindowInfo()
    }
Return

MenuHandler:
    If (A_ThisMenuItem == "Visible") {
        ShowWindow(g_hWnd, !IsWindowVisible(g_hWnd))
    } Else If (A_ThisMenuItem == "Enabled") {
        DllCall("EnableWindow", "Ptr", g_hWnd, "UInt", !IsWindowEnabled(g_hWnd))
    } Else If (A_ThisMenuItem == "Always on Top") {
        WinSet AlwaysOnTop, Toggle, ahk_id %g_hWnd%
    } Else If (A_ThisMenuItem == "Close Window") {
        WinClose ahk_id %g_hWnd%
    } Else If (A_ThisMenuItem == "Redraw Window") {
        WinSet Redraw,, ahk_id %g_hWnd%
    }
Return

UpdateCommandsMenu() {
    Visible := IsWindowVisible(g_hWnd)
    Enabled := IsWindowEnabled(g_hWnd)
    WinGet ExStyle, ExStyle, ahk_id %g_hWnd%

    Menu CommandsMenu, % (Visible) ? "Check" : "Uncheck", Visible
    Menu CommandsMenu, % (Enabled) ? "Check" : "Uncheck", Enabled

    Menu CommandsMenu, % (ExStyle & 0x8) ? "Check" : "Uncheck", Always on Top ; WS_EX_TOPMOST
    Menu CommandsMenu, % (IsChild(g_hWnd)) ? "Disable" : "Enable", Always on Top
}

IsWindowEnabled(hWnd) {
    Return DllCall("IsWindowEnabled", "Ptr", hWnd)
}

ShowCommandsMenu:
    UpdateCommandsMenu()

    Flags:= 0x8 ; TPM_TOPALIGN | TPM_RIGHTALIGN
    WingetPos wx, wy, ww, wh, ahk_id %hSpyWnd%
    ControlGetPos cx, cy, cw, ch,, ahk_id %hBtnCommands%
    x := wx + cx + cw
    y := wy + cy + ch
    DllCall("TrackPopupMenu", "Ptr", hCommandsMenu, "UInt", 0x8, "Int", x, "Int", y, "Int", 0, "Ptr", hSpyWnd, "Ptr", 0)
Return

SetText:
    Gui Spy: Submit, NoHide
    If (IsChild(g_hWnd)) {
        ControlSetText,, %EdtText%, ahk_id %g_hWnd%
    } Else {
        WinSetTitle ahk_id %g_hWnd%,, %EdtText%
    }
Return

ShowBorder(hWnd, Duration := 500, Color := "0x3FBBE3", r := 3) {
    Local x, y, w, h, Index

    WinGetPos x, y, w, h, ahk_id %hWnd%
    If (!w) {
        Return
    }

    g_Borders := []
    Loop 4 {
        Index := A_Index + 90
        Gui %Index%: +hWndhBorder -Caption +ToolWindow +AlwaysOnTop
        Gui %Index%: Color, %Color%
        g_Borders.Push(hBorder)
    }

    Gui 91: Show, % "NA x" (x - r) " y" (y - r) " w" (w + r + r) " h" r ; Top
    Gui 92: Show, % "NA x" (x - r) " y" (y + h) " w" (w + r + r) " h" r ; Bottom
    Gui 93: Show, % "NA x" (x - r) " y" y " w" r " h" h ; Left
    Gui 94: Show, % "NA x" (x + w) " y" y " w" r " h" h ; Right

    If (Duration != -1) {
        Sleep %Duration%
        Loop 4 {
            Index := A_Index + 90
            Gui %Index%: Destroy
        }
    }
}

GetClassLong(hWnd, Param) {
    Static GetClassLong := A_PtrSize == 8 ? "GetClassLongPtr" : "GetClassLong"
    Return DllCall(GetClassLong, "Ptr", hWnd, "Int", Param)
}

GetWindowLong(hWnd, Param) {
    ;GetWindowLong := A_PtrSize == 8 ? "GetWindowLongPtr" : "GetWindowLong"
    Return DllCall("GetWindowLong", "Ptr", hWnd, "Int", Param)
}

; Details
LoadClassInfo:
    Gui ListView, %hClassInfo%
    LV_Delete()

    SetFormat Integer, H
    WinGetClass ClassName, ahk_id %g_hWnd%
    ClassStyle := GetClassLong(g_hWnd, -26)

    LV_Add("", "Class name", ClassName)
    LV_Add("", "Control ID", GetWindowLong(g_hWnd, -12))
    LV_Add("", "Font", GetFont())
    LV_Add("", "Window procedure", GetClassLong(g_hWnd, -24))
    LV_Add("", "Instance handle", GetClassLong(g_hWnd, -16))
    LV_Add("", "Class style", ClassStyle . GetClassStyles(ClassStyle))
    LV_Add("", "Icon handle", GetClassLong(g_hWnd, -14))
    LV_Add("", "Small icon handle", GetClassLong(g_hWnd, -34))
    LV_Add("", "Cursor handle", GetCursor(GetClassLong(g_hWnd, -12)))
    LV_Add("", "Background Brush", GetSysColorName(GetClassLong(g_hWnd, -10) - 1))
    LV_Add("", "Menu name", GetClassLong(g_hWnd, -8))
    LV_Add("", "Window extra bytes", GetClassLong(g_hWnd, -18))
    LV_Add("", "Class extra bytes", GetClassLong(g_hWnd, -20))
    LV_Add("", "Class atom", GetClassLong(g_hWnd, -32))
    LV_Add("", "User data", GetWindowLong(g_hWnd, -21))
    SetFormat Integer, D
    LV_Add("", "Unicode", DllCall("IsWindowUnicode", "Ptr", g_hWnd) ? "Yes" : "No")
    LV_Add("", "Tab order index", GetTabOrderIndex(g_hWnd))
    LV_Add("", "Help context ID", DllCall("GetWindowContextHelpId", "Ptr", g_hWnd))
    LV_Add("", "Touch-capable", DllCall("IsTouchWindow", "Ptr", g_hWnd, "Ptr", 0))
Return

GetFont() {
    FontName := FontSize := FontStyle := ""

    Wingetclass Class, ahk_id %g_hWnd%
    If (Class == "Scintilla") {
        FontName := Scintilla_GetFont(g_hWnd)
        FontSize := SendMsg(2485, 32) ; SCI_STYLEGETSIZE, STYLE_DEFAULT
    } Else {
        Control_GetFont(g_hWnd, FontName, FontSize, FontStyle)
        If (FontName == "" || FontSize > 1000) {
            Return "System default"
        }
    }

    FontInfo := FontName . ", " . Format("{:d}", FontSize)
    If (FontStyle != "") {
        FontInfo .= ", " . FontStyle
    }

    Return FontInfo
}

; www.autohotkey.com/forum/viewtopic.php?p=465438#465438
Control_GetFont(hWnd, ByRef Name, ByRef Size, ByRef Style, IsGDIFontSize := 0) {
    SendMessage 0x31, 0, 0, , ahk_id %hWnd% ; WM_GETFONT
    If (ErrorLevel == "FAIL") {
        Return
    }

    hFont := Errorlevel
    VarSetCapacity(LOGFONT, LOGFONTSize := 60 * (A_IsUnicode ? 2 : 1 ))
    DllCall("GetObject", "Ptr", hFont, "Int", LOGFONTSize, "Ptr", &LOGFONT)

    Name := DllCall("MulDiv", "Int", &LOGFONT + 28, "Int", 1, "Int", 1, "Str")

    Style := Trim((Weight := NumGet(LOGFONT, 16, "Int")) == 700 ? "Bold" : (Weight == 400) ? "" : " w" . Weight
    . (NumGet(LOGFONT, 20, "UChar") ? " Italic" : "")
    . (NumGet(LOGFONT, 21, "UChar") ? " Underline" : "")
    . (NumGet(LOGFONT, 22, "UChar") ? " Strikeout" : ""))

    Size := IsGDIFontSize ? -NumGet(LOGFONT, 0, "Int") : Round((-NumGet(LOGFONT, 0, "Int") * 72) / A_ScreenDPI)
}

Scintilla_GetFont(hWnd) {
    WinGet PID, PID, ahk_id %hWnd%
    If !(hProc := DllCall("OpenProcess", "UInt", 0x438, "Int", False, "UInt", PID, "Ptr")) {
        Return
    }

    ; LF_FACESIZE := 32
    Address := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "UPtr", 32, "UInt", 0x1000, "UInt", 4, "Ptr")

    SendMessage 2486, 32, Address,, ahk_id %hWnd% ; SCI_STYLEGETFONT, STYLE_DEFAULT
    If (ErrorLevel != "FAIL") {
        VarSetCapacity(FontName, 32, 0)
        DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", Address, "Ptr", &FontName, "UPtr", 32, "Ptr", 0)
        FontName := StrGet(&FontName, "UTF-8")
    }

    DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", Address, "UPtr", 0, "UInt", 0x8000) ; MEM_RELEASE
    DllCall("CloseHandle", "Ptr", hProc)

    Return FontName
}

Scintilla_GetLexerLanguage(hWnd) {
    WinGet PID, PID, ahk_id %hWnd%
    If !(hProc := DllCall("OpenProcess", "UInt", 0x438, "Int", False, "UInt", PID, "Ptr")) {
        Return
    }

    Sendmessage 4012, 0, 0,, ahk_id %hWnd% ; SCI_GETLEXERLANGUAGE
    BufferSize := ErrorLevel
    Address := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "UPtr", BufferSize, "UInt", 0x1000, "UInt", 4, "Ptr")

    Sendmessage 4012, 0, Address,, ahk_id %hWnd% ; SCI_GETLEXERLANGUAGE
    If (ErrorLevel != "FAIL") {
        VarSetCapacity(LexerName, BufferSize, 0)
        DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", Address, "Ptr", &LexerName, "UPtr", 32, "Ptr", 0)
        LexerName := StrGet(&LexerName, "UTF-8")
    }

    DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", Address, "UPtr", 0, "UInt", 0x8000) ; MEM_RELEASE
    DllCall("CloseHandle", "Ptr", hProc)

    Return LexerName
}

GetClassStyles(Style) {
    Static CS := {0x1: "CS_VREDRAW"
    , 0x2: "CS_HREDRAW"
    , 0x8: "CS_DBLCLKS"
    , 0x20: "CS_OWNDC"
    , 0x40: "CS_CLASSDC"
    , 0x80: "CS_PARENTDC"
    , 0x200: "CS_NOCLOSE"
    , 0x800: "CS_SAVEBITS"
    , 0x1000: "CS_BYTEALIGNCLIENT"
    , 0x2000: "CS_BYTEALIGNWINDOW"
    , 0x4000: "CS_GLOBALCLASS"
    , 0x10000: "CS_IME"
    , 0x20000: "CS_DROPSHADOW"}

    Styles := " ("
    For k, v in CS {
        If (Style & k) {
            Styles .= v ", "
        }
    }

    Return RTrim(Styles, ", ") . ")"
}

LoadCursors() {
    Static Constants := {"IDC_ARROW": 32512
        , "IDC_IBEAM": 32513
        , "IDC_WAIT": 32514
        , "IDC_CROSS": 32515
        , "IDC_UPARROW": 32516
        , "IDC_SIZENWSE": 32642
        , "IDC_SIZENESW": 32643
        , "IDC_SIZEWE": 32644
        , "IDC_SIZENS": 32645
        , "IDC_SIZEALL": 32646
        , "IDC_NO": 32648
        , "IDC_HAND": 32649
        , "IDC_APPSTARTING": 32650
        , "IDC_HELP": 32651}

    For Key, Value in Constants {
        hCursor := DllCall("LoadCursor", "Ptr", 0, "UInt", Value, "Ptr")
        Cursors[hCursor] := Key
    }
}

GetCursor(CursorHandle) {
    Cursor := Cursors[CursorHandle]
    Return (Cursor != "") ? Cursor : CursorHandle
}

GetTabOrderIndex(hWnd) {
    hParent := GetAncestor(hWnd)

    WinGet ControlList, ControlListHwnd, ahk_id %hParent%
    Index := 1
    Loop Parse, ControlList, `n
    {
        If (!IsWindowVisible(A_LoopField)) {
            Continue
        }

        WinGet Style, Style, ahk_id %A_LoopField%
        If !(Style & 0x10000) { ; WS_TABSTOP
            Continue
        }

        If (A_LoopField == hWnd) {
            Return Index
        }

        Index++
    }

    Return 0
}

Tab_AddItem(hTab, Text) {
    VarSetCapacity(TCITEM, 16 + A_PtrSize * 3, 0)
    NumPut(0x1, TCITEM, 0, "UInt") ; TCIF_TEXT
    NumPut(&Text, TCITEM, 8 + A_PtrSize, "Ptr")
    SendMessage 0x1304, 0, 0,, ahk_id %hTab% ; TCM_GETITEMCOUNT
    SendMessage 0x133E, %ErrorLevel%, &TCITEM, , ahk_id %hTab% ; TCM_INSERTITEMW
}

StylesTabHandler:
    If (A_GuiEvent == "N") {
        Code := NumGet(A_EventInfo + 0, A_PtrSize * 2, "Int")
        If (Code == -551) { ; TCN_SELCHANGE
            SendMessage 0x130B, 0, 0,, ahk_id %hStylesTab% ; TCM_GETCURSEL
            nTab := Errorlevel + 1
            If (nTab == 1) {
                GuiControl Hide, ListBox3
                GuiControl Hide, ListBox2
                GuiControl Show, ListBox1

                GuiControl Hide, EdtExtraStyleSum
                GuiControl Hide, EdtExStyleSum
                GuiControl Show, EdtStyleSum
            } Else If (nTab == 2) {
                GuiControl Hide, ListBox1
                GuiControl Hide, ListBox3
                GuiControl Show, ListBox2

                GuiControl Hide, EdtExtraStyleSum
                GuiControl Hide, EdtStyleSum
                GuiControl Show, EdtExStyleSum
            } Else If (nTab == 3) {
                GuiControl Hide, ListBox1
                GuiControl Hide, ListBox2
                GuiControl Show, ListBox3

                GuiControl Hide, EdtStyleSum
                GuiControl Hide, EdtExStyleSum
                GuiControl Show, EdtExtraStyleSum
            }
        }
    }
Return

; Styles
LoadStyles:
    Gui Spy: Default

    GuiControl,, EdtStyleSum, %g_Style%
    GuiControl,, EdtExStyleSum, %g_ExStyle%
    GuiControl,, EdtExtraStyleSum, %g_ExtraStyle%

    WinGetClass Class, ahk_id %g_hWnd%
    If (Class == "") {
        Return
    }

    ; Load control styles
    LoadStyles(Class, "ListBox1")

    If (Class == "ToolbarWindow32" || Class == "ReBarWindow32") {
        LoadStyles("CommonControls", "ListBox1", True)
    }

    ; Load window styles
    LoadStyles("Window", "ListBox1", True)
    LoadStyles("WindowEx", "ListBox2")

    ; Delete the third tab
    SendMessage 0x1308, 2, 0,, ahk_id %hStylesTab% ; TCM_DELETEITEM
    If (ErrorLevel == True) {
        GuiControl Hide, ListBox3
        GuiControl Show, ListBox1
        SendMessage 0x1330, 0, 0,, ahk_id %hStylesTab% ; TCM_SETCURFOCUS
        Sleep 0
        SendMessage 0x130C, 0, 0,, ahk_id %hStylesTab% ; TCM_SETCURSEL
    }

    If (Class == "ComboBox" && g_Style & 0x10) { ; CBS_OWNERDRAWFIXED
        Class := "ComboBoxEx"
    }

    ; Add third tab
    If (Class == "SysListView32"
    ||  Class == "SysTreeView32"
    ||  Class == "SysTabControl32"
    ||  Class == "ToolbarWindow32"
    ||  Class == "ComboBoxEx") {
        Tab_AddItem(hStylesTab, RegExReplace(Class, "Sys|32|Control|Window") . " Extended Styles")
        LoadStyles(Class . "Ex", "ListBox3")
    }

    WStyle := g_Style
    Type := 0
    If (Class == "Button") {
        Type := WStyle & 0xF ; BS_TYPEMASK
        WStyle &= ~Type
    } Else If (Class == "SysListView32") {
        Type := WStyle & 0x3 ; LVS_TYPEMASK
        WStyle &= ~Type
    } Else If (Class == "Static") {
        Type := WStyle & 0x1F ; SS_TYPEMASK
        WStyle &= ~Type
    }

    ControlGet Items, List,,, ahk_id %hLbxStyles%
    Loop Parse, Items, `n
    {
        LStyle := StrSplit(A_LoopField, "`t")[2]
        If (WStyle & LStyle || Type == LStyle) {
            WStyle &= ~LStyle
            GuiControl Choose, %hLbxStyles%, %A_Index%
        }
    }

    If (WStyle) {
        Leftover := Format("0x{:08X}", WStyle)
        GuiControl,, %hLbxStyles%, % Leftover . "`t" . Leftover . "||"
    }

    SendMessage 0x115, 6, 0,, ahk_id %hLbxStyles% ; WM_VSCROLL, scroll to top
    WinSet Redraw,, ahk_id %hLbxStyles%

    ; Extended styles
    WExStyle := g_ExStyle
    ControlGet Items, List,,, ahk_id %hLbxExStyles%
    Loop Parse, Items, `n
    {
        LExStyle := StrSplit(A_LoopField, "`t")[2]
        If (WExStyle & LExStyle || LExStyle == 0) {
            WExStyle &= ~LExStyle
            GuiControl Choose, %hLbxExStyles%, %A_Index%
        }
    }

    If (WExStyle) {
        Leftover := Format("0x{:08X}", WExStyle)
        GuiControl,, %hLbxExStyles%, % Leftover . "`t" . Leftover . "||"
    }

    SendMessage 0x115, 6, 0,, ahk_id %hLbxExStyles% ; WM_VSCROLL, scroll to top
    WinSet Redraw,, ahk_id %hLbxExStyles%

    ; Extra control styles (LV, TV, Toolbar, Tab)
    ExtraStyle := g_ExtraStyle
    ControlGet Items, List,,, ahk_id %hLbxExtraStyles%
    Loop Parse, Items, `n
    {
        LExtraStyle := StrSplit(A_LoopField, "`t")[2]
        If (ExtraStyle & LExtraStyle || LExtraStyle == 0) {
            ExtraStyle &= ~LExtraStyle
            GuiControl Choose, %hLbxExtraStyles%, %A_Index%
        }
    }
Return

LoadStyles(IniSection, ListBox, Append := False) {
    Static IniFile := A_ScriptDir . "\Constants\Styles.ini"
    IniRead Section, %IniFile%, %IniSection%

    Child := (IniSection == "Window" && IsChild(g_hWnd)) ? True : False

    Values := ""
    Loop Parse, Section, `n
    {
        Fields := StrSplit(A_LoopField, "|")
        Const := Fields[1]

        If (Child && (Const == "WS_MAXIMIZEBOX" || Const == "WS_MINIMIZEBOX" || Const == "WS_OVERLAPPED")) {
            Continue
        }

        If (!Child && (Const == "WS_TABSTOP" || Const == "WS_GROUP")) {
            Continue
        }

        Values .= Const . "`t" . Fields[2] . "|"
        oStyles[Const] := {"Value": Fields[2], "Desc": Fields[3]}
    }

    Gui Spy: Default
    GuiControl,, %ListBox%, % (Append) ? Values : "|" . Values
}

LbxStylesHandler:
    Gui Spy: Default
    GuiControlGet hLbx, hWnd, %A_GuiControl%
    GuiControl -AltSubmit, %hLbx%

    GuiControlGet Items,, %hLbx%

    Sum := 0
    Loop Parse, Items, |
    {
        StringSplit Field, A_LoopField, `t
        Sum += Field2
    }

    GuiControl,, % StrReplace(A_GuiControl, "Lbx", "Edt") . "um", % Format("0x{:08X}", Sum)

    ; Style description
    GuiControl +AltSubmit, %hLbx%
    SendMessage 0x188, 0, 0,, ahk_id %hLbx% ; LB_GETCURSEL
    If (ErrorLevel != "FAIL") {
        ; Credits to just_me
        Index := ErrorLevel
        SendMessage 0x18A, %Index%, 0,, ahk_id %hLbx% ; LB_GETTEXTLEN
        Len := ErrorLevel
        VarSetCapacity(LB_Text, Len << !!A_IsUnicode, 0)
        SendMessage 0x189, %Index%, % &LB_Text,, ahk_id %hLbx% ; LB_GETTEXT
        Const := StrSplit(StrGet(&LB_Text, Len), "`t")[1]
        Desc := StrReplace(oStyles[Const].Desc, "\n", "`n")
        GuiControl,, GrpDesc, %Const%
        GuiControl,, TxtDesc, %Desc%
    }
Return

ApplyStyle:
    SendMessage 0x130B, 0, 0,, ahk_id %hStylesTab% ; TCM_GETCURSEL
    nTab := ErrorLevel + 1

    If (nTab == 1) {
        GuiControlGet Style,, EdtStyleSum
        WinSet Style, %Style%, ahk_id %g_hWnd%
    } Else If (nTab == 2) {
        GuiControlGet ExStyle,, EdtExStyleSum
        WinSet ExStyle, %ExStyle%, ahk_id %g_hWnd%
    } Else If (nTab == 3) {
        GuiControlGet ExtraStyle,, EdtExtraStyleSum
        WinGetClass Class, ahk_id %g_hWnd%

        If (Class == "SysListView32") {
            SendMessage 0x1036, 0, %ExtraStyle%,, ahk_id %g_hWnd% ; LVM_SETEXTENDEDLISTVIEWSTYLE
        } Else If (Class == "SysTreeView32") {
            SendMessage 0x112C, 0, %ExtraStyle%,, ahk_id %g_hWnd% ; TVM_SETEXTENDEDSTYLE
        } Else If (Class == "SysTabControl32") {
            SendMessage 0x1334, 0, %ExtraStyle%,, ahk_id %g_hWnd% ; TCM_SETEXTENDEDSTYLE
        } Else If (Class == "ToolbarWindow32") {
            SendMessage 0x454, 0, %ExtraStyle%,, ahk_id %g_hWnd% ; TB_SETEXTENDEDSTYLE
        } Else If (Class == "ComboBox" && (g_Style & 0x10)) {
            SendMessage 0x40E, 0, %ExtraStyle%,, ahk_id %g_hWnd% ; CBEM_SETEXTENDEDSTYLE
        }
    }

    ; 0x17: SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE
    DllCall("SetWindowPos", "Ptr", g_hWnd, "UInt", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x17)
    WinSet Redraw,, ahk_id %g_hWnd%
Return

ResetStyle:
    nTab := DllCall("SendMessage", "Ptr", hStylesTab, "UInt", 0x130B, "UInt", 0, "UInt", 0) + 1
    If (nTab == 1) {
        GuiControl, Spy:, EdtStyleSum, %g_Style%
    } Else If (nTab == 2) {
        GuiControl, Spy:, EdtExStyleSum, %g_ExStyle%
    } Else If (nTab == 3) {
        GuiControl, Spy:, EdtExtraStyleSum, %g_ExtraStyle%
    }

    GoSub LoadStyles
Return

GetExtraStyle(hWnd) {
    WinGetClass Class, ahk_id %hWnd%

    If (Class == "SysListView32") {
        Message := 0x1037 ; LVM_GETEXTENDEDLISTVIEWSTYLE
    } Else If (Class == "SysTreeView32") {
        Message := 0x112D ; TVM_GETEXTENDEDSTYLE
    } Else If (Class == "SysTabControl32") {
        Message := 0x1335 ; TCM_GETEXTENDEDSTYLE
    } Else If (Class == "ToolbarWindow32") {
        Message := 0x455 ; TB_GETEXTENDEDSTYLE
    } Else If (Class == "ComboBox" && g_Style & 0x10) {
        Message := 0x409 ; CBEM_GETEXTENDEDSTYLE
    }

    SendMessage %Message%, 0, 0,, ahk_id %hWnd%
    Return Format("0x{:08X}", ErrorLevel)
}

ShowDescription:
    GuiControlGet Const,, GrpDesc
    GuiControlGet Desc,, TxtDesc

    Gui Desc: New, LabelDesc -SysMenu OwnerSpy
    Gui Color, White
    Gui Margin, 10, 0
    Gui Add, CheckBox, x0 y0 w0 h0

    Gui Add, Picture, x12 y12 w32 h32 Icon5, user32.dll
    Gui Font, s12 c0x003399, Segoe UI
    Gui Add, Text, x58 y15 w473 h23 +0x200, %Const%
    Gui Font

    Gui Font, s10, Segoe UI
    Gui Add, Edit, vEdtDesc x55 y55 w444 Multi -VScroll -E0x200, %Desc%
    Gui Font

    GuicontrolGet Pos, Pos, EdtDesc
    py := PosY + PosH + 20
    Gui Add, Text, hWndhFooter x-1 y%py% w533 h48 -Background

    Gui Font, s9, Segoe UI
    Gui Add, Button, gDescClose x432 yp+12 w88 h25 Default, &Close

    Gui Show, w531, Style Description
Return

DescEscape:
DescClose:
    Gui Desc: Destroy
Return

; Messages
LoadMessages:
    WinGetClass Class, ahk_id %g_hWnd%

    Constants := GetMessages(Class)

    Gui Spy: Default
    GuiControlGet CurrentItem,, CbxMessages, Text
    GuiControl,, CbxMessages, |%Constants%
    GuiControl Text, CbxMessages, %CurrentItem%

    ; Common Control Messages
    If (Class == "ToolbarWindow32" || Class == "ReBarWindow32") {
        GuiControl,, CbxMessages, % GetMessages("CommonControls")
    }

    If (g_WinMsgs == "") {
        g_WinMsgs := GetMessages("Window")
    }

    GuiControl,, CbxMessages, %g_WinMsgs%
Return

GetMessages(Class) {
    Static IniFile := A_ScriptDir . "\Constants\Messages.ini"

    If (Class == "") {
        Return
    }

    IniRead Section, %IniFile%, %Class%

    Constants := ""
    Loop Parse, Section, `n
    {
        Constants .= StrSplit(A_LoopField, "=")[1] . "|"
    }

    Sort Constants, D|
    Return Constants
}

SendMsg:
PostMsg:
    Gui Spy: Submit, NoHide

    Function := (A_ThisLabel == "SendMsg") ? "SendMessage" : "PostMessage"

    If CbxMessages is Not Number
    {
        If (SubStr(CbxMessages, 1, 3) == "WM_") {
            ClassName := "Window"
        } Else {
            ClassName := GetClassName(g_hWnd)
        }

        IniRead Message, %A_ScriptDir%\Constants\Messages.ini, %ClassName%, %CbxMessages%
        If (Message == "ERROR") {
            Gui Spy: +OwnDialogs
            MsgBox 0x10, %AppName%, %CbxMessages%: invalid message.
            Return
        }
    } Else {
        Message := CbxMessages
    }

    DataTypes := {"Number": "UPtr", "String": "WStr"}
    wType := DataTypes[wParamType]
    lType := DataTypes[lParamType]

    Result := DllCall(Function, "Ptr", g_hWnd, "UInt", Message, wType, wParam, lType, lParam)
    GuiControl,, Result, %Result%
Return

GoogleSearch:
    GuiControlGet Message,, CbxMessages

    If (Message == "") {
        Return
    }

    If (SubStr(Message, 1, 3) == "SCI") {
        URL := "http://www.scintilla.org/ScintillaDoc.html#"
    } Else {
        URL := "https://www.google.com/#q="
    }

    Try {
        Run %URL%%Message%
    }
Return

CopyToClipboard:
    Gui Spy: Default

    CRLF := "`r`n"
    Output := ""

    If (Tab == 1) { ; General
        Gui Spy: Submit, NoHide
        Output .= "[General]" . CRLF
        Output .= "Handle:`t" . EdtHandle . CRLF
        Output .= "Text:`t" . EdtText . CRLF
        Output .= "Class:`t" . EdtClass . CRLF
        Output .= "ClassNN:`t" . EdtClassNN . CRLF
        Output .= "Style:`t" . EdtStyle . CRLF
        Output .= "Extended:`t" . EdtExStyle . CRLF
        Output .= "Position:`t" . EdtPosition . CRLF
        Output .= "Size:`t" . EdtSize . CRLF
        Output .= "Cursor:`t" . EdtCursor . CRLF
    }
    Else If (Tab == 2) { ; Styles
        If (g_Style) {
            GuiControlGet Styles,, %hLbxStyles%
            Output .= "[Styles]" . CRLF . StrReplace(Styles, "|", CRLF) . CRLF . CRLF
        }

        If (g_ExStyle) {
            GuiControlGet ExStyles,, %hLbxExStyles%
            Output .= "[ExStyles]" . CRLF . StrReplace(ExStyles, "|", CRLF) . CRLF . CRLF
        }

        If (g_ExtraStyle) {
            GuiControlGet ExtraStyles,, %hLbxExtraStyles%
            Output .= "[ExtraStyles]" . CRLF . StrReplace(ExtraStyles, "|", CRLF)
        }
    }
    Else If (Tab == 3) { ; Details
        ControlGet, ClassInfo, List,,, ahk_id %hClassInfo%
        ControlGet, PropInfo, List,,, ahk_id %hPropInfo%
        Output .= "[Details]" . CRLF . ClassInfo . CRLF . CRLF . "[Properties]" . CRLF . PropInfo
    }
    Else If (Tab == 5) { ; Extra
        ControlGet, ExtraInfo, List,,, ahk_id %hExtraInfo%
        Output .= "[Extra]" . CRLF . ExtraInfo
    }
    Else If (Tab == 6) { ; Windows
        ControlGet, Child, List,,, ahk_id %hChildList%
        If (Child != "") {
            Output .= "[Child]" . CRLF . Child . CRLF . CRLF
        }

        ControlGet, Sibling, List,,, ahk_id %hSiblingList%
        If (Sibling != "") {
            Output .= "[Sibling]" . CRLF . Sibling . CRLF . CRLF
        }

        GuiControlGet ParentLink,, ParentLink
        Output .= "Parent:`t" . RegExReplace(ParentLink, "\<\/?a\>") . CRLF
        GuiControlGet OwnerLink,, OwnerLink
        Output .= "Owner:`t" . RegExReplace(OwnerLink, "\<\/?a\>")
    }
    Else If (Tab == 7) { ; Process
        ControlGet, ProcInfo, List,,, ahk_id %hProcInfo%
        Output .= "[Process]" . CRLF . ProcInfo
    }

    Clipboard := RTrim(Output, CRLF)
Return

ControlFromPoint(mx, my, hWnd) {
    hParent := GetParent(hWnd)
    If (hParent == 0) {
        hParent := hWnd
    }

    SmallerArea := 999999999
    hChildWnd := 0

    WinGet List, ControlListHwnd, ahk_id %hParent% ; EnumChildWindows
    Loop Parse, List, `n
    {
        VarSetCapacity(RECT, 16, 0)
        DllCall("GetWindowRect", "Ptr", A_LoopField, "Ptr", &RECT)
        Left := NumGet(RECT, 0, "Int")
        Top := NumGet(RECT, 4, "Int")
        Right := NumGet(RECT, 8, "Int")
        Bottom := NumGet(RECT, 12, "Int")

        If ((mx >= Left) && (mx <= Right) && (my >= Top) && (my <= Bottom)) {
            Area := (Right - Left) * (Bottom - Top)
            If (Area < SmallerArea) {
                SmallerArea := Area
                hChildWnd := A_LoopField
            }
        }
    }

    Return (hChildWnd == 0) ? hWnd : hChildWnd
}

; Details tab
LoadProperties:
    Gui Spy: ListView, %hPropInfo%
    LV_Delete()

    Callback := RegisterCallback("PropEnumProcEx", "F")
    DllCall("EnumPropsEx", "Ptr", g_hWnd, "Ptr", Callback, "UInt", lParam := 0)
Return

PropEnumProcEx(hWnd, lpszString, hData, dwData) {
    Global hPropInfo

    Property := StrGet(lpszString, "UTF-16")
    If (Property == "") {
        Property := lpszString . " (Atom)"
    }

    Gui Spy: ListView, %hPropInfo%
    LV_Add("", Property, Format("0x{:08X}", hData))

    Return True
}

LoadExtraInfo:
    Gui Spy: ListView, %hExtraInfo%

    LV_Delete()
    While (LV_GetText(foo, 0, 1)) {
        LV_DeleteCol(1)
    }

    WinGetClass Class, ahk_id %g_hWnd%

    If (Class == "Edit" || InStr(Class, "RICHEDIT")) {
        LV_InsertCol(1, "169", "Property")
        LV_InsertCol(2, "169", "Value")

        ControlGetText Text,, ahk_id %g_hWnd%
        Length := StrLen(Text) . " characters"
        ControlGet Lines, LineCount,,, ahk_id %g_hWnd%
        ControlGet CurLine, CurrentLine,,, ahk_id %g_hWnd%
        ControlGet CurCol, CurrentCol,,, ahk_id %g_hWnd%

        LV_Add("", "Length", Length)
        LV_Add("", "Current line", CurLine)
        LV_Add("", "Current column", CurCol)
        LV_Add("", "Line count", Lines)
        LV_Add("", "Text Limit", SendMsg(0xD5) . " bytes") ; EM_GETLIMITTEXT
        LV_Add("", "Modified", {0: "False", 1: "True"}[SendMsg(0xB8)]) ; EM_GETMODIFY
    }
    Else If (InStr(Class, "Scintilla")) {

        LV_InsertCol(1, "169", "Property")
        LV_InsertCol(2, "169", "Value")

        LexerName := Scintilla_GetLexerLanguage(g_hWnd)
        CodePage := SendMsg(2137) ; SCI_GETCODEPAGE
        Pos := SendMsg(2008)
        Line := SendMsg(2166, Pos)
        Char := SendMsg(2007, Pos)
        Size := FormatBytes(SendMsg(2006), Sep, "B", 0) . " bytes"
        SelSize := FormatBytes(SendMsg(2161, 0, 0) - 1, Sep, "B", 0) . " bytes"

        LV_Add("", "Lexer", SendMsg(4002) . (LexerName != "" ? " (" . LexerName . ")" : "")) ; SCI_GETLEXER
        LV_Add("", "Current position", Pos + 1) ; SCI_GETCURRENTPOS
        LV_Add("", "Char at position", Char . " (""" . Chr(Char) . """)") ; SCI_GETCHARAT
        LV_Add("", "Style at position", SendMsg(2010, Pos)) ; SCI_GETSTYLEAT
        LV_Add("", "Current line", Line + 1) ; SCI_LINEFROMPOSITION
        LV_Add("", "Position from line", SendMsg(2167, Line) + 1) ; SCI_POSITIONFROMLINE
        LV_Add("", "Line end position", SendMsg(2136, Line) + 1) ; SCI_GETLINEENDPOSITION
        LV_Add("", "Line length", SendMsg(2350, Line)) ; SCI_LINELENGTH
        LV_Add("", "Current column", SendMsg(2129, Pos) + 1) ; SCI_GETCOLUMN
        LV_Add("", "Line count", SendMsg(2154)) ; SCI_GETLINECOUNT
        LV_Add("", "Document size", Size) ; SCI_GETLENGTH
        LV_Add("", "File encoding", (CodePage == 65001 ? "UTF-8 (65001)" : CodePage)) ; SCI_GETCODEPAGE
        LV_Add("", "Modified", SendMsg(2159) ? "True" : "False") ; SCI_GETMODIFY
        LV_Add("", "Read only", SendMsg(2140) ? "True" : "False") ; SCI_GETREADONLY
        LV_Add("", "Wrap mode", SendMsg(2269)) ; SCI_GETWRAPMODE
        LV_Add("", "Tab width", SendMsg(2121)) ; SCI_GETTABWIDTH
        LV_Add("", "Indent with spaces", !SendMsg(2125) ? "True" : "False") ; SCI_GETUSETABS
        LV_Add("", "Show indentation guides", SendMsg(2133) ? "True" : "False") ; SCI_GETINDENTATIONGUIDES
        LV_Add("", "EOL mode", {0: "CRLF", 1: "CR", 2: "LF"}[SendMsg(2030)]) ; SCI_GETEOLMODE
        LV_Add("", "Paste convert EOL", SendMsg(2468) ? "True" : "False") ; SCI_GETPASTECONVERTENDINGS
        LV_Add("", "Overtype mode", SendMsg(2187) ? "1 (overtype)" : "0 (insert)") ; SCI_GETOVERTYPE
        LV_Add("", "Anchor position", SendMsg(2009) + 1) ; SCI_GETANCHOR
        LV_Add("", "Selection start", SendMsg(2143) + 1) ; SCI_GETSELECTIONSTART
        LV_Add("", "Selection end", SendMsg(2145) + 1) ; SCI_GETSELECTIONEND
        LV_Add("", "Selected text length", SelSize) ; SCI_GETSELTEXT
        LV_Add("", "Selection mode", SendMsg(2423)) ; SCI_GETSELECTIONMODE
        LV_Add("", "Selection is rectangular", SendMsg(2372) ? "True" : "False") ; SCI_SELECTIONISRECTANGLE
        LV_Add("", "Virtual space options", SendMsg(2597)) ; SCI_GETVIRTUALSPACEOPTIONS
        LV_Add("", "Rectangular selection modifier", SendMsg(2599)) ; SCI_GETRECTANGULARSELECTIONMODIFIER
        ; SCI_GETMOUSESELECTIONRECTANGULARSWITCH
        LV_Add("", "Mouse rectangular selection", SendMsg(2669) ? "True" : "False")
        LV_Add("", "Selection start line position", SendMsg(2424, Line) + 1) ; SCI_GETLINESELSTARTPOSITION
        LV_Add("", "Selection end line position", SendMsg(2425, Line) + 1) ; SCI_GETLINESELENDPOSITION
        LV_Add("", "Multiple selection", SendMsg(2564) ? "True" : "False") ; SCI_GETMULTIPLESELECTION
        ; SCI_GETADDITIONALSELECTIONTYPING
        LV_Add("", "Additional selection typing", SendMsg(2566) ? "True" : "False")
        LV_Add("", "Multipaste", SendMsg(2615)) ; SCI_GETMULTIPASTE
        LV_Add("", "Line height", SendMsg(2279, Line)) ; SCI_TEXTHEIGHT
        LV_Add("", "Baseline extra ascent", SendMsg(2526)) ; SCI_GETEXTRAASCENT
        LV_Add("", "Baseline extra descent", SendMsg(2528)) ; SCI_GETEXTRADESCENT
        LV_Add("", "Lines on screen", SendMsg(2370)) ; SCI_LINESONSCREEN
        LV_Add("", "First visible line", SendMsg(2152) + 1) ; SCI_GETFIRSTVISIBLELINE
        LV_Add("", "Current line wrap count", SendMsg(2235, Line)) ; SCI_WRAPCOUNT
        LV_Add("", "Mouse hover time", SendMsg(2265)) ; SCI_GETMOUSEDWELLTIME
        LV_Add("", "Word start position", SendMsg(2266, Pos, 1) + 1) ; SCI_WORDSTARTPOSITION
        LV_Add("", "Word end position", SendMsg(2267, Pos, 1) + 1) ; SCI_WORDENDPOSITION
        LV_Add("", "Autocomplete ignore case", SendMsg(2116) ? "True" : "False") ; SCI_AUTOCGETIGNORECASE
        LV_Add("", "Autocomplete list presorted", SendMsg(2661)) ; SCI_AUTOCGETORDER
        LV_Add("", "Autocomplete list max rows", SendMsg(2211)) ; SCI_AUTOCGETMAXHEIGHT
        LV_Add("", "Position before", SendMsg(2417, Pos) + 1) ; SCI_POSITIONBEFORE
        LV_Add("", "Position after", SendMsg(2418, Pos) + 1) ; SCI_POSITIONAFTER
        LV_Add("", "Current indicator", SendMsg(2501)) ; SCI_GETINDICATORCURRENT
        LV_Add("", "Target start", SendMsg(2191) + 1) ; SCI_GETTARGETSTART
        LV_Add("", "Target end", SendMsg(2193) + 1) ; SCI_GETTARGETEND
        LV_Add("", "Search flags", SendMsg(2199)) ; SCI_GETSEARCHFLAGS
        LV_Add("", "Error status", SendMsg(2383)) ; SCI_GETSTATUS
        LV_Add("", "Font quality", SendMsg(2612)) ; SCI_GETFONTQUALITY
        LV_Add("", "Technology (drawing API)", SendMsg(2631)) ; SCI_GETTECHNOLOGY
        LV_Add("", "Buffered drawing", SendMsg(2034) ? "True" : "False") ; SCI_GETBUFFEREDDRAW
        LV_Add("", "Zoom factor", SendMsg(2374)) ; SCI_GETZOOM
        LV_Add("", "Edge mode", SendMsg(2362)) ; SCI_GETEDGEMODE 
        LV_Add("", "Edge column", SendMsg(2360) + 1) ; SCI_GETEDGECOLUMN
        LV_Add("", "Scroll width", SendMsg(2275)) ; SCI_GETSCROLLWIDTH
        LV_Add("", "Scroll width tracking", SendMsg(2517) ? "True" : "False") ; SCI_GETSCROLLWIDTHTRACKING
        LV_Add("", "End at last line", SendMsg(2278) ? "True" : "False") ; SCI_GETENDATLASTLINE
        LV_Add("", "View white space", SendMsg(2020)) ; SCI_GETVIEWWS
        LV_Add("", "White space size", SendMsg(2087)) ; SCI_GETWHITESPACESIZE
        LV_Add("", "View EOL characters", SendMsg(2355) ? "True" : "False") ; SCI_GETVIEWEOL
        LV_Add("", "Caret width", SendMsg(2189)) ; SCI_GETCARETWIDTH
        LV_Add("", "Caret blinking rate", SendMsg(2075) . " ms") ; SCI_GETCARETPERIOD
        LV_Add("", "Markers in current line", SendMsg(2046, Line)) ; SCI_MARKERGET
        LV_Add("", "Automatic fold", SendMsg(2664)) ; SCI_GETAUTOMATICFOLD
        LV_Add("", "All lines visible", SendMsg(2236) ? "True" : "False") ; SCI_GETALLLINESVISIBLE
        ;LV_Add("", "", SendMsg()) ;

        Loop 5 { ; The maximum number of margins
            i := A_Index - 1
            LV_Add("", "Margin " . A_Index . " - type, width, mask"
            , SendMsg(2241, i) . ", " . SendMsg(2243, i) . ", " . SendMsg(2245, i))
            ; SCI_GETMARGINTYPEN, SCI_GETMARGINWIDTHN, SCI_GETMARGINMASKN
        }

    }
    Else If (Class == "ToolbarWindow32") {

        LV_InsertCol(1, "41", "Index")
        LV_InsertCol(2, "85", "Command ID")
        LV_InsertCol(3, "212", "Button Text")

        Items := GetToolbarItems(g_hWnd)
        For Each, Item in Items {
            LV_Add("", A_Index, Item.ID, Item.String)
        }
    }
    Else If (Class == "SysHeader32") {

        LV_InsertCol(1, "42", "Index")
        LV_InsertCol(2, "48", "Width")
        LV_InsertCol(3, "248", "Text")

        Items := GetHeaderInfo(g_hWnd)
        For Each, Item in Items {
            LV_Add("", A_Index, Item.Width, Item.Text)
        }
    }
    Else If (Class == "msctls_progress32") {

        LV_InsertCol(1, "169", "Property")
        LV_InsertCol(2, "169", "Value")

        LV_Add("", "Range", SendMsg(0x407, 1) . " - " . SendMsg(0x407, 0)) ; PBM_GETRANGE
        LV_Add("", "Position", SendMsg(0x408)) ; PBM_GETPOS
        LV_Add("", "Step increment", SendMsg(0x40D)) ; PBM_GETSTEP
        LV_Add("", "State", {1: "Normal", 2: "Error", 3: "Paused"}[SendMsg(0x411)]) ; PBM_GETSTATE
    }
    Else If (Class ~= "ListBox" || Class ~= "ComboBox") {

        LV_InsertCol(1, "38", "Line")
        LV_InsertCol(2, "300", "Text")

        ControlGet ItemList, List,,, ahk_id %g_hWnd%
        Loop Parse, ItemList, `n
        {
            LV_Add("", A_Index, A_LoopField)
        }
    }
    Else If (Class == "msctls_statusbar32") {

        LV_InsertCol(1, "38", "Part")
        LV_InsertCol(2, "300", "Text")

        SB_Text := GetStatusBarText(g_hWnd)
        Loop Parse, SB_Text, |
        {
            LV_Add("", A_Index, A_LoopField)
        }
    }
    Else If (Class == "SysTabControl32") {

        LV_InsertCol(1, "42", "Index")
        LV_InsertCol(2, "296", "Text")

        Tabs := ControlGetTabs(g_hWnd)
        Loop % Tabs.Length() {
            LV_Add("", A_Index, Tabs[A_Index])
        }
    }
    Else If (Class == "SysListView32") {

        SendMessage 0x101F, 0, 0,, ahk_id %g_hWnd% ; LVM_GETHEADER
        hHeader := ErrorLevel
        SendMessage 0x1200, 0, 0,, ahk_id %hHeader% ; HDM_GETITEMCOUNT
        Columns := ErrorLevel + 1

        Loop %Columns% {
            ColTitle := A_Index == 1 ? "Index" : "Column " . A_Index - 1
            LV_InsertCol(A_Index, "", ColTitle)
        }

        ControlGet ItemList, List,,, ahk_id %g_hWnd%
        Loop Parse, ItemList, `n
        {
            Items := StrSplit(A_LoopField, A_Tab)
            LV_Add("", A_Index, Items*)
        }

        Loop %Columns% {
            LV_ModifyCol(A_Index, "AutoHdr")
        }
    }

    ; GetMenu return value: If the window is a child window, the return value is undefined.
    If (!IsChild(g_hWnd) && hMenu := GetMenu(g_hWnd)) {
        GuiControl Enable, %hBtnMenu%
    } Else {
        GuiControl Disable, %hBtnMenu%
    }
Return

SendMsg(Message, wParam := 0, lParam := 0) {
    SendMessage %Message%, %wParam%, %lParam%,, ahk_id %g_hWnd%
    Return ErrorLevel
}

Screenshot:
    If (!WinExist("ahk_id" . g_hWnd)) {
        Gui Spy: +OwnDialogs
        MsgBox 0x40010, Error, Window no longer exists.
        Return
    }

    If (IsChild(g_hWnd)) {
        WinActivate % "ahk_id" . GetAncestor(g_hWnd)
        Sleep 100
        If (g_ShowBorder) {
            ShowBorder(g_hWnd, -1, g_BorderColor, g_BorderWidth)
            Sleep 100
            Send !{PrintScreen}
            Sleep 200
        } Else {
            CaptureWindow(hSpyWnd, g_hWnd)
        }
    } Else {
        WinActivate ahk_id %g_hWnd%
        Sleep 100
        Send !{PrintScreen}
    }

    Loop 4 {
        Index := A_Index + 90
        Gui %Index%: Destroy
    }

    WinActivate ahk_id %hSpyWnd%
    Gui Spy: +OwnDialogs
    MsgBox 0x40040, %AppName%, Content copied to the clipboard.
Return

CaptureWindow(hwndOwner, hwnd) {
    VarSetCapacity(RECT, 16, 0)
    DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", &RECT)
    width  := NumGet(RECT, 8, "Int")  - NumGet(RECT, 0, "Int")
    height := NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")

    hdc    := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdc, "UPtr")
    hBmp   := DllCall("CreateCompatibleBitmap", "Ptr", hdc, "Int", width, "Int", height, "UPtr")
    hdcOld := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hBmp)

    DllCall("BitBlt", "Ptr", hdcMem
        , "Int", 0, "Int", 0, "Int", width, "Int", height
        , "Ptr", hdc, "Int", Numget(RECT, 0, "Int"), "Int", Numget(RECT, 4, "Int")
        , "UInt", 0x00CC0020) ; SRCCOPY

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hdcOld)

    DllCall("OpenClipboard", "Ptr", hwndOwner) ; Clipboard owner
    DllCall("EmptyClipboard")
    DllCall("SetClipboardData", "UInt", 0x2, "Ptr", hBmp) ; CF_BITMAP
    DllCall("CloseClipboard")

    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)

    Return True
}

GetToolbarItems(hToolbar) {
    WinGet PID, PID, ahk_id %hToolbar%

    If !(hProc := DllCall("OpenProcess", "UInt", 0x438, "Int", False, "UInt", PID, "Ptr")) {
        Return
    }

    If (A_Is64bitOS) {
        Try DllCall("IsWow64Process", "Ptr", hProc, "Int*", Is32bit := true)
    } Else {
        Is32bit := True
    }

    RPtrSize := Is32bit ? 4 : 8
    TBBUTTON_SIZE := 8 + (RPtrSize * 3)

    SendMessage 0x418, 0, 0,, ahk_id %hToolbar% ; TB_BUTTONCOUNT
    ButtonCount := ErrorLevel

    IDs := [] ; Command IDs
    Loop %ButtonCount% {
        Address := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "UPtr", TBBUTTON_SIZE, "UInt", 0x1000, "UInt", 4, "Ptr")

        SendMessage 0x417, % A_Index - 1, Address,, ahk_id %hToolbar% ; TB_GETBUTTON
        If (ErrorLevel == 1) {
            VarSetCapacity(TBBUTTON, TBBUTTON_SIZE, 0)
            DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", Address, "Ptr", &TBBUTTON, "UPtr", TBBUTTON_SIZE, "Ptr", 0)
            IDs.Push(NumGet(&TBBUTTON, 4, "Int"))
        }

        DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", Address, "UPtr", 0, "UInt", 0x8000) ; MEM_RELEASE
    }

    ToolbarItems := []
    Loop % IDs.Length() {
        ButtonID := IDs[A_Index]
        ;SendMessage 0x44B, %ButtonID% , 0,, ahk_id %hToolbar% ; TB_GETBUTTONTEXTW
        ;BufferSize := ErrorLevel * 2
        BufferSize := 128

        Address := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "UPtr", BufferSize, "UInt", 0x1000, "UInt", 4, "Ptr")

        SendMessage 0x44B, %ButtonID%, Address,, ahk_id %hToolbar% ; TB_GETBUTTONTEXTW

        VarSetCapacity(Buffer, BufferSize, 0)
        DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", Address, "Ptr", &Buffer, "UPtr", BufferSize, "Ptr", 0)

        ToolbarItems.Push({"ID": IDs[A_Index], "String": Buffer})

        DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", Address, "UPtr", 0, "UInt", 0x8000) ; MEM_RELEASE
    }

    DllCall("CloseHandle", "Ptr", hProc)

    Return ToolbarItems
}

LoadWindowsTab:
    GoSub LoadChildList
    GoSub LoadSiblingList

    hParent := GetParent(g_hWnd)
    ParentClass := (hParent) ? " (" GetClassName(hParent) . ")" : ""
    ParentLink := "<a>" . Format("0x{:08X}", hParent) . "</a>" . ParentClass
    GuiControl, Spy:, ParentLink, %ParentLink%

    hOwner := GetOwner(g_hWnd)
    OwnerClass := (hOwner) ? " (" GetClassName(hOwner) . ")" : ""
    OwnerLink := "<a>" . Format("0x{:08X}", hOwner) . "</a>" . OwnerClass
    GuiControl, Spy:, OwnerLink, %OwnerLink%
Return

LinkToHandle:
    GuiControlGet LinkText, Spy:, %A_GuiControl%
    If (RegExMatch(LinkText, "(0x\w+)", Match)) {
        ShowWindowInfoIfExist(Match)
    }
Return

WindowsTabHandler:
    If (A_GuiEvent == "N") {
        Code := NumGet(A_EventInfo + 0, A_PtrSize * 2, "Int")
        If (Code == -551) { ; TCN_SELCHANGE
            SendMessage 0x130B, 0, 0,, ahk_id %hWindowsTab% ; TCM_GETCURSEL
            nTab := Errorlevel + 1

            If (nTab == 1) {
                GuiControl Hide, %hSiblingList%
                GuiControl Show, %hChildList%
            } Else {
                GuiControl Hide, %hChildList%
                GuiControl Show, %hSiblingList%
            }
        }
    }
Return

LoadChildList:
    Gui Spy: ListView, %hChildList%
    LV_Delete()

    WinGet ChildList, ControlListHwnd, ahk_id %g_hWnd%
    Loop Parse, ChildList, `n
    {
        If (GetParent(A_LoopField) != g_hWnd) {
            Continue
        }

        WinGetClass Class, ahk_id %A_LoopField%
        ControlGetText Text,, ahk_id %A_LoopField%
        LV_Add("", Format("0x{:08X}", A_LoopField), Class, Text)
    }
Return

LoadSiblingList:
    Gui Spy: ListView, %hSiblingList%
    LV_Delete()

    hParent := GetParent(g_hWnd)

    If (IsChild(g_hWnd)) {
        WinGet SiblingList, ControlListHwnd, ahk_id %hParent%
        Loop Parse, SiblingList, `n
        {
            If (A_LoopField == g_hWnd) {
                Continue
            }

            If (GetParent(A_LoopField) != hParent) {
                Continue
            }

            WinGetClass Class, ahk_id %A_LoopField%
            ControlGetText Text,, ahk_id %A_LoopField%
            LV_Add("", Format("0x{:08X}", A_LoopField), Class, Text)
        }

    } Else {
        WinGet WinList, List, % (hParent == 0) ? "" : "ahk_id " . hParent
        Loop %WinList% {
            hWnd := WinList%A_Index%

            If (hWnd == g_hWnd) {
                Continue
            }

            WinGetClass Class, ahk_id %hWnd%
            WinGetTitle Text, ahk_id %hWnd%
            LV_Add("", Format("0x{:08X}", hWnd), Class, Text)
        }
    }
Return

ChildListHandler:
SiblingListHandler:
    Gui Spy: ListView, % (A_ThisLabel == "ChildListHandler") ? hChildList : hSiblingList
    If (A_GuiEvent != "ColClick") {
        LV_GetText(hWnd, LV_GetNext())
        ShowWindowInfoIfExist(hWnd)
    }
Return

OnWM_KEYDOWN(wParam, lParam, msg, hWnd) {
    Global

    If (wParam == 112) { ; F1
        GoSub ShowHelp

    } Else If (wParam == 113) { ; F2
        If (hParent := GetParent(g_hWnd)) {
            g_hWnd := hParent
            ShowWindowInfo()
        }

    } Else If (wParam == 114) { ; F3
        GoSub ShowFindDlg

    } Else If (wParam == 115) { ; F4
        GoSub ShowTree

    } Else If (wParam == 116) { ; F5
        If (WinActive("ahk_id" . hTreeWnd)) {
            Return
        }

        Gui Spy: Submit, NoHide
        ShowWindowInfoIfExist(EdtHandle)

    } Else If (wParam == 117) { ; F6
        GoSub FlashWindow

    } Else If (wParam == 118) { ; F7
        GoSub ShowXYWHDlg

    } Else If (wParam == 119) { ; F8
        GoSub CopyToClipboard

    } Else If (wParam == 120) { ; F9
        GoSub Screenshot
    }
}

UpdateTitleBar:
    WinGetClass Class, ahk_id %g_hWnd%
    hWnd := Format("0x{:X}", g_hWnd)
    WinSetTitle ahk_id %hSpyWnd%,, %AppName% [%hWnd%`, %Class%]
Return

; https://autohotkey.com/board/topic/70727-ahk-l-controlgettabs/
ControlGetTabs(hTab) {
    Static MAX_TEXT_LENGTH := 260
         , MAX_TEXT_SIZE := MAX_TEXT_LENGTH * (A_IsUnicode ? 2 : 1)

    WinGet PID, PID, ahk_id %hTab%

    ; Open the process for read/write and query info.
    ; PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_QUERY_INFORMATION
    If !(hProc := DllCall("OpenProcess", "UInt", 0x438, "Int", False, "UInt", PID, "Ptr")) {
        Return
    }

    ; Should we use the 32-bit struct or the 64-bit struct?
    If (A_Is64bitOS) {
        Try DllCall("IsWow64Process", "Ptr", hProc, "Int*", Is32bit := true)
    } Else {
        Is32bit := True
    }

    RPtrSize := Is32bit ? 4 : 8
    TCITEM_SIZE := 16 + RPtrSize * 3

    ; Allocate a buffer in the (presumably) remote process.
    remote_item := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0
                         , "uPtr", TCITEM_SIZE + MAX_TEXT_SIZE
                         , "UInt", 0x1000, "UInt", 4, "Ptr") ; MEM_COMMIT, PAGE_READWRITE
    remote_text := remote_item + TCITEM_SIZE

    ; Prepare the TCITEM structure locally.
    VarSetCapacity(TCITEM, TCITEM_SIZE, 0)
    NumPut(1, TCITEM, 0, "UInt") ; mask (TCIF_TEXT)
    NumPut(remote_text, TCITEM, 8 + RPtrSize) ; pszText
    NumPut(MAX_TEXT_LENGTH, TCITEM, 8 + RPtrSize * 2, "Int") ; cchTextMax

    ; Write the local structure into the remote buffer.
    DllCall("WriteProcessMemory", "Ptr", hProc, "Ptr", remote_item, "Ptr", &TCITEM, "UPtr", TCITEM_SIZE, "Ptr", 0)

    Tabs := []
    VarSetCapacity(TabText, MAX_TEXT_SIZE)

    SendMessage 0x1304, 0, 0,, ahk_id %hTab% ; TCM_GETITEMCOUNT
    Loop % (ErrorLevel != "FAIL") ? ErrorLevel : 0 {
        ; Retrieve the item text.
        SendMessage, % (A_IsUnicode) ? 0x133C : 0x1305, A_Index - 1, remote_item,, ahk_id %hTab% ; TCM_GETITEM
        If (ErrorLevel == 1) { ; Success
            DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", remote_text, "Ptr", &TabText, "UPtr", MAX_TEXT_SIZE, "Ptr", 0)
        } Else {
            TabText := ""
        }

        Tabs[A_Index] := TabText
    }

    ; Release the remote memory and handle.
    DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", remote_item, "UPtr", 0, "UInt", 0x8000) ; MEM_RELEASE
    DllCall("CloseHandle", "Ptr", hProc)

    Return Tabs
}

SetDHW:
    g_DetectHidden := !g_DetectHidden
Return

SetMinimize:
    g_Minimize := !g_Minimize
Return

SetExplorerTheme(hWnd) {
    DllCall("UxTheme.dll\SetWindowTheme", "Ptr", hWnd, "WStr", "Explorer", "Ptr", 0)
}

SetButtonIcon(hButton, File, Index := 1) {
    himl := DllCall("ImageList_Create", "Int", 16, "Int", 16, "UInt", 0x20, "Int", 1, "Int", 1, "Ptr") ; ILC_COLOR32
    IL_Add(himl, File, Index)
    VarSetCapacity(BUTTON_IMAGELIST, 20 + A_PtrSize, 0)
    NumPut(himl, BUTTON_IMAGELIST, 0, "Ptr")
    NumPut(4, BUTTON_IMAGELIST, 16 + A_PtrSize, "UInt") ; Alignment (BUTTON_IMAGELIST_ALIGN_CENTER)
    SendMessage 0x1602, 0, &BUTTON_IMAGELIST,, ahk_id %hButton% ; BCM_SETIMAGELIST
    Return ErrorLevel
}

ShowXYWHDlg:
    Gui XYWH: New, LabelXYWH
    Gui Font, s9, Segoe UI
    Gui Color, White

    Gui Add, GroupBox, x10 y6 w145 h105, Relative to:
    Gui Add, Radio, vClientCoords gSetXYWH x25 y27 w120 h23 +Checked, Client area
    Gui Add, Radio, vWindowCoords gSetXYWH x25 y51 w120 h23, Window border
    Gui Add, Radio, vScreenCoords gSetXYWH x25 y75 w120 h23, Screen coords

    Gui Add, GroupBox, x166 y5 w253 h105
    Gui Add, Text, x182 y31 w26 h23 +0x200, X:
    Gui Add, Edit, vEdtX x209 y31 w70 h21
    Gui Add, UpDown, gMoveWindow Range-64000-64000 +0x80
    Gui Add, Text, x303 y31 w26 h23 +0x200, Y:
    Gui Add, Edit, vEdtY x330 y31 w70 h21
    Gui Add, UpDown, gMoveWindow Range-64000-64000 +0x80
    Gui Add, Text, x182 y69 w26 h23 +0x200, W:
    Gui Add, Edit, vEdtW x209 y69 w70 h21
    Gui Add, UpDown, gMoveWindow Range-64000-64000 +0x80
    Gui Add, Text, x303 y69 w26 h23 +0x200, H:
    Gui Add, Edit, vEdtH x330 y69 w70 h21
    Gui Add, UpDown, gMoveWindow Range-64000-64000 +0x80

    Gui Add, Text, x-1 y121 w460 h49 +0x200 -Background +Border
    Gui Add, Button, gResetXYWH x9 y133 w88 h25, &Reset
    Gui Add, Button, gMoveWindow x235 y133 w88 h25 +Default, &Apply
    Gui Add, Button, gXYWHClose x331 y133 w88 h25, &Close

    Gui Show, w429 h170, Position and Size

    g_NewXYWH := True
    GoSub SetXYWH

    If (IsChild(g_hWnd)) {
        GuiControl Enable, ClientCoords
        GuiControl Enable, WindowCoords
        GuiControl Enable, ScreenCoords
    } Else {
        GuiControl Disable, ClientCoords
        GuiControl Disable, WindowCoords
        GuiControl Disable, ScreenCoords
        GuiControl,, ScreenCoords, 1
    }
Return

XYWHEscape:
XYWHClose:
    Gui XYWH: Destroy
Return

SetXYWH:
    Gui XYWH: Submit, NoHide

    If (IsChild(g_hWnd)) {
        If (ClientCoords) {
            GetWindowPos(g_hWnd, X, Y, W, H)
        } Else If (WindowCoords) {
            ControlGetPos X, Y, W, H,, ahk_id %g_hWnd%
        } Else If (ScreenCoords) {
            WinGetPos X, Y, W, H, ahk_id %g_hWnd%
        }
    } Else { ; Top-level window
        WinGetPos X, Y, W, H, ahk_id %g_hWnd%
    }

    GuiControl, XYWH:, EdtX, %X%
    GuiControl, XYWH:, EdtY, %Y%
    GuiControl, XYWH:, EdtW, %W%
    GuiControl, XYWH:, EdtH, %H%

    If (g_NewXYWH) {
        g_BackupXYWH := [X, Y, W, H]
        g_NewXYWH := False
    }
Return

MoveWindow:
    Gui XYWH: Submit, NoHide

    If (IsChild(g_hWnd)) {

        If (ClientCoords) {
            SetWindowPos(g_hWnd, EdtX, EdtY, EdtW, EdtH, 0, 0x14) ; SWP_NOACTIVATE | SWP_NOZORDER
        } Else If (WindowCoords) {
            ControlMove,, %EdtX%, %EdtY%, %EdtW%, %EdtH%, ahk_id %g_hWnd%
        } Else If (ScreenCoords) {
            VarSetCapacity(POINT, 8, 0)
            NumPut(EdtX, POINT, 0)
            NumPut(EdtY, POINT, 4)
            DllCall("ScreenToClient", "Ptr", GetParent(g_hWnd), "Ptr", &POINT) ; PARENT
            X := NumGet(POINT, 0)
            Y := NumGet(POINT, 4)
            SetWindowPos(g_hWnd, X, Y, EdtW, EdtH, 0, 0x14) ; SWP_NOACTIVATE | SWP_NOZORDER
        }
    } Else {
        WinMove ahk_id %g_hWnd%,, %EdtX%, %EdtY%, %EdtW%, %EdtH%
    }

    WinSet Redraw,, ahk_id %g_hWnd%
Return

ResetXYWH:
    Gui XYWH: Submit, NoHide

    If (IsChild(g_hWnd)) {
        GuiControl, XYWH:, ClientCoords, 1
    }

    GuiControl,, EdtX, % g_BackupXYWH[1]
    GuiControl,, EdtY, % g_BackupXYWH[2]
    GuiControl,, EdtW, % g_BackupXYWH[3]
    GuiControl,, EdtH, % g_BackupXYWH[4]
    GoSub MoveWindow
Return

OnWM_RBUTTONDOWN(wParam, lParam, msg, hWnd) {
    Global
    If (hWnd == hLbxStyles || hWnd == hLbxExStyles || hWnd == hLbxExtraStyles) {
        SendMessage 0x1A9, 0, lParam,, ahk_id %hWnd% ; LB_ITEMFROMPOINT
        Index := ErrorLevel
        SendMessage 0x18A, %Index%, 0,, ahk_id %hWnd% ; LB_GETTEXTLEN
        Len := ErrorLevel
        VarSetCapacity(LB_Text, Len << !!A_IsUnicode, 0)
        SendMessage 0x189, %Index%, % &LB_Text,, ahk_id %hWnd% ; LB_GETTEXT
        Const := StrSplit(StrGet(&LB_Text, Len), "`t")[1]
        Desc := StrReplace(oStyles[Const].Desc, "\n", "`n")
        GuiControl,, GrpDesc, %Const%
        GuiControl,, TxtDesc, %Desc%
    }
}

ShowWindowInfoIfExist(hWnd) {
    If (IsWindow(hWnd)) {
        g_hWnd := hWnd
        ShowWindowInfo()
    } Else {
        Gui Spy: +OwnDialogs
        MsgBox 0x40010, %AppName%, Invalid window handle.
    }
}

; Returns an object containing the text and width of each item of a remote SysHeader32 control
GetHeaderInfo(hHeader) {
    Static MAX_TEXT_LENGTH := 260
         , MAX_TEXT_SIZE := MAX_TEXT_LENGTH * (A_IsUnicode ? 2 : 1)

    WinGet PID, PID, ahk_id %hHeader%

    ; Open the process for read/write and query info.
    ; PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_QUERY_INFORMATION
    If !(hProc := DllCall("OpenProcess", "UInt", 0x438, "Int", False, "UInt", PID, "Ptr")) {
        Return
    }

    ; Should we use the 32-bit struct or the 64-bit struct?
    If (A_Is64bitOS) {
        Try DllCall("IsWow64Process", "Ptr", hProc, "Int*", Is32bit := True)
    } Else {
        Is32bit := True
    }

    RPtrSize := Is32bit ? 4 : 8
    cbHDITEM := (4 * 6) + (RPtrSize * 6)

    ; Allocate a buffer in the remote process.
    remote_item := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0
                         , "UPtr", cbHDITEM + MAX_TEXT_SIZE
                         , "UInt", 0x1000, "UInt", 4, "Ptr") ; MEM_COMMIT, PAGE_READWRITE
    remote_text := remote_item + cbHDITEM

    ; Prepare the HDITEM structure locally.
    VarSetCapacity(HDITEM, cbHDITEM, 0)
    NumPut(0x3, HDITEM, 0, "UInt") ; mask (HDI_WIDTH | HDI_TEXT)
    NumPut(remote_text, HDITEM, 8, "Ptr") ; pszText
    NumPut(MAX_TEXT_LENGTH, HDITEM, 8 + RPtrSize * 2, "Int") ; cchTextMax

    ; Write the local structure into the remote buffer.
    DllCall("WriteProcessMemory", "Ptr", hProc, "Ptr", remote_item, "Ptr", &HDITEM, "UPtr", cbHDITEM, "Ptr", 0)

    HDInfo := {}
    VarSetCapacity(HDText, MAX_TEXT_SIZE)

    SendMessage 0x1200, 0, 0,, ahk_id %hHeader% ; HDM_GETITEMCOUNT
    Loop % (ErrorLevel != "FAIL") ? ErrorLevel : 0 {
        ; Retrieve the item text.
        SendMessage, % (A_IsUnicode) ? 0x120B : 0x1203, A_Index - 1, remote_item,, ahk_id %hHeader% ; HDM_GETITEMW
        If (ErrorLevel == 1) { ; Success
            DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", remote_item, "Ptr", &HDITEM, "UPtr", cbHDITEM, "Ptr", 0)
            DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", remote_text, "Ptr", &HDText, "UPtr", MAX_TEXT_SIZE, "Ptr", 0)
        } Else {
            HDText := ""
        }

        HDInfo.Push({"Width": NumGet(HDITEM, 4, "UInt"), "Text": HDText})
    }

    ; Release the remote memory and handle.
    DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", remote_item, "UPtr", 0, "UInt", 0x8000) ; MEM_RELEASE
    DllCall("CloseHandle", "Ptr", hProc)

    Return HDInfo
}

SetMouseCoordMode:
    GuiControlGet g_MouseCoordMode, Spy:, MouseCoordMode
Return

GetClientCoords(hWnd, ByRef x, ByRef y) {
    VarSetCapacity(POINT, 8, 0)
    NumPut(x, POINT, 0, "Int")
    NumPut(y, POINT, 4, "Int")
    hParent := GetParent(hWnd)
    DllCall("ScreenToClient", "Ptr", (hParent == 0 ? hWnd : hParent), "Ptr", &POINT)
    x := NumGet(POINT, 0, "Int")
    y := NumGet(POINT, 4, "Int")
}

GetWindowCoords(hWnd, ByRef x, ByRef y) {
    hParent := GetParent(hWnd)
    WinGetPos px, py,,, % "ahk_id" . (hParent == 0 ? hWnd : hParent)
    x := x - px
    y := y - py
}

; fnbar: 0 = horizontal, 1 = vertical, 2 = hWnd is a scroll bar
GetScrollInfo(hWnd, fnBar := 1) {
    Local o := {}
    NumPut(VarSetCapacity(SCROLLINFO, 28, 0), SCROLLINFO, 0, "UInt")
    NumPut(0x1F, SCROLLINFO, 4, "UInt") ; fMask: SIF_ALL
    DllCall("GetScrollInfo", "Ptr", hWnd, "Int", fnBar, "Ptr", &SCROLLINFO)
    o.Min  := NumGet(SCROLLINFO, 8, "Int")
    o.Max  := NumGet(SCROLLINFO, 12, "Int")
    o.Page := NumGet(SCROLLINFO, 16, "UInt")
    o.Pos  := NumGet(SCROLLINFO, 20, "Int")
    Return o
}

ShowScrollBarInfo:
    V := H := "No"
    WinGet Style, Style, ahk_id %g_hWnd%
    WinGetClass Class, ahk_id %g_hWnd%

    If (Class == "ScrollBar") {
        If (Style & 1) { ; SBS_VERT
            V := "Yes"
            VSB := GetScrollInfo(g_hWnd, 2)
        } Else {
            H := "Yes"
            HSB := GetScrollInfo(g_hWnd, 2)
        }
    } Else {
        If (Style & 0x200000) { ; WS_VSCROLL
            V := "Yes"
        }
        If (Style & 0x100000) { ; WS_HSCROLL
            H := "Yes"
        }

        HSB := GetScrollInfo(g_hWnd, 0)
        VSB := GetScrollInfo(g_hWnd, 1)
    }

    HPercent := (HSB.Pos) ? " (" . Round(HSB.Pos / (HSB.Max - HSB.Min) * 100) . "%)" : ""
    VPercent := (VSB.Pos) ? " (" . Round(VSB.Pos / (VSB.Max - VSB.Min) * 100) . "%)" : ""

    Gui ScrollInfo: New, LabelScrollInfo hWndhScrollInfo -MinimizeBox OwnerSpy
    SetWindowIcon(hScrollInfo, ResDir . "\TreeIcons.icl", 31)
    Gui Font, s9, Segoe UI
    Gui Color, White
    Gui Add, CheckBox, w0 y0

    Gui Add, GroupBox, x15 y13 w148 h152, Horizontal Scrollbar
    Gui Add, Text, x24 y32 w60 h23 +0x200, Visible:
    Gui Add, Edit, x86 y36 w60 h21 -E0x200, %H%
    Gui Add, Text, x24 y57 w60 h23 +0x200, Minimum:
    Gui Add, Edit, x86 y61 w60 h21 -E0x200, % HSB.Min
    Gui Add, Text, x24 y82 w60 h23 +0x200, Maximum:
    Gui Add, Edit, x86 y86 w60 h21 -E0x200, % HSB.Max
    Gui Add, Text, x24 y107 w60 h23 +0x200, Position:
    Gui Add, Edit, x86 y111 w70 h21 -E0x200, % HSB.Pos . HPercent
    Gui Add, Text, x24 y132 w60 h23 +0x200, Page size:
    Gui Add, Edit, x86 y136 w60 h21 -E0x200, % HSB.Page

    Gui Add, GroupBox, x178 y13 w148 h152, Vertical Scrollbar
    Gui Add, Text, x188 y32 w56 h23 +0x200, Visible:
    Gui Add, Edit, x250 y36 w60 h21 -E0x200, %V%
    Gui Add, Text, x188 y57 w56 h23 +0x200, Minimum:
    Gui Add, Edit, x250 y61 w60 h21 -E0x200, % VSB.Min
    Gui Add, Text, x188 y82 w56 h23 +0x200, Maximum:
    Gui Add, Edit, x250 y86 w60 h21 -E0x200, % VSB.Max
    Gui Add, Text, x188 y107 w56 h23 +0x200, Position:
    Gui Add, Edit, x250 y111 w70 h21 -E0x200, % VSB.Pos . VPercent
    Gui Add, Text, x188 y132 w56 h23 +0x200, Page size:
    Gui Add, Edit, x250 y136 w60 h21 -E0x200, % VSB.Page

    Gui Add, Text, x-1 y180 w343 h50 -Background +Border
    Gui Add, Button, gScrollInfoClose x247 y193 w84 h24 +Default, &OK

    WinGetPos, X, Y,,, ahk_id %hSpyWnd%
    x += 30
    y += 109
    Gui Show, x%x% y%y% w341 h229, Scrollbars
Return

ScrollInfoEscape:
ScrollInfoClose:
    Gui ScrollInfo: Destroy
Return

GetSysColorName(Value) {
    Static SysColors := {0: "COLOR_SCROLLBAR"
    , 1: "COLOR_BACKGROUND"
    , 2: "COLOR_ACTIVECAPTION"
    , 3: "COLOR_INACTIVECAPTION"
    , 4: "COLOR_MENU"
    , 5: "COLOR_WINDOW"
    , 6: "COLOR_WINDOWFRAME"
    , 7: "COLOR_MENUTEXT"
    , 8: "COLOR_WINDOWTEXT"
    , 9: "COLOR_CAPTIONTEXT"
    , 10: "COLOR_ACTIVEBORDER"
    , 11: "COLOR_INACTIVEBORDER"
    , 12: "COLOR_APPWORKSPACE"
    , 13: "COLOR_HIGHLIGHT"
    , 14: "COLOR_HIGHLIGHTTEXT"
    , 15: "COLOR_BTNFACE"
    , 16: "COLOR_BTNSHADOW"
    , 17: "COLOR_GRAYTEXT"
    , 18: "COLOR_BTNTEXT"
    , 19: "COLOR_INACTIVECAPTIONTEXT"
    , 20: "COLOR_BTNHIGHLIGHT"
    , 21: "COLOR_3DDKSHADOW"
    , 22: "COLOR_3DLIGHT"
    , 23: "COLOR_INFOTEXT"
    , 24: "COLOR_INFOBK"
    , 26: "COLOR_HOTLIGHT"
    , 27: "COLOR_GRADIENTACTIVECAPTION"
    , 28: "COLOR_GRADIENTINACTIVECAPTION"
    , 29: "COLOR_MENUHILIGHT"
    , 30: "COLOR_MENUBAR"}

    Color := SysColors[Value]
    Return (Color == "") ? Value : Color
}

GetWindowPos(hWnd, ByRef X, ByRef Y, ByRef W, ByRef H) {
    VarSetCapacity(RECT, 16, 0)
    DllCall("GetWindowRect", "Ptr", hWnd, "Ptr", &RECT)
    DllCall("MapWindowPoints", "Ptr", 0, "Ptr", GetParent(hWnd), "Ptr", &RECT, "UInt", 2)
    X := NumGet(RECT, 0, "Int")
    Y := NumGet(RECT, 4, "Int")
    w := NumGet(RECT, 8, "Int") - X
    H := NumGet(RECT, 12, "Int") - Y
}

FindToolHandler:
    If (g_Minimize) {
        WinMove ahk_id %hSpyWnd%,,,,, 78
        g_Minimized := True
    }

    Dragging := True

    GuiControl,, %hFindTool%, %Bitmap2%

    DllCall("SetCapture", "Ptr", hSpyWnd)
    hOldCursor := DllCall("SetCursor", "Ptr", hCrossHair, "Ptr")
Return

OnWM_MOUSEMOVE(wParam, lParam, msg, hWnd) {
    Static hOldWnd := 0

    If (Dragging) {
        MouseGetPos x, y, hWin, hCtl, 2

        g_hWnd := (hCtl == "") ? hWin : hCtl

        If (g_MouseCoordMode != "Screen") {
            SendMessage 0x84, 0, % y << 16 | x,, ahk_id %hWnd% ; WM_NCHITTEST
            HitTest := ErrorLevel

            If (HitTest == 1 || hCtl != "") { ; 1 = HTCLIENT
                If (g_MouseCoordMode == "Client") {
                    GetClientCoords(g_hWnd, x, y)
                } Else If (g_MouseCoordMode == "Window") {
                    GetWindowCoords(g_hWnd, x, y)
                }
            }
        }

        GuiControl, Spy:, EdtCursor, %x%, %y%

        If (g_DetectHidden) {
            g_hWnd := ControlFromPoint(x, y, g_hWnd)
        }

        If (g_hWnd != hOldWnd && !IsBorder(g_hWnd)) {
            ShowBorder(g_hWnd, -1)
            If (IsChild(g_hWnd)) {
                MouseGetPos,,,, ClassNN
                LoadControlInfo(ClassNN)
            } Else {
                LoadWindowInfo()
            }
            GoSub UpdateTitleBar
        }

        hOldWnd := g_hWnd
    }
}

OnWM_LBUTTONUP(wParam, lParam, msg, hWnd) {
    If (Dragging) {
        Dragging := False

        DllCall("ReleaseCapture")
        DllCall("SetCursor", "Ptr", hOldCursor)
        GuiControl,, %hFindTool%, %Bitmap1%

        Loop 4 {
            Index := A_Index + 90
            Gui %Index%: Destroy
        }

        MouseGetPos,,,, ClassNN
        ShowWindowInfo()

        If (g_Minimized) {
            If (Workaround) {
                SendMessage 0x130C, 1, 0,, ahk_id %hTab% ; TCM_SETCURSEL
                SendMessage 0x1330, 0, 0,, ahk_id %hTab% ; TCM_SETCURFOCUS
                Sleep 0
                SendMessage 0x130C, 0, 0,, ahk_id %hTab% ; TCM_SETCURSEL
                Workaround := False
            }

            WinMove ahk_id %hSpyWnd%,,,,, 493
        }
    }
}

SetWindowIcon(hWnd, Filename, Index := 1) {
    Local hSmIcon := LoadPicture(Filename, "w16 Icon" . Index, ErrorLevel)
    SendMessage 0x80, 0, hSmIcon,, ahk_id %hWnd% ; WM_SETICON, ICON_SMALL
    Return ErrorLevel
}

GetWindowPlacement(hWnd) {
    VarSetCapacity(WINDOWPLACEMENT, 44, 0)
    NumPut(44, WINDOWPLACEMENT)
    DllCall("GetWindowPlacement", "Ptr", hWnd, "Ptr", &WINDOWPLACEMENT)
    Result := {}
    Result.x := NumGet(WINDOWPLACEMENT, 7 * 4, "UInt")
    Result.y := NumGet(WINDOWPLACEMENT, 8 * 4, "UInt")
    Result.w := NumGet(WINDOWPLACEMENT, 9 * 4, "UInt") - Result.x
    Result.h := NumGet(WINDOWPLACEMENT, 10 * 4, "UInt") - Result.y
    Result.showCmd := NumGet(WINDOWPLACEMENT, 8, "UInt")
    ; 1 = normal, 2 = minimized, 3 = maximized
    Return Result
}

GetWindowInfo(hWnd) {
    NumPut(VarSetCapacity(WINDOWINFO, 60, 0), WINDOWINFO)
    DllCall("GetWindowInfo", "Ptr", hWnd, "Ptr", &WINDOWINFO)
    wi := Object()
    wi.WindowX := NumGet(WINDOWINFO, 4, "Int")
    wi.WindowY := NumGet(WINDOWINFO, 8, "Int")
    wi.WindowW := NumGet(WINDOWINFO, 12, "Int") - wi.WindowX
    wi.WindowH := NumGet(WINDOWINFO, 16, "Int") - wi.WindowY
    wi.ClientX := NumGet(WINDOWINFO, 20, "Int")
    wi.ClientY := NumGet(WINDOWINFO, 24, "Int")
    wi.ClientW := NumGet(WINDOWINFO, 28, "Int") - wi.ClientX
    wi.ClientH := NumGet(WINDOWINFO, 32, "Int") - wi.ClientY
    wi.Style   := NumGet(WINDOWINFO, 36, "UInt")
    wi.ExStyle := NumGet(WINDOWINFO, 40, "UInt")
    wi.Active  := NumGet(WINDOWINFO, 44, "UInt")
    wi.BorderW := NumGet(WINDOWINFO, 48, "UInt")
    wi.BorderH := NumGet(WINDOWINFO, 52, "UInt")
    wi.Atom    := NumGet(WINDOWINFO, 56, "UShort")
    wi.Version := NumGet(WINDOWINFO, 58, "UShort")
    Return wi
}

GetParent(hWnd) {
    Return DllCall("GetParent", "Ptr", hWnd, "Ptr")
}

GetOwner(hWnd) {
    Return DllCall("GetWindow", "Ptr", hWnd, "UInt", 4, "Ptr") ; GW_OWNER
}

ShowWindow(hWnd, nCmdShow := 1) {
    DllCall("ShowWindow", "Ptr", hWnd, "Int", nCmdShow)
}

IsWindow(hWnd) {
    Return DllCall("IsWindow", "Ptr", hWnd)
}

IsWindowVisible(hWnd) {
    Return DllCall("IsWindowVisible", "Ptr", hWnd)
}

GetMenu(hWnd) {
    Return DllCall("GetMenu", "Ptr", hWnd, "Ptr")
}

GetSubMenu(hMenu, nPos) {
    Return DllCall("GetSubMenu", "Ptr", hMenu, "Int", nPos, "Ptr")
}

GetMenuItemCount(hMenu) {
    Return DllCall("GetMenuItemCount", "Ptr", hMenu)
}

GetMenuItemID(hMenu, nPos) {
    Return DllCall("GetMenuItemID", "Ptr", hMenu, "Int", nPos)
}

GetMenuString(hMenu, uIDItem) {
    ; uIDItem: the zero-based relative position of the menu item
    Local lpString, MenuItemID
    VarSetCapacity(lpString, 4096)
    If !(DllCall("GetMenuString", "Ptr", hMenu, "UInt", uIDItem, "Str", lpString, "Int", 4096, "UInt", 0x400)) {
        MenuItemID := GetMenuItemID(hMenu, uIDItem)
        If (MenuItemID > -1) {
            Return "SEPARATOR"
        } Else {
            Return (GetSubMenu(hMenu, uIDItem)) ? "SUBMENU" : "ERROR"
        }
    }
    Return lpString
}

GetClassName(hWnd) {
    WinGetClass Class, ahk_id %hWnd%
    Return Class
}

GetFileIcon(File, SmallIcon := 1) {
    VarSetCapacity(SHFILEINFO, cbFileInfo := A_PtrSize + 688)
    If (DllCall("Shell32.dll\SHGetFileInfoW"
        , "WStr", File
        , "UInt", 0
        , "Ptr" , &SHFILEINFO
        , "UInt", cbFileInfo
        , "UInt", 0x100 | SmallIcon)) { ; SHGFI_ICON
        Return NumGet(SHFILEINFO, 0, "Ptr")
    }
}

SetWindowPos(hWnd, x, y, w, h, hWndInsertAfter := 0, uFlags := 0x40) { ; SWP_SHOWWINDOW
    Return DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", hWndInsertAfter, "Int", x, "Int", y, "Int", w, "Int", h, "UInt", uFlags)
}

ShowSettingsDlg:
    Gui Settings: New, LabelSettings hWndhSettingsDlg -MinimizeBox OwnerSpy
    SetWindowIcon(hSettingsDlg, ResDir . "\Settings.ico")
    Gui Font, s9, Segoe UI
    Gui Color, White

    Gui Add, GroupBox, x8 y7 w319 h56, %AppName%
    Gui Add, CheckBox, vg_AlwaysOnTop x20 y27 w291 h23 Checked%g_AlwaysOnTop%, Show the window always on top

    Gui Add, GroupBox, x8 y69 w319 h152, Screenshot
    Gui Add, Radio, % "x20 y88 w290 h23 " . (!g_ShowBorder ? "Checked" : "")
    , Capture the contents of the control only
    Gui Add, Radio, vg_ShowBorder x20 y118 w290 h23 Checked%g_ShowBorder%
    , Display a border around the control
    Gui Add, Text, x36 y150 w78 h23 +0x200, Border color:
    Gui Add, Progress, vBorderColorPreview x119 y151 w23 h23 +0x800000 c%g_BorderColor%, 100
    Gui Add, Button, gChooseBorderColor x150 y150 w80 h24, Choose
    Gui Add, Text, x36 y183 w79 h23 +0x200, Border width:
    Gui Add, Edit, vg_BorderWidth x119 y184 w42 h21
    Gui Add, UpDown, x159 y184 w18 h21, %g_BorderWidth%

    Gui Add, Text, x-1 y231 w338 h48 -Background +Border
    Gui Add, Button, gApplySettings x152 y243 w84 h24 +Default, &OK
    Gui Add, Button, gSettingsClose x243 y243 w84 h24, &Cancel
    Gui Show, w335 h278, Settings
Return

SettingsEscape:
SettingsClose:
    Gui Settings: Destroy
Return

ApplySettings:
    Gui Settings: Submit
    WinSet AlwaysOnTop, % g_AlwaysOnTop ? "On" : "Off", ahk_id %hSpyWnd%
    g_ShowBorder := (g_ShowBorder == 2) ? 1 : 0
    g_BorderColor := g_BorderColorTemp
Return

ChooseBorderColor:
    g_BorderColorTemp := g_BorderColor
    If (ChooseColor(g_BorderColorTemp, hSettingsDlg)) {
        GuiControl, Settings: +c%g_BorderColorTemp%, BorderColorPreview
    }
Return

ChooseColor(ByRef Color, hOwner := 0) {
    rgbResult := ((Color & 0xFF) << 16) + (Color & 0xFF00) + ((Color >> 16) & 0xFF)

    VarSetCapacity(CUSTOM, 64, 0)
    NumPut(VarSetCapacity(CHOOSECOLOR, A_PtrSize * 9, 0), CHOOSECOLOR, 0)
    NumPut(hOwner, CHOOSECOLOR, A_PtrSize)
    NumPut(rgbResult, CHOOSECOLOR, A_PtrSize * 3)
    NumPut(&CUSTOM, CHOOSECOLOR, A_PtrSize * 4) ; COLORREF *lpCustColors
    NumPut(0x103, CHOOSECOLOR, A_PtrSize * 5) ; Flags: CC_ANYCOLOR | CC_RGBINIT | CC_FULLOPEN

    RetVal := DllCall("comdlg32\ChooseColorA", "Str", CHOOSECOLOR)
    If (ErrorLevel != 0 || RetVal == 0) {
        Return False
    }

    rgbResult := NumGet(CHOOSECOLOR, A_PtrSize * 3)
    Color := (rgbResult & 0xFF00) + ((rgbResult & 0xFF0000) >> 16) + ((rgbResult & 0xFF) << 16)
    Color := Format("0x{:06X}", Color)
    Return True
}

OnWM_SYSCOMMAND(wParam, lParam, msg, hWnd) {
    If (wParam == 0xC0DE) {
        Gui Spy: +OwnDialogs
        MsgBox 0x40040, About, %AppName% %Version%`nWindow information tool`n`nCredits:`n - J Brown (WinSpy++ developer)`n - Lexicos (AutoHotkey developer)
    }
}

ShowFindDlg:
    If (FindDlgExist) {
        Gui Find: Show
    } Else {
        Gui Find: New, LabelFind hWndhFindDlg
        Gui Font, s9, Segoe UI
        Gui Color, White

        Gui Add, Text, x15 y16 w81 h23 +0x200, Text or Title:
        Gui Add, Edit, hWndhEdtFindByText vEdtFindByText gFindWindow x144 y17 w286 h21
        Gui Add, CheckBox, vChkFindRegEx x441 y16 w120 h23, Regular Expression
        Gui Add, Text, x15 y54 w79 h23 +0x200, Class Name:
        Gui Add, ComboBox, vCbxFindByClass gFindWindow x144 y54 w286
        Gui Add, Text, x15 y93 w110 h23 +0x200, Process ID or Name:
        Gui Add, ComboBox, vCbxFindByProcess gFindWindow x144 y93 w286

        Gui Add, ListView, hWndhFindList gFindListHandler x10 y130 w554 h185 +LV0x14000
        , hWnd|Class|Text|Process
        LV_ModifyCol(1, 0)
        LV_ModifyCol(2, 133)
        LV_ModifyCol(3, 285)
        LV_ModifyCol(4, 112)

        Gui Add, Text, x-1 y329 w576 h49 +Border -Background
        Gui Add, Button, gFindOK x381 y342 w88 h25 Default, &OK
        Gui Add, Button, gFindClose x477 y342 w88 h25, &Cancel

        Gui Show, w574 h377, Find Window
        SetExplorerTheme(hFindList)

        FindDlgExist := True
    }

    ; Unique class names
    Global Classes := []
    WinGet WinList, List
    Loop %WinList% {
        hThisWnd := WinList%A_Index%
        WinGetClass WClass, ahk_id %hThisWnd%
        AddUniqueClass(WClass)

        WinGet ControlList, ControlListHwnd, ahk_id %hThisWnd%
        Loop Parse, ControlList, `n
        {
            WinGetClass CClass, ahk_id %A_LoopField%
            AddUniqueClass(CClass)
        }
    }

    ClassList := ""
    Loop % Classes.Length()  {
        ClassList .= Classes[A_Index] . "|"
    }

    GuiControl,, CbxFindByClass, %ClassList%

    ; Unique process names
    Processes := []
    For Process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process") {
        If (Process.ProcessID < 10) {
            Continue
        }

        Unique := True
        Loop % Processes.Length() {
            If (Process.Name == Processes[A_Index]) {
                Unique := False
                Break
            }
        }

        If (Unique) {
            Processes.Push(Process.Name)
        }
    }

    ProcList := ""
    MaxItems := Processes.Length()
    Loop %MaxItems%  {
        ProcList .= Processes[MaxItems - A_Index + 1] . "|"
    }

    GuiControl,, CbxFindByProcess, %ProcList%
Return

AddUniqueClass(ClassName) {
    Local Unique := True
    Loop % Classes.Length() {
        If (ClassName == Classes[A_Index]) {
            Unique := False
            Break
        }
    }

    If (Unique) {
        Classes.Push(ClassName)
    }
}

FindEscape:
FindClose:
    Gui Find: Hide
Return

FindWindow:
    Gui Find: Submit, NoHide

    Gui ListView, %hFindList%
    GuiControl -Redraw, %hFindList%
    LV_Delete()

    WinGet WinList, List
    Loop %WinList% {
        hThisWnd := WinList%A_Index%
        If (hThisWnd == hFindDlg) {
            Continue
        }

        WinGetClass WClass, ahk_id %hThisWnd%
        WinGetTitle WTitle, ahk_id %hThisWnd%
        WinGet WProcess, ProcessName, ahk_id %hThisWnd%
        WinGet WProcPID, PID, ahk_id %hThisWnd%

        If (MatchCriteria(WTitle, WClass, IsNumber(CbxFindByProcess) ? WProcPID : WProcess)) {
            LV_Add("", hThisWnd, WClass, WTitle, WProcess)
        }

        WinGet ControlList, ControlListHwnd, ahk_id %hThisWnd%
        Loop Parse, ControlList, `n
        {
            ControlGetText CText,, ahk_id %A_LoopField%
            WinGetClass CClass, ahk_id %A_LoopField%
            WinGet CProcess, ProcessName, ahk_id %A_LoopField%
            WinGet CProcPID, PID, ahk_id %A_LoopField%

            If (MatchCriteria(CText, CClass, IsNumber(CbxFindByProcess) ? CProcPID : CProcess)) {
                LV_Add("", A_LoopField, CClass, CText, CProcess)
            }
        }
    }

    GuiControl +Redraw, %hFindList%
Return

MatchCriteria(Text, Class, Process) {
    Global

    If (EdtFindByText != "") {
        If (ChkFindRegEx) {
            If (RegExMatch(Text, EdtFindByText) < 1) {
                Return False
            }
        } Else {
            If (!InStr(Text, EdtFindByText)) {
                Return False
            }
        }
    }

    If (CbxFindByClass != "" && !InStr(Class, CbxFindByClass)) {
        Return False
    }

    If (CbxFindByProcess != "") {
        Return IsNumber(Process) ? CbxFindByProcess == Process : InStr(Process, CbxFindByProcess)
    }

    Return True
}

FindOK:
    Gui ListView, %hFindList%
    LV_GetText(hWnd, LV_GetNext())
    GuiControl, Spy:, EdtHandle, %hWnd%
    WinActivate ahk_id %hSpyWnd%
    Gui Find: Hide
Return

FindListHandler:
    If (A_GuiEvent == "DoubleClick") {
        GoSub FindOK
    }
Return

CreateImageList() {
    ImageList := IL_Create(32)
    IL_Add(ImageList, TreeIcons, 1)  ; Generic window icon
    IL_Add(ImageList, TreeIcons, 2)  ; Desktop (#32769)
    IL_Add(ImageList, TreeIcons, 3)  ; Dialog (#32770)
    IL_Add(ImageList, TreeIcons, 4)  ; Button
    IL_Add(ImageList, TreeIcons, 5)  ; CheckBox
    IL_Add(ImageList, TreeIcons, 6)  ; ComboBox
    IL_Add(ImageList, TreeIcons, 7)  ; DateTime
    IL_Add(ImageList, TreeIcons, 8)  ; Edit
    IL_Add(ImageList, TreeIcons, 9)  ; GroupBox
    IL_Add(ImageList, TreeIcons, 10) ; Hotkey
    IL_Add(ImageList, TreeIcons, 11) ; Icon
    IL_Add(ImageList, TreeIcons, 12) ; Link
    IL_Add(ImageList, TreeIcons, 13) ; ListBox
    IL_Add(ImageList, TreeIcons, 14) ; ListView
    IL_Add(ImageList, TreeIcons, 15) ; MonthCal
    IL_Add(ImageList, TreeIcons, 16) ; Picture
    IL_Add(ImageList, TreeIcons, 17) ; Progress
    IL_Add(ImageList, TreeIcons, 18) ; Radio
    IL_Add(ImageList, TreeIcons, 19) ; RichEdit
    IL_Add(ImageList, TreeIcons, 20) ; Separator
    IL_Add(ImageList, TreeIcons, 21) ; Slider
    IL_Add(ImageList, TreeIcons, 22) ; Status bar
    IL_Add(ImageList, TreeIcons, 23) ; Tab
    IL_Add(ImageList, TreeIcons, 24) ; Text
    IL_Add(ImageList, TreeIcons, 25) ; Toolbar
    IL_Add(ImageList, TreeIcons, 26) ; Tooltips
    IL_Add(ImageList, TreeIcons, 27) ; TreeView
    IL_Add(ImageList, TreeIcons, 28) ; UpDown
    IL_Add(ImageList, TreeIcons, 29) ; IE
    IL_Add(ImageList, TreeIcons, 30) ; Scintilla
    IL_Add(ImageList, TreeIcons, 31) ; ScrollBar
    IL_Add(ImageList, TreeIcons, 32) ; SysHeader
    Return ImageList
}

ShowTree:
    If (WinExist("ahk_id" . hTreeWnd)) {
        Gui Tree: Show
        SetWindowIcon(hTreeWnd, "shell32.dll", 42)
    } Else {
        Gui Tree: New, LabelTree hWndhTreeWnd +Resize
        SetWindowIcon(hTreeWnd, "shell32.dll", 42)

        Menu TreeMenu, Add, &Reload`tF5, LoadTree
        Menu TreeMenu, Add
        Menu TreeMenu, Add, E&xit`tEsc, TreeClose
        Menu MenuBar, Add, &Tree, :TreeMenu
        Menu ViewMenu, Add, Show &Hidden Windows, ToggleHiddenWindows
        Menu ViewMenu, Add
        Menu ViewMenu, Add, &Flash Window`tF6, FlashWindow
        Menu ViewMenu, Add
        Menu ViewMenu, Add, E&xpand All Nodes, ExpandAll
        Menu ViewMenu, Add, &Collapse All Nodes, CollapseAll
        Menu MenuBar, Add, &View, :ViewMenu
        Gui Tree: Menu, MenuBar

        Gui Font, s9, Segoe UI
        Gui Add, TreeView, hWndhTree gTreeHandler x0 y0 w681 h445 -Lines +0x9000

        Gui Show, w681 h445, %AppName% - Tree

        TV_SetImageList(CreateImageList())
        SetExplorerTheme(hTree)
    }

    GoSub LoadTree
Return

TreeEscape:
TreeClose:
    Gui Tree: Hide
Return

TreeSize:
    If (A_EventInfo == 1) { ; Minimized
        Return
    }

    AutoXYWH("wh", hTree)
Return

LoadTree:
    Global TreeIDs := {}

    Gui Tree: Default
    TV_Delete()

    RootID := TV_Add("Desktop", 0, "Icon2")
    TreeIDs[RootID] := DllCall("GetDesktopWindow", "Ptr")

    WinGet WinList, List
    Loop %WinList% {
        hWnd := WinList%A_Index%

        WinGetClass Class, ahk_id %hWnd%
        WinGetTitle Title, ahk_id %hWnd%
        If (Title != "") {
            Title := " - " . Title
        }

        Invisible := !IsWindowVisible(hWnd)

        If (!g_TreeShowAll && Invisible) {
            Continue
        }

        If (Invisible) {
            Title .= " (hidden)"
        }

        Icon := GetWindowIcon(hWnd, Class, True)

        ID := TV_Add(Class . Title, RootID, "Icon" . Icon)
        TreeIDs[ID] := hWnd
        Tree(hWnd, ID)
    }

    TV_Modify(RootID, "+Expand")

    For Key, Value in TreeIDs {
        If (g_hWnd == Value) {
            TV_Modify(Key, "Select")
        }
    }
Return

Tree(hParentWnd, ParentID) {
    WinGet WinList, ControlListHwnd, ahk_id %hParentWnd%
    Loop Parse, WinList, `n
    {
        If (GetParent(A_LoopField) != hParentWnd) {
            Continue
        }

        WinGetClass Class, ahk_id %A_LoopField%
        If (IsChild(A_LoopField)) {
            ControlGetText Text,, ahk_id %A_LoopField%
        } Else {
            WinGetTitle Text,, ahk_id %A_LoopField%
        }

        If (Text != "") {
            Text := " - " . Text
        }

        Invisible := !IsWindowVisible(A_LoopField)

        If (!g_TreeShowAll && Invisible) {
            Continue
        }

        If (Invisible) {
            Text .= " (hidden)"
        }

        Icon := GetWindowIcon(A_LoopField, Class)

        ID := TV_Add(Class . Text, ParentID, "Icon" . Icon)
        TreeIDs[ID] := A_LoopField
        Tree(A_LoopField, ID)
    }
}

TreeHandler:
    If (A_GuiEvent == "DoubleClick") {
        g_hWnd := TreeIDs[A_EventInfo]
        ShowWindowInfo()
    }
Return

GetWindowIcon(hWnd, Class, TopLevel := False) {
    Static Classes := {0:0
    , "#32770": 3
    , "Button": 4
    , "CheckBox": 5
    , "ComboBox": 6
    , "SysDateTimePick32": 7
    , "Edit": 8
    , "GroupBox": 9
    , "msctls_hotkey32": 10
    , "Icon": 11
    , "SysLink": 12
    , "ListBox": 13
    , "SysListView32": 14
    , "SysMonthCal32": 15
    , "Picture": 16
    , "msctls_progress32": 17
    , "Radio": 18
    , "RebarWindow32": 25
    , "RichEdit": 19
    , "Separator": 20
    , "msctls_trackbar32": 21
    , "msctls_statusbar32": 22
    , "SysTabControl32": 23
    , "Static": 24
    , "ToolbarWindow32": 25
    , "tooltips_class32": 26
    , "SysTreeView32": 27
    , "msctls_updown32": 28
    , "Internet Explorer_Server": 29
    , "Scintilla": 30
    , "ScrollBar": 31
    , "SysHeader32": 32}

    If (Class == "Button") {
        WinGet Style, Style, ahk_id %hWnd%
        Type := Style & 0xF
        If (Type == 7) {
            Class := "GroupBox"
        } Else If (Type ~= "2|3|5|6") {
            Class := "CheckBox"
        } Else If (Type ~= "4|9") {
            Class := "Radio"
        } Else {
            Class := "Button"
        }
    } Else If (Class == "Static") {
        WinGet Style, Style, ahk_id %hWnd%
        Type := Style & 0x1F ; SS_TYPEMASK
        If (Type == 3) {
            Class := "Icon"
        } Else If (Type == 14) {
            Class := "Picture"
        } Else If (Type == 0x10) {
            Class := "Separator"
        } Else {
            Class := "Static"
        }
    } Else If (InStr(Class, "RICHED", True) == 1) {
        Class := "RichEdit" ; RICHEDIT50W
    }

    Icon := Classes[Class]
    If (Icon != "") {
        Return Icon
    }

    SendMessage 0x7F, 2, 0,, ahk_id %hWnd% ; WM_GETICON, ICON_SMALL2
    hIcon := ErrorLevel

    If (hIcon == 0 && TopLevel) {
        WinGet ProcessPath, ProcessPath, ahk_id %hWnd%
        hIcon := GetFileIcon(ProcessPath)
    }

    IconIndex := (hIcon) ? IL_Add(ImageList, "HICON: " . hIcon) : 1
    Return IconIndex
}

ToggleHiddenWindows:
    g_TreeShowAll := !g_TreeShowAll
    GoSub LoadTree
    Menu ViewMenu, ToggleCheck, Show &Hidden Windows
Return

CollapseAll:
ExpandAll:
    Expand := (A_ThisLabel == "ExpandAll") ? "+Expand" : "-Expand"

    ItemID := 0
    Loop {
        ItemID := TV_GetNext(ItemID, "Full")
        If (!ItemID) {
            Break
        }

        TV_Modify(ItemID, Expand)
    }
Return

FlashWindow:
    If (A_Gui == "Tree") {
        hWnd := TreeIDs[TV_GetSelection()]
    } Else {
        hWnd := g_hWnd
    }

    ShowBorder(hWnd, 200, 0xFF0000)
    Sleep 200
    ShowBorder(hWnd, 200, 0xFF0000)
    Sleep 200
    ShowBorder(hWnd, 200, 0xFF0000)
Return

; Based on a script written by Lexicos
ShowMenuViewer:
    If (MenuViewerExist) {
        Gui MenuViewer: Show
    } Else {
        Gui MenuViewer: New, +LabelMenuViewer +hWndhMenuViewer +Resize
        Gui Font, s9, Segoe UI
        Gui Color, 0xF1F5FB

        Gui Add, ListView, hWndhMenuList vLVMenu x0 y0 w600 h400 +LV0x14000, Menu Item String|Keyboard|Menu ID
        LV_ModifyCol(1, 410)
        LV_ModifyCol(2, 103)
        LV_ModifyCol(3, "65 Integer")
        SetExplorerTheme(hMenuList)

        Gui Add, Edit, hWndhEdtMenuSearch vEdtMenuSearch gSearchMenu x8 y408 w200 h23 +0x2000000 ; WS_CLIPCHILDREN
        DllCall("SendMessage", "Ptr", hEdtMenuSearch, "UInt", 0x1501, "Ptr", 1, "WStr", "Search")

        Gui Add, Picture, hWndhSearchIcon x178 y1 w16 h16, %ResDir%\Search.ico
        DllCall("SetParent", "Ptr", hSearchIcon, "Ptr", hEdtMenuSearch)
        WinSet Style, -0x40000000, ahk_id %hSearchIcon% ; -WS_CHILD
        ControlFocus,, ahk_id %hEdtMenuSearch%

        NoAmpersands := True
        Gui Add, CheckBox, vNoAmpersands gShowMenuItems x220 y408 w167 h23 Checked%NoAmpersands%
        , Remove Ampersands (&&)
        Gui Add, Button, vBtnMenuCopy gCopyMenuList x466 y407 w125 h25, Copy to Clipboard
        Gui Show, w600 h440, Menu Viewer
        MenuViewerExist := True
    }

    GoSub ShowMenuItems
Return

ShowMenuItems:
    Gui MenuViewer: Default
    Gui Submit, NoHide

    LV_Delete()
    hMenu := GetMenu(g_hWnd)
    If (hMenu) {
        MenuItems := []
        GetMenuItems(hMenu, "", "")
    }
Return

GetMenuItems(hMenu, Prefix, ByRef Commands) {
    Global
    ItemCount := GetMenuItemCount(hMenu)

    Loop %ItemCount% {
        ItemString := GetMenuString(hMenu, A_Index - 1)
        ItemID := GetMenuItemID(hMenu, A_Index - 1)

        RegExMatch(ItemString, "\t(.+)", Keyboard)
        ItemString := RegExReplace(ItemString, "\t.*")
        If (ItemString == "SEPARATOR") {
            ItemString := "----------------------------"
        }

        MenuItems.Push([ItemString, Keyboard1, ItemID])

        If (NoAmpersands) {
            ItemString := StrReplace(ItemString, "&")
        }

        LV_Add("", Prefix . ItemString, Keyboard1, ItemID)

        If (ItemID == -1) { ; Submenu
            hSubMenu := GetSubMenu(hMenu, A_Index - 1)
            If (hSubMenu) {
                Prefix .= "        "
                GetMenuItems(hSubMenu, Prefix, Commands)
                Prefix := StrReplace(Prefix, "        ", "",, 1)
                Continue
            }
        }
    }
}

SearchMenu:
    Gui MenuViewer: Submit, NoHide

    Gui ListView, %hMenuList%
    LV_Delete()

    Loop % MenuItems.Length() {
        MenuItem := MenuItems[A_Index][1]
        Keyboard := MenuItems[A_Index][2]
        MenuID   := MenuItems[A_Index][3]

        If (NoAmpersands) {
            MenuItem := StrReplace(MenuItem, "&")
        }

        If (InStr(MenuItem, EdtMenuSearch)
        ||  InStr(Keyboard, EdtMenuSearch)
        ||  InStr(MenuID, EdtMenuSearch)) {
            LV_Add("", MenuItem, Keyboard, MenuID)
        }
    }
Return

CopyMenuList:
    Gui MenuViewer: Default
    ControlGet MenuList, List,,, ahk_id %hMenuList%
    Clipboard := StrReplace(MenuList, "        ", "`t")
Return

MenuViewerEscape:
MenuViewerClose:
    Gui MenuViewer: Hide
Return

MenuViewerSize:
    If (A_EventInfo == 1) { ; Minimized
        Return
    }

    AutoXYWH("wh", hMenuList)
    AutoXYWH("y", hEdtMenuSearch)
    AutoXYWH("y", hSearchIcon)
    AutoXYWH("y", "NoAmpersands")
    AutoXYWH("xy", "BtnMenuCopy")
Return

MenuViewerContextMenu:
    Row := LV_GetNext()
    LV_GetText(MenuString, Row, 1)
    LV_GetText(MenuID, Row, 3)

    If (A_GuiControl == "LVMenu" && MenuID > 0 && !InStr(MenuString, "-----")) {
        Menu MenuMenu, Add, Invoke Menu Command, InvokeMenuCommand
        Menu MenuMenu, Show
    }
Return

InvokeMenuCommand:
    PostMessage 0x111, %MenuID%,,, ahk_id %g_hWnd%
Return

LoadProcessProperties:
    Gui Spy: Submit, NoHide

    WinGet PID, PID, ahk_id %g_hWnd%

    StrQuery := "SELECT * FROM Win32_Process WHERE ProcessId=" . PID
    Enum := ComObjGet("winmgmts:").ExecQuery(StrQuery)._NewEnum
    If (Enum[Process]) {
        ExePath := Process.ExecutablePath

        hIcon := GetFileIcon(ExePath, 0)
        If (!hIcon || ExePath == "") {
            hIcon := DllCall("LoadIcon", "Ptr", 0, "UInt", 32512, "Ptr") ; IDI_APPLICATION
        }

        GuiControl,, ProgIcon, % "HICON:" . hIcon
        GuiControl,, ProgName, % Process.Name
        FileGetVersion ProgVer, %ExePath%
        GuiControl,, ProgVer, %ProgVer%

        Gui ListView, %hProcInfo%
        LV_Delete()
        LV_Add("", "Path", ExePath)
        LV_Add("", "Command line", Process.CommandLine)
        LV_Add("", "Process ID", Process.ProcessId)
        LV_Add("", "Thread ID", DllCall("GetWindowThreadProcessId", "Ptr", g_hWnd, "Ptr", 0))
        CreationDate := Process.CreationDate
        SubStr(CreationDate, 1, InStr(CreationDate, ".") - 1)
        FormatTime CreationDate, %CreationDate% D1 T0 ; Short date and time with seconds
        LV_Add("", "Started", CreationDate)
        LV_Add("", "Working Size", FormatBytes(Process.WorkingSetSize, Sep))
        LV_Add("", "Virtual Size", FormatBytes(Process.VirtualSize, Sep))
        LV_Add("", "Image Type", GetImageType(PID))
    }
Return

GetImageType(PID) {
    ; PROCESS_QUERY_INFORMATION
    hProc := DllCall("OpenProcess", "UInt", 0x400, "Int", False, "UInt", PID, "Ptr")
    If (!hProc) {
        Return "N/A"
    }

    If (A_Is64bitOS) {
        ; Determines whether the specified process is running under WOW64.
        Try DllCall("IsWow64Process", "Ptr", hProc, "Int*", Is32Bit := True)
    } Else {
        Is32Bit := True
    }

    DllCall("CloseHandle", "Ptr", hProc)

    Return (Is32Bit) ? "32-bit" : "64-bit"
}

EndProcess:
    GuiControlGet Filename,, ProgName
    If (Filename == "N/A") {
        Return
    }

    Gui Spy: +OwnDialogs
    MsgBox 0x40031, %AppName%, Are you sure you want to exit %Filename%?
    IfMsgBox OK, {
        WinGet PID, PID, ahk_id %g_hWnd%
        Process Close, %PID%
        If (ErrorLevel == 0) {
            Gui Spy: +OwnDialogs
            MsgBox 0x40010, Error, The process named %Filename% with PID %PID% could not be ended.
        }
    }
Return

OpenFolder:
    Gui ListView, %hProcInfo%
    LV_GetText(ExePath, 1, 2)
    If (ExePath != "") {
        Run *open explorer.exe /select`,"%ExePath%"
    }
Return

FormatBytes(Value, sThousand := ".", Unit := -1, ShowUnit := True) {
    If ((Unit == -1 && Value > 999) || Unit == "K") {
        Value /= 1024
        Unit := ShowUnit ? " K" : ""
    } Else {
        Unit := ShowUnit ? " B" : ""
    }

    a := ""
    Loop % StrLen(Value) {
        a .= SubStr(Value, 1 - A_Index, 1)
        If (Mod(A_Index, 3) == 0) {
            a .= sThousand
        }
    }

    a := RTrim(a, sThousand)

    b := ""
    Loop % StrLen(a) {
        b .= SubStr(a, 1 - A_Index, 1)
    }

    Return b . Unit
}

; http://ahkscript.org/boards/viewtopic.php?t=1079
AutoXYWH(DimSize, cList*) {
    Static cInfo := {}

    If (DimSize = "reset") {
        Return cInfo := {}
    }

    For i, ctrl in cList {
        ctrlID := A_Gui ":" ctrl
        If (cInfo[ctrlID].x = "") {
            GuiControlGet i, %A_Gui%: Pos, %ctrl%
            MMD := InStr(DimSize, "*") ? "MoveDraw" : "Move"
            fx := fy := fw := fh := 0
            For i, dim in (a := StrSplit(RegExReplace(DimSize, "i)[^xywh]"))) {
                If (!RegExMatch(DimSize, "i)" . dim . "\s*\K[\d.-]+", f%dim%)) {
                    f%dim% := 1
                }
            }
            cInfo[ctrlID] := {x: ix, fx: fx, y: iy, fy: fy, w: iw, fw: fw, h: ih, fh: fh, gw: A_GuiWidth, gh: A_GuiHeight, a: a, m: MMD}
        } Else If (cInfo[ctrlID].a.1) {
            dgx := dgw := A_GuiWidth - cInfo[ctrlID].gw, dgy := dgh := A_GuiHeight - cInfo[ctrlID].gh
            Options := ""
            For i, dim in cInfo[ctrlID]["a"] {
                Options .= dim . (dg%dim% * cInfo[ctrlID]["f" . dim] + cInfo[ctrlID][dim]) . A_Space
            }
            GuiControl, % A_Gui ":" cInfo[ctrlID].m, % ctrl, % Options
        }
    }
}

IsBorder(hWnd) {
    Loop % g_Borders.Length() {
        If (g_Borders[A_Index] == hWnd) {
            Return True
        }
    }
    Return False
}

IsNumber(n) {
    If n Is Number
        Return True
    Return False
}

ShowHelp:
Gui Spy: +OwnDialogs
MsgBox 0x40, %AppName% Keyboard Shortcuts, 
(
F2:  Go to the parent window
F3:  Show the Find dialog
F4:  Show the hierarchical window tree
F5:  Reload window information
F6:  Highlight window location
F7:  Position and Size dialog
F8:  Copy information to the clipboard
F9:  Copy screenshot to the clipboard
)
Return
