Func ScanPages()
	D3Click("search") ; search
	Dim $items[1][5]
	While 1
		If Not GetData($items) Then ExitLoop
		D3Click("next_page") ; Next page
	WEnd
	_ArrayDisplay($items)
EndFunc

Func ChooseItemType($type, $subtype = "All") ; 1Hand, 2Hand, Offhand, Armor, Follower Special
	; Get data
	If Not IsNumber($subtype) Then $subtype = GetID($type, $subtype)
	If Not IsNumber($type) Then $type = GetID("itemtypes", $type)

	D3Click("item_type") ; Open filter
	D3Click(833, 566+$type*40)

	D3Click("item_subtype") ; Open subfilter
	D3Click("item_subtype_scrollup", 9) ; Scroll up (reset)
	D3Click(792, 625+$subtype*40) ; click
EndFunc

Func ChooseRarity($rarity)
	If Not IsNumber($rarity) Then $rarity = GetID("rarity", $rarity)
	D3Click("rarity") ; Open filter
	D3Click(833, 735+$rarity*40)
EndFunc

Func ChooseFilter($nr, $type, $subtype, $entry, $value)
	If $entry == "" Then Return 0
	;ResetFilter($nr)
	$entry = GetID($type & "_" & $subtype, $entry)
	$max = GetID($type & "_" & $subtype, "Max")
	$max -= ($nr-1)
	debug("Entry: " & $entry & " @ Max: " & $max)
	D3Click(770, 793 + ($nr-1) * 50) ; Open filter
	D3sleep(200)
	; Search for scrollbar
	$scrollup = PixelSearch(527, 821 + ($nr-1)*50, 1070, 867+ ($nr-1)*50, 16763272,3)
	If ($entry > 10) Then ; kann nicht sofort klicken
		$clicks = Floor(($entry - 10) / 4) + 1
		If ($entry > $max - 10) Then ; ist ganz hinten
			$entry = 10 - ($max - $entry)
			$clicks = Floor($max / 4) + 1
		Else
			$entry = $entry - $clicks*4
		EndIf
		D3Click($scrollup[0], $scrollup[1] + 365, 9*$clicks) ; nach unten scrollen
		debug("Filter: " & $nr & ", Eintrag: " & $entry & ", Anzahl klicks: " & $clicks)
	EndIf
	D3Click(770, 850 + ($nr - 1)*50 + $entry * 40) ; click entry filter
	; Click on value
	D3Click(842, 800 + ($nr - 1)*50)
	D3Send("{BACKSPACE 3}")
	D3Send($value)
EndFunc

Func ResetFilter($nr)
	D3Click(770, 793 + ($nr-1) * 50) ; Open filter
	$scrollup = PixelSearch(527, 821 + ($nr-1)*50, 1070, 867+ ($nr-1)*50, 16763272,3)
	If @Error Then Return D3Click(770, 793 + ($nr-1) * 50) ; Open filter
	D3Click($scrollup[0], $scrollup[1], 160) ; scrollup
	D3Click(770, 850 + ($nr-1) * 50) ; click first entry
EndFunc