Func debug($string, $priority = 0)
	If $priority == 1 And Not $debugOut Then Return $string
	ConsoleWrite($string & @CRLF)
	Return $string
EndFunc

Func mouseinfo()
	$pos = MouseGetPos()
	sleep(2000)
	debug($pos[0] & "," & $pos[1] & ":" & PixelGetColor($pos[0], $pos[1]))
EndFunc

Func D3Click($position, $subpos = -1, $clicks = 1, $checkcolor = false, $diff = "entrydiff")
	If Not IsArray($position) Then
		Dim $posiArray[3]
		$posiArray[0] = IniRead("localconf", $position, "x", 0)
		$posiArray[1] = IniRead("localconf", $position, "y", 0)
		$posiArray[2] = IniRead("localconf", $position, "color", 0)
		$position = $posiArray
	EndIf
	If $subpos > -1 Then
		$position[0] -= 50
		If $diff <> "itemdiff" Then $position[1] += IniRead("localconf", "diff", "filterentrydiff", 0)
		$position[1] += (IniRead("localconf", "diff", $diff, 0)*$subpos)
	EndIf
	If $checkcolor And PixelGetColor($position[0], $position[1]) <> $position[2] Then Return False
	ControlClick("Diablo III", "", 0 , "left", $clicks, $position[0], $position[1])
	D3Sleep(50)
	Return True
EndFunc

Func D3Scroll($position, $direction = "down", $count = 1)
	Dim $posiArray[2]
	$posiArray[0] = IniRead("localconf", $position, "x", 0)
	$posiArray[1] = IniRead("localconf", $position, "y", 0) + IniRead("localconf", "diff", "filterentrydiff", 0)
	WinActivate("Diablo III")
	MouseMove($posiArray[0], $posiArray[1], 1)
	D3sleep(100)
	MouseWheel($direction, $count)
	D3sleep(50)
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
	Dim $posiArray[3]
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

Func startup()
	Global $checkBid = 0
	Global $checkBuyout = 0
	Global $realtimepurchase = false
	Global $knownItems[1][5]
	Global $filterInfo[3][2]
	Global $g_searchList[1][5] ; itemType, subType, rarity, filterInfo, purchaseInfo

	; lets "login" first
	connect()

	Global $start = false
	$sSQliteDll = _SQLite_Startup ()
	If @error Then
		MsgBox(16, "SQLite Error", "SQLite.dll Can't be Loaded!")
		Exit - 1
	EndIf

	Global $db = _SQLite_Open("items.db")

	; find process and get base adress
	Global $pid = WinGetProcess("Diablo III")
	Global $mem = _MemoryOpen($pid)
	WinActivate("Diablo III")
	$module = "Diablo III.exe"
	Global $baseadd = _MemoryModuleGetBaseAddress($pid, $module)
EndFunc

Func feierabend()
	_MemoryClose($mem)
	_Sqlite_close($db)
	_SQLite_Shutdown()
EndFunc

Func lookFor($stat,$center = 0)
	$left = IniRead("localconf", "filterwindow", "left", 0)
	$top = IniRead("localconf", "filterwindow", "top", 0)
	$right = IniRead("localconf", "filterwindow", "right", 0)
	$bottom = IniRead("localconf", "filterwindow", "bottom", 0)
	$stat = StringStripWS($stat,8)
	Dim $position[2]
	$res= _ImageSearchArea("D3AHImages\" & $stat & ".jpg",$center,$left,$top,$right,$bottom, $position[0],$position[1],100)
	If $res = 1 Then
		Return $position
	EndIf
	Return SetError(1,0, $position)
EndFunc