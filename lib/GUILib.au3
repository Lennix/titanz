;PACKAGES
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <WinAPI.au3>
#Include <EditConstants.au3>
#include <ScreenCapture.au3>
#include <GDIPlus.au3>

#cs		#############		#
#		CONFIGURATION		#
#ce		#############		#

Const $configSize = 22													;number of configuration properties we have to put in
Const $configNormalEntries = 22											;number of normal entries we write to ini
Const $configDiffEntries = 3											;number of diff entires we calculated and write then to ini
Const $configEntries = $configNormalEntries + $configDiffEntries		;number of all entries we write to ini

Const $color_red = 0xff0000
Const $color_green = 0x008000
Const $color_white = 0xffffff
Const $color_yellow = 0x808000

Global $configProperties[$configSize] = ["search", "price", "buyout", "accept_buyout", "item_type", "item_subtype", "rarity", "filter_1", "filtervalue_1", "filter_2", "filtervalue_2", "filter_3", "filtervalue_3", "filter_dropdownwindow_entry1", "filter_dropdownwindow_entry2", "firstitem", "seconditem", "next_page", "prev_page", "filterwindow", "socketsearch", "bid"]
Global $configDiffProperties[$configDiffEntries] = ["filterentrydiff", "entrydiff", "itemdiff"]
Global $Pref =@ScriptDir & "/conf/pref.ini"
Global $g_socketKnown = FileRead("socketsearch")
Global $g_confPath = @ScriptDir & "/conf/localconf.ini"
Global $g_settings = @ScriptDir & "/conf/settings.ini"
Local $DLLHashes = DllOpen(@ScriptDir & "/UDF/hashes.dll")
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
Local $combo = 0
Local $pos_time = 0
Local $pos_1
Local $pos_2
Local $picbutton
Local $neustring = ""
Local $hImage
Local $image
Local $filterwindow = False
Local $socketsearch = False
Local $main

Global $configProcessPoint = 0
Global $configCheckPoint = 0
Global $diffPoint = 0
Global $width_faktor
Global $height_faktor
Global $configEndPoint = $configSize
Global $diffPosition[4]

Global $combo_amount = 49
Global $filterlist_combo[$combo_amount]

;Convert Pref to localconf
Func ConvertPreftoLocalconf($point)
	$datei = FileOpen(@MyDocumentsDir & "\Diablo III\D3Prefs.txt")

	$res_width = StringSplit(FileReadLine($datei,10),'"')
	$res_height = StringSplit(FileReadLine($datei,11),'"')

	$res_width = int($res_width[2])
	$res_height = int($res_height[2])

	$width_faktor = $res_width / 1920
	$height_faktor = $res_height / 1080

	Switch $configProperties[$point]

		Case  "filterwindow"
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

		Case  "socketsearch"
			$left = IniRead($Pref, "socketsearch" , "left", 0)
			$top = IniRead($Pref, "socketsearch" , "top", 0)
			$right = IniRead($Pref, "socketsearch" , "right", 0)
			$bottom = IniRead($Pref, "socketsearch" , "bottom", 0)

			$left *= $width_faktor
			$top *= $width_faktor
			$right *= $width_faktor
			$bottom *= $width_faktor

			IniWrite($g_confPath, "socketsearch" , "left", Round($left))
			IniWrite($g_confPath, "socketsearch" , "top", Round($top))
			IniWrite($g_confPath, "socketsearch" , "right", Round($right))
			IniWrite($g_confPath, "socketsearch" , "bottom", Round($bottom))

		Case Else
			$Section_X = IniRead($Pref, $configProperties[$point], "x", 0)
			$Section_Y = IniRead($Pref, $configProperties[$point], "y", 0)
			$Section_color = IniRead($Pref, $configProperties[$point], "color", 0)

			$new_x = $Section_X * $width_faktor
			$new_y = $Section_Y * $height_faktor

			IniWrite($g_confPath,$configProperties[$point], "x" , Round($new_x))
			IniWrite($g_confPath,$configProperties[$point], "y" , Round($new_y))
			IniWrite($g_confPath, $configProperties[$point], "color", $Section_color)
	EndSwitch

		If $point = $configNormalEntries - 1 Then
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

Func WriteConfManually($pos,$color)
	If $edit = Not 0 Then
		Switch $configProperties[$configProcessPoint]

			Case "filterwindow"
				If $filterwindow = False Then
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "left", $pos[0])
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "top", $pos[1])
					$filterwindow = True

					$edit_content = "[" & $configProperties[$configProcessPoint] & "]" & @CRLF
					$edit_content &= "left = " & $pos[0] & @CRLF
					$edit_content &= "top = "& $pos[1] & @CRLF
					ConsoleWrite($edit_content)
					$edit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)

				ElseIf $filterwindow = True Then
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "right", $pos[0])
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "bottom", $pos[1])
					$filterwindow = False

					$edit_content &= "right = " & $pos[0] & @CRLF
					$edit_content &= "bottom = "& $pos[1] & @CRLF
					ConsoleWrite($edit_content)
					$edit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)

					$configProcessPoint += 1

				EndIf

			Case "socketsearch"
				If $socketsearch = False Then
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "left", $pos[0])
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "top", $pos[1])
					$socketsearch = True

					$edit_content = "[" & $configProperties[$configProcessPoint] & "]" & @CRLF
					$edit_content &= "left = " & $pos[0] & @CRLF
					$edit_content &= "top = "& $pos[1] & @CRLF
					ConsoleWrite($edit_content)
					$edit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)

				ElseIf $socketsearch = True Then
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "right", $pos[0])
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "bottom", $pos[1])
					$socketsearch = False

					$edit_content &= "right = " & $pos[0] & @CRLF
					$edit_content &= "bottom = "& $pos[1] & @CRLF
					ConsoleWrite($edit_content)
					$edit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)

					$configProcessPoint += 1

				EndIf

			Case "bid"
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "x", $pos[0])
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "y", $pos[1])
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "color", $color)

				$filterentrydiff_1 = IniRead($g_confPath, "filter_1", "y", 0)
				$filterentrydiff_2 = IniRead($g_confPath, "filter_2", "y", 0)
				IniWrite($g_confPath,"diff", "filterentrydiff",Round($filterentrydiff_2 - $filterentrydiff_1))

				$entrydiff_1 = IniRead($g_confPath, "filter_dropdownwindow_entry1", "y", 0)
				$entrydiff_2 = IniRead($g_confPath, "filter_dropdownwindow_entry2", "y", 0)
				IniWrite($g_confPath,"diff", "entrydiff",Round($entrydiff_2 - $entrydiff_1))

				$itemdiff_1 = IniRead($g_confPath, "firstitem", "y", 0)
				$itemdiff_2 = IniRead($g_confPath, "seconditem", "y", 0)
				IniWrite($g_confPath,"diff", "itemdiff",Round($itemdiff_2 - $itemdiff_1))

				$edit_content = "[" & $configProperties[$configProcessPoint] & "]" & @CRLF
				$edit_content &= "x = " & $pos[0] & @CRLF
				$edit_content &= "y = "& $pos[1] & @CRLF
				$edit_content &= "color = " & $color
				$edit_content &= @CRLF
				$edit_content &= "filterentrydiff = " & Round($filterentrydiff_2 - $filterentrydiff_1) & @CRLF
				$edit_content &= "entrydiff = " & Round($entrydiff_2 - $entrydiff_1) & @CRLF
				$edit_content &= "itemdiff = " & Round($itemdiff_2 - $itemdiff_1)
				ConsoleWrite($edit_content)
				$edit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)

				$edit = 0

			Case Else
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "x", $pos[0])
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "y", $pos[1])
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "color", $color)

				$edit_content = "[" & $configProperties[$configProcessPoint] & "]" & @CRLF
				$edit_content &= "x = " & $pos[0] & @CRLF
				$edit_content &= "y = "& $pos[1] & @CRLF
				$edit_content &= "color = " & $color
				ConsoleWrite($edit_content)
				$edit = GUICtrlCreateEdit($edit_content,0,0,100,100,$ES_READONLY)
				$configProcessPoint += 1

		EndSwitch


	EndIf
EndFunc

Func processConfig()
	If not $configComplete Then
		ConvertPreftoLocalconf($configProcessPoint)

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
Func Menucreate()
	;$ctrlmenu[0] = GUICtrlCreateButton("Control center")
	;GUICtrlSetBkColor ($ctrlmenu[0],$color_red)
	;$ctrlmenu[1] = GUICtrlCreateButton("Create localconf manually",300,100,75,20)
	;GUICtrlCreateButton("Create images manually",300,130,75,20)
	;$helpmenu[0] = GUICtrlCreateMenu("Help")
	;$helpmenu[1] = GUICtrlCreateButton("Credits",300,160,75,20)
	;$helpmenu[2] = GUICtrlCreateButton("Page",300,190,75,20)
EndFunc

;login eingaben in Global username und password gespeichert
Func createGUI()
	$main = GUICreate("Titanz ©2012 Lennix, Zero, Neltor", 400, 300, -1, -1, -1, $WS_EX_TOPMOST)
	$helpmenu[2] = GUICtrlCreateLabel("",268,0,132,70)
	$ctrlmenu[1] = GUICtrlCreateLabel("",278,93,110,24)
	$ctrlmenu[2] = GUICtrlCreateLabel("",278,124,110,24)
	GUICtrlCreatePic("bg.jpg", 0, 0, 400, 300)
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

Func login()
	$password = GUICtrlRead($password)
	ConsoleWrite($password &@lf)

	$shash = "SHA256"

    ConsoleWrite('String:'& $password &': Hash-'& $shash &':'& _Hashes($password, $shash, $DLLHashes, 0) & @lf)
EndFunc

;ready
Func readyBotGUI()
	GUIDelete()
	createGUI()
	;GUICtrlCreatePic("logo.bmp", 249, 0, 101, 102)
	;GUICtrlSetState(-1,$GUI_DISABLE)
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
	Switch $msg[0]
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

		Case $picbutton
			SafeImage()

		Case $login
			login()

		Case $GUI_EVENT_CLOSE				;0x002A052A,0x001B02E0
			ConsoleWrite($msg[1])
			If $msg[1] = $main Then
				Exit
			Else
				GUIDelete($msg)
			EndIf


	EndSwitch
EndFunc

Func check($pos,$color)
	If $edit = Not 0 Then
		WriteConfManually($pos,$color)
	EndIf

	If $combo = Not 0 Then
		If $pos_time = 1 Then
			$pos_2 = $pos
			takepic($pos_1,$pos_2)
			WinActivate("Diablo III")

		ElseIf $pos_time = 0 Then
			$pos_1 = $pos
			$pos_time = 1
			WinActivate("Titanz ©2012 Lennix, Zero, Neltor")
		EndIf
	EndIf
EndFunc

Func GuiCreateImages()
	GUIDelete()
	createGUI()
	$counter = 0
	;$data = FileOpen($g_settings)

	$combo = GUICtrlCreateCombo("None",10,10,200,10)
 	$entry_1 = IniRead($g_settings,"piclist","pic",1)

	$entry = StringSplit($entry_1,",")

	while $counter < $combo_amount
	;ConsoleWrite($counter)

		$filterlist_combo[$counter] = $entry[$counter+1]
		GUICtrlSetData($combo,$entry[$counter+1] & "|","None")
		ConsoleWrite($combo)
		$counter += 1
	WEnd

	$picbutton = GUICtrlCreateButton("Speichern",75,75,50,20)
	GUICtrlSetState($combo,$GUI_DISABLE)

	GUISetState(@SW_SHOW)
	WinActivate("Diablo III")
EndFunc

Func takepic($pos_1,$pos_2)
	_GDIPlus_Startup()

	ConsoleWrite($pos_1[0] & @CRLF & $pos_1[1] & @CRLF & $pos_2[0] & @CRLF & $pos_2[1])
	$hBitmap = _ScreenCapture_Capture("", $pos_1[0], $pos_1[1], $pos_2[0], $pos_2[1])

    $hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)

    $iX = _GDIPlus_ImageGetWidth($hImage)
    $iY = _GDIPlus_ImageGetHeight($hImage)

	$image = GUICreate("image",$iX,$iY,100,100, -1, $WS_EX_TOPMOST)
	GUISetState(@SW_SHOW)

	$hGraphic = _GDIPlus_GraphicsCreateFromHWND ($image)
	_GDIPLus_GraphicsDrawImage($hGraphic, $hImage, 0,0)

	_GDIPlus_GraphicsDispose($hGraphic)

	GUICtrlSetState($combo,$GUI_ENABLE)

	$pos_time = 0
EndFunc




;------------------------------------
;$sValue = string or file (need to set sfile = 0 for string, sfile = 1 for file)
;$sHash = hash algorthm
;$DLLHashes = the dll location or handle
;$sFile = 0 = string [default], 1 = file
;------------------------------------
Func _Hashes($sValue, $sHash = 'MD5', $DLLHashes = 'hashes.dll', $sFile = 0)
    Local $aValue[1], $sSplit, $hashes = Random(-100,100) & 'hashes.txt'
    If $sFile = 1 And FileExists($sValue) Then $hashes = $sValue
    If $sFile = 0 Then FileWrite($hashes,$sValue) ;seems to only want files so well write a temp one
    $aValue = DllCall($DLLHashes, 'str', 'testit', 'str', $hashes, 'str',$sHash, 'int', false)
    If $sFile = 0 Then FileDelete($hashes) ;then delete it
    If Not @error And IsArray($aValue) Then
        $sSplit = StringSplit($aValue[0],@LF) ;extract hash string
        If Not @error Then $aValue[0] = StringTrimRight($sSplit[1],1)
        If StringInStr($aValue[0],'Error:') Then Return SetError(1,0,0)
        Return $aValue[0]
    EndIf
    SetError(1,0,0)
EndFunc




Func SafeImage()
	$test = GUICtrlRead($combo)


	$test2 = StringSplit($test," ")
	For $i = 1 to (UBound($test2)- 1) Step 1
		$neustring &= $test2[$i]
	Next
	$CLSID = _GDIPlus_EncodersGetCLSID("JPG")
	ConsoleWrite($neustring)
	_GDIPlus_ImageSaveToFileEx($hImage,@ScriptDir & "/D3AHImages/" & $neustring & ".JPG",$CLSID)

	_GDIPlus_ImageDispose($hImage)
	_GDIPlus_ShutDown()
	GuiDelete($image)
	$neustring = ""
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

	If Not FileExists(@ScriptDir & "/conf/localconf.ini") Then
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