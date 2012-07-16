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

Local $configProperties[$configSize] = [	"search", "price", "buyout", "accept_buyout","item_type", "item_subtype", "rarity", "filter_1","filtervalue_1", "filter_2", "filtervalue_2", "filter_3","filtervalue_3", "filter_dropdownwindow_entry1","filter_dropdownwindow_entry2","firstitem", "seconditem", "next_page", "prev_page", "filterwindow", "socketsearch", "bid"]
local $configProperties_descriptions[24] = ["place the cursor over the search button","place the cursor over the max buyout price field","place the cursor over the buyout button","select an item click on byout and place the cursor over the accept buyout button","place the cursor over the expand button of the item type field","place the cursor over the expand button of the item subtype field","place the cursor over the expand button of the rarity field","place the cursor over the expand button of the first filter entry","place the cursor over the value field of the first filter","place the cursor over the expand button of the second filter entry","place the cursor over the value field of the second filter","place the cursor over the expand button of the third filter entry","place the cursor over the value field of the third filter","place the cursor over the first entry of any expanded filter","place the cursor over the second entry of any expanded filter","place the cursor over the first item","place the cursor over the second item","place the cursor over the next page button","place the cursor over the previous page button","place the cursor over the left upper corner of the first filter window","place the cursor over the right lower corner of the third expanded filter window" & @CRLF & "remember that not every filter window has the same size depending on the item type you chose, theirfore leave some space to the left to get all window sizes","hover over the first item with sockets, now place the cursor over the left upper corner of the top socket","hover over the last item with sockets, now place the cursor over the right lower corner of the bottom socket","place the cursor over the bid button"]
Local $configDiffProperties[$configDiffEntries] = ["filterentrydiff", "entrydiff", "itemdiff"]
Local $Pref =@ScriptDir & "/conf/pref.ini"
Global $g_socketKnown = FileRead("socketsearch")
Global $g_confPath = @ScriptDir & "/conf/localconf.ini"
Global $g_settings = @ScriptDir & "/conf/settings.ini"
Local $DLLHashes = DllOpen(@ScriptDir & "/UDF/hashes.dll")
Local $configProcessPointLabel = ""

Global $configComplete = False
Global $needConfigCheck = False
Global $runtime = False
Global $logedin = True
Local $ctrlmenu[6]
Local $back
Local $helpmenu[3]
Local $okbutton
Local $login
Local $username
Local $password
Global $msg
Local $edit_content
Local $picedit = 0
Global $g_console
Global $g_console_data
Local $labelstatus
Local $label_conf_entry = 0,$label_conf_entry_x,$label_conf_entry_y,$label_conf_entry_color
Local $label_conf_entry_left,$label_conf_entry_top,$label_conf_entry_right,$label_conf_entry_bottom,$labelstatus_description,$labelReady
Global $g_status
Global $g_status_data = 0
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


Local $configProcessPoint = 0
Local $configCheckPoint = 0
Local $diffPoint = 0
Local $width_faktor
Local $height_faktor
Local $configEndPoint = $configSize
Local $diffPosition[4]

Local $combo_amount = 49
Local $filterlist_combo[$combo_amount]

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
	If $label_conf_entry = Not 0 Then
		Switch $configProperties[$configProcessPoint]

			Case "filterwindow"
				If $filterwindow = False Then
					GUICtrlSetState($label_conf_entry_left,$GUI_Show)

					IniWrite($g_confPath, $configProperties[$configProcessPoint], "left", $pos[0])
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "top", $pos[1])
					$filterwindow = True

					GUICtrlSetData($label_conf_entry,"[" & $configProperties[$configProcessPoint] & "]")
					GUICtrlSetData($label_conf_entry_x,"left = " & $pos[0])
					GUICtrlSetData($label_conf_entry_y,"top = "& $pos[1])
					GUICtrlSetData($label_conf_entry_color,"right = ")
					GUICtrlSetData($label_conf_entry_left,"bottom = ")
					GUICtrlSetData($labelstatus,"filterwindow_bottom_right")
					GUICtrlSetData($labelstatus_description,$configProperties_descriptions[20])


				ElseIf $filterwindow = True Then
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "right", $pos[0])
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "bottom", $pos[1])
					$filterwindow = False

					GUICtrlSetData($labelstatus,"socketsearch")
					GUICtrlSetData($labelstatus_description,$configProperties_descriptions[21])

					GUICtrlSetData($label_conf_entry_color,"right = " & $pos[0])
					GUICtrlSetData($label_conf_entry_left,"bottom = "& $pos[1])

					$configProcessPoint += 1

				EndIf

			Case "socketsearch"
				If $socketsearch = False Then
					GUICtrlSetState($label_conf_entry_left,$GUI_Show)

					IniWrite($g_confPath, $configProperties[$configProcessPoint], "left", $pos[0])
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "top", $pos[1])
					$socketsearch = True

					GUICtrlSetData($label_conf_entry,"[" & $configProperties[$configProcessPoint] & "]")
					GUICtrlSetData($label_conf_entry_x,"left = " & $pos[0])
					GUICtrlSetData($label_conf_entry_y,"top = "& $pos[1])
					GUICtrlSetData($label_conf_entry_color,"right = ")
					GUICtrlSetData($label_conf_entry_left,"bottom = ")
					GUICtrlSetData($labelstatus,"socketsearch_bottom_right")
					GUICtrlSetData($labelstatus_description,$configProperties_descriptions[22])

				ElseIf $socketsearch = True Then
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "right", $pos[0])
					IniWrite($g_confPath, $configProperties[$configProcessPoint], "bottom", $pos[1])
					$socketsearch = False

					GUICtrlSetData($label_conf_entry_color,"right = " & $pos[0])
					GUICtrlSetData($label_conf_entry_left,"bottom = "& $pos[1])

					GUICtrlSetData($labelstatus,"bid")
					GUICtrlSetData($labelstatus_description,$configProperties_descriptions[23])

					$configProcessPoint += 1
				EndIf

			Case "bid"
				GUICtrlSetState($label_conf_entry_left,$GUI_Show)
				GUICtrlSetState($label_conf_entry_top,$GUI_Show)
				GUICtrlSetState($label_conf_entry_right,$GUI_Show)
				GUICtrlSetState($label_conf_entry_bottom,$GUI_Show)
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

				GUICtrlSetData($label_conf_entry,"[" & $configProperties[$configProcessPoint] & "]")
				GUICtrlSetData($label_conf_entry_x,"x = " & $pos[0])
				GUICtrlSetData($label_conf_entry_y,"y = "& $pos[1])
				GUICtrlSetData($label_conf_entry_color,"color = " & $color)
				GUICtrlSetData($label_conf_entry_left,"")
				GUICtrlSetData($label_conf_entry_top,"filterentrydiff = " & Round($filterentrydiff_2 - $filterentrydiff_1))
				GUICtrlSetData($label_conf_entry_right,"entrydiff = " & Round($entrydiff_2 - $entrydiff_1))
				GUICtrlSetData($label_conf_entry_bottom,"itemdiff = " & Round($itemdiff_2 - $itemdiff_1))
				$label_conf_entry = 0
				GUICtrlSetData($labelReady,"Manual overwrite completed")
				GUICtrlSetData($labelstatus,"")
				GUICtrlSetData($labelstatus_description,"")

			Case Else
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "x", $pos[0])
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "y", $pos[1])
				IniWrite($g_confPath, $configProperties[$configProcessPoint], "color", $color)

				GUICtrlSetData($label_conf_entry,"[" & $configProperties[$configProcessPoint] & "]")
				GUICtrlSetData($label_conf_entry_x,"x = " & $pos[0])
				GUICtrlSetData($label_conf_entry_y,"y = "& $pos[1])
				GUICtrlSetData($label_conf_entry_color,"color = " & $color)
				GUICtrlSetData($labelstatus,$configProperties[$configProcessPoint+1])
				GUICtrlSetData($labelstatus_description,$configProperties_descriptions[$configProcessPoint+1])

				$configProcessPoint += 1
		EndSwitch


	EndIf
EndFunc

Func processConfig()
	If not $configComplete Then
		ConvertPreftoLocalconf($configProcessPoint)

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

Func GUIcheck($msg)
	Switch $msg[0]
		Case $ctrlmenu[1]
			Guicreatelocalconfinfo()

		Case $ctrlmenu[2]
			GuiCreateImages()

		Case $ctrlmenu[3]
			$g_console = GUICtrlCreateEdit($g_console_data,0,200,400,100,BitOR($ES_AUTOVSCROLL, $WS_VSCROLL,$ES_READONLY))
			$ctrlmenu[5] = GUICtrlCreatePic("console_hide.jpg", 0, 183, 400, 17)
			GUICtrlSetState($ctrlmenu[5],$GUI_DISABLE)
			GUICtrlSetState($ctrlmenu[5],$GUI_HIDE)
			GUICtrlSetState($ctrlmenu[5],$GUI_Show)
			$ctrlmenu[4] = GUICtrlCreateLabel("",0,183,400,17)
			GUICtrlSetCursor($ctrlmenu[4],0)
			GUICtrlSetTip($ctrlmenu[4],"Hide Console")
			GUICtrlSetBkColor(-1,-2)
			GUICtrlDelete($ctrlmenu[3])

		Case $ctrlmenu[4]
			GUICtrlSetState($g_console,$GUI_HIDE)
			GUICtrlSetState($ctrlmenu[5],$GUI_HIDE)
			GUICtrlDelete($ctrlmenu[4])
			$ctrlmenu[3] = GUICtrlCreateLabel("",0,283,400,17)
			GUICtrlSetTip($ctrlmenu[3],"Show Console")
			GUICtrlSetCursor($ctrlmenu[3],0)
			GUICtrlSetBkColor(-1,-2)

		Case $helpmenu[1]
			GuiCredits()

		Case $helpmenu[2]
			ShellExecute("http://www.d3ahbot.com")

		Case $back
			readyBotGUI(1)

		Case $okbutton
			GuiCreateLocalconf()

		Case $picbutton
			SafeImage()

		Case $login
			login()

		Case $GUI_EVENT_CLOSE				;0x002A052A,0x001B02E0
			If $msg[1] = $main Then
				Exit
			Else
				GUIDelete($msg)
			EndIf


	EndSwitch
EndFunc

Func Contentcreate()
	$helpmenu[2] = GUICtrlCreateLabel("",268,0,132,70)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetCursor($helpmenu[2],0)
	GUICtrlSetTip($helpmenu[2],"Visit our Homepage")

	$ctrlmenu[1] = GUICtrlCreateLabel("",278,93,110,24)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetCursor($ctrlmenu[1],0)
	GUICtrlSetTip($ctrlmenu[1],"If your Localconf isn't working." & @CRLF & "Use this function to manually set the coordinates!")

	$ctrlmenu[2] = GUICtrlCreateLabel("",278,124,110,24)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetCursor($ctrlmenu[2],0)
	GUICtrlSetTip($ctrlmenu[2],"If the Bot can't find the images." & @CRLF & "Use this function to take the pictures manually!")

	$ctrlmenu[3] = GUICtrlCreateLabel("",0,283,400,17)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetTip($ctrlmenu[3],"Show Console")
	GUICtrlSetCursor($ctrlmenu[3],0)
EndFunc

Func Contentdelete()
	GUICtrlDelete($ctrlmenu[2])
	GUICtrlDelete($ctrlmenu[1])
	GUICtrlDelete($helpmenu[2])
	GUICtrlDelete($labelstatus)
	GUICtrlDelete($g_status)
	GUICtrlDelete($back)
	GUICtrlDelete($combo)
	GUICtrlDelete($picbutton)
	GUICtrlDelete($ctrlmenu[3])
	GUICtrlDelete($okbutton)
;~ 	GUICtrlDelete()
;~ 	GUICtrlDelete()
EndFunc

;login eingaben in Global username und password gespeichert
Func createGUI()
	$main = GUICreate("Titanz ©2012 Lennix, Zero, Neltor", 400, 300, -1, -1, -1, $WS_EX_TOPMOST)
	GUISetState(@SW_SHOW)
EndFunc

#cs
;login eingaben in Global username und password gespeichert
Func loginBotGUI()
	GUIDelete()
	createGUI()
	GUICtrlCreatePic("logo.bmp", 249, 0, 101, 102)
	GUICtrlSetState(-1,$GUI_DISABLE)
	$head = GUICtrlCreateLabel("Welcome to titan-z", 100, 10)
	GUICtrlSetColor($head, $color_white)
	GUICtrlSetBkColor(-1,-2)
	$username = GUICtrlCreateInput("username",10,40,200)
	$password = GUICtrlCreateInput("password",10,65,200,20,$ES_PASSWORD)
	$login = GUICtrlCreateButton("login",10,100,50,25)
	GUISetState(@SW_SHOW)

EndFunc


Func login()
	$password = GUICtrlRead($password)
	ConsoleWrite($password &@lf)

	$shash = "SHA256"

    ConsoleWrite('String:'& $password &': Hash-'& $shash &':'& _Hashes($password, $shash, $DLLHashes, 0) & @lf)
EndFunc
#ce

;ready
Func readyBotGUI($msg)
	If $msg = 1	Then
		Contentdelete()
		Contentcreate()
	Else
		Contentcreate()
	EndIf

;~ 	GUICtrlSetState($ctrlmenu[2],$GUI_ENABLE)
;~ 	GUICtrlSetState($ctrlmenu[2],$GUI_Show)

;~ 	GUICtrlSetState($back,$GUI_DISABLE)
;~ 	GUICtrlSetState($back,$GUI_HIDE)


	GUICtrlCreatePic("conf/bg.jpg", 0, 0, 400, 300)
	GUICtrlSetState(-1,$GUI_DISABLE)

	$labelstatus = GUICtrlCreateLabel("Status:", 15, 20)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetColor($labelstatus, $color_green)

	$g_status = GUICtrlCreateLabel($g_status_data, 60, 20,180,20)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetColor($g_status, $color_green)

	If $g_status_data <> 0 Then
		GUICtrlSetData($g_status,$g_status_data)
	EndIf

	;GUICtrlSetBkColor(-1,-2)
	;$f5 = GUICtrlCreateLabel("push F5  to start", 90, 80)
	;GUICtrlSetColor($f5, $color_white)
	;GUICtrlSetBkColor(-1,-2)
	;$f6 = GUICtrlCreateLabel("push F6  to stop while running", 90, 110)
	;GUICtrlSetColor($f6, $color_white)
	;GUICtrlSetBkColor(-1,-2)

EndFunc

;stop
Func stopBotGUI()
	$labelReady = GUICtrlCreateLabel("STOPPED", 135, 20)
	GUICtrlSetColor($labelReady, $color_yellow)
	GUICtrlCreateLabel("push F5  to continue", 90, 80)
EndFunc

;checks if pressing the F10 button should write sth to the localconf or take a picture
Func check($pos,$color)
	If $label_conf_entry = Not 0 Then
		WriteConfManually($pos,$color)
	EndIf

	If $combo = Not 0 Then
		If $pos_time = 1 Then
			$pos_2 = $pos
			takepic($pos_1,$pos_2)
			GUICtrlSetData($labelstatus,"Press F10 to set the top-left coordinates")
			WinActivate("Diablo III")

		ElseIf $pos_time = 0 Then
			$pos_1 = $pos
			$pos_time = 1
			GUICtrlSetData($labelstatus,"Press F10 to set the right-bottom coordinates")
			WinActivate("Titanz ©2012 Lennix, Zero, Neltor")
		EndIf
	EndIf
EndFunc

Func GuiCreateImages()
	Contentdelete()
	Contentcreate()


	$counter = 0

	GUICtrlCreatePic("conf/bg_images.jpg", 0, 0, 400, 300)
	GUICtrlSetState(-1,$GUI_DISABLE)

	GUICtrlSetState($ctrlmenu[2],$GUI_DISABLE)
	GUICtrlSetState($ctrlmenu[2],$GUI_HIDE)

	$back = GUICtrlCreateLabel("",278,124,110,24)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetState($back,$GUI_ONTOP)
	GUICtrlSetCursor($back,0)
	GUICtrlSetTip($back,"Get back to the start menu!")

	$combo = GUICtrlCreateCombo("None",10,50,150,10)
 	$entry_1 = IniRead($g_settings,"piclist","pic",1)

	$labelstatus = GUICtrlCreateLabel("Press F10 to set the top-left coordinates", 5, 20,250,12)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetBkColor(-1,-2)

	GUICtrlCreateLabel("of the image you want to create", 5, 30)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetBkColor(-1,-2)

	$entry = StringSplit($entry_1,",")

	while $counter < $combo_amount
		$filterlist_combo[$counter] = $entry[$counter+1]
		GUICtrlSetData($combo,$entry[$counter+1] & "|","None")
		$counter += 1
	WEnd

	$picbutton = GUICtrlCreateButton("Speichern",10,80,100,20)
	GUICtrlSetState($combo,$GUI_DISABLE)

	WinActivate("Diablo III")
EndFunc

Func Guicreatelocalconfinfo()
	Contentdelete()
	Contentcreate()

	GUICtrlCreatePic("conf/bg_local.jpg", 0, 0, 400, 300)
	GUICtrlSetState(-1,$GUI_DISABLE)

	$labelReady = GUICtrlCreateLabel("By clicking the OK Button" & @CRLF & "your localconf will be deleted!!!", 5, 20)
	GUICtrlSetColor($labelReady, $color_red)
	GUICtrlSetBkColor(-1,-2)

	$back = GUICtrlCreateLabel("",278,93,110,24)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetCursor($back,0)

	GUICtrlSetState($ctrlmenu[1],$GUI_DISABLE)
	$okbutton = GUICtrlCreateButton("OK",5,50,50)

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

	Contentdelete()
	Contentcreate()

	GUICtrlCreatePic("conf/bg_local.jpg", 0, 0, 400, 300)
	GUICtrlSetState(-1,$GUI_DISABLE)

	$back = GUICtrlCreateLabel("",278,93,110,24)
	GUICtrlSetBkColor(-1,-2)
	GUICtrlSetCursor($back,0)

	GUICtrlSetState($ctrlmenu[1],$GUI_DISABLE)

	$labelReady = GUICtrlCreateLabel("Press F10 to get the coordinates of the point", 100, 50,150,150)
	GUICtrlSetColor($labelReady, $color_green)
	GUICtrlSetBkColor(-1,-2)

	$labelstatus = GUICtrlCreateLabel("search", 110, 85,150,150)
	GUICtrlSetColor(-1, $color_green)
	GUICtrlSetBkColor(-1,-2)

	$labelstatus_description = GUICtrlCreateLabel($configProperties_descriptions[0],100,110,150,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetBkColor(-1,-2)

	$label_conf_entry = GUICtrlCreateLabel("[section]",7,5,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetBkColor(-1,-2)

	$label_conf_entry_x = GUICtrlCreateLabel("x = ",7,17,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetBkColor(-1,-2)

	$label_conf_entry_y = GUICtrlCreateLabel("y = ",7,29,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetBkColor(-1,-2)

	$label_conf_entry_color = GUICtrlCreateLabel("color = ",7,41,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetBkColor(-1,-2)

	$label_conf_entry_left = GUICtrlCreateLabel("left = ",7,53,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetState($label_conf_entry_left,$GUI_HIDE)
	GUICtrlSetBkColor(-1,-2)

	$label_conf_entry_top = GUICtrlCreateLabel("top = ",7,65,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetState($label_conf_entry_top,$GUI_HIDE)
	GUICtrlSetBkColor(-1,-2)

	$label_conf_entry_right = GUICtrlCreateLabel("right = ",7,77,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetState($label_conf_entry_right,$GUI_HIDE)
	GUICtrlSetBkColor(-1,-2)

	$label_conf_entry_bottom = GUICtrlCreateLabel("bottom = ",7,89,150)
	GUICtrlSetColor(-1, $color_white)
	GUICtrlSetState($label_conf_entry_bottom,$GUI_HIDE)
	GUICtrlSetBkColor(-1,-2)
EndFunc

Func GuiCredits()
EndFunc

;RUNTIME GUI
Func buildRuntimeGUI($status)
	GUIDelete()
	createGUI()

	;mainStatusBotGUI()
	Switch $status
		Case 0
			loginBotGUI()
		Case 1
			readyBotGUI(0)
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

Func setstatus($status)
	GUICtrlSetData($g_status,$status)
	$g_status_data = $status
EndFunc

Func setconsole($message, $status = "", $return = "")
	iGet("log", "message=" & $message)
	$message = @hour & ":" & @MIN & ":" & @SEC & " -> " & $message
	FileWriteLine("log.txt", $message)
	$g_console_data = $message & @CRLF & $g_console_data
	GUICtrlSetData($g_console,$g_console_data)
	If $status <> "" Then setstatus($status)
	If $return <> "" Then Return $return
EndFunc