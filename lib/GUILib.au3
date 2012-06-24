#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <WinAPI.au3>

#cs		#############		#
#		CONFIGURATION		#
#ce		#############		#

Const $configSize = 17													;number of configuration properties we have to put in
Const $configNormalEntries = 16											;number of normal entries we write to ini
Const $configDiffEntries = 3											;number of diff entires we calculated and write then to ini
Const $configEntries = $configNormalEntries + $configDiffEntries		;number of all entries we write to ini

Const $color_red = 0xff0000
Const $color_green = 0x008000
Const $color_white = 0xffffff
Const $color_yellow = 0x808000

Global $configProperties[$configSize] = ["search", "price", "buyout", "accept_buyout", "item_type", "item_subtype", "rarity", "filter_1", "filtervalue_1", "filter_2", "filtervalue_2", "filter_3", "filtervalue_3", "firstitem", "next_page" , "prev_page","bid"]
Global $configDiffProperties[$configDiffEntries] = ["filterentrydiff", "entrydiff", "itemdiff"]
Global $Pref = "conf/pref.ini"
Global $configProcessPointLabel = ""

Global $configComplete = False
Global $needConfigCheck = False
Global $runtime = False
Global $logedin = True
Global $login
Global $username
Global $password
Global $msg

Global $configProcessPoint = 0
Global $configCheckPoint = 0
Global $diffPoint = 0
Global $width_faktor
Global $height_faktor
Global $configEndPoint = $configSize
Global $diffPosition[4]



;Convert Pref to localconf
Func writeConfigPoint($point)
	$datei = FileOpen(@MyDocumentsDir & "\Diablo III\D3Prefs.txt")

	$res_width = StringSplit(FileReadLine($datei,10),'"')
	$res_height = StringSplit(FileReadLine($datei,11),'"')

	$res_width = int($res_width[2])
	$res_height = int($res_height[2])

	$width_faktor = $res_width / 2560
	$height_faktor = $res_height / 1440

	$Section_X = IniRead($Pref, $configProperties[$point], "x", 0)
	$Section_Y = IniRead($Pref, $configProperties[$point], "y", 0)
	$Section_color = IniRead($Pref, $configProperties[$point], "color", 0)

	$new_x = $Section_X * $width_faktor
	$new_y = $Section_Y * $height_faktor

	IniWrite($g_confPath,$configProperties[$point], "x" , Round($new_x))
	IniWrite($g_confPath,$configProperties[$point], "y" , Round($new_y))
	IniWrite($g_confPath, $configProperties[$point], "color", $Section_color)

	If $point = $configNormalEntries - 1 Then
		$left = IniRead($Pref, "filterwindow" , "left", 0)
		$top = IniRead($Pref, "filterwindow" , "top", 0)
		$right = IniRead($Pref, "filterwindow" , "right", 0)
		$bottom = IniRead($Pref, "filterwindow" , "bottom", 0)

		$left *= $width_faktor
		$top *= $width_faktor
		$right *= $width_faktor
		$bottom *= $width_faktor

		IniWrite($g_confPath, "filterwindow" , "left", Round($left))
		IniWrite($g_confPath, "filterwindow" , "top", Round($top))
		IniWrite($g_confPath, "filterwindow" , "right", Round($right))
		IniWrite($g_confPath, "filterwindow" , "bottom", Round($bottom))
	EndIf

	If $point = $configNormalEntries Then
		$filterentrydiff = IniRead($Pref, "diff", "filterentrydiff", 0)
		$entrydiff = IniRead($Pref, "diff", "entrydiff", 0)
		$itemdiff = IniRead($Pref, "diff", "itemdiff", 0)

		$filterentrydiff *= $width_faktor
		$entrydiff *= $width_faktor
		$itemdiff *= $width_faktor

		IniWrite($g_confPath,"diff", "filterentrydiff",Round($filterentrydiff))
		IniWrite($g_confPath,"diff", "entrydiff",Round($entrydiff))
		IniWrite($g_confPath,"diff", "itemdiff",Round($itemdiff))
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
	GUICreate("Titanz ©2012 Lennix, Zero, Neltor", 350, 200, -1, -1, -1, $WS_EX_TOPMOST)
	GUICtrlCreatePic("4.jpg", 0, 0, 350, 200)
	GUICtrlSetState(-1,$GUI_DISABLE)
EndFunc

;login eingaben in Global username und password gespeichert
Func loginBotGUI()

	GUICtrlCreatePic("2.jpg", 249, 0, 101, 102)
	GUICtrlSetState(-1,$GUI_DISABLE)
	$head = GUICtrlCreateLabel("TITANz -> login", 100, 10)
	GUICtrlSetColor($head, $color_white)
	GUICtrlSetBkColor(-1,-2)
	$username = GUICtrlCreateInput("username",10,40,200)
	$password = GUICtrlCreateInput("password",10,65,200)
	$further = GUICtrlCreateLabel("For further information go to www.d3ahbot.com", 10, 150)
	GUICtrlSetColor($further, $color_white)
	GUICtrlSetBkColor(-1,-2)
	$login = GUICtrlCreateButton("login",10,100,50,25)
	GUISetState(@SW_SHOW)
	;sleep(500000)
EndFunc

;ready
Func readyBotGUI()
	GUICtrlCreatePic("2.jpg", 249, 0, 101, 102)
	GUICtrlSetState(-1,$GUI_DISABLE)
	$labelReady = GUICtrlCreateLabel("READY", 135, 20)
	GUICtrlSetColor($labelReady, $color_green)
	GUICtrlSetBkColor(-1,-2)
	$ctrlmenu = GUICtrlCreateMenu("Control center")
	GUICtrlCreateMenuItem("Create localconf manually",$ctrlmenu)
	GUICtrlCreateMenuItem("Create images manually",$ctrlmenu)
	$helpmenu = GUICtrlCreateMenu("Help")
	GUICtrlCreateMenuItem("Credits",$helpmenu)
	GUICtrlCreateMenuItem("Page",$helpmenu)
	$f5 = GUICtrlCreateLabel("push F5  to start", 90, 80)
	GUICtrlSetColor($f5, $color_white)
	GUICtrlSetBkColor(-1,-2)
	$f6 = GUICtrlCreateLabel("push F6  to stop while running", 90, 110)
	GUICtrlSetColor($f6, $color_white)
	GUICtrlSetBkColor(-1,-2)
	GUISetState(@SW_SHOW)
	;sleep(500000)
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

	;mainStatusBotGUI()
	Switch $status
		Case 0
			loginBotGUI()
		Case 1
			readyBotGUI()
	EndSwitch
EndFunc


#cs		#############		#
#		   RUNTIME			#
#ce		#############		#

If Not FileExists($g_confPath) Then
	while not $configComplete
		processConfig()
    wend
Else
	;log in abfragen später abfrage über HP einfügen
	If Not $logedin Then
		buildRuntimeGUI(0)
	Else
		buildRuntimeGUI(1)
	EndIf
EndIf

Func start()
	If $configComplete Then
		$runtime = True
		;GUISetState(@SW_HIDE)
	EndIf
EndFunc

Func stop()
	If $runtime Then
		$runtime = False
		buildRuntimeGUI(0)
	EndIf
EndFunc

Func quit()
	FileDelete("socketsearch")
	FileWrite("socketsearch",$g_socketKnown)
	Exit
EndFunc