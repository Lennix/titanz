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

Const $configSize = 21													;number of configuration properties we have to put in
Const $configNormalEntries = 17											;number of normal entries we write to ini
Const $configDiffEntries = 5											;number of diff entires we calculated and write then to ini
Const $configEntries = $configNormalEntries + $configDiffEntries		;number of all entries we write to ini

Const $color_red = 0xff0000
Const $color_green = 0x008000
Const $color_yellow = 0x808000

Global $configProperties[$configSize] = ["search", "price", "buyout", "accept_buyout", "item_type", "item_subtype", "rarity", "filter_1", "filtervalue_1", "filter_2", "filtervalue_2", "filter_3", "filtervalue_3", "scrollbartopleft", "scrollbarbottomright", "scrollbuttontop", "scrollbuttonbottom", "filter3_dropdownwindow_entry1", "filter3_dropdownwindow_entry2", "firstitem", "seconditem"]
Global $configDiffProperties[$configDiffEntries] = ["scrollbuttondiff", "filterentrydiff", "entrydiff", "itemdiff", "scrollsquarediff"]
Global $Ini = "localconf"
Global $configProcessPointLabel = ""

Global $configComplete = False
Global $needConfigCheck = False
Global $runtime = False

Global $configProcessPoint = 0
Global $configCheckPoint = 0
Global $diffPoint = 0
Global $configEndPoint = $configSize
Global $diffPosition[4]

;write a point to CONFIG
Func writeConfigPoint($point)
	$pos = MouseGetPos()
	Sleep(1000)
	IniWrite($Ini, $configProperties[$point], "x", $pos[0])
	IniWrite($Ini, $configProperties[$point], "y", $pos[1])
	IniWrite($Ini, $configProperties[$point], "color", PixelGetColor($pos[0], $pos[1]))
EndFunc

Func getYCoord()
	$pos = MouseGetPos()
	return $pos[1]
EndFunc

; 1-4 -> one diff | 5 -> all diffs
Func calculateDiff($diff)
	If ($diff < 1 Or $diff == 5) Then
		$scrollButtonTopY = IniRead($Ini, "scrollbuttontop", "y", 0)
		IniWrite($Ini, "diff", $configDiffProperties[0], ($diffPosition[0] - $scrollButtonTopY ))
	EndIf
	If ($diff > 0 And $diff < 2) Or $diff == 5 Then
		$dragDownY = IniRead($Ini, "filter_3", "y", 0)
		IniWrite($Ini, "diff", $configDiffProperties[1], ($diffPosition[1] - $dragDownY))
	EndIf
	If ($diff > 1 And $diff < 3) Or $diff == 5 Then
		IniWrite($Ini, "diff", $configDiffProperties[2], ($diffPosition[2] - $diffPosition[1]))
	EndIf
	If ($diff > 2 And $diff < 4) Or $diff == 5 Then
		$firstItemY = IniRead($Ini, "firstitem", "y", 0)
		IniWrite($Ini, "diff", $configDiffProperties[3], ($diffPosition[3] - $firstItemY))
	EndIf
	If ($diff > 3 And $diff < 5) Or $diff == 5 Then
		$scrollSquareTopY = IniRead($Ini, "scrollbartopleft", "y", 0)
		$scrollSquareBottomY = IniRead($Ini, "scrollbarbottomright", "y", 0)
		IniWrite($Ini, "diff", $configDiffProperties[4], ($scrollSquareBottomY - $scrollSquareTopY))
	EndIf
EndFunc

Func processConfig()
	If not $configComplete Then
		Switch $configProcessPoint
			;DIFF POINTS
			Case 16 To 18, 20								;16:scrollbuttonbottom, 17:itemwindow1, 18:itemwindow2, 20:seconditem
				$diffPosition[$diffPoint] = getYCoord()
				$diffPoint += 1
			;NORMAL POINTS
			Case Else
				writeConfigPoint($configProcessPoint)
		EndSwitch
		$configProcessPoint += 1
		;check if config is complete now
		If $configProcessPoint < $configEndPoint Then
			;config not finished -> change label
			GUICtrlSetData($configProcessPointLabel, $configProperties[$configProcessPoint])
		Else
			;calculate diffs for:
			Switch $configEndPoint
				;check configuration
				Case 16 to 19, 20  ;19 if we have corrupt entrydiff (can be 18 if filterentrydiff is corrupted too)
					calculateDiff($diffPoint - 1)
				;first configuration
				Case $configSize
					calculateDiff(5)
			EndSwitch
			;built config complete GUI for:
			If not $needConfigCheck Then
				;first configuration
				$configComplete = True
				buildRuntimeGUI(1)
			Else
				;check configuration
				checkConfig(True)
			EndIf
		EndIf
	EndIf
EndFunc

Func checkConfig($continueCheck)
	$temp = 0
	While ($configCheckPoint < $configEntries And $continueCheck)
		switch $configCheckPoint
			;DIFF ENTRIES
			Case 16 to 18, 20 to 21 ;21 for checking the last diff value which is calculated by two normal entries
				$temp = IniRead($Ini, "diff", $configDiffProperties[$diffPoint], 0)
				If $temp == 0 Then
					$continueCheck = False
					Switch $diffPoint
						Case 0 To 1, 3
							builtConfigGUI($configCheckPoint, $configCheckPoint)
						Case 2
							If $diffPosition[1] <> 0 Then
								builtConfigGUI($configCheckPoint, $configCheckPoint)
							Else
								$diffPoint = 1
								builtConfigGUI($configCheckPoint - $diffPoint, $configCheckPoint + $diffPoint)
							EndIf
						Case 4
							calculateDiff($diffPoint)
					EndSwitch
				Else
					$diffPoint += 1
				EndIf
			;NORMAL ENTRIES
			Case Else
				$temp = IniRead($Ini, $configProperties[$configCheckPoint], "y", 0)
				If $temp == 0 Then
					$continueCheck = False
					builtConfigGUI($configCheckPoint, $configCheckPoint)
				EndIf
		EndSwitch
		$configCheckPoint += 1
	WEnd
	If $configCheckPoint >= $configEntries Then
		$configComplete = True
		buildRuntimeGUI(1)
	EndIf
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
	GUIDelete()
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
	$needConfigCheck = True
	checkConfig(True)
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