; All search-related stuff here which doesn't fit into the other categories

func addToSearchList($itemType, $subType, $rarity, $filter, $purchase)
	$idx = UBound($g_searchList)
	ReDim $g_searchList[$idx+1][6]
	$g_maxSearchIdx = $idx

	$g_searchList[$idx][1] = $itemType
	$g_searchList[$idx][2] = $subType
	$g_searchList[$idx][3] = $rarity
	$g_searchList[$idx][4] = $filter
	$g_searchList[$idx][5] = $purchase
EndFunc

Func GetFromSearchList($idx, ByRef $itemType, ByRef $subType, ByRef $rarity, ByRef $filter, ByRef $purchase)
	If $idx > $g_maxSearchIdx Then Return False
	$itemType = $g_searchList[$idx][1]
	$subType = $g_searchList[$idx][2]
	$rarity = $g_searchList[$idx][3]
	$filter = $g_searchList[$idx][4]
	$purchase = $g_searchList[$idx][5]
	Return True
EndFunc

Func ReloadSearchList()
	ReDim $g_searchList[1][6]
	$g_maxSearchIdx = 0
	loadSearchList()
EndFunc

Func Reset($full = false)
	If $full Then ReloadSearchList()
	If IsArray($knownItems) Then ReDim $knownItems[1][5]
	$realtimepurchase = False
EndFunc

Func Search($idx)
	Local $type, $subType, $rarity, $stats, $purchase
	$g_socketSearch = false
	Reset()
	If Not GetFromSearchList($idx, $type, $subtype, $rarity, $stats, $purchase) Then Return False
	$price = $purchase[1]
	$checkbid = $purchase[2]
	$checkBuyout = $purchase[3]
	ChooseItemType($type, $subtype)
	ChooseRarity($rarity)
	SetPrice($price)
	If UBound($stats) <= 3 Then
		$realtimepurchase = true
		_Search($stats)
		If @Error Then Return False
	ElseIf UBound($stats) <= 5 Then
		Dim $tmpStats[3][2]
		For $i = 0 To 2
			$tmpStats[$i][0] = $stats[$i][0]
			$tmpStats[$i][1] = $stats[$i][1]
		Next
		$knownItems = _Search($tmpStats)
		If @Error Then Return False
		$realtimepurchase = true
		If UBound($stats) <= 4 Then
			$tmpStats[2][0] = $stats[3][0]
			$tmpStats[2][1] = $stats[3][1]
			$items2 = _Search($tmpStats)
		Else
			$tmpStats[1][0] = $stats[3][0]
			$tmpStats[1][1] = $stats[3][1]
			$tmpStats[2][0] = $stats[4][0]
			$tmpStats[2][1] = $stats[4][1]
			$items2 = _Search($tmpStats)
		EndIf
		SaveToDB($stats, MergeItems($knownItems, $items2))
	EndIf
EndFunc

Func _Search($stats)
	$savestats = $stats
	Dim $filterLock[3]
	; first filter check if they can keep their stats
	For $i = 0 To 2 ; filterInfo
		For $j = 0 To Ubound($stats) - 1
			If $stats[$j][0] <> "" And $filterInfo[$i][0] == $stats[$j][0] Then
				If Not ChooseFilter($i+1, $stats[$j][0], $stats[$j][1]) Then Return SetError(1, 0, False)
				$filterLock[$i] = true
				$stats[$j][0] = "" ; clear stat
				ExitLoop
			EndIf
		Next
	Next
	; now set remaining filters
	For $j = 0 To UBound($stats) - 1
		If $stats[$j][0] <> "" Then
			For $i = 0 To 3
				If Not $filterLock[$i] Then
					If $filterInfo[$i][0] <> "" Then ResetFilter($i+1)
					If Not ChooseFilter($i+1, $stats[$j][0], $stats[$j][1]) Then Return SetError(1, 0, False)
					$filterLock[$i] = true
					ExitLoop
				EndIf
			Next
		EndIf
	Next
	; clear remaining filters
	For $i = 0 To 2
		If Not $filterLock[$i] And $filterInfo[$i][0] <> "" Then ResetFilter($i+1)
	Next
	$items = ScanPages()
	;SaveToDB($savestats, $items)
	Return $items
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
	Dim $items[1][5]
	While 1
		If Not GetData($items) Then ExitLoop
		If Not D3Click("next_page", -1, 1, true) Then ExitLoop ; Next page
		$timer = TimerInit()
		Do
			D3Sleep(20)
			;If Not CheckColor("prev_page") And Not CheckColor("next_page") Then ExitLoop
		Until CheckColor("prev_page") Or TimerDiff($timer) > 5000
		D3Sleep(250)
	WEnd
	CleanItems($items)
	Return $items
EndFunc

Func GetData(ByRef $items)
	For $i = 0 To 10
		$currMax = UBound($items)
		ReDim $items[$currMax+1][5]
		$item = GetItemData($i)
		If Not CheckItem($item, $i) Then Return False
		For $y = 0 To 4
			$items[$currMax][$y] = $item[$y]
		Next
	Next
	Return True
EndFunc

Func CheckItem($item, $nr)
	If $item[4] <> 102 Or Not $realtimepurchase Then Return True ; already sold
	If $g_socketSearch Then
		lookForSocket($nr, $item[2])
		If @Error Then
			Return True
		Else
			debug("Bid: " & $item[1] & ", BO: " & $item[0] & ", Empty socket!")
		EndIf
	EndIf
	If UBound($knownItems) > 1 Then ; multi-search
		$found = false
		For $i = 0 To UBound($knownItems)-1
			If $knownItems[$i][2] == $item[2] Then
				debug("Found an item twice! BO: " & $item[0] & ", Bid: " & $item[1])
				$found = true; item already known so it matches our parameters
				ExitLoop
			EndIf
		Next
		If Not $found Then Return True
	EndIf
	If $checkBuyout > 0 And $item[0] > 0 And $item[0] <= $checkBuyout Then
		Return Buy($nr)
	ElseIf $checkBid > 0 And $item[1] <= $checkBid Then
		Return Bid($nr)
	EndIf
EndFunc

Func GetItemData($nr)
	Dim $return[5]
	Local $offsets[5] = [0, 0, 4, 40, 32+280*$nr]

	$basepointer = _MemoryPointerRead($baseadd + 0xFC7590, $mem, $offsets)
	If @Error Then
		debug("Error reading memory")
		Return 0
	EndIf

	$basepointer = $basepointer[0]

	$timeleft = 0xa0
	$currentbid = 0xb0
	$buyout = 0xb8
	$minbid = 0xc0
	$flags = 0xc8
	$ID = 0xe0
	; 0x108, 0x110, 0x118

	$return[0] = _MemoryRead($basepointer + $buyout, $mem)
	$return[1] = _MemoryRead($basepointer + $minbid, $mem)
	$return[2] = _MemoryRead($basepointer + $timeleft, $mem)
	$return[3] = _MemoryRead($basepointer + $currentbid, $mem)
	$return[4] = _MemoryRead($basepointer + $flags, $mem)

	if $debugOut Then debug("ID: " & $return[2] & ", Buyout: " & $return[0] & ", MinBid: " & $return[1] & ", currentBid: " & $return[3])

	Return $return
EndFunc

Func CleanItems(ByRef $items)
	$max = UBound($items)-1
	If $max > 12 Then
		For $i = $max To $max - 11 Step -1
			If $items[$i][2] == $items[$i-11][2] Then _ArrayDelete($items, $i)
		Next
	EndIf
	For $i = UBound($items)-1 To 0 Step -1
		If $items[$i][4] <> 102 Then _ArrayDelete($items, $i)
	Next
EndFunc

Func MergeItems($items1, $items2)
	Dim $items[1][5]
	$currMax = 1
	For $i = 0 To Ubound($items1)-1
		For $y = 0 To UBound($items2)-1
			If $items1[$i][2] == $items2[$y][2] Then
				$currMax += 1
				ReDim $items[$currMax][5]
				For $d = 0 To 4
					$items[$currMax-1][$d] = $items1[$i][$d]
				Next
				ExitLoop
			EndIf
		Next
	Next
	Return $items
EndFunc