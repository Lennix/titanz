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
	If $g_testMode Then
		GetData()
		d3sleep(30000)
		Return True
	EndIf
	Local $class, $type, $subType, $rarity, $filter, $purchase
	Reset()
	If Not GetFromSearchList($idx, $class, $type, $subtype, $rarity, $filter, $purchase) Then Return False
	IniWrite($g_settings, "search", "currentsearchid", $idx)
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
	$max = UBound($g_filter) -1
	If $max > 2 Then $max = 2
	For $i = 0 To $max
		If Not ChooseFilter($i+1, $g_filter[$i][0], $g_filter[$i][1]) Then Return False
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
	$pagecount = 0
	While 1
		If Not GetData() Then ExitLoop
		$pagecount += 1
		D3Sleep(1000) ; basesleep of 1 second
		Do
			D3Sleep(50)
		Until $g_queriesperhour < $g_targetQPH
		If Not CheckRun() Or Not D3Click("next_page", -1, 1, true) Then ExitLoop ; Next page
		$timer = TimerInit()
		Do
			D3Sleep(20)
			;If Not CheckColor("prev_page") And Not CheckColor("next_page") Then ExitLoop
		Until CheckColor("prev_page") Or TimerDiff($timer) > 5000
	WEnd
	setconsole("Filter " & $g_searchIdx & " pagecount: " & $pagecount)
EndFunc

Func GetData()
	Dim $auctions[11]
	For $i = 0 To 10 ; All items
		$auction = GetAuctionData($i)
		If @Error Then ContinueLoop
		$auctions[$i] = $auction
	Next
	$knownIDs = SendAuctionsToDB($auctions) ; this will return the itemIDs we may inspect
	Dim $items[11]
	For $i = 0 To 10
		$auction = GetAuctionData($i)
		If @Error Or StringInStr($knownIDs,$auction[0]) > 0 Then ContinueLoop
		$item = GetItemData($i)
		If @Error Then
			setconsole("Couldn't get item information")
			ContinueLoop
		EndIf
		If Not CheckItem($auction, $item, $i) Then ExitLoop
		_ArrayInsert($item, 0, $auction[0])
		$items[$i] = $item
	Next
	SendItemsToDB($items)
	D3Move("home")
	Return True
EndFunc

Func CheckItem($auction, $item, $nr)
	$stats = $item[0]
	For $i = 0 To UBound($g_filter)-1
		If $g_filter[$i][0] == "HasSockets" Then ContinueLoop
		$found = false
		If $g_filter[$i][0] == "EmptySockets" Then
			If lookForSocket($nr, $auction[0]) Then $found = True
		Else
			For $j = 0 To Ubound($stats)-1 Step 2
				If $stats[$j] == $g_filter[$i][0] And $stats[$j+1] - $g_filter[$i][1] >= 0 Then $found = True
			Next
		EndIf
		If Not $found Then Return True
	Next

	If $auction[4] <> 102 Then Return True ; already sold

	If $g_checkBuyout > 0 And $auction[2] > 0 And $auction[2] <= $g_checkBuyout Then
		Return Buy($nr)
	ElseIf $g_checkBid > 0 And $auction[1] <= $g_checkBid Then
		Return Bid($nr)
	EndIf
EndFunc

Func GetAuctionData($nr)
	Dim $return[5]
	Local $offsets[5] = [0, 0, 4, 40, 32+280*$nr]

	$basepointer = _MemoryPointerRead($baseadd + 0xFC75B0, $mem, $offsets)
	If @Error Then
		debug("Error reading memory")
		$g_testMode = true
		Return SetError(2)
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
	D3Sleep(150)
	$error = False

	Dim $return[5]

	$return[0] = _MemoryRead($g_baseinfo, $mem, "char[512]") ; Basic Info

	If $g_memoryCheck == $return[0] Then
		setconsole("Read the same twice!")
		debug($return[0])
		d3sleep(10000)
		Return SetError(1)
	EndIf
	$g_memoryCheck = $return[0]

	$itemStats = _StringBetween($return[0], "{c:ff6969ff}", "{/c}")
	If @Error Then
		setconsole("Couldn't parse base info")
		debug($return[0])
		d3sleep(10000)
		Return SetError(1)
	EndIf

	$return[0] = ParseStats($itemStats)

	$return[1] = _MemoryRead($g_itembase + 0xFF0, $mem, "char[10]") ; Armor / DPS
	Dim $socketInfo[3]
	$socketInfo[0] = StringTrimRight(StringTrimLeft(_MemoryRead($g_itembase + 0x1130, $mem, "char[72]"), 14),1)
	$socketInfo[1] = StringTrimRight(StringTrimLeft(_MemoryRead($g_itembase + 0x1180, $mem, "char[72]"), 14),1)
	$socketInfo[2] = StringTrimRight(StringTrimLeft(_MemoryRead($g_itembase + 0x11D0, $mem, "char[72]"), 14),1)
	$return[2] = ParseStats($socketInfo) ; Socket
	$return[3] = StringTrimLeft(_MemoryRead($g_itembase + 0x1360, $mem, "char[14]"), 12) ; Item Level
	$itemType = _StringBetween(_MemoryRead($g_itembase + 0xFC8, $mem, "char[64]"), "}", "{") ; Item type
	If @Error Then
		setconsole("Couldn't parse item type")
		Return SetError(1)
	EndIf
	$return[4] = $itemType[0]

	;debug("Basic: " & $return[0] & ", Armor/DPS: " & $return[1] & ", Socket: " & $return[2] & ", ItemLvl: " & $return[3] & ", Type: " & $return[4])

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
			$replace = StringReplace($replace, ".", "")
			If StringIsInt($replace) Or StringIsFloat($replace) Then
				$parsed[$i][1] = $replace
			Else
				$temp &= $replace
			Endif
		Next
		$parsed[$i][0] = $temp
	Next
	Dim $tmpInfo[UBound($stats)*2]
	For $i = 0 To UBound($parsed)-1
		$tmpInfo[$i*2] = $parsed[$i][0]
		$tmpInfo[$i*2+1] = $parsed[$i][1]
	Next
	Return $tmpInfo
EndFunc

Func MergeData($auction, $item)
	Dim $return[UBound($auction)+UBound($item)]
	For $i = 0 To Ubound($auction)-1
		$return[$i] = $auction[$i]
	Next
	For $i = 0 To UBound($item)-1
		$return[UBound($auction)+$i] = $item[$i]
	Next
	Return $return
EndFunc

; This function is called periodically
Func Watchdog()
	If $g_testMode Then Return True
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

Func SendAuctionsToDB($info)
	$response = iGet("sendAuctions","info=" & _JSONEncode($info))
	If @Error Then Return ""
	Return $response[2][1]
EndFunc

Func SendItemsToDB($info)
	iGet("sendItems","info=" & _JSONEncode($info))
EndFunc

Func FillTestData()
	Dim $return[11]
	For $i = 0 To 10
		Dim $info[10]
		$info[0] = Random(1,1337,1)
		$info[1] = Random(1,100000000,1)
		$info[2] = Random(1,100000000,1)
		$info[3] = Random(1,100000000,1)
		$info[4] = 104
		Dim $baseInfo[6]
		$baseInfo[0] = "Dexterity"
		$baseInfo[1] = Random(100,200,1)
		$baseInfo[2] = "Vitality"
		$baseInfo[3] = Random(100,200,1)
		$baseInfo[4] = "AllResistance"
		$baseInfo[5] = Random(10,50,1)
		$info[5] = $baseInfo
		$info[6] = Random(200,400,1)
		Dim $socket[6]
		$socket[0] = "Dexterity"
		$socket[1] = 38
		$socket[2] = "Dexterity"
		$socket[3] = 42
		$socket[4] = "Dexterity"
		$socket[5] = 42
		$info[7] = $socket
		$info[8] = Random(60,63,1)
		$info[9] = "Rare Chest"
		$return[$i] = $info
	Next
	Return $return
EndFunc