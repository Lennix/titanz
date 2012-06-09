Func debug($string)
	ConsoleWrite($string & @CRLF)
	Return $string
EndFunc

Func mouseinfo()
	$pos = MouseGetPos()
	sleep(2000)
	debug($pos[0] & "," & $pos[1] & ":" & PixelGetColor($pos[0], $pos[1]))
EndFunc

Func D3Click($x, $y, $clicks = 1)
	ControlClick("Diablo III", "", 0 , "left", $clicks, $x, $y)
	D3Sleep(50)
EndFunc

Func D3Send($String)
	ControlSend("Diablo III", "", 0, $String)
	D3sleep(250)
EndFunc

Func D3Sleep($time)
	$time = Random($time * 0.9, $time * 1.1)
	sleep($time)
EndFunc

Func GetID($section, $key)
	Return IniRead("settings.ini", $section, $key, "")
EndFunc

Func StartIt()
	$start = Not $start
EndFunc