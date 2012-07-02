Func debug($string, $priority = 0)
	If $priority == 1 And Not $debugOut Then Return $string
	ConsoleWrite($string & @CRLF)
	$g_console_data &= $string & @CRLF
	setconsole($g_console_data)
	Return $string
EndFunc

Func mouseinfo()
	$pos = MouseGetPos()
	$color = PixelGetColor($pos[0],$pos[1])
	sleep(200)
	debug($pos[0] & "," & $pos[1] & ":" & PixelGetColor($pos[0], $pos[1]))
	check($pos,$color)
EndFunc

Func D3Click($position, $subpos = -1, $clicks = 1, $checkcolor = false, $diff = "entrydiff")
	If Not IsArray($position) Then
		Dim $posiArray[3]
		$posiArray[0] = IniRead($g_confPath, $position, "x", 0)
		$posiArray[1] = IniRead($g_confPath, $position, "y", 0)
		$posiArray[2] = IniRead($g_confPath, $position, "color", 0)
		$position = $posiArray
	EndIf
	If $subpos > -1 Then
		If $diff <> "itemdiff" Then
			$position[0] -= 50
			$position[1] += IniRead($g_confPath, "diff", "filterentrydiff", 0)
		EndIf
		$position[1] += (IniRead($g_confPath, "diff", $diff, 0)*$subpos)
	EndIf
	If $checkcolor And PixelGetColor($position[0], $position[1]) <> $position[2] Then Return False
	ControlClick("Diablo III", "", 0 , "left", $clicks, $position[0], $position[1])
	D3Sleep(50)
	Return True
EndFunc

Func D3Move($position, $subpos = -1, $clicks = 1, $checkcolor = false, $diff = "entrydiff")
	If Not IsArray($position) Then
		Dim $posiArray[3]
		$posiArray[0] = IniRead($g_confPath, $position, "x", 0)
		$posiArray[1] = IniRead($g_confPath, $position, "y", 0)
		$posiArray[2] = IniRead($g_confPath, $position, "color", 0)
		$position = $posiArray
	EndIf
	If $subpos > -1 Then
		If $diff <> "itemdiff" Then
			$position[0] -= 50
			$position[1] += IniRead($g_confPath, "diff", "filterentrydiff", 0)
		EndIf
		$position[1] += (IniRead($g_confPath, "diff", $diff, 0)*$subpos)
	EndIf
	If $checkcolor And PixelGetColor($position[0], $position[1]) <> $position[2] Then Return False
	$curPos = MouseGetPos()
	$diff = sqrt(($curPos[0] - $position[0])^2+($curPos[1] - $position[1])^2)
	MouseMove($position[0], $position[1], 0)
	;D3Sleep($diff/2)
	Return True
EndFunc

Func D3Scroll($position, $direction = "down", $count = 1)
	Dim $posiArray[2]
	$posiArray[0] = IniRead($g_confPath, $position, "x", 0)
	$posiArray[1] = IniRead($g_confPath, $position, "y", 0) + IniRead($g_confPath, "diff", "filterentrydiff", 0)
	WinActivate("Diablo III")
	D3Move($posiArray)
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
	$posiArray[0] = IniRead($g_confPath, $position, "x", 0)
	$posiArray[1] = IniRead($g_confPath, $position, "y", 0)
	Return PixelGetColor($posiArray[0], $posiArray[1]) == IniRead($g_confPath, $position, "color", 0)
EndFunc

Func GetID($section, $key)
	Return IniRead("conf/settings.ini", $section, $key, "")
EndFunc

Func StartIt()
	$start = Not $start
	If $start Then
		Reset(2)
	EndIf
	If $g_querycount > 0 Then
		$seconds = TimerDiff($g_starttimer)/1000
		$minutes = $seconds / 60
		$hours = $minutes / 60
		Debug("Time: " & Round($seconds) & "s, queries: " & $g_querycount)
		debug("> " & $g_querycount / $seconds & " queries/s")
		debug("> " & $g_querycount / $minutes & " queries/m")
		debug("> " & $g_querycount / $hours & " queries/h")
	EndIf
	$g_starttimer = TimerInit()
	$g_querycount = 0
EndFunc

Func startup()
	Global $checkBid = 0
	Global $checkBuyout = 0
	Global $realtimepurchase = false
	Global $knownItems[1][5]
	Global $filterInfo[3][2]
	Global $g_searchList[1][7] ; class; itemType, subType, rarity, filterInfo, purchaseInfo

	; lets "login" first
	connect()

	Global $start = false

	; find process and get base adress
	Global $pid = WinGetProcess("Diablo III")
	Global $mem = _MemoryOpen($pid)
	$module = "Diablo III.exe"
	Global $baseadd = _MemoryModuleGetBaseAddress($pid, $module)

	AdlibRegister("Watchdog", 100)
EndFunc

Func feierabend()
	_MemoryClose($mem)
EndFunc

Func lookForFilter($nr, $entry, $center = 0)
	For $x = 0 To 10
		$tmpEntry = $entry
		If $entry == "Empty Sockets" Then $tmpEntry = "Has Sockets"
		$position = LookFor($tmpEntry,"filterwindow",1)
		If Not @Error Then
			D3Click($position)
			$filterInfo[$nr-1][0] = $entry
			Return True
		EndIf
		D3Scroll("filter_" & $nr, "down", 5)
		If $x == 10 Then Return False
	Next
EndFunc

Func LookFor($img, $window, $center = 0)
	$img = StringStripWS($img, 8)
	$left = IniRead($g_confPath, $window, "left", 0)
	$top = IniRead($g_confPath, $window, "top", 0)
	$right = IniRead($g_confPath, $window, "right", 0)
	$bottom = IniRead($g_confPath, $window, "bottom", 0)
	If $debugOut Then debug("LookFor " & $img & " in " & $window & ": " & $left & ", " & $top & ", " & $right & ", " & $bottom)
	Dim $position[2]
	$res= _ImageSearchArea("D3AHImages\" & $img & ".JPG",$center,$left,$top,$right,$bottom, $position[0],$position[1],100)
	If $res = 1 Then Return $position
	Return SetError(1,0, $position)
EndFunc

Func lookForSocket($nr, $id)
	If StringInStr($g_socketKnown, $id & ",") Then Return False ; we already know that item no need to scan
	$g_socketKnown &= $id & ","
	D3Move("firstitem", $nr, 1, false, "itemdiff")
	D3sleep(50)
	LookFor("EmptySocket", "socketsearch")
	If Not @Error Then Return True
	Return False
EndFunc