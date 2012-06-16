#include "NomadMemory.au3"
#include "ClickLib.au3"
#include "BaseLib.au3"
#include "GUILib.au3"
#include "ComLib.au3"
#include "SearchLib.au3"
#include <Array.au3>
#include <ImageSearch.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>
#include <INet.au3>

Global $debugOut = true
Global $g_searchIdx = 0
Global $g_maxSearchIdx = 0

HotKeySet("{F10}", "mouseinfo")
HotKeySet("{F11}", "StartIt")

startup()

While 1
	if $start then
		$g_searchIdx += 1
		If $g_searchIdx > $g_maxSearchIdx Then $g_searchIdx = 1
		Search($g_searchIdx)
		D3sleep(2000)
	EndIf
	D3sleep(200)
WEnd

feierabend()

Func Reset()
	If IsArray($knownItems) Then ReDim $knownItems[1][5]
	$realtimepurchase = False
EndFunc

Func Search($idx)
	Local $type, $subType, $rarity, $stats, $purchase
	Reset()
	If Not GetFromSearchList($idx, $type, $subtype, $rarity, $stats, $purchase) Then Return False
	$price = $purchase[1]
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
	SaveToDB($savestats, $items)
	Return $items
EndFunc

Func SaveToDB($stats, $items)

EndFunc

Func ScanPages()
	D3Click("search") ; search
	D3sleep(250)
	Dim $items[1][5]
	While 1
		If Not GetData($items) Then ExitLoop
		If Not D3Click("next_page", -1, 1, true) Then ExitLoop ; Next page
		$timer = TimerInit()
		Do
			D3Sleep(50)
		Until CheckColor("prev_page") Or TimerDiff($timer) > 10000
	WEnd
	CleanItems($items)
	Return $items
EndFunc

Func Buy($nr)
	D3Click("firstitem", $nr, 1, false, "itemdiff")
	D3Click("buyout")
	D3sleep(10000)
	;D3Click("accept_buyout")
EndFunc

Func Bid($nr)
	D3Click("firstitem", $nr, 1, false, "itemdiff")
	D3Click("bid")
	D3sleep(10000)
	;D3Click("accept_buyout")
EndFunc

Func GetData(ByRef $items)
	For $i = 0 To 10
		$currMax = UBound($items)
		ReDim $items[$currMax+1][5]
		$item = GetItemData($i)
		CheckItem($item, $i)
		For $y = 0 To 4
			$items[$currMax][$y] = $item[$y]
		Next
	Next
	Return True
EndFunc

Func CheckItem($item, $nr)
	If $item[4] <> 102 Or Not $realtimepurchase Then Return false ; already sold
	If UBound($knownItems) > 1 Then ; multi-search
		$found = false
		For $i = 0 To UBound($knownItems)-1
			If $knownItems[$i][2] == $item[2] Then
				debug("Found an item twice! BO: " & $item[0] & ", Bid: " & $item[1])
				$found = true; item already known so it matches our parameters
				ExitLoop
			EndIf
		Next
		If Not $found Then Return false
	EndIf
	If $checkBuyout > 0 And $item[0] > 0 And $item[0] <= $checkBuyout Then
		Buy($nr)
	ElseIf $checkBid > 0 And $item[1] <= $checkBid Then
		Bid($nr)
	EndIf
EndFunc

Func GetItemData($nr)
	Dim $return[5]
	Local $offsets[5] = [0, 0, 4, 40, 32+280*$nr]

	$basepointer = _MemoryPointerRead($baseadd + 0xFA3DB0, $mem, $offsets)
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

	if $debugOut Then debug("Buyout: " & $return[0] & ", MinBid: " & $return[1] & ", currentBid: " & $return[3])

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

#cs
$max = 0
Dim $armorTypes[128] = ["All", "Axe", "Bow", "Daibo", "Crossbow", "Mace", "Mighty Weapon", "Polearm", "Staff", "Sword"]
For $i = 0 To 127
	If $armorTypes[$i] <> "" Then
		If $armorTypes[$i] <> "..." Then IniWrite("settings.ini","2-Hand", $armorTypes[$i], $i)
		$max += 1
	EndIf
Next
;IniWrite("settings.ini","1-Hand_all", "max", $max)
#ce

		#cs
		$checkBid = 0
		$checkBuyout = 1000000
		$items = Search("armor", "amulet", "All", "Dexterity", 140, -1, "Attack Speed", 14, "Critical Hit Chance", 4, "Critical Hit Damage", 40)
		$checkBid = 0
		$checkBuyout = 1000000
		$items = Search("armor", "amulet", "All", "Magic Find", 40)
		$checkBid = 0
		$checkBuyout = 1500000
		$items = Search("armor", "amulet", "All", "Magic Find", 35, -1, "Gold Find", 35)
		$checkBid = 0
		$checkBuyout = 300000
		$items = Search("armor", "ring", "All", "Magic Find", 18)
		$checkBid = 0
		$checkBuyout = 1000000
		$items = Search("armor", "amulet", "All", "Dexterity", 180, -1, "Critical Hit Damage", 50)
		$checkBid = 0
		$checkBuyout = 3000000
		$items = Search("armor", "gloves", "All", "Dexterity", 140, -1, "Critical Hit Damage", 30, "Attack Speed", 16)
		$checkBid = 0
		$checkBuyout = 1500000
		$items = Search("armor", "shoulders", "All", "Dexterity", 185)
		$checkBid = 0
		$checkBuyout = 3000000
		$items = Search("armor", "belt", "All", "Dexterity", 185)
		$checkBid = 0
		$checkBuyout = 1000000
		$items = Search("armor", "helm", "All", "Dexterity", 185)
		$checkBid = 0
		$checkBuyout = 3000000
		$items = Search("armor", "ring", "All", "Dexterity", 40, -1, "Attack Speed", 15, "Critical Hit Damage", 20)
		$checkBid = 0
		$checkBuyout = 1000000
		$items = Search("armor", "boots", "All", "Dexterity", 205, -1, "Movement Speed", 12)
		$checkBid = 0
		$checkBuyout = 2000000
		$items = Search("armor", "pants", "All", "Dexterity", 240, -1, "Has Sockets", 2)
		#ce