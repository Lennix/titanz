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
Const $color_red = 0xff0000
Const $color_green = 0x008000
Const $color_yellow = 0x808000

Global $configProperties[$configSize] = ["Search", "Buyout", "AcceptBuyout", "First ItemType", "Second ItemType", "Rarity", "Stat1_DropDown", "Stat1_Value", "Stat2_DropDown", "Stat2_Value", "Stat3_DropDown", "Stat3_Value", "Stat3_DropDownItem1","Stat3_DropDownItem2", "Stat3_DropDownScrollButton_Top", "Stat3_DropDownScrollButton_Bottom"]
Global $Ini = "localconf"

Global $configComplete = false
Global $configProcessPoint = 0
Global $configProcessPointLabel = ""
Global $diffPoint = 0
Global $diffPosition[4]

Global $runtime = False

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
		If $configProcessPoint < $configSize Then
			;config not finished -> change label
			GUICtrlSetData($configProcessPointLabel, $configProperties[$configProcessPoint])
		Else
			;calculate diffs
			$dragDownY = IniRead($Ini, "Stat3_DropDown", "y", 0)
			IniWrite($Ini, "DragDownToItem", "diff", ($diffPosition[0] - $dragDownY))
			IniWrite($Ini, "ItemToItem", "diff",($diffPosition[1] - $diffPosition[0]))
			IniWrite($Ini, "ScrollToScroll", "diff",($diffPosition[3] - $diffPosition[2]))
			;config is complete
		    $configComplete = True
			buildRuntimeGUI(1)
		EndIf
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
Func builtConfigGUI()
	createGUI()
	GUICtrlCreateLabel("Welcome to TITAN - Z", 70, 20)
	GUICtrlCreateLabel("Before you can start u have to do the program configuration", 10, 50)
	GUICtrlCreateLabel("Move your cursor to ", 50, 95)
	$configProcessPointLabel = GUICtrlCreateLabel($configProperties[$configProcessPoint], 150, 95)
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
	;load CONFIG
	$configComplete = True
	buildRuntimeGUI(1)
Else
	;start CONFIG
	builtConfigGUI()
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