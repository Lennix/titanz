Func ChooseItemType($type, $subtype = "All") ; 1Hand, 2Hand, Offhand, Armor, Follower Special
	; Get data
	If Not IsNumber($subtype) Then $subtype = GetID($type, $subtype)
	If Not IsNumber($type) Then $type = GetID("itemtypes", $type)

	D3Click("item_type") ; Open filter
	D3Click("item_type", $type)

	D3Click("item_subtype") ; Open subfilter
	D3Scroll("item_subtype", "up", 5) ; scroll up
	;D3Click("item_subtype_scrollup", 9) ; Scroll up (reset)
	D3Click("item_subtype", $subtype) ; click
EndFunc

Func ChooseRarity($rarity)
	If Not IsNumber($rarity) Then $rarity = GetID("rarity", $rarity)
	D3Click("rarity") ; Open filter
	D3Click("rarity", $rarity)
EndFunc

Func SetPrice($price)
	D3Click("price")
	D3Send("{BACKSPACE 10}")
	If $price > -1 Then D3Send($price)
EndFunc

Func SetResellPrice($bid, $buyout)
	D3Click("startingprice")
	If $bid > -1 Then D3Send($bid)
	D3Click("buyoutprice")
	If $buyout > -1 Then D3Send($buyout)
EndFunc

Func ChooseFilter($nr, $entry, $value)
	If $entry == "" Then Return 0
	If $entry == "Empty Sockets" Then $g_socketSearch = true
	If $filterInfo[$nr-1][0] <> $entry Then
		D3Click("filter_" & $nr) ; Open filter
		For $x = 0 To 10
			$tmpEntry = $entry
			If $entry == "Empty Sockets" Then $tmpEntry = "Has Sockets"
			$position = LookFor($tmpEntry,1)
			If Not @Error Then
				D3Click($position)
				$filterInfo[$nr-1][0] = $entry
				ExitLoop
			EndIf
			D3Scroll("filter_" & $nr, "down", 5)
			If $x == 10 Then Return False
		Next
	EndIf

	If $filterInfo[$nr-1][1] <> $value Then
		; Click on value
		$filterInfo[$nr-1][1] = $value
		D3Click("filtervalue_" & $nr)
		D3Send("{BACKSPACE 3}")
		D3Send($value)
	EndIf
	Return True
EndFunc

Func ResetFilter($nr)
	$filterInfo[$nr-1][0] = ""
	$filterInfo[$nr-1][1] = 0
	D3Click("filter_" & $nr) ; Open filter
	D3Sleep(200) ; wait for filter to open
	D3Scroll("filter_" & $nr, "up", 30)
	D3Click("filter_" & $nr, 0) ; choose first entry
	D3Click("filtervalue_" & $nr)
	D3Send("{BACKSPACE 3}")
EndFunc