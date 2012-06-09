Func debug($string)
	ConsoleWrite($string & @CRLF)
	Return $string
EndFunc

Func mouseinfo()
	$pos = MouseGetPos()
	sleep(2000)
	debug($pos[0] & "," & $pos[1] & ":" & PixelGetColor($pos[0], $pos[1]))
EndFunc

Func D3Click($position, $subpos = 0, $clicks = 1)
	If Not IsArray($position) Then
		Dim $posiArray[3]
		$posiArray[0] = IniRead("localconf", $position, "x", 0)
		$posiArray[1] = IniRead("localconf", $position, "y", 0)
		$position = $posiArray
	EndIf
	If $subpos > 0 Then $position[1] += (IniRead("localconf", "diff", $position, 0)*$subpos)
	ControlClick("Diablo III", "", 0 , "left", $clicks, $position[0], $position[1])
	D3Sleep(500)
EndFunc

Func D3Scroll($position, $count, $direction)
	If StringInStr($position, "filter") Then ; filter is special cause of changing width, we have to search
		$position = StringSplit($position, "_")
		$nr = $position[2] - 1
		$left = IniRead("localconf", "scrollbartopleft", "x", 0)
		$top = IniRead("localconf", "scrollbartopleft", "y", 0) + ($nr * IniRead("localconf", "diff", "DragDownToItem", 0))
		$right = IniRead("localconf", "scrollbarbottomright", "x", 0)
		$bottom = IniRead("localconf", "scrollbarbottomright", "y", 0) + ($nr * IniRead("localconf", "diff", "DragDownToItem", 0))
		$position = PixelSearch($left, $top, $right, $bottom, 16763272,3)
		If @Error Then Return debug("Failed to find scrollbar")
	ElseIf IniRead("localconf", $position, "x", 0) > 0 Then ; Position of open filter, add diff
		Dim $posiArray[3]
		$posiArray[0] = IniRead("localconf", $position, "x", "")
		$posiArray[1] = IniRead("localconf", $position, "y", "") + IniRead("localconf", "diff", "DragDownToItem", 0)
		$position = $posiArray
	EndIf
	If $direction == "down" Then $position[1] += IniRead("localconf", "diff", "ScrollToScroll", 0)
	D3Click($position, 0, $count * 9)
EndFunc

Func D3Send($String)
	ControlSend("Diablo III", "", 0, $String)
	D3sleep(250)
EndFunc

Func D3Sleep($time)
	$time = Random($time * 0.9, $time * 1.1)
	sleep($time)
EndFunc

Func CheckColor($position)
	$posiArray[0] = IniRead("localconf", $position, "x", 0)
	$posiArray[1] = IniRead("localconf", $position, "y", 0)
	Return PixelGetColor($posiArray[0], $posiArray[1]) == IniRead("localconf", $position, "color", 0)
EndFunc

Func GetID($section, $key)
	Return IniRead("settings.ini", $section, $key, "")
EndFunc

Func StartIt()
	$start = Not $start
EndFunc