#region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Fileversion=0.1
#AutoIt3Wrapper_Res_LegalCopyright=D3AHBOT Team
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Obfuscator=y
#endregion ;**** Directives created by AutoIt3Wrapper_GUI ****
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

Global $debugOut = False
Global $g_testMode = False

HotKeySet("{F7}", "quit")
HotKeySet("{F8}", "StopIt")
HotKeySet("{F9}", "StartIt")
HotKeySet("{F10}", "mouseinfo")
HotKeySet("{F11}", "craft")

startup()

While 1
	$msg = GUIGetMsg(1)
	If $msg[0] <> 0 Then GUIcheck($msg)

	If CheckRun(True) Then
		$g_searchIdx += 1
		ReloadSearchList() ; we will reload the circle every time
		If $g_searchIdx > $g_maxSearchIdx Then
			$g_targetQPH = $g_baseQPH + Random(0, 50, 1)
			setconsole("Finished cycle. Current queries/h: " & Round($g_queriesperhour, 2))
			$g_searchIdx = 1
		EndIf
		Search($g_searchIdx)
	EndIf
	D3sleep(25)
WEnd

feierabend()