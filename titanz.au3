#include <Array.au3>

Global $debugOut = false
Global $g_searchIdx = 0
Global $g_maxSearchIdx = 0
Global $g_socketSearch = false
Global $g_socketKnown = FileRead("socketsearch")
Global $g_confPath = "conf/localconf.ini"
Global $g_sid = 0

#include "UDF/NomadMemory.au3"
#include "UDF/ImageSearch.au3"
#include "UDF/WinHttp.au3"
#include "UDF/JSON.au3"

#include "lib/ClickLib.au3"
#include "lib/BaseLib.au3"
#include "lib/GUILib.au3"
#include "lib/ComLib.au3"
#include "lib/SearchLib.au3"



HotKeySet("{F10}", "mouseinfo")
HotKeySet("{F11}", "StartIt")
hotkeyset("{F4}","DebugPages")
hotkeyset("{F6}","stop")
hotkeyset("{F5}","start")
hotkeyset("{F7}","quit")

startup()

While 1
	if $start then
		$g_searchIdx += 1
		If $g_searchIdx > $g_maxSearchIdx Then
			$g_searchIdx = 1
			Reset(true)
		EndIf
		Search($g_searchIdx)
		D3sleep(2000)
	EndIf
	D3sleep(200)
WEnd

feierabend()
