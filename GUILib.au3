;PACKAGES
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>

;KEYS
hotkeyset("{F8}","processConfig")
hotkeyset("{F6}","stop")
hotkeyset("{F5}","start")
hotkeyset("{F7}","quit")


#cs		#############		#
#		CONFIGURATION		#
#ce		#############		#

Const $configSize = 16
Const $configDiffSize = 3

Const $color_red = 0xff0000
Const $color_green = 0x008000
Const $color_yellow = 0x808000

Global $configProperties[$configSize] = ["search", "buyout", "accept_buyout", "item_type", "item_subtype", "rarity", "stat1_dropdownbutton", "stat1_value", "stat2_dropdownbutton", "stat2_value", "stat3_dropdownbutton", "stat3_value", "stat3_dropdownwindow_item1","stat3_dropdownwindow_item2", "stat3_scrollbutton_topleft", "stat3_scrollbutton_bottomright"]
Global $configDiffProperties[$configDiffSize] = ["DragDownToItem", "ItemToItem", "ScrollToScroll"]
Global $Ini = "localconf"

Global $configComplete = false
Global $runtime = False

Global $configProcessPoint = 0
Global $configEndPoint = $configSize
Global $configProcessPointLabel = ""
Global $diffPoint = 0
Global $diffPosition[4]



;write a point to CONFIG
Func writeConfigPoint($point)
	$pos = MouseGetPos()
	Sleep(2000)
	IniWrite($Ini, $configProperties[$point], "x", $pos[0])
	IniWrite($Ini, $configProperties[$point], "y", $pos[1])
	IniWrite($Ini, $configProperties[$point], "color", PixelGetColor($pos[0], $pos[1]))
EndFunc

Func getYCoord()
	$pos = MouseGetPos()
	return $pos[1]
EndFunc

; 0 -> 1diff; 1 -> 2diff; 2 -> 3diff; 3 -> all diffs
Func calculateDiff($diff)
	If $diff < 1 Or $diff == 3 Then
		$dragDownY = IniRead($Ini, "Stat3_DropDown", "y", 0)
		IniWrite($Ini, $configDiffProperties[0], "diff", ($diffPosition[0] - $dragDownY))
	EndIf
	If ($diff > 0 And $diff < 2) Or $diff == 3 Then
		IniWrite($Ini, $configDiffProperties[1], "diff",($diffPosition[1] - $diffPosition[0]))
	EndIf
	If ($diff > 1 And $diff < 3) Or $diff == 3 Then
		IniWrite($Ini, $configDiffProperties[2], "diff",($diffPosition[3] - $diffPosition[2]))
	EndIf
EndFunc

Func processConfig()
	If not $configComplete Then
		Switch $configProcessPoint
			;get difference positions
			Case 12 To 15
				$diffPosition[$diffPoint] = getYCoord()
				$diffPoint += 1
			;write normal points
			Case Else
				writeConfigPoint($configProcessPoint)
		EndSwitch
		$configProcessPoint += 1
		;check if config is complete now
		If $configProcessPoint < $configEndPoint Then
			;config not finished -> change label
			GUICtrlSetData($configProcessPointLabel, $configProperties[$configProcessPoint])
		Else
			;calculate diffs
			Switch $configEndPoint
				Case 12
					calculateDiff(0)
				Case 13
					calculateDiff(1)
				Case 14
					If $diffPosition[0] == 0 Then
						calculateDiff(2)
					Else
						calculateDiff(3)
					EndIf
			EndSwitch
			;config is complete
		    $configComplete = True
			buildRuntimeGUI(1)
		EndIf
	EndIf
EndFunc

Func checkConfig()
	$temp = 0
	$tempId = 0
	$errorCatched = false
	For $i = 0 To 14 Step +1
		switch $i
			Case 0 to 11
				$temp = IniRead($Ini, $configProperties[$i], "y", 0)
			Case 12 To 14
				$temp = IniRead($Ini, $configDiffProperties[$i + $configDiffSize - $configSize + 1], "diff", 0)
				If $i == 14 Then
					$tempId = 15
				Else
					$tempId = $i
				EndIf
		EndSwitch
		If $temp == 0 Then
			If $tempId == 0 Then
				builtConfigGUI($i, $i)
			Else
				builtConfigGUI($tempId - 1, $tempId)
			EndIf
		EndIf
	Next
	$configComplete = True
	buildRuntimeGUI(1)
EndFunc



#cs		#############		#
#			 GUI			#
#ce		#############		#

;create
Func createGUI()
	GUICreate("Titan - Z       ©2012 Lennix, Zero", 300, 200, -1, -1, -1, $WS_EX_TOPMOST)
EndFunc

;mainstatus
Func mainStatusBotGUI()
	GUICtrlCreateLabel("TITAN - Z  is", 70, 20)
	GUICtrlCreateLabel("push F7  to quit", 90, 140)
	GUISetState(@SW_SHOW)
EndFunc

;ready
Func readyBotGUI()
	$labelReady = GUICtrlCreateLabel("READY", 135, 20)
	GUICtrlSetColor($labelReady, $color_green)
	GUICtrlCreateLabel("push F5  to start", 90, 80)
	GUICtrlCreateLabel("push F6  to stop while running", 90, 110)
EndFunc

;stop
Func stopBotGUI()
	$labelReady = GUICtrlCreateLabel("STOPPED", 135, 20)
	GUICtrlSetColor($labelReady, $color_yellow)
	GUICtrlCreateLabel("push F5  to continue", 90, 80)
EndFunc

;CONFIG GUI
Func builtConfigGUI($configStartPoint, $cconfigEndPoint)
	$configProcessPoint = $configStartPoint
	$configEndPoint = $cconfigEndPoint
	createGUI()
	GUICtrlCreateLabel("Welcome to TITAN - Z", 70, 20)
	GUICtrlCreateLabel("Before you can start u have to do the program configuration", 10, 50)
	GUICtrlCreateLabel("Move your cursor to ", 30, 95)
	$configProcessPointLabel = GUICtrlCreateLabel("                                                    ", 130, 95)
	GUICtrlSetData($configProcessPointLabel, $configProperties[$configProcessPoint])
	GUICtrlSetColor($configProcessPointLabel, $color_red)
	GUICtrlCreateLabel("Then push F8", 110, 140)
	GUISetState(@SW_SHOW)
EndFunc

;RUNTIME GUI
Func buildRuntimeGUI($status)
	GUIDelete()
	createGUI()
	mainStatusBotGUI()
	Switch $status
		Case 1
			readyBotGUI()
		Case Else
			stopBotGUI()
	EndSwitch
EndFunc


#cs		#############		#
#		   RUNTIME			#
#ce		#############		#

If FileExists($Ini) Then
	checkConfig()
Else
	;start CONFIG
	builtConfigGUI(0, $configSize)
EndIf

Func start()
	If $configComplete Then
		$runtime = True
		GUISetState(@SW_HIDE)
	EndIf
EndFunc

Func stop()
	If $runtime Then
		$runtime = False
		buildRuntimeGUI(0)
	EndIf
EndFunc

Func quit()
	Exit
EndFunc