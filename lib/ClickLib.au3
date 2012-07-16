Func ChooseClass($class)
	If $debugOut Then debug("Choosing class " & $class)
	D3Click("class")
	$position = LookFor($class, "classsearch", 1)
	If @Error Then
		D3Click("class")
		Return False ; couldn't find desired class
	Else
		D3Click($position)
		Return True
	EndIf
EndFunc

Func ChooseItemType($type, $subtype = "All") ; 1Hand, 2Hand, Offhand, Armor, Follower Special
	; Get data
	If Not IsNumber($subtype) Then $subtype = GetID($type, $subtype)
	If Not IsNumber($type) Then $type = GetID("itemtypes", $type)

	D3Click("item_type") ; Open filter
	D3Click("item_type", $type)

	D3Click("item_subtype") ; Open subfilter
	D3Scroll("item_subtype", "up", 5) ; scroll up
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

Func ChooseFilter($nr, $entry, $value)
	If $debugOut Then debug("Choosing filter " & $nr & " for " & $entry & " - " & $value)
	If $entry == "" Then Return 0

	D3Click("filter_" & $nr) ; Open filter
	If Not lookForFilter($nr, $entry, 1) Then
		D3Click("filter_" & $nr) ; close filter
		Return False
	EndIf

	; Click on value
	D3Click("filtervalue_" & $nr)
	D3Send("{BACKSPACE 3}")
	D3Send($value)
	Return True
EndFunc

Func ResetFilter($nr)
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
	setconsole("Buying item nr" & $nr)
	d3sleep(2000)
	If Not CheckRun() Then Return False
	D3Click("accept_buyout")
	d3sleep(5000)
	D3Click("accept_buyout_notify")
	d3sleep(2000)
	Return False
EndFunc

Func Bid($nr)
	D3Click("firstitem", $nr, 1, false, "itemdiff")
	D3Click("bid")
	setconsole("Bidding on item nr" & $nr)
	d3sleep(2000)
	If Not CheckRun() Then Return False
	D3Click("accept_buyout")
	d3sleep(5000)
	D3Click("accept_buyout_notify")
	d3sleep(2000)
	Return False
EndFunc

Func craft()
	Do
		D3Click("craftgem")
		D3sleep(3000)
	Until Not CheckColor("craftgem")
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

Func SetResellPrice($bid, $buyout)
	D3Click("startingprice")
	If $bid > -1 Then D3Send($bid)
	D3Click("buyoutprice")
	If $buyout > -1 Then D3Send($buyout)
EndFunc