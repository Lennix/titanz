#include <Array.au3>
#include <String.au3>

#include "UDF/NomadMemory.au3"
#include "UDF/ImageSearch.au3"
#include "UDF/WinHttp.au3"
#include "UDF/JSON.au3"

#include "lib/ClickLib.au3"
#include "lib/BaseLib.au3"
#include "lib/GUILib.au3"
#include "lib/ComLib.au3"
#include "lib/SearchLib.au3"

HotKeySet("{F7}","quit")
HotKeySet("{F8}", "StopIt")
HotKeySet("{F9}", "StartIt")
HotKeySet("{F10}", "mouseinfo")
HotKeySet("{F11}", "craft")

startup()

While 1
	$msg = GUIGetMsg(1)
	If $msg[0] <> 0 Then GUIcheck($msg)

	If CheckRun(True) then
		$g_searchIdx += 1
		ReloadSearchList() ; we will reload the circle every time
		If $g_searchIdx > $g_maxSearchIdx Then $g_searchIdx = 1
		Search($g_searchIdx)
	EndIf
	D3sleep(25)
WEnd

feierabend()
