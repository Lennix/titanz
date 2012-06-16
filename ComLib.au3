; This lib is used for ocmmunication with the server backend

Global $domain = "http://d3ahbot.com/"

Func connect()
	; We currently don't authenticate, just get item list
	loadSearchList()
EndFunc

Func loadSearchList()
	$input = iGet("listItems")
	$search = StringSplit($input, "|") ; main delimiter
	If @Error Then Return False
	For $i = 1 To $search[0]
		$inner = StringSplit($search[$i], ";") ; inner delimiter
		If @Error Or $inner[0] <> 5 Then ContinueLoop
		$itemType = $inner[1]
		$subType = $inner[2]
		$rarity = $inner[3]
		$t_filter = StringSplit($inner[4],",")
		If @Error Then ContinueLoop
		Dim $filter[$t_filter[0]][2]
		For $j = 0 To $t_filter[0]-1
			$innerArray = StringSplit($t_filter[$j+1], "-")
			If @Error Then ContinueLoop
			$filter[$j][0] = $innerArray[1]
			$filter[$j][1] = $innerArray[2]
		Next
		$purchase = StringSplit($inner[5],",")
		If @Error Then ContinueLoop
		addToSearchList($itemType, $subType, $rarity, $filter, $purchase)
	Next
EndFunc

Func iGet($action, $params = "")
	Return debug(_INetGetSource($domain & "backend.php?action=" & $action),1)
EndFunc