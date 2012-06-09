Func ScanPages()
	D3Click(699, 1119) ; search
	Dim $items[1][5]
	While 1
		If Not GetData($items) Then ExitLoop
		D3Click(1634, 1093) ; Next page
	WEnd
	_ArrayDisplay($items)
EndFunc

Func ChooseItemType($type, $subtype = "All") ; 1Hand, 2Hand, Offhand, Armor, Follower Special
	; Get data
	If Not IsNumber($subtype) Then $subtype = GetID($type, $subtype)
	If Not IsNumber($type) Then $type = GetID("itemtypes", $type)

	D3Click(833, 510) ; Open filter
	D3Click(833, 566+$type*40)

	D3Click(833, 570) ; Open subfilter
	D3Click(833, 626, 9) ; Scroll up (reset)
	D3Click(792, 625+$subtype*40) ; click
EndFunc

Func ChooseRarity($rarity)
	If Not IsNumber($rarity) Then $rarity = GetID("rarity", $rarity)
	D3Click(833, 680) ; Open filter
	D3Click(833, 735+$rarity*40)
EndFunc

Func ChooseFilter($nr, $type, $subtype, $entry, $value)
	If $entry == "" Then Return 0
	;ResetFilter($nr)
	$entry = GetID($type & "_" & $subtype, $entry)
	$max = GetID($type & "_" & $subtype, "Max")
	debug("Entry: " & $entry & " @ Max: " & $max)
	D3Click(770, 793 + ($nr-1) * 50) ; Open filter
	If ($entry > 10) Then ; kann nicht sofort klicken
		$clicks = Floor(($entry - 10) / 4) + 1
		If ($entry > $max - 10) Then ; ist ganz hinten
			$entry = 9 - ($max - $entry)
			$clicks = Floor($max / 4) + 1
		Else
			$entry = $entry - $clicks*4
		EndIf
		D3Click(1000,1217 + ($nr - 1)*50, 9*$clicks) ; nach unten scrollen
		debug("Filter: " & $nr & ", Eintrag: " & $entry & ", Anzahl klicks: " & $clicks)
	EndIf
	D3Click(770, 850 + ($nr - 1)*50 + $entry * 40) ; click entry filter
	; Click on value
	D3Click(842, 800 + ($nr - 1)*50)
	D3Send("{^a}")
	D3Send($value)
EndFunc

Func ResetFilter($nr)
	D3Click(770, 793 + ($nr-1) * 50) ; Open filter
	D3Click(1000, 850 + ($nr-1) * 50, 160)
	D3Click(770, 850 + ($nr-1) * 50) ; click first entry
EndFunc