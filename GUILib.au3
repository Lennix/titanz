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

Const $configSize = 12
Const $configKeys = 3
Const $color_red = 0xff0000
Const $color_green = 0x008000
Const $color_yellow = 0x808000

Enum $firstItemTypeCONF, $secondItemTypeCONF, $rarityCONF, $stat1DropDownCONF, $stat1ValueCONF, $stat2DropDownCONF, $stat2ValueCONF, $stat3DropDownCONF, $stat3ValueCONF, $searchCONF, $buyoutCONF, $acceptBuyoutCONF ;0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11

Global $configProperties[$configSize] = ["First ItemType", "Second ItemType", "Rarity", "Stat1_DropDown", "Stat1_Value", "Stat2_DropDown", "Stat2_Value", "Stat3_DropDown", "Stat3_Value", "Search", "Buyout", "AcceptBuyout"]
Global $config[$configSize][$configKeys]
Global $Ini = "localconf"

Global $configComplete = false
Global $configProcessPoint = 0
Global $configProcessPointLabel = ""

Global $runtime = False

;load CONFIG
Func loadConfig()
	For $i = 0 to $configSize-1 Step +1
		$config[$i][0] = IniRead($Ini, $configProperties[$i], "x", 0)
		$config[$i][1] = IniRead($Ini, $configProperties[$i], "y", 0)
		$config[$i][2] = IniRead($Ini, $configProperties[$i], "color", 0)
	Next
	$configComplete = True
	buildRuntimeGUI(1)
EndFunc

;write a point to CONFIG
Func writeConfigPoint($point)
	$pos = MouseGetPos()
	Sleep(2000)
	IniWrite($Ini, $configProperties[$point], "x", $pos[0])
	IniWrite($Ini, $configProperties[$point], "y", $pos[1])
	IniWrite($Ini, $configProperties[$point], "color", PixelGetColor($pos[0], $pos[1]))
EndFunc

Func processConfig()
	If not $configComplete Then
		;write a point to CONFIG
		writeConfigPoint($configProcessPoint)
		$configProcessPoint += 1
		;check if config is complete now
		If $configProcessPoint < $configSize Then
			;config not finished -> change label
			GUICtrlSetData($configProcessPointLabel, $configProperties[$configProcessPoint])
		Else
			;config is complete -> load data
			loadConfig()
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
	loadConfig()
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