; All search-related stuff here which doesn't fit into the other categories

func addToSearchList($class, $itemType, $subType, $rarity, $filter, $purchase)
	$idx = UBound($g_searchList)
	ReDim $g_searchList[$idx+1][7]
	$g_maxSearchIdx = $idx

	$g_searchList[$idx][1] = $class
	$g_searchList[$idx][2] = $itemType
	$g_searchList[$idx][3] = $subType
	$g_searchList[$idx][4] = $rarity
	$g_searchList[$idx][5] = $filter
	$g_searchList[$idx][6] = $purchase
EndFunc

Func GetFromSearchList($idx, ByRef $class, ByRef $itemType, ByRef $subType, ByRef $rarity, ByRef $filter, ByRef $purchase)
	If $idx > $g_maxSearchIdx Then Return False
	$class = $g_searchList[$idx][1]
	$itemType = $g_searchList[$idx][2]
	$subType = $g_searchList[$idx][3]
	$rarity = $g_searchList[$idx][4]
	$filter = $g_searchList[$idx][5]
	$purchase = $g_searchList[$idx][6]
	Return True
EndFunc

Func ReloadSearchList()
	ReDim $g_searchList[1][7]
	$g_maxSearchIdx = 0
	loadSearchList()
EndFunc

Func Reset()
	For $i = 1 To 3
		ResetFilter($i)
	Next
EndFunc

Func Search($idx)
	Local $class, $type, $subType, $rarity, $filter, $purchase
	Reset()
	If Not GetFromSearchList($idx, $class, $type, $subtype, $rarity, $filter, $purchase) Then Return False
	$g_checkbid = $purchase[2]
	$g_checkBuyout = $purchase[3]
	ChooseClass($class)
	ChooseItemType($type, $subtype)
	ChooseRarity($rarity)
	SetPrice($purchase[1])
	ReDim $g_filter[UBound($filter)][2]
	$g_filter = $filter
	_Search()
EndFunc

Func _Search()
	; we're going to choose the filter here
	$count = 1
	For $i = 0 To Ubound($g_filter) -1
		If ChooseFilter($count, $g_filter[$i][0], $g_filter[$i][1]) Then $count += 1
		If $count > 3 Then ExitLoop
	Next
	ScanPages()
EndFunc

Func DebugPages()
	$oldDebug = $debugOut
	$debugOut = True
	ScanPages()
	$debugOut = $oldDebug
EndFunc

Func ScanPages()
	D3Click("search") ; search
	$timer = TimerInit()
	D3sleep(100)
	Do
		D3Sleep(25)
	Until CheckColor("prev_page_grey") Or TimerDiff($timer) > 5000
	While 1
		If Not GetData() Then ExitLoop
		Do
			D3Sleep(50)
		Until $g_queriesperhour < 800
		If Not CheckRun() Or Not D3Click("next_page", -1, 1, true) Then ExitLoop ; Next page
		$timer = TimerInit()
		Do
			D3Sleep(20)
			;If Not CheckColor("prev_page") And Not CheckColor("next_page") Then ExitLoop
		Until CheckColor("prev_page") Or TimerDiff($timer) > 5000
	WEnd
EndFunc

Func GetData()
	Dim $info[10][2]
	For $i = 0 To 10 ; All items
		$auction = GetAuctionData($i)
		If @Error Then ContinueLoop
		$item = GetItemData($i)
		If @Error Then ContinueLoop
		$info[$i][0] = $auction
		$Info[$i][1] = $item
		If Not CheckItem($auction, $item, $i) Then Return False
	Next
	SaveToDB($info)
	D3Move("home")
	Return True
EndFunc

Func CheckItem($auction, $item, $nr)
	If StringInStr($g_itemsKnown, $auction[0] & ",") Then Return True ; we already know that item no need to scan
	$g_itemsKnown &= $auction[0] & ","
	If @Error Then Return True
	For $i = 0 To UBound($g_filter)-1
		$stats = $item[0]
		$found = false
		If $g_filter[$i][0] == "EmptySockets" Then
			If lookForSocket($nr, $auction[0]) Then
				debug("Bid: " & $auction[1] & ", BO: " & $auction[2] & ", Empty socket!")
				$found = True
			EndIf
		Else
			For $j = 0 To Ubound($stats)-1
				If $stats[$j][0] == $g_filter[$i][0] Then
					debug("We are looking for " & $stats[$j][0])
					If $stats[$j][1] >= $g_filter[$i][1] Then $found = True
				EndIf
			Next
		EndIf
		If Not $found Then Return True
	Next

	If $auction[4] <> 102 Then Return True ; already sold

	If $g_checkBuyout > 0 And $auction[0] > 0 And $auction[0] <= $g_checkBuyout Then
		Return Buy($nr)
	ElseIf $g_checkBid > 0 And $auction[1] <= $g_checkBid Then
		Return Bid($nr)
	EndIf
EndFunc

Func GetAuctionData($nr)
	Dim $return[5]
	Local $offsets[5] = [0, 0, 4, 40, 32+280*$nr]

	$basepointer = _MemoryPointerRead($baseadd + 0xFC85B0, $mem, $offsets)
	If @Error Then
		debug("Error reading memory")
		Return SetError(1)
	EndIf

	$basepointer = $basepointer[0]

	$ID = 0xa0
	$currentbid = 0xb0
	$buyout = 0xb8
	$minbid = 0xc0
	$flags = 0xc8

	$return[0] = _MemoryRead($basepointer + $ID, $mem)
	$return[1] = _MemoryRead($basepointer + $minbid, $mem)
	$return[2] = _MemoryRead($basepointer + $buyout, $mem)
	$return[3] = _MemoryRead($basepointer + $currentbid, $mem)
	$return[4] = _MemoryRead($basepointer + $flags, $mem)

	If $return[4] <> 102 And $return[4] <> 104 Then Return SetError(1) ; invalid item
	if $debugOut Then debug("ID: " & $return[0] & ", MinBid: " & $return[1] & ", Buyout: " & $return[2] & ", currentBid: " & $return[3] & ", flags: " & $return[4])

	Return $return
EndFunc

Func GetItemData($nr)
	; first move over the item
	D3Move("firstitem", $nr, 1, false, "itemdiff")
	D3Sleep(50)

	Dim $return[5]
	Local $offsets[5] = [0, 4, 12, 8, 20]

	$itemDesc = _MemoryPointerRead($baseadd + 0xEEA1A8, $mem, $offsets)
	If @Error Then
		debug("Error reading memory")
		Return SetError(1)
	EndIf

	$itemDesc = $itemDesc[0]

	$return[0] = _MemoryRead($itemDesc, $mem, "char[512]") ; Basic Info
	$itemStats = _StringBetween($return[0], "{c:ff6969ff}", "{/c}")
	If @Error Then Return SetError(1)
	$return[0] = ParseStats($itemStats)

	$return[1] = _MemoryRead(0x1BEE334C, $mem, "char[10]") ; Armor / DPS
	Dim $socketInfo[3]
	$socketInfo[0] = StringTrimLeft(_MemoryRead(0x1BEE348C, $mem, "char[72]"), 14)
	$socketInfo[1] = StringTrimLeft(_MemoryRead(0x1BEE34DC, $mem, "char[72]"), 14)
	$socketInfo[2] = StringTrimLeft(_MemoryRead(0x1BEE352C, $mem, "char[72]"), 14)
	$return[2] = $socketInfo ; Socket
	$return[3] = StringTrimLeft(_MemoryRead(0x1BEE36BC, $mem, "char[14]"), 12) ; Item Level
	$itemType = _StringBetween(_MemoryRead(0x1BEE3324, $mem, "char[64]"), "}", "{") ; Item type
	If @Error Then Return SetError(1)
	$return[4] = $itemType[0]

	debug("Basic: " & $return[0] & ", Armor/DPS: " & $return[1] & ", Socket: " & $return[2] & ", ItemLvl: " & $return[3] & ", Type: " & $return[4])

	Return $return
EndFunc

Func ParseStats($stats)
	Dim $parsed[UBound($stats)][2]
	For $i = 0 To UBound($stats)-1
		$temp = ""
		$inner = StringSplit($stats[$i], " ")
		For $j = 0 To $inner[0]
			$replace = StringReplace($inner[$j], "+", "")
			$replace = StringReplace($replace, "%", "")
			If StringIsInt($replace) Or StringIsFloat($replace) Then
				$parsed[$i][1] = $replace
			Else
				$temp &= $replace
			Endif
		Next
		$parsed[$i][0] = $temp
	Next
	Return $parsed
EndFunc

; This function is called periodically
Func Watchdog()
	$item = GetAuctionData(0)
	If IsArray($item) And $item[2] <> $g_wd_lastitemID And ($item[4] == 102 Or $item[4] == 104) Then ; we have new (valid) data
		$g_wd_lastitemID = $item[2]
		$g_querycount += 1
	EndIf
	If $g_querycount > 0 Then
		$hours = TimerDiff($g_starttimer)/1000 / 60 / 60
		$g_queriesperhour = $g_querycount / $hours
	EndIf
EndFunc

Func SaveToDB($info)
	iGet("saveToDB","sid=" & $g_sid & "&info=" & $info)
EndFunc