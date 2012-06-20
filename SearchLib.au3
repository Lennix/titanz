; All search-related stuff here which doesn't fit into the other categories

func addToSearchList($itemType, $subType, $rarity, $filter, $purchase)
	$idx = UBound($g_searchList)
	ReDim $g_searchList[$idx+1][6]
	$g_maxSearchIdx = $idx

	$g_searchList[$idx][1] = $itemType
	$g_searchList[$idx][2] = $subType
	$g_searchList[$idx][3] = $rarity
	$g_searchList[$idx][4] = $filter
	$g_searchList[$idx][5] = $purchase
EndFunc

Func GetFromSearchList($idx, ByRef $itemType, ByRef $subType, ByRef $rarity, ByRef $filter, ByRef $purchase)
	If $idx > $g_maxSearchIdx Then Return False
	$itemType = $g_searchList[$idx][1]
	$subType = $g_searchList[$idx][2]
	$rarity = $g_searchList[$idx][3]
	$filter = $g_searchList[$idx][4]
	$purchase = $g_searchList[$idx][5]
	Return True
EndFunc

Func ReloadSearchList()
	ReDim $g_searchList[1][6]
	$g_maxSearchIdx = 0
	loadSearchList()
EndFunc