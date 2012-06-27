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

Func D3Scroll($position, $direction = "down", $count = 1)
	Dim $posiArray[2]
	$posiArray[0] = IniRead($g_confPath, $position, "x", 0)
	$posiArray[1] = IniRead($g_confPath, $position, "y", 0) + IniRead($g_confPath, "diff", "filterentrydiff", 0)
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

	; find process and get base adress
	Global $pid = WinGetProcess("Diablo III")
	Global $mem = _MemoryOpen($pid)
	$module = "Diablo III.exe"
	Global $baseadd = _MemoryModuleGetBaseAddress($pid, $module)
EndFunc

Func feierabend()
	_MemoryClose($mem)
EndFunc

Func lookFor($nr, $entry, $center = 0)
	; get filter context and look into settings if we already know the answer
	#cs
	$input = IniRead("conf/settings.ini", "lookFor", $g_searchList[$g_searchIdx][1] & "-" & $g_searchList[$g_searchIdx][2] & "-" & $entry, "")
	If StringLen($input) > 0 Then ; we already know what to do
		$input = StringSplit($input, ",") ; x,y, scrollamount
		If Not @Error Then
			If $input[3] > 0 Then
				D3Scroll("filter_" & $nr, "down", 5*$input[3])
				D3sleep(50)
			EndIf
			Dim $position[3]
			$position[0] = $input[1]
			$position[1] = $input[2]
			D3Click($position)
			$filterInfo[$nr-1][0] = $entry
			Return True
		EndIf
	EndIf
	#ce
	; in case we dont know that yet
	For $x = 0 To 10
		$tmpEntry = $entry
		If $entry == "Empty Sockets" Then $tmpEntry = "Has Sockets"
		$position = _LookFor($tmpEntry,1)
		If Not @Error Then
			D3Click($position)
			;IniWrite("conf/settings.ini", "lookFor", $g_searchList[$g_searchIdx][1] & "-" & $g_searchList[$g_searchIdx][2] & "-" & $entry, $position[0] & "," & $position[1] & "," & $x)
			$filterInfo[$nr-1][0] = $entry
			Return True
		EndIf
		D3Scroll("filter_" & $nr, "down", 5)
		If $x == 10 Then Return False
	Next
EndFunc

Func _lookFor($stat, $center = 0)
	$left = IniRead($g_confPath, "filterwindow", "left", 0)
	$top = IniRead($g_confPath, "filterwindow", "top", 0)
	$right = IniRead($g_confPath, "filterwindow", "right", 0)
	$bottom = IniRead($g_confPath, "filterwindow", "bottom", 0)
	$stat = StringStripWS($stat,8)
	Dim $position[2]
	$res= _ImageSearchArea("D3AHImages\" & $stat & ".jpg",$center,$left,$top,$right,$bottom, $position[0],$position[1],100)
	If $res = 1 Then
		Return $position
	EndIf
	Return SetError(1,0, $position)
EndFunc

Func lookForSocket($nr, $id)
	If StringInStr($g_socketKnown, $id & ",") Then Return SetError(1,0, false); we already know that item no need to scan
	$g_socketKnown &= $id & ","
	Dim $itemPosition[2]
	$itemPosition[0] = IniRead($g_confPath, "firstitem", "x", 0)
	$itemPosition[1] = IniRead($g_confPath, "firstitem", "y", 0)
	$curPos = MouseGetPos()
	$diff = sqrt(($curPos[0] - $itemPosition[0])^2+($curPos[1] - ($itemPosition[1] + $nr*IniRead($g_confPath, "diff", "itemdiff", 0)))^2)
	MouseMove($itemPosition[0], $itemPosition[1] + $nr*IniRead($g_confPath, "diff", "itemdiff", 0),1)
	D3Sleep(Round($diff/3))
	$left = IniRead($g_confPath, "socketsearch", "left", 0)
	$top = IniRead($g_confPath, "socketsearch", "top", 0)
	$right = IniRead($g_confPath, "socketsearch", "right", 0)
	$bottom = IniRead($g_confPath, "socketsearch", "bottom", 0)
	Dim $position[2]
	$res= _ImageSearchArea("D3AHImages\EmptySocket.jpg",0,$left,$top,$right,$bottom, $position[0],$position[1],100)
	If $res = 1 Then Return $position
	Return SetError(1,0, $position)
EndFunc