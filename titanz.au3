#include "NomadMemory.au3"
#include "ClickLib.au3"
#include "BaseLib.au3"
#include "GUILib.au3"
#include <Array.au3>
#include <ImageSearch.au3>

#RequireAdmin

$start = false

HotKeySet("{F10}", "mouseinfo")
HotKeySet("{F11}", "StartIt")

$pid = WinGetProcess("Diablo III")
$mem = _MemoryOpen($pid)

WinActivate("Diablo III")

$module = "Diablo III.exe"

$baseadd = _MemoryModuleGetBaseAddress($pid, $module)

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

Global $checkBid = 0
Global $checkBuyout = 0
Global $realtimepurchase = false
Global $knownItems[1][5]

While 1
	if $start then
		Dim $stats[5][2]
		$stats[0][0] = "Critical Hit Damage"
		$stats[0][1] = 21
		$stats[1][0] = "Dexterity"
		$stats[1][1] = 80
		$stats[2][0] = "Critical Hit Chance"
		$stats[2][1] = 4
		$stats[3][0] = "Attack Speed"
		$stats[3][1] = 14
		$stats[4][0] = "Vitality"
		$stats[4][1] = 20
		$checkBid = 5000000
		$checkBuyout = 10000000
		$items = Search("armor", "gloves", "All", $stats)
		_ArrayDisplay($items)
		$start = False
	EndIf
	D3sleep(200)
WEnd

_MemoryClose($mem)

Func Search($type, $subtype, $rarity, $stats, $price = -1)
	ChooseItemType($type, $subtype)
	ChooseRarity($rarity)
	SetPrice($price)
	If UBound($stats) <= 3 Then
		$realtimepurchase = true
		Return _Search($stats)
	ElseIf UBound($stats) <= 5 Then
		Dim $tmpStats[3][2]
		For $i = 0 To 2
			$tmpStats[$i][0] = $stats[$i][0]
			$tmpStats[$i][1] = $stats[$i][1]
		Next
		$knownItems = _Search($tmpStats)
		$realtimepurchase = true
		If UBound($stats) <= 4 Then
			$tmpStats[2][0] = $stats[3][0]
			$tmpStats[2][1] = $stats[3][1]
			$items2 = _Search($tmpStats,2)
		Else
			$tmpStats[1][0] = $stats[3][0]
			$tmpStats[1][1] = $stats[3][1]
			$tmpStats[2][0] = $stats[4][0]
			$tmpStats[2][1] = $stats[4][1]
			$items2 = _Search($tmpStats,1)
		EndIf
	EndIf
EndFunc

Func _Search($stats, $same = 0)
	If $same < 1 Then ResetFilter(1)
	If $same < 2 Then ResetFilter(2)
	ResetFilter(3)
	If IsArray($stats) Then
		For $i = $same To UBound($stats)-1
			ChooseFilter($i+1, $stats[$i][0], $stats[$i][1])
		Next
	EndIf
	Return ScanPages()
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
	D3Click("accept_buyout")
EndFunc

Func Bid($nr)
	D3Click("firstitem", $nr, 1, false, "itemdiff")
	D3Click("bid")
	D3sleep(10000)
	D3Click("accept_buyout")
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
	If $checkBuyout > 0 And $item[0] > 0 And $item[0] <= $checkBuyout Then Buy($nr)
	If $checkBid > 0 And $item[1] <= $checkBid Then Bid($nr)
EndFunc

Func GetItemData($nr)
	Dim $return[5]
	Local $offsets[5] = [0, 0, 4, 40, 32+280*$nr]

	$basepointer = _MemoryPointerRead($baseadd + 0xF9D998, $mem, $offsets)
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