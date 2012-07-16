Func debug($string, $priority = 0)
	If $priority == 1 And Not $debugOut Then Return $string
	ConsoleWrite($string & @CRLF)
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
	If $g_runlevel == 2 Then
		$g_runlevel = 0
		setconsole("Stopped", "Stopped")
	Else
		If Not InitializePointer() Then Return False
		$g_runlevel = 2
		setconsole("Started", "Running")
	EndIf

	$g_starttimer = TimerInit()
	$g_querycount = 0
EndFunc

Func startup()
	Global $g_searchIdx = IniRead($g_settings, "search", "currentsearchid", 0)
	Global $g_maxSearchIdx = 0
	Global $g_socketSearch = false
	Global $g_itemsKnown = FileRead("socketsearch")
	Global $g_confPath = "conf/localconf.ini"
	Global $g_sid = 0
	Global $g_querycount = 0
	Global $g_queriesperhour = 0
	Global $g_wd_lastitemID = 0
	Global $g_checkBid = 0
	Global $g_checkBuyout = 0
	Global $g_searchList[1][7] ; class; itemType, subType, rarity, filterInfo, purchaseInfo
	Global $g_filter[1][2]
	Global $g_baseQPH = 775
	Global $g_targetQPH = 800

	Global $g_memoryCheck = ""
	Global $g_itembase = 0
	Global $g_baseinfo = 0
	Global $g_startTimer = 0

	; lets "login" first 01 F2 E3 F7 05
	connect()

	Global $g_runlevel = 0

	; find process and get base adress
	Global $pid = WinGetProcess("Diablo III")
	If $pid == -1 Then $g_testMode = true
	Global $mem = _MemoryOpen($pid)
	Global $baseadd = _MemoryModuleGetBaseAddress($pid, "Diablo III.exe")

	AdlibRegister("Watchdog", 100)

	$g_starttimer = 0
EndFunc

Func feierabend()
	_MemoryClose($mem)
EndFunc

Func lookForFilter($nr, $entry, $center = 0)
	For $x = 0 To 10
		$tmpEntry = $entry
		If $entry == "EmptySockets" Then $tmpEntry = "HasSockets"
		$position = LookFor($tmpEntry,"filterwindow",1)
		If Not @Error Then
			D3Click($position)
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
	D3Move("firstitem", $nr, 1, false, "itemdiff")
	D3sleep(50)
	LookFor("EmptySocket", "socketsearch")
	If Not @Error Then Return True
	Return False
EndFunc

Func CheckRun($lowerRunLevel = false)
	If $lowerRunLevel And $g_runlevel == 1 Then $g_runlevel = 0
	;If D3Click("errormsg", -1, 1, true) Then Return False
	If $g_runlevel >= 1 Then Return True
	Return False
EndFunc

Func AscToHex($String)
	$return = ""
	For $i = 1 To StringLen($string)
		$return &= Hex(Asc(StringMid($string,$i,1)),2)
	Next
	Return $return
EndFunc

Func InitializePointer()
	$initTimer = TimerInit()
	; item base
	$itembasecheck = ""
	If $g_itembase <> 0 Then $itembasecheck = debug(_MemoryRead($g_itembase, $mem, "char[32]"))
	If $g_itembase == 0 Or StringLeft($itembasecheck,8) <> "EQUIPPED" Then
		$g_itembase = _MemoryScan($mem, AscToHex("EQUIPPED")) ; search for "EQUIPPED"
		If Not @Error Then
			debug($g_itembase)
			setconsole("Found item base")
		Else
			setconsole("Couldn't find item base", "Error")
			Return False
		EndIf
	EndIf

	; base info
	If $g_baseinfo == 0 Then $g_baseinfo = "0x" & Hex(IniRead($g_settings, "internal", "baseinfo", 0))
	$baseinfoCheck = _MemoryRead($g_baseinfo, $mem, "char[512]")
	If $g_baseinfo == 0 Or StringLeft($baseinfoCheck, 26) <> "{icon:bullet} {c:ff6969ff}" Then
		$baseinfo1 = MemoryScan($mem, AscToHex(InputBox("Pointer Search", "First Affix - 2 Affixes")))
		setconsole("Found " & UBound($baseinfo1)-1 & " pointer")
		$baseinfo2 = MemoryScan($mem, AscToHex(InputBox("Pointer Search", "First Affix - Multiple Affixes")))
		setconsole("Found " & UBound($baseinfo2)-1 & " pointer")
		$found = False
		For $i = 1 To UBound($baseinfo1)-1
			For $j = 1 To UBound($baseinfo2)-1
				If $baseinfo1[$i] == $baseinfo2[$j] Then
					Debug("Baseinfo: " & $baseinfo1[$i])
					$g_baseinfo = $baseinfo1[$i]
					$found = True
				EndIf
			Next
		Next
		If Not $found Then
			setconsole("Couldn't get baseinfo pointer", "Error")
			Return False
		Else
			setconsole("Found base info")
			$g_baseinfo -= 0x1A
			IniWrite($g_settings, "internal", "baseinfo", $g_baseinfo)
		EndIf
	EndIf
	; read again in case pointer changed
	$baseinfoCheck = _MemoryRead($g_baseinfo, $mem, "char[512]")
	$itemStats = _StringBetween($baseinfoCheck, "{c:ff6969ff}", "{/c}")
	If @Error Then
		setconsole("Couldn't parse base info", "Error")
		Return False
	EndIf

	setconsole("Finished initializing after " & Round(TimerDiff($initTimer)/1000,2) & " seconds")
	Return True
EndFunc