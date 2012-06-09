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

;Search("1-Hand", "All", "Rare", "Experience", 200, "Dexterity", 10, "", 0)

$latesttime = 0

While 1
	if $start then
		;ScanPages()
		;D3Sleep(30000)
	EndIf
	D3sleep(200)
WEnd

_MemoryClose($mem)

Func Search($type, $subtype, $rarity, $stat1, $value1, $stat2, $value2, $stat3, $value3)
	ChooseItemType($type, $subtype)
	ChooseRarity($rarity)
	ResetFilter(1)
	ResetFilter(2)
	ResetFilter(3)
	ChooseFilter(1, $type, $subtype, $stat1, $value1)
	ChooseFilter(2, $type, $subtype, $stat2, $value2)
	ChooseFilter(3, $type, $subtype, $stat3, $value3)
	D3Click(698, 1115) ; search
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