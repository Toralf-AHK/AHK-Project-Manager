AlignCode(){
  static Symbol := " := "

  Lines := StrSplit(SCI_GETSELTEXT(),"`n","`r")
  If ( Lines.MaxIndex() < 2){ ; minimum of 2 lines
    ToolTip, Select minimum of two lines 
    SetTimer, RemoveToolTip, -2000
    Return 
  }
  InputBox, Symbol , Align Code, Specify a Character or String`nthat should be aligned on all lines, , , , , , , , %Symbol%
  If (StrLen(Symbol) < 1){ ; a symbol must be specified
    ToolTip, You must specify a string that is at least one character long
    SetTimer, RemoveToolTip, -2000
    Return 
  }
  MaxLen := []
  Counter := 0
  For i,line in Lines {
    Lines[i] := StrSplit(line, Symbol, " `t")
    If InStr(line, Symbol){
      Counter++
      For k, str in Lines[i]
        MaxLen[k] := Max( MaxLen[k] ? MaxLen[k] : 0, StrLen(str))
    }
  }
  If (Counter < 2){  ; minimum of 2 lines with symbol
    ToolTip, The String "%Symbol%" could not be found in at least two of the selected lines.
    SetTimer, RemoveToolTip, -2000
    Return 
  }
  NewLines =
  For i,segments in Lines {
    For k, str in segments {
      If (k = 1)
        Align := ""
      Else
        Align := "-"
      
      NewLines .= Format("{:" Align MaxLen[k] "s}", str) . Symbol
    }
    NewLines := SubStr(NewLines,1,-1 * StrLen(Symbol)) . "`r`n"
  }

  SCI_REPLACESEL(NewLines)
  Return
  
  RemoveToolTip:
    ToolTip
  return
}
