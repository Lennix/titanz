;PACKAGES
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>

;KEYS
;hotkeyset("{F8}","processConfig")
hotkeyset("{F6}","stop")
hotkeyset("{F5}","start")
hotkeyset("{F7}","quit")


#cs		#############		#
#		CONFIGURATION		#
#ce		#############		#

Const $configSize = 14													;number of configuration properties we have to put in
Const $configNormalEntries = 13											;number of normal entries we write to ini
Const $configDiffEntries = 5											;number of diff entires we calculated and write then to ini
Const $configEntries = $configNormalEntries + $configDiffEntries		;number of all entries we write to ini

Const $color_red = 0xff0000
Const $color_green = 0x008000
Const $color_yellow = 0x808000

Global $configProperties[$configSize] = ["search", "price", "buyout", "accept_buyout", "item_type", "item_subtype", "rarity", "filter_1", "filtervalue_1", "filter_2", "filtervalue_2", "filter_3", "filtervalue_3", "firstitem"]
Global $configDiffProperties[$configDiffEntries] = ["scrollbuttondiff", "filterentrydiff", "entrydiff", "itemdiff", "scrollsquarediff"]
Global $Ini = "localconf"
Global $Pref = "Pref"
Global $configProcessPointLabel = ""

Global $configComplete = False
Global $needConfigCheck = False
Global $runtime = False

Global $configProcessPoint = 0
Global $configCheckPoint = 0
Global $diffPoint = 0
Global $width_faktor													
Global $height_faktor
Global $configEndPoint = $configSize
Global $diffPosition[4]

;write a point to CONFIG
Func writeConfigPoint($point)	
	$datei = FileOpen(@MyDocumentsDir & "\Diablo III\D3Prefs.txt")		
	
	$res_width = StringSplit(FileReadLine($datei,10),'"')
	$res_height = StringSplit(FileReadLine($datei,11),'"')	
		
	$res_width = int($res_width[2])
	$res_height = int($res_height[2])	
	
	$width_faktor = $res_width / 1920
	$height_faktor = $res_height / 1080	
			
	$Section_X = IniRead($Pref, $configProperties[$point], "x", 0)
	$Section_Y = IniRead($Pref, $configProperties[$point], "y", 0)	
	$Section_color = IniRead($Pref, $configProperties[$point], "color", 0)
	
	$new_x = $Section_X * $width_faktor
	$new_y = $Section_Y * $height_faktor
	
	IniWrite($Ini,$configProperties[$point], "x" , $new_x)
	IniWrite($Ini,$configProperties[$point], "y" , $new_y)
	IniWrite($Ini, $configProperties[$point], "color", $Section_color)
	
	If $point = 13 Then
		$filterentrydiff = IniRead($Pref, "diff", "filterentrydiff", 0)
		$entrydiff = IniRead($Pref, "diff", "entrydiff", 0)
		$itemdiff = IniRead($Pref, "diff", "itemdiff", 0)
		$filterentrydiff *= $width_faktor
		$entrydiff *= $width_faktor
		$itemdiff *= $width_faktor
		IniWrite($Ini,"diff", "filterentrydiff",$filterentrydiff)
		IniWrite($Ini,"diff", "entrydiff",$entrydiff)
		IniWrite($Ini,"diff", "itemdiff",$itemdiff)
	EndIf
	
EndFunc

Func processConfig()
	If not $configComplete Then
		writeConfigPoint($configProcessPoint)
		
		$configProcessPoint += 1
		;check if config is complete now
		If $configProcessPoint < $configEndPoint Then
			;config not finished -> change label
			GUICtrlSetData($configProcessPointLabel, $configProperties[$configProcessPoint])
		Else
			
			;built config complete GUI for:
			
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

#cs
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
#ce

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

If Not FileExists($Ini) Then
	while not $configComplete
		processConfig()
    wend	
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