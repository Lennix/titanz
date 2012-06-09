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
	D3Click("item_type", $type)

	D3Click("item_subtype") ; Open subfilter
	D3Click("item_subtype_scrollup", 9) ; Scroll up (reset)
	D3Click("item_subtype", $subtype) ; click
EndFunc

Func ChooseRarity($rarity)
	If Not IsNumber($rarity) Then $rarity = GetID("rarity", $rarity)
	D3Click("rarity") ; Open filter
	D3Click("rarity", $rarity)
EndFunc

Func ChooseFilter($nr, $type, $subtype, $entry, $value)
	If $entry == "" Then Return 0
	;ResetFilter($nr)
	$entry = GetID($type & "_" & $subtype, $entry)
	$max = GetID($type & "_" & $subtype, "Max")
	$max -= ($nr-1)
	debug("Entry: " & $entry & " @ Max: " & $max)
	D3Click("filter_" & $nr) ; Open filter
	D3sleep(200) ; wait for filter to open
	If ($entry > 10) Then ; kann nicht sofort klicken
		$clicks = Floor(($entry - 10) / 4) + 1
		If ($entry > $max - 10) Then ; ist ganz hinten
			$entry = 10 - ($max - $entry)
			$clicks = Floor($max / 4) + 1
		Else
			$entry = $entry - $clicks*4
		EndIf
		D3Scroll("filter_" & $nr, $clicks, "down")
		debug("Filter: " & $nr & ", Eintrag: " & $entry & ", Anzahl klicks: " & $clicks)
	EndIf
	D3Click("filter_" & $nr, $entry) ; click entry filter
	; Click on value
	D3Click("filtervalue_" & $nr)
	D3Send("{BACKSPACE 3}")
	D3Send($value)
EndFunc

Func ResetFilter($nr)
	D3Click("filter_" & $nr) ; Open filter
	D3Sleep(200) ; wait for filter to open
	D3Scroll("filter_" & $nr, 20, "up")
	D3Click("filter_" & $nr,1 ) ; choose first entry
EndFunc