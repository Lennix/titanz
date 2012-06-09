#include "NomadMemory.au3"
#include "ClickLib.au3"
#include "BaseLib.au3"
#include "GUILib.au3"
#include <Array.au3>

#RequireAdmin

$start = false

HotKeySet("{F10}", "mouseinfo")
HotKeySet("{F11}", "StartIt")

$pid = WinGetProcess("Diablo III")
$mem = _MemoryOpen($pid)

$module = "Diablo III.exe"

$baseadd = _MemoryModuleGetBaseAddress($pid, $module)

#cs
$max = 0

Dim $armorTypes[128] = ["None", "...", "Attack Speed", "...", "...", "...", "...", "...", "...", "...", "...", "...", "...", "...", "...", "...", "...", "...", "...", "...", "Critical Hit Damage", "Dexterity", "Experience", "Has Sockets", "Hatred Regeneration", "Indestructible", "Intelligence", "Life Steal", "Life after Kill", "Life on Hit", "Life per Spirit Spent", "Mana Regeneration", "Max Arcane Power", "Max Discipline", "Max Fury", "Max Mana", "Min Bleed Damage", "Reduced Level", "Spirit Regeneration", "Strength", "Vitality", "...", "...", "...", "...", "...", "..."]
For $i = 0 To 127
	If $armorTypes[$i] <> "" Then
		If $armorTypes[$i] <> "..." Then IniWrite("settings.ini","1-Hand_all", $armorTypes[$i], $i)
		$max += 1
	EndIf
Next
IniWrite("settings.ini","1-Hand_all", "max", $max)
#ce
Dim $stats[2][2]
$stats[0][0] = "Experience"
$stats[0][1] = 200
$stats[1][0] = "Dexterience"
$stats[1][1] = 200
Search("1-Hand", "All", "Rare", $stats, 100000)

$latesttime = 0

While 1
	if $start then
		;ScanPages()
		;D3Sleep(30000)
	EndIf
	D3sleep(200)
WEnd

_MemoryClose($mem)

Func Search($type, $subtype, $rarity, $stats, $price)
	ChooseItemType($type, $subtype)
	ChooseRarity($rarity)
	ResetFilter(1)
	ResetFilter(2)
	ResetFilter(3)
	For $i = 0 To UBound($stats)-1
		ChooseFilter($i, $type, $subtype, $stats[$i][0], $stats[$i][1])
	Next
	SetPrice($price)
	D3Click("search") ; search
	D3Sleep(500); Wait for result
	If CheckColor("item1") Then Buy(1)
EndFunc

Func Buy($nr)
	; We currently only buy item 1
	D3Click("item1")
	D3Click("Buyout")
	D3sleep(500)
	D3Click("accept_buyout")
EndFunc

Func GetData(ByRef $items)
	For $i = 0 To 10
		$item = GetItemData($i)

		_ArrayAdd($items, $item)
	Next
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