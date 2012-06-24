; This lib is used for ocmmunication with the server backend

Global $domain = "http://d3ahbot.com/"

Func connect()
	debug("Connecting to backend")
	; first login and get sessionID
	$hRequest = iGet("login", "username=lennix&password=fa79010cf00be721e94e8d804c490f9b0658d5c7f69c0337dbdb4248dcfa3c9f")
	If $hRequest[1][1] == "success" Then
		$g_sid = $hRequest[2][1]
		; load itemList
		loadSearchList()
	Else
		debug("Failed to authenticate with backend")
	EndIf

EndFunc

Func loadSearchList()
	$input = iGet("listItems", "sid=" & $g_sid)
	if @Error Then Return debug("Noooo!")
	$input = $input[2][1]
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
	$hOpen = _WinHttpOpen()
	$hConnect = _WinHttpConnect($hOpen, "d3ahbot.com")
	$hRet = _JSONDecode(debug(_WinHttpSimpleRequest($hConnect, "POST", "index.php?component=backend&action=" & $action, "", $params)))
	_WinHttpCloseHandle($hOpen)
	If $hRet[1][1] == "fail" Then SetError(1)
	Return $hRet
EndFunc