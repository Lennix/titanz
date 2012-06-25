;PACKAGES
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <WinAPI.au3>
#Include <EditConstants.au3>
#include <ScreenCapture.au3>

#cs		#############		#
#		CONFIGURATION		#
#ce		#############		#

Const $configSize = 20													;number of configuration properties we have to put in
Const $configNormalEntries = 19											;number of normal entries we write to ini
Const $configDiffEntries = 3											;number of diff entires we calculated and write then to ini
Const $configEntries = $configNormalEntries + $configDiffEntries		;number of all entries we write to ini

Const $color_red = 0xff0000
Const $color_green = 0x008000
Const $color_white = 0xffffff
Const $color_yellow = 0x808000

Global $configProperties[$configSize] = ["search", "price", "buyout", "accept_buyout", "item_type", "item_subtype", "rarity", "filter_1", "filtervalue_1", "filter_2", "filtervalue_2", "filter_3", "filtervalue_3", "filter_dropdownwindow_entry1", "filter_dropdownwindow_entry2", "firstitem", "seconditem", "next_page" , "prev_page", "bid"]
Global $configDiffProperties[$configDiffEntries] = ["filterentrydiff", "entrydiff", "itemdiff"]
Global $Pref = "conf/pref.ini"
Global $g_socketKnown = FileRead("socketsearch")
Global $g_confPath = "conf/localconf.ini"
Global $configProcessPointLabel = ""

Global $configComplete = False
Global $needConfigCheck = False
Global $runtime = False
Global $logedin = True
Global $ctrlmenu[3]
Global $helpmenu[3]
Global $okbutton
Global $login
Global $username
Global $password
Global $msg
Global $edit_content
Global $edit = 0
Global $picedit = 0
Local $pos_time = 0
Local $pos_1
Local $pos_2

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


;login eingaben in Global username und password gespeichert
Func createGUI()
	GUICreate("Titanz ©2012 Lennix, Zero, Neltor", 350, 200, -1, -1, -1, $WS_EX_TOPMOST)
	GUICtrlCreatePic("4.jpg", 0, 0, 350, 200)
	GUICtrlSetState(-1,$GUI_DISABLE)
	Menucreate()
EndFunc

;login eingaben in Global username und password gespeichert
Func loginBotGUI()
	GUIDelete()
	createGUI()
	GUICtrlCreatePic("logo.bmp", 249, 0, 101, 102)
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
EndFunc

;ready
Func readyBotGUI()
	GUIDelete()
	createGUI()
	GUICtrlCreatePic("logo.bmp", 249, 0, 101, 102)
	GUICtrlSetState(-1,$GUI_DISABLE)
	$labelReady = GUICtrlCreateLabel("READY", 135, 20)
	GUICtrlSetColor($labelReady, $color_green)
	GUICtrlSetBkColor(-1,-2)
	$f5 = GUICtrlCreateLabel("push F5  to start", 90, 80)
	GUICtrlSetColor($f5, $color_white)
	GUICtrlSetBkColor(-1,-2)
	$f6 = GUICtrlCreateLabel("push F6  to stop while running", 90, 110)
	GUICtrlSetColor($f6, $color_white)
	GUICtrlSetBkColor(-1,-2)
	GUISetState(@SW_SHOW)
EndFunc

;stop
Func stopBotGUI()
	$labelReady = GUICtrlCreateLabel("STOPPED", 135, 20)
	GUICtrlSetColor($labelReady, $color_yellow)
	GUICtrlCreateLabel("push F5  to continue", 90, 80)
EndFunc

Func GUIcheck($msg)
	Switch $msg
		Case $ctrlmenu[1]
			Guicreateinfo()

		Case $ctrlmenu[2]
			GuiCreateImages()

		Case $helpmenu[1]
			GuiCredits()

		Case $helpmenu[2]
			ShellExecute("http://www.d3ahbot.com")

		Case $okbutton
			GuiCreateLocalconf()

	EndSwitch
EndFunc

#cs
Func check($pos,$color)
	If $edit = Not 0 Then
		writeconf($pos,$color)
	EndIf

	If $picedit = Not 0 Then
		If $pos_time = 0 Then
			$pos_1 = $pos
		EndIf

		If $pos_time = 1 Then
			$pos_2 = $pos
			$pos_time = 0
			takepic($pos_1,$pos_2)
		EndIf
	;If
EndFunc
#ce
Func Menucreate()
	$ctrlmenu[0] = GUICtrlCreateMenu("Control center")
	$ctrlmenu[1] = GUICtrlCreateMenuItem("Create localconf manually",$ctrlmenu[0])
	$ctrlmenu[2] = GUICtrlCreateMenuItem("Create images manually",$ctrlmenu[0])
	$helpmenu[0] = GUICtrlCreateMenu("Help")
	$helpmenu[1] = GUICtrlCreateMenuItem("Credits",$helpmenu[0])
	$helpmenu[2] = GUICtrlCreateMenuItem("Page",$helpmenu[0])
EndFunc

Func takepic($pos_1,$pos_2)

	$filter = StringSplit(FileReadLine($datei,42),' ')


	;_ScreenCapture_Capture(, 0, 0, 796, 596)
EndFunc

Func writeconf($pos,$color)
	If $edit = Not 0 Then
		$edit_content = "[" & $configProperties[$configProcessPoint] & "]" & @CRLF
		$edit_content &= "x = " & $pos[0] & @CRLF
		$edit_content &= "y = "& $pos[1] & @CRLF
		$edit_content &= "color = " & $color
		ConsoleWrite($edit_content)
		$edit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)

		If $configProcessPoint <= $configNormalEntries Then
			IniWrite($g_confPath, $configProperties[$configProcessPoint], "x", $pos[0])
			IniWrite($g_confPath, $configProperties[$configProcessPoint], "y", $pos[1])
			IniWrite($g_confPath, $configProperties[$configProcessPoint], "color", $color)
		EndIf

		If $configProcessPoint = $configNormalEntries Then
			$filterentrydiff_1 = IniRead($g_confPath, "filter_1", "y", 0)
			$filterentrydiff_2 = IniRead($g_confPath, "filter_2", "y", 0)
			IniWrite($g_confPath,"diff", "filterentrydiff",Round($filterentrydiff_2 - $filterentrydiff_1))

			$entrydiff_1 = IniRead($g_confPath, "filter_dropdownwindow_entry1", "y", 0)
			$entrydiff_2 = IniRead($g_confPath, "filter_dropdownwindow_entry2", "y", 0)
			IniWrite($g_confPath,"diff", "entrydiff",Round($entrydiff_2 - $entrydiff_1))

			$itemdiff_1 = IniRead($g_confPath, "firstitem", "y", 0)
			$itemdiff_2 = IniRead($g_confPath, "seconditem", "y", 0)
			IniWrite($g_confPath,"diff", "itemdiff",Round($itemdiff_2 - $itemdiff_1))

			$edit = 0
		EndIf

		$configProcessPoint += 1
	EndIf
EndFunc

Func GuiCreateLocalconf()

	If FileExists($g_confPath) Then
		FileDelete($g_confPath)
	EndIf

	GUIDelete()
	createGUI()
	GUICtrlCreatePic("logo.bmp", 249, 0, 101, 102)
	GUICtrlSetState(-1,$GUI_DISABLE)
	$labelReady = GUICtrlCreateLabel("testesetset", 135, 20)
	GUICtrlSetColor($labelReady, $color_green)
	GUICtrlSetBkColor(-1,-2)
	$edit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)
	GUISetState(@SW_SHOW)
EndFunc

Func Guicreateinfo()
	GUIDelete()
	createGUI()
	$labelReady = GUICtrlCreateLabel("By clicking the OK Button your localconf will be deleted!!!", 50, 20)
	GUICtrlSetColor($labelReady, $color_white)
	GUICtrlSetBkColor(-1,-2)
	$okbutton = GUICtrlCreateButton("OK",120,50,50)
	GUISetState(@SW_SHOW)
EndFunc

Func GuiCreateImages()
	GUIDelete()
	createGUI()

	$datei = FileOpen("settings.ini")
	$picedit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)

	GUISetState(@SW_SHOW)
EndFunc

Func GuiCredits()
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