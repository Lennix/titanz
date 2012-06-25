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
	debug("Choosing filter " & $nr & " for " & $entry & " - " & $value)
	If $entry == "" Then Return 0
	If $entry == "Empty Sockets" Then $g_socketSearch = true
	If $filterInfo[$nr-1][0] <> $entry Then
		D3Click("filter_" & $nr) ; Open filter
		If Not lookFor($nr, $entry, 1) Then
			D3Click("filter_" & $nr) ; close filter
			Return False
		EndIf
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

Func Buy($nr)
	D3Click("firstitem", $nr, 1, false, "itemdiff")
	D3Click("buyout")
	debug("Buying " & $nr)
	d3sleep(2000)
	D3Click("accept_buyout")
	d3sleep(1000)
	D3Click("accept_buyout_notify")
	d3sleep(1000)
	Return True
EndFunc

Func Bid($nr)
	D3Click("firstitem", $nr, 1, false, "itemdiff")
	D3Click("bid")
	debug("Bidding " & $nr)
	d3sleep(2000)
	D3Click("accept_buyout")
	d3sleep(1000)
	D3Click("accept_buyout_notify")
	d3sleep(1000)
	Return True
EndFunc

#cs
loacalconfig positions we need:
- completed: firstitem_ahstash(filter4), sendtostash
- sell: firstitem_stash, startingprice, buyoutprice, createauction
#ce
Func Resell($itemId, $bid, $buyout)
	D3Click("completed")
	D3Sleep(200)
	;new scroll algorithm to find item at ah stash
	D3Click("sendtostash")
	D3Click("sell")
	D3Sleep(200)
	D3Click("firstitem_stash")
	SetResellPrice($bid, $buyout)
	D3Click("createauction")
EndFunc