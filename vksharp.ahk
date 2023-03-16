#SingleInstance force
#NoEnv
#NoTrayIcon
#MaxMem, 512

token := "" ; ВСТАВЬТЕ СЮДА ТОКЕН ОТ ВК

OnError("error")
SetBatchLines, -1

error(e) {
	global
	Critical
	
	msg_text := e.What "#" e.Line "`n`nТекст ошибки:`n" e.Message "."
	visible_error := "VK Sharp был принудительно остановлен из-за непредвиденной ошибки, которую не предусмотрел разработчик.`n`nКод ошибки: " msg_text "`n`n"
	
	Gui, 1:Destroy
	
	title := "VK Sharp - произошла ошибка"
	settimer, catchmsgbox, 1000
	MsgBox, 16, % title, % visible_error "Пожалуйста, подождите...`n."
	exitapp
	sleep 10000
}

catchMsgbox() {
	global
	
	title := "VK Sharp - произошла ошибка"
	settimer, catchmsgbox, off
	WinWait, % title
	WinGet, msgboxwid, ID, % title
	Control, Disable,, Button1, ahk_id %msgboxwid%	
	ControlSetText, Static2, % visible_error "Попытка сообщить об ошибке разработчику автоматически...", ahk_id %msgboxwid%
	
	StringReplace, msg_text, msg_text, `n, `%newline`%, All
	StringReplace, msg_text, msg_text, `%newline`%, `%0A, All
	StringReplace, msg_text, msg_text, +, `%2B, All
	StringReplace, msg_text, msg_text, #, `%23, All
	
	try whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	try whr.Open("POST", "http://mrakw.eternalhost.info/renux/api.php?method=bt.vksharp&text=" msg_text, true)
	try whr.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36")
	try whr.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
	try whr.Send()
	try whr.WaitForResponse()
	try response := whr.ResponseText
	catch e {
		ControlSetText, Static2, % visible_error "Сообщить не удалось. Попробуйте связаться самостоятельно (vk.com/strdev).", ahk_id %msgboxwid%
		Control, Enable,, Button1, ahk_id %msgboxwid%
		return
	}
	
	if (trim(response) = "") {
		ControlSetText, Static2, % visible_error "Сообщить не удалось. Попробуйте связаться самостоятельно (vk.com/strdev).", ahk_id %msgboxwid%
		Control, Enable,, Button1, ahk_id %msgboxwid%
		return
	}
	
	if response not contains ok
	{
		ControlSetText, Static2, % visible_error "Сообщить не удалось. Попробуйте связаться самостоятельно (vk.com/strdev).", ahk_id %msgboxwid%
		Control, Enable,, Button1, ahk_id %msgboxwid%
		return
	}
	
	ControlSetText, Static2, % visible_error "Разработчик принял сообщение о Вашей ошибке. Спасибо!", ahk_id %msgboxwid%
	Control, Enable,, Button1, ahk_id %msgboxwid%
}

global title := "VK Sharp"
global fontname := "Segoe UI"
global version := "2.2"
global ignore_vkerrors, started, operatorID, token

global HB_Button:=[]
global Button:=[]
pToken := Gdip_Startup()

FileCreateDir, %A_ScriptDir%/vksharpdir
SetWorkingDir, %A_ScriptDir%/vksharpdir
FileDelete, log.txt

logtxt("Стартует VK Sharp2 by Streleck1y...")

OnExit("ExitFunction")

Base64enc( ByRef OutData, ByRef InData, InDataLen ) {
 DllCall( "Crypt32.dll\CryptBinaryToString" ( A_IsUnicode ? "W" : "A" )
        , UInt,&InData, UInt,InDataLen, UInt,1, UInt,0, UIntP,TChars, "CDECL Int" )
 VarSetCapacity( OutData, Req := TChars * ( A_IsUnicode ? 2 : 1 ) )
 DllCall( "Crypt32.dll\CryptBinaryToString" ( A_IsUnicode ? "W" : "A" )
        , UInt,&InData, UInt,InDataLen, UInt,1, Str,OutData, UIntP,Req, "CDECL Int" )
Return TChars
}

OddOrEven(num) {
	return ((Num & 1) != 0) ? "O": "E"
}

GetFileSizeFromInternet(url, ProxyName = "", ProxyBypass = "")
{
   INTERNET_OPEN_TYPE_DIRECT = 1
   INTERNET_OPEN_TYPE_PROXY = 3
   AccessType := ProxyName ? INTERNET_OPEN_TYPE_DIRECT : INTERNET_OPEN_TYPE_PROXY
   INTERNET_FLAG_RELOAD = 0x80000000
   HTTP_QUERY_CONTENT_LENGTH = 5
   coding := A_IsUnicode ? "W" : "A"
 
   hModule := DllCall("LoadLibrary", Str, "wininet.dll")
   hInternet := DllCall("wininet\InternetOpen" . coding
                  , Str, ""   
                  , UInt, INTERNET_OPEN_TYPE_DIRECT
                  , Str, ""
                  , Str, ""
                  , UInt, 0)
   if !hInternet
   {
      Error := A_LastError
      DllCall("FreeLibrary", UInt, hModule)
      Return "Ошибка " . Error
   }
 
   hFile := DllCall("wininet\InternetOpenUrl" . coding
               , UInt, hInternet
               , Str, url
               , Str, ""
               , UInt, 0
               , UInt, INTERNET_FLAG_RELOAD
               , UInt, 0)
   if !hFile
   {
      Error := A_LastError
      DllCall("wininet\InternetCloseHandle", UInt, hInternet)
      DllCall("FreeLibrary", UInt, hModule)
      Return "Ошибка " . Error
   }
 
   VarSetCapacity(buff, 64)
   VarSetCapacity(bufflen, 2)
   Loop 4
   {
      success := DllCall("wininet\HttpQueryInfo" . coding
                  , UInt, hFile
                  , UInt, HTTP_QUERY_CONTENT_LENGTH
                  , UInt, &buff
                  , UInt, &bufflen
                  , UInt, 0)
      if success
         Break
   }
   Result := success ? StrGet(&buff) : "Невозможно извлечь информацию"
 
   DllCall("wininet\InternetCloseHandle", UInt, hInternet)
   DllCall("wininet\InternetCloseHandle", UInt, hFile)
   DllCall("FreeLibrary", UInt, hModule)
 
   Return Result
}

reply(text) {
	global
	random, random_id, 1, 100000
	vk_api("messages.send&user_id=" OperatorID "&random_id=" random_id "&message=" text, token)
	try last_id_msg := api.response
}

exitFunction() {
	global
	if (started) {
		reply("%26#128373; Владелец машины '" A_UserName ":" A_ComputerName "' завершил работу программы. Доступ закрыт.")
	}
	
	logtxt("Работа программы завершена.")
}

logtxt(text) {
	FileAppend, [%A_Hour%:%A_MM%:%A_Sec%] %text%`n, log.txt
}

SaveScreenshotToFile(x, y, w, h, filePath)  {
   hBitmap := GetHBitmapFromScreen(x, y, w, h)
   gdip := new GDIplus
   pBitmap := gdip.BitmapFromHBitmap(hBitmap)
   DllCall("DeleteObject", Ptr, hBitmap)
   gdip.SaveBitmapToFile(pBitmap, filePath)
   gdip.DisposeImage(pBitmap)
}

GetHBitmapFromScreen(x, y, w, h)  {
   hDC := DllCall("GetDC", Ptr, 0, Ptr)
   hBM := DllCall("CreateCompatibleBitmap", Ptr, hDC, Int, w, Int, h, Ptr)
   pDC := DllCall("CreateCompatibleDC", Ptr, hDC, Ptr)
   oBM := DllCall("SelectObject", Ptr, pDC, Ptr, hBM, Ptr)
   DllCall("BitBlt", Ptr, pDC, Int, 0, Int, 0, Int, w, Int, h, Ptr, hDC, Int, x, Int, y, UInt, 0x00CC0020)
   DllCall("SelectObject", Ptr, pDC, Ptr, oBM)
   DllCall("DeleteDC", Ptr, pDC)
   DllCall("ReleaseDC", Ptr, 0, Ptr, hDC)
   Return hBM  ; should be deleted with DllCall("DeleteObject", Ptr, hBM)
}

class GDIplus   {
   __New()  {
      if !DllCall("GetModuleHandle", Str, "gdiplus", Ptr)
         DllCall("LoadLibrary", Str, "gdiplus")
      VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
      DllCall("gdiplus\GdiplusStartup", PtrP, pToken, Ptr, &si, Ptr, 0)
      this.token := pToken
   }
   
   __Delete()  {
      DllCall("gdiplus\GdiplusShutdown", Ptr, this.token)
      if hModule := DllCall("GetModuleHandle", Str, "gdiplus", Ptr)
         DllCall("FreeLibrary", Ptr, hModule)
   }
   
   BitmapFromHBitmap(hBitmap, Palette := 0)  {
      DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", Ptr, hBitmap, Ptr, Palette, PtrP, pBitmap)
      return pBitmap  ; should be deleted with this.DisposeImage(pBitmap)
   }
   
   SaveBitmapToFile(pBitmap, sOutput, Quality=75)  {
      SplitPath, sOutput,,, Extension
      if Extension not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
         return -1

      DllCall("gdiplus\GdipGetImageEncodersSize", UIntP, nCount, UIntP, nSize)
      VarSetCapacity(ci, nSize)
      DllCall("gdiplus\GdipGetImageEncoders", UInt, nCount, UInt, nSize, Ptr, &ci)
      if !(nCount && nSize)
         return -2
      
      Loop, % nCount  {
         sString := StrGet(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
         if !InStr(sString, "*." Extension)
            continue
         
         pCodec := &ci+idx
         break
      }
      
      if !pCodec
         return -3

      if RegExMatch(Extension, "i)^J(PG|PEG|PE|FIF)$") && Quality != 75  {
         DllCall("gdiplus\GdipGetEncoderParameterListSize", Ptr, pBitmap, Ptr, pCodec, UintP, nSize)
         VarSetCapacity(EncoderParameters, nSize, 0)
         DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pBitmap, Ptr, pCodec, UInt, nSize, Ptr, &EncoderParameters)
         Loop, % NumGet(EncoderParameters, "UInt")  {
            elem := (24+A_PtrSize)*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
            if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)  {
               p := elem+&EncoderParameters-pad-4
               NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
               break
            }
         }      
      }
      
      if A_IsUnicode
         pOutput := &sOutput
      else  {
         VarSetCapacity(wOutput, StrPut(sOutput, "UTF-16")*2, 0)
         StrPut(sOutput, &wOutput, "UTF-16")
         pOutput := &wOutput
      }
      E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, pOutput, Ptr, pCodec, UInt, p ? p : 0)
      return E ? -5 : 0
   }
   
   DisposeImage(pBitmap)  {
      return DllCall("gdiplus\GdipDisposeImage", Ptr, pBitmap)
   }
}

CreateFormData(ByRef retData, ByRef retHeader, objParam) {
	New CreateFormData(retData, retHeader, objParam)
}

Class CreateFormData {

	__New(ByRef retData, ByRef retHeader, objParam) {

		Local CRLF := "`r`n", i, k, v, str, pvData
		; Create a random Boundary
		Local Boundary := this.RandomBoundary()
		Local BoundaryLine := "------------------------------" . Boundary

    this.Len := 0 ; GMEM_ZEROINIT|GMEM_FIXED = 0x40
    this.Ptr := DllCall( "GlobalAlloc", "UInt",0x40, "UInt",1, "Ptr"  )          ; allocate global memory

		; Loop input paramters
		For k, v in objParam
		{
			If IsObject(v) {
				For i, FileName in v
				{
					str := BoundaryLine . CRLF
					     . "Content-Disposition: form-data; name=""" . k . """; filename=""" . FileName . """" . CRLF
					     . "Content-Type: " . this.MimeType(FileName) . CRLF . CRLF
          this.StrPutUTF8( str )
          this.LoadFromFile( Filename )
          this.StrPutUTF8( CRLF )
				}
			} Else {
				str := BoundaryLine . CRLF
				     . "Content-Disposition: form-data; name=""" . k """" . CRLF . CRLF
				     . v . CRLF
        this.StrPutUTF8( str )
			}
		}

		this.StrPutUTF8( BoundaryLine . "--" . CRLF )

    ; Create a bytearray and copy data in to it.
    retData := ComObjArray( 0x11, this.Len ) ; Create SAFEARRAY = VT_ARRAY|VT_UI1
    pvData  := NumGet( ComObjValue( retData ) + 8 + A_PtrSize )
    DllCall( "RtlMoveMemory", "Ptr",pvData, "Ptr",this.Ptr, "Ptr",this.Len )

    this.Ptr := DllCall( "GlobalFree", "Ptr",this.Ptr, "Ptr" )                   ; free global memory 

    retHeader := "multipart/form-data; boundary=----------------------------" . Boundary
	}

  StrPutUTF8( str ) {
    Local ReqSz := StrPut( str, "utf-8" ) - 1
    this.Len += ReqSz                                  ; GMEM_ZEROINIT|GMEM_MOVEABLE = 0x42
    this.Ptr := DllCall( "GlobalReAlloc", "Ptr",this.Ptr, "UInt",this.len + 1, "UInt", 0x42 )   
    StrPut( str, this.Ptr + this.len - ReqSz, ReqSz, "utf-8" )
  }
  
  LoadFromFile( Filename ) {
    Local objFile := FileOpen( FileName, "r" )
    this.Len += objFile.Length                     ; GMEM_ZEROINIT|GMEM_MOVEABLE = 0x42 
    this.Ptr := DllCall( "GlobalReAlloc", "Ptr",this.Ptr, "UInt",this.len, "UInt", 0x42 )
    objFile.RawRead( this.Ptr + this.Len - objFile.length, objFile.length )
    objFile.Close()       
  }

	RandomBoundary() {
		str := "0|1|2|3|4|5|6|7|8|9|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z"
		Sort, str, D| Random
		str := StrReplace(str, "|")
		Return SubStr(str, 1, 12)
	}

	MimeType(FileName) {
		n := FileOpen(FileName, "r").ReadUInt()
		Return (n        = 0x474E5089) ? "image/png"
		     : (n        = 0x38464947) ? "image/gif"
		     : (n&0xFFFF = 0x4D42    ) ? "image/bmp"
		     : (n&0xFFFF = 0xD8FF    ) ? "image/jpeg"
		     : (n&0xFFFF = 0x4949    ) ? "image/tiff"
		     : (n&0xFFFF = 0x4D4D    ) ? "image/tiff"
		     : "application/octet-stream"
	}

}

vk_api(method, token) {
	global
	err_code = 0
	StringReplace, method, method, `n, `%newline`%, All
	StringReplace, method, method, `%newline`%, `%0A, All
	StringReplace, method, method, +, `%2B, All
	StringReplace, method, method, #, `%23, All
	random, rid, 1000, 9999
	StringReplace, method, method, `%random_id`%, % rid, All
	MessagePeerRound := Round(MessagePeer)
	StringReplace, method, method, peer_id=%MessagePeer%, peer_id=%MessagePeerRound%
	MessagePeer = % MessagePeerRound
	api_host := "https://api.vk.com/api.php?oauth=1&"
	
	try whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	Loop, parse, method, `&
	{
		RegExMatch(A_LoopField, "v=(.*)", loopfieldout)
		if loopfieldout
			text_api := api_host "&method=" method "&access_token=" token
		else
			text_api := api_host "&method=" method "&access_token=" token "&v=5.95"
	}
	
	logtxt("VK_API(): Формирование и отправка POST-запроса...")
	try whr.Open("POST", text_api, true)
	try whr.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36")
	try whr.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
	try whr.Send()
	try whr.WaitForResponse()
	try response := whr.ResponseText
	catch e {
		logtxt("VK_API(): Ошибка. Не удалось получить ответ сервера: " e.Message)
		return
	}
	
	logtxt("VK_API(): ЗАПРОС '" method "'.")
	logtxt("VK_API(): ОТВЕТ: '" response "'.")
	
	if (trim(response) = "") {
		logtxt("VK_API(): Ошибка. Ответ сервера пуст.")
		return
	}
	
	try JSON = %response%
	try htmldoc := ComObjCreate("htmlfile")
	try Script := htmldoc.Script
	try Script.execScript(" ", "JScript")
	try api := Script.eval("(" . JSON . ")")
	catch e {
		logtxt("VK_API(): Ошибка преобразования JSON ответа в объект: " response "`n`nОшибка: " e.Message ".")
		return
	}
	
	if !ignore_vkerrors
	{
		err_code = 0
		try err_code := api.error.error_code
		if err_code
		{
			if err_code = 1
			{
				MsgBox, 16, %title%, ВКонтакте выдал неизвестную ошибку. Попробуйте повторить запрос позже.
			}
			
			if err_code = 2
			{
				MsgBox, 16, %title%, Приложение было выключено. Пересоздайте токен рабочего приложения.
				IniWrite, % "", config.ini, vkauth, token
				reload
			}
			
			if err_code = 3
			{
				MsgBox, 16, %title%, Передан неизвестный метод. Проверьте`, правильно ли указано название вызываемого метода.
				return
			}
			
			if err_code = 4
			{
				MsgBox, 16, %title%, ВКонтакте сообщает о неверной подписи.
				return
			}
			
			if err_code = 5
			{
				MsgBox, 16, %title%, Сессия недействительна. Необходима авторизация.
				exitapp
			}
			
			if err_code = 6
			{
				sleep 333
				vk_api(method, token)
				return
			}
			
			if err_code = 7
			{
				Loop, parse, method, `.
				{
					permission := A_LoopField
					break
				}
				
				Gui, +OwnDialogs
				MsgBox, 16, %title%, Приложение не имеет прав для запроса. Перевойдите в аккаунт с помощью токена`, который с правом %permission%.
				IniWrite, % "", config.ini, vkauth, token
				reload
				exitapp
			}
			
			if err_code = 8
			{
				MsgBox, 16, %title%, Недопустимый синтаксис запроса.
				return
			}
			
			if err_code = 9
			{
				MsgBox, 16, %title%, Слишком много однотипных действий. Нужно сократить число однотипных обращений.
				return
			}
			
			if err_code = 10
			{
				MsgBox, 16, %title%, Произошла внутренняя ошибка сервера.
				return
			}
			
			if err_code = 14
			{
				try captcha_sid := api.error.captcha_sid
				try captcha_img := api.error.captcha_img
				
				vk_api(method "&captcha_sid=" captcha_sid "&captcha_key=" captcha(captcha_img), token)
				return
			}
			
			if err_code = 17
			{
				redirect_uri := api.error.redirect_uri
				try ie := ComObjCreate("InternetExplorer.Application")
				catch {
					iecrash = 1
				}
				try ie.toolbar := false
				catch {
					iecrash = 1
				}
				try ie.visible := true
				catch {
					iecrash = 1
				}
				try ie.navigate(redirect_uri)
				catch {
					iecrash = 1
				}
				
				if iecrash = 1
				{
					MsgBox, 16, %title%, Произошла ошибка при создании объекта. Убедитесь`, что у Вас установлен и обновлен Internet Explorer`, а также не имеется поврежденных файлов.
					return
				}
				
				loop {
					try ie_readystate := ie.ReadyState
					catch {
						return
					}
					
					if ie_readystate = 4
						break
				}
				
				try ie.visible := true
				WinGet, ieid, ID, ahk_class IEFrame
				logtxt("`n[Вход] Ожидание действий пользователя...")
				loop {
					IfWinNotExist, ahk_id %ieid%
					{
						MsgBox, 16, %title%, Запрос не может быть выполнен.
						break
					}
					
					ControlGetText, ielink, Edit1, ahk_id %ieid%
					if ielink contains success
					{
						vk_api(method, token)
						break
					}
				}
				
				process, close, iexplore.exe
			}
		}
	}
	
	;if method contains edit
	;	MsgBox % response
	
	return response
}

captcha(urltofile)
{
	global
	URLDownloadToFile, % urltofile, %A_temp%\gh_captcha.png
	WinSet, Disable,, ahk_id %mainwid%
	GuiControl, hide, textpagestatic3
	
	Gui, Captcha:Destroy
	Gui, Captcha:-SysMenu +AlwaysOnTop +hwndcaptchawin
	Gui, Captcha:Color, White
	Gui, Captcha:Font, S9 CDefault, Segoe UI
	Gui, Captcha:Add, Picture, x12 y9 w130 h50 vCaptchaImg, %A_Temp%\gh_captcha.png
	Gui, Captcha:Add, Edit, x12 y69 w130 h20 vCaptchaEnter, 
	Gui, Captcha:Add, Button, x12 y99 w130 h30 gCaptchaOK, OK
	Gui, Captcha:Show, w154 h137, Введите капчу
	captchaenter = 0
	settimer, captchaguiclose, 1
	return
	
	captchaguiclose:
	IfWinActive, ahk_id %mainwid%
		WinActivate, ahk_id %captchawin%
		
	if captchaenter
	{
		settimer, captchaguiclose, off
		return
	}
	
	IfWinNotActive, ahk_id %captchawin%
		return
		
	if GetKeyState("Escape", "P")
		goto captchaok
		
	if GetKeyState("Enter", "P")
		goto captchaok
	
	return
	
	captchaok:
	gui, captcha:submit, nohide
	if !captchaenter
		return
	
	settimer, captchaguiclose, off
	gui, captcha:destroy
	WinSet, Enable,, ahk_id %mainwid%
	return CaptchaEnter
}

HB_Button_Hover(){
    Static Index , Hover_On
    MouseGetPos,,,, ctrl , 2
    if( ! Hover_On && ctrl ){
        loop , % HB_Button.Length()
            if( ctrl = HB_Button[ A_Index ].hwnd )
                HB_Button[ A_Index ].Draw_Hover() , Index := A_Index , Hover_On := 1 , break
    }else if( Hover_On = 1 )
        if( ctrl != HB_Button[ Index ].Hwnd )
            HB_Button[ Index ].Draw_Default() , Hover_On := 0
}
;-----------------------------------------------------------------
 
class Flat_Round_Switch_Type_1	{
	__New(x,y,w:=19,Text:="Text",Font:="Arial",FontSize:= "10 Bold" , FontColor:="FFFFFF" ,Window:="1",Background_Color:="36373A",State:=0,Label:=""){
		This.State:=State
		This.X:=x
		This.Y:=y
		This.W:=w
		This.H:=21
		This.Text:=Text
		This.Font:=Font
		This.FontSize:=FontSize
		This.FontColor:= "0xFF" FontColor
		This.Background_Color:= "0xFF" Background_Color
		This.Window:=Window
		This.Create_Off_Bitmap()
		This.Create_On_Bitmap()
		This.Create_Trigger()
		This.Label:=Label
		sleep,20
		if(This.State)
			This.Draw_On()
		else
			This.Draw_Off()
	}
	Create_Trigger(){
		Gui , % This.Window ": Add" , Picture , % "x" This.X " y" This.Y " w" This.W " h" This.H " 0xE hwndhwnd"
		This.Hwnd:=hwnd
		BD := THIS.Switch_State.BIND( THIS ) 
		GUICONTROL +G , % This.Hwnd , % BD
	}
	Create_Off_Bitmap(){
		;Bitmap Created Using: HB Bitmap Maker
		pBitmap:=Gdip_CreateBitmap( This.W , 21 ) 
		 G := Gdip_GraphicsFromImage( pBitmap )
		Gdip_SetSmoothingMode( G , 2 )
		Brush := Gdip_BrushCreateSolid( This.Background_Color )
		Gdip_FillRectangle( G , Brush , -1 , -1 , This.W+2 , 23 )
		Gdip_DeleteBrush( Brush )
		Pen := Gdip_CreatePen( "0xFF44474A" , 1 )
		Gdip_DrawRoundedRectangle( G , Pen , 1 , 2 , 26 , 14 , 5 )
		Gdip_DeletePen( Pen )
		Pen := Gdip_CreatePen( "0xFF1B1D1E" , 1 )
		Gdip_DrawRoundedRectangle( G , Pen , 1 , 2 , 26 , 13 , 5 )
		Gdip_DeletePen( Pen )
		Brush := Gdip_BrushCreateSolid( "0xFF262827" )
		Gdip_FillRoundedRectangle( G , Brush , 1 , 2 , 26 , 13 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0xFF303334" )
		Gdip_FillRoundedRectangle( G , Brush , 2 , 3 , 24 , 11 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0x8827282B" )
		Gdip_FillEllipse( G , Brush , 0 , 0 , 18 , 18 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "8827281F" )
		Gdip_FillEllipse( G , Brush , 0 , 0 , 17 , 17 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 3 , 2 , 11 , 14 , "0xFF60646A" , "0xFF393B3F" , 1 , 1 )
		Gdip_FillEllipse( G , Brush , 1 , 1 , 15 , 15 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 5 , 3 , 10 , 12 , "0xFF4D5055" , "0xFF36383B" , 1 , 1 )
		Gdip_FillEllipse( G , Brush , 2 , 2 , 13 , 13 )
		Gdip_DeleteBrush( Brush )
		;Adding text
		;-------------------------------------------------------------
		Brush := Gdip_BrushCreateSolid( This.FontColor )
		Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " vCenter c" Brush " x33 y0" , This.Font , This.W-33, This.H )
		Gdip_DeleteBrush( Brush )
		;-------------------------------------------------------------
		Gdip_DeleteGraphics( G )
		This.Off_Bitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		Gdip_DisposeImage(pBitmap)
	}
	Create_On_Bitmap(){
		;Bitmap Created Using: HB Bitmap Maker
		pBitmap:=Gdip_CreateBitmap( This.W , 21 ) 
		 G := Gdip_GraphicsFromImage( pBitmap )
		Gdip_SetSmoothingMode( G , 2 )
		Brush := Gdip_BrushCreateSolid( This.Background_Color )
		Gdip_FillRectangle( G , Brush , -1 , -1 , This.W+2 , 23 )
		Gdip_DeleteBrush( Brush )
		Pen := Gdip_CreatePen( "0xFF44474A" , 1 )
		Gdip_DrawRoundedRectangle( G , Pen , 1 , 2 , 26 , 14 , 5 )
		Gdip_DeletePen( Pen )
		Pen := Gdip_CreatePen( "0xFF1B1D1E" , 1 )
		Gdip_DrawRoundedRectangle( G , Pen , 1 , 2 , 26 , 13 , 5 )
		Gdip_DeletePen( Pen )
		;------------------------------------------------------------------
		;On Background Colors
		Brush := Gdip_BrushCreateSolid( "0xFF4169E1" )
		Gdip_FillRoundedRectangle( G , Brush , 2 , 3 , 25 , 11 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0xFF4169E1" )
		;--------------------------------------------------------------------
		Gdip_FillRoundedRectangle( G , Brush , 2 , 5 , 23 , 9 , 4 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0x8827282B" )
		Gdip_FillEllipse( G , Brush , 11 , 0 , 18 , 18 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0xFF1A1C1F" )
		Gdip_FillEllipse( G , Brush , 11 , 0 , 17 , 17 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 3 , 2 , 11 , 14 , "0xFF60646A" , "0xFF393B3F" , 1 , 1 )
		Gdip_FillEllipse( G , Brush , 12 , 1 , 15 , 15 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 5 , 3 , 10 , 12 , "0xFF4D5055" , "0xFF36383B" , 1 , 1 )
		Gdip_FillEllipse( G , Brush , 13 , 2 , 13 , 13 )
		Gdip_DeleteBrush( Brush )
		;Adding text
		;-------------------------------------------------------------
		Brush := Gdip_BrushCreateSolid( This.FontColor )
		Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " vCenter c" Brush " x33 y0" , This.Font , This.W-33, This.H )
		Gdip_DeleteBrush( Brush )
		;-------------------------------------------------------------
		Gdip_DeleteGraphics( G )
		This.On_Bitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		Gdip_DisposeImage(pBitmap)
	}
	Switch_State(){
		(This.State:=!This.State)?(This.Draw_On()):(This.Draw_Off())
		if(This.Label)	
			gosub,% This.Label
	}
	Draw_Off(){
		SetImage( This.Hwnd , This.Off_Bitmap )
	}
	Draw_On(){
		SetImage( This.Hwnd , This.On_Bitmap )
	}
}
 
;-----------------------------------------------------------------
;Add the button class to the bottom of your script (or go lib route if you know how to)

class Button_Type1	{
	__New(x,y,w,h,text,FontSize,name,label,Window,Color:="0xFF186498",Set:=0){
		This.X:=X,This.Y:=Y,This.W:=W,This.H:=H,This.FontSize:=FontSize,This.Text:=Text,This.Name:=Name,This.Label:=Label,This.Color:=Color,This.Window:=Window,This.isPressed:=0,This.Set:=Set
		This.Create_Default_Button()
		This.Create_Hover_Button()
		This.Create_Pressed_Button()
		This.Add_Trigger()
		This.Draw_Default()
	}
	Add_Trigger(){
		global
		Gui,% This.Window ":Add",Picture,% "x" This.X " y" This.Y " w" This.W " h" This.H " v" This.Name " g" This.Label " 0xE"
		GuiControlGet,hwnd,% This.Window ":hwnd",% This.Name
		This.Hwnd:=hwnd
	}
	Create_Default_Button(){
		;Bitmap Created Using: HB Bitmap Maker
		pBitmap:=Gdip_CreateBitmap( This.W , This.H ) 
		 G := Gdip_GraphicsFromImage( pBitmap )
		Gdip_SetSmoothingMode( G , 2 )
		Brush := Gdip_BrushCreateSolid( "0xFFFFFFFF" )
		Gdip_FillRectangle( G , Brush , -1 , -1 , This.W+2 , This.H+2 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0xFF060B0F" )
		Gdip_FillRoundedRectangle( G , Brush , 2 , 3 , This.W-5 , This.H-7 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0xFF386aff" )
		Gdip_FillRoundedRectangle( G , Brush , 3 , 4 , This.W-7 , This.H-9 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H-10 , "0xFF386aff" , "0xFF386aff" , 1 , 1 )
		Gdip_FillRoundedRectangle( G , Brush , 4 , 5 , This.W-9 , This.H-11 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W-30 , This.H+21 , "0xFF386aff" , "0xFF386aff" , 1 , 1 )
		Gdip_FillRoundedRectangle( G , Brush , 4 , 7 , This.W-9 , This.H-13 , 5 )
		Gdip_DeleteBrush( Brush )
		Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter caaFFFFFF x0 y1" , fontname , This.W , This.H )
		Gdip_DeleteGraphics( G )
		This.Default_Bitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		Gdip_DisposeImage(pBitmap)
	}
	Create_Hover_Button(){
		;Bitmap Created Using: HB Bitmap Maker
		pBitmap:=Gdip_CreateBitmap( This.W , This.H ) 
		 G := Gdip_GraphicsFromImage( pBitmap )
		Gdip_SetSmoothingMode( G , 2 )
		Brush := Gdip_BrushCreateSolid( "0xFFFFFFFF" )
		Gdip_FillRectangle( G , Brush , -1 , -1 , This.W+2 , This.H+2 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0xFF060B0F" )
		Gdip_FillRoundedRectangle( G , Brush , 2 , 3 , This.W-5 , This.H-7 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0xFF386aff" )
		Gdip_FillRoundedRectangle( G , Brush , 3 , 4 , This.W-7 , This.H-9 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H-10 , "0xFF386aff" , "0xFF386aff" , 1 , 1 )
		Gdip_FillRoundedRectangle( G , Brush , 4 , 5 , This.W-9 , This.H-11 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W-30 , This.H+1 , "0xFF386aff" , "0xFF386aff" , 1 , 1 )
		Gdip_FillRoundedRectangle( G , Brush , 4 , 7 , This.W-9 , This.H-13 , 5 )
		Gdip_DeleteBrush( Brush )
		
		;Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter cFFFFFFFF x-1 y2" , "Segoe UI" , This.W , This.H )
		Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter cFFDCDCDC x-1 y1" , fontname , This.W , This.H )
		Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter cFFDCDCDC x-1 y0" , fontname , This.W , This.H )
		;Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter cFFFFFFFF x0 y0" , "Segoe UI" , This.W , This.H )
		;Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter cFFFFFFFF x1 y2" , "Segoe UI" , This.W , This.H )
		;Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter cFFFFFFFF x1 y1" , "Segoe UI" , This.W , This.H )
		
		Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter caaF0F0F0 x0 y1" , fontname , This.W , This.H )
		Gdip_DeleteGraphics( G )
		This.Hover_Bitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		Gdip_DisposeImage(pBitmap)
	}
	Create_Pressed_Button(){
		;Bitmap Created Using: HB Bitmap Maker
		pBitmap:=Gdip_CreateBitmap( This.W , This.H ) 
		 G := Gdip_GraphicsFromImage( pBitmap )
		Gdip_SetSmoothingMode( G , 4 )
		Brush := Gdip_BrushCreateSolid( "0xFF1C2125" )
		Gdip_FillRectangle( G , Brush , -1 , -1 , This.W+2 , This.H+2 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_BrushCreateSolid( "0xFF31363B" )
		Gdip_FillRoundedRectangle( G , Brush , 2 , 3 , This.W-5 , This.H-6 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H , "0xFF151A20" , "0xFF151A20" , 1 , 1 )
		Gdip_FillRoundedRectangle( G , Brush , 2 , 3 , This.W-5 , This.H-8 , 5 )
		Gdip_DeleteBrush( Brush )
		Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W-7 , This.H+10  , "0xFF003366" , "0xFF42474D"  , 1 , 1 )
		Gdip_FillRoundedRectangle( G , Brush , 3 , 4 , This.W-7 , This.H-10 , 5 )
		Gdip_DeleteBrush( Brush )
		Gdip_TextToGraphics( G , This.Text , "s" This.FontSize " Bold Center vcenter caaF0F0F0 x0 y0" , fontname , This.W , This.H )
		Gdip_DeleteGraphics( G )
		This.Pressed_Bitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		Gdip_DisposeImage(pBitmap)
	}
	Draw_Default(){
		SetImage(This.Hwnd, This.Default_Bitmap)
	}
	Draw_Hover(){
		SetImage(This.Hwnd, This.Hover_Bitmap)
	}
	Draw_Pressed(){
		SetImage(This.Hwnd, This.Pressed_Bitmap)
		SetTimer,Watch_Hover,Off
		While(GetKeyState("LButton"))
			sleep,10
		SetTimer,Watch_Hover,On
		MouseGetPos,,,,ctrl,2
		if(ctrl!=This.hwnd){
			This.Draw_Default()
			return false
		}else	{
			This.Draw_Hover()
			return true
		}
	}
}

Watch_Hover(){
	IfWinNotActive, ahk_id %mainwid%
		return
	
	Static Index,lctrl,Hover_On
	MouseGetPos,,,,ctrl,2
	if(!Hover_On&&ctrl){
		loop,% Button.Length()
			if(ctrl=Button[A_Index].hwnd)
				Button[A_Index].Draw_Hover(),lctrl:=ctrl,Index:=A_Index,Hover_On:=1,break
	}else if(Hover_On=1)
		if((!ctrl||lctrl!=ctrl)&&Button[Index].isPressed=0)
			Button[Index].Draw_Default(),Hover_On:=0
}

class HB_Flat_Rounded_Button_Type_1 {
    __New( x := 10 , y := 10 , w := 150 , h := 40 , Button_Color := "FF0000" , Button_Background_Color := "222222" , Text := "Button" , Font := "Arial" , Font_Size := 16 , Font_Color_Top := "000000" , Font_Color_Bottom := "FFFFFF" , Window := "1" , Label := "" , Default_Button := 1, Roundness:=5 ){
        This.Roundness:=Roundness
        This.Text_Color_Top := "0xFF" Font_Color_Top 
        This.Text_Color_Bottom := "0xFF" Font_Color_Bottom 
        This.Font := Font 
        This.Font_Size := Font_Size 
        This.Text := Text
        This.X := x 
        This.Y := y 
        This.W := w 
        This.H := h 
        This.Button_Background_Color := "0xFF" Button_Background_Color 
        This.Button_Color := "0xFF" Button_Color 
        This.Window := Window
        This.Label := Label 
        This.Default_Button := Default_Button 
        This.Create_Default_Bitmap() 
        This.Create_Hover_Bitmap() 
        This.Create_Pressed_Bitmap() 
        This.Create_Trigger()
        sleep, 20
        This.Draw_Default()
    }
    Create_Trigger(){
        global
        num := HB_Button.Length()+1
        Gui , % This.Window ": Add" , Picture , % "x" This.X " y" This.Y " w" This.W " h" This.H " hwndHwnd v" Num " g" This.Label " 0xE"
        This.Number := Num , This.Hwnd := Hwnd
    }
    Create_Default_Bitmap(){
        ;Bitmap Created Using: HB Bitmap Maker
        pBitmap:=Gdip_CreateBitmap( This.W , This.H ) ;96x29
         G := Gdip_GraphicsFromImage( pBitmap )
        Gdip_SetSmoothingMode( G , 2 )
        ;Brush := Gdip_BrushCreateSolid( This.Button_Background_Color )
        Gdip_FillRectangle( G , Brush , 0 , 0 , This.W , This.H )
        ;Gdip_DeleteBrush( Brush )
        Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H , "0xFF486A8D" , "0xFF486A8D" , 0 , 0 )
        Gdip_FillRoundedRectangle( G , Brush , 0 , 0 , This.W , This.H-0 , This.Roundness )
        ;Gdip_DeleteBrush( Brush )
        
        ;---------------------------------------------------
        if(This.Default_Button)
            Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H , "0xFF486A8D" , "0xFF486A8D" , 1 , 1 )
        else    
            Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H , This.Button_Color , "0xFF486A8D" , 1 , 1 )
        ;-------------------------------------------    
            
        ;Gdip_FillRoundedRectangle( G , Brush , 1 , 2 , This.W-2 , This.H-5 , This.Roundness )
        ;Gdip_DeleteBrush( Brush )
        Pen := Gdip_CreatePen( "0xFF1A1C1F" , 1 )
        ;Gdip_DrawRoundedRectangle( G , Pen , 0 , 0 , This.W-1 , This.H-3 , This.Roundness )
        Gdip_DeletePen( Pen )
        Brush := Gdip_BrushCreateSolid( This.Text_Color_Bottom )
        Gdip_TextToGraphics( G , This.Text , "s" This.Font_Size " Center vCenter c" Brush " x1 y2 " , This.Font , This.W , This.H-1 )
        Gdip_DeleteBrush( Brush )
        Brush := Gdip_BrushCreateSolid( This.Text_Color_Top )
        Gdip_TextToGraphics( G , This.Text , "s" This.Font_Size " Center vCenter c" Brush " x0 y1 " , This.Font , This.W , This.H-1 )
        Gdip_DeleteBrush( Brush )
        Gdip_DeleteGraphics( G )
        This.Default_Bitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
        Gdip_DisposeImage(pBitmap)
    }
    Create_Hover_Bitmap(){
        ;Bitmap Created Using: HB Bitmap Maker
        pBitmap:=Gdip_CreateBitmap( This.W , This.H ) ;96x29
         G := Gdip_GraphicsFromImage( pBitmap )
        Gdip_SetSmoothingMode( G , 2 )
        Brush := Gdip_BrushCreateSolid( This.Button_Background_Color )
        Gdip_FillRectangle( G , Brush , -1 , -1 , This.W+2 , This.H+2 )
        Gdip_DeleteBrush( Brush )
        
        Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H , "0xFF61646A" , "0xFF2E2124" , 1 , 1 )
        Gdip_FillRoundedRectangle( G , Brush , 0 , 1 , This.W , This.H-3 , This.Roundness )
        Gdip_DeleteBrush( Brush )
        ;---------------------------------------------------------------------------
        if(This.Default_Button)
            Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H , "0xFF55585D" , "0xFF3B3E41" , 1 , 1 )
            
        else 
            Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H , "0x44A826A2" , "0xFF3B3E41" , 1 , 1 )
        ;----------------------------------------------------------------   
        Gdip_FillRoundedRectangle( G , Brush , 1 , 2 , This.W-2 , This.H-5 , This.Roundness )
        Gdip_DeleteBrush( Brush )
        Pen := Gdip_CreatePen( "0xFF1A1C1F" , 1 )
        Gdip_DrawRoundedRectangle( G , Pen , 0 , 0 , This.W-1 , This.H-3 , This.Roundness )
        Gdip_DeletePen( Pen )
        Brush := Gdip_BrushCreateSolid( This.Text_Color_Bottom )
        Gdip_TextToGraphics( G , This.Text , "s" This.Font_Size " Center vCenter c" Brush " x1 y2" , This.Font , This.W , This.H-1 )
        Gdip_DeleteBrush( Brush )
        Brush := Gdip_BrushCreateSolid( This.Text_Color_Top )
        Gdip_TextToGraphics( G , This.Text , "s" This.Font_Size " Center vCenter c" Brush " x0 y1" , This.Font , This.W , This.H-1 )
        Gdip_DeleteBrush( Brush )
        Gdip_DeleteGraphics( G )
        This.Hover_Bitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
        Gdip_DisposeImage(pBitmap)
    }
    Create_Pressed_Bitmap(){
        pBitmap:=Gdip_CreateBitmap( This.W , This.H ) 
         G := Gdip_GraphicsFromImage( pBitmap )
        Gdip_SetSmoothingMode( G , 2 )
        Brush := Gdip_BrushCreateSolid( This.Button_Background_Color )
        Gdip_FillRectangle( G , Brush , -1 , -1 , This.W+2 , This.H+2 )
        Gdip_DeleteBrush( Brush )
        Brush := Gdip_CreateLineBrushFromRect( 0 , 0 , This.W , This.H , "0xFF2A2C2E" , "0xFF45474E" , 1 , 1 )
        Gdip_FillRoundedRectangle( G , Brush , 0 , 1 , This.W , This.H-3 , This.Roundness )
        Gdip_DeleteBrush( Brush )
        Brush := Gdip_BrushCreateSolid( "0xFF2A2C2E" )
        Gdip_FillRoundedRectangle( G , Brush , 0 , 0 , This.W , This.H-8 , This.Roundness )
        Gdip_DeleteBrush( Brush )
        Brush := Gdip_BrushCreateSolid( "0xFF46474D" )
        Gdip_FillRoundedRectangle( G , Brush , 0 , 7 , This.W , This.H-8 , This.Roundness )
        Gdip_DeleteBrush( Brush )
        ;------------------------------------------------------------------
        if(This.Default_Button)
            Brush := Gdip_CreateLineBrushFromRect( 5 , 3 , This.W ,This.H-7 , "0xFF333639" , "0xFF43474B" , 1 , 1 )
        else 
            Brush := Gdip_CreateLineBrushFromRect( 5 , 3 , This.W ,This.H-7 , "0xFF333639" , "0xFF0066aa" , 1 , 1 )
        ;-----------------------------------------------------------------------
        Gdip_FillRoundedRectangle( G , Brush , 1 , 2 , This.W-3 , This.H-6 , This.Roundness )
        Gdip_DeleteBrush( Brush )
        Pen := Gdip_CreatePen( "0xFF1A1C1F" , 1 )
        Gdip_DrawRoundedRectangle( G , Pen , 0 , 0 , This.W-1 , This.H-3 , This.Roundness )
        Gdip_DeletePen( Pen )
        Brush := Gdip_BrushCreateSolid( This.Text_Color_Bottom )
        Gdip_TextToGraphics( G , This.Text , "s" This.Font_Size " Center vCenter c" Brush " x1 y3" , This.Font , This.W , This.H-1 )
        Gdip_DeleteBrush( Brush )
        Brush := Gdip_BrushCreateSolid( This.Text_Color_Top )
        Gdip_TextToGraphics( G , This.Text , "s" This.Font_Size " Center vCenter c" Brush " x0 y2" , This.Font , This.W , This.H-1 )
        Gdip_DeleteBrush( Brush )
        Gdip_DeleteGraphics( G )
        This.Pressed_Bitmap := Gdip_CreateHBITMAPFromBitmap( pBitmap )
        Gdip_DisposeImage( pBitmap )
    }
    Draw_Default(){
        SetImage( This.Hwnd , This.Default_Bitmap )
    }
    Draw_Hover(){
        SetImage( This.Hwnd , This.Hover_Bitmap )
    }
    Draw_Pressed(){
        SetImage( This.Hwnd , This.Pressed_Bitmap )
        SetTimer , HB_Button_Hover , Off
        While( GetKeyState( "LButton" ) )
            sleep , 10
        SetTimer , HB_Button_Hover , On
        MouseGetPos,,,, ctrl , 2
        if( This.Hwnd != ctrl ){
            This.Draw_Default()
            return False
        }else   {
            This.Draw_Hover()
            return true
        }
    }
}
;-----------------------------------------------------------------
 
 
 
 
 
 
 
;-----------------------------------------------------------------
;Add the GDIP Lib to the bottom of your script (or go lib route if you know how to)
; Thats it.All done
 
;######################################################################################################################################
;#####################################################                          #######################################################
;#####################################################        Gdip LITE         #######################################################
;#####################################################                          #######################################################
;######################################################################################################################################
; Gdip standard library v1.45 by tic (Tariq Porter) 07/09/11
; Modifed by Rseding91 using fincs 64 bit compatible Gdip library 5/1/2013
BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster=""){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdi32\BitBlt", Ptr, dDC, "int", dx, "int", dy, "int", dw, "int", dh, Ptr, sDC, "int", sx, "int", sy, "uint", Raster ? Raster : 0x00CC0020)
}
Gdip_DrawImage(pGraphics, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    if (Matrix&1 = "")
        ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
    else if (Matrix != 1)
        ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
    if(sx = "" && sy = "" && sw = "" && sh = ""){
        if(dx = "" && dy = "" && dw = "" && dh = ""){
            sx := dx := 0, sy := dy := 0
            sw := dw := Gdip_GetImageWidth(pBitmap)
            sh := dh := Gdip_GetImageHeight(pBitmap)
        }else   {
            sx := sy := 0,sw := Gdip_GetImageWidth(pBitmap),sh := Gdip_GetImageHeight(pBitmap)
        }
    }
    E := DllCall("gdiplus\GdipDrawImageRectRect", Ptr, pGraphics, Ptr, pBitmap, "float", dx, "float", dy, "float", dw, "float", dh, "float", sx, "float", sy, "float", sw, "float", sh, "int", 2, Ptr, ImageAttr, Ptr, 0, Ptr, 0)
    if ImageAttr
        Gdip_DisposeImageAttributes(ImageAttr)
    return E
}
Gdip_SetImageAttributesColorMatrix(Matrix){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    VarSetCapacity(ColourMatrix, 100, 0)
    Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", "", 1), "[^\d-\.]+", "|")
    StringSplit, Matrix, Matrix, |
    Loop, 25
    {
        Matrix := (Matrix%A_Index% != "") ? Matrix%A_Index% : Mod(A_Index-1, 6) ? 0 : 1
        NumPut(Matrix, ColourMatrix, (A_Index-1)*4, "float")
    }
    DllCall("gdiplus\GdipCreateImageAttributes", A_PtrSize ? "UPtr*" : "uint*", ImageAttr)
    DllCall("gdiplus\GdipSetImageAttributesColorMatrix", Ptr, ImageAttr, "int", 1, "int", 1, Ptr, &ColourMatrix, Ptr, 0, "int", 0)
    return ImageAttr
}
Gdip_GetImageWidth(pBitmap){
   DllCall("gdiplus\GdipGetImageWidth", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Width)
   return Width
}
Gdip_GetImageHeight(pBitmap){
   DllCall("gdiplus\GdipGetImageHeight", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Height)
   return Height
}
Gdip_DeletePen(pPen){
   return DllCall("gdiplus\GdipDeletePen", A_PtrSize ? "UPtr" : "UInt", pPen)
}
Gdip_DeleteBrush(pBrush){
   return DllCall("gdiplus\GdipDeleteBrush", A_PtrSize ? "UPtr" : "UInt", pBrush)
}
Gdip_DisposeImage(pBitmap){
   return DllCall("gdiplus\GdipDisposeImage", A_PtrSize ? "UPtr" : "UInt", pBitmap)
}
Gdip_DeleteGraphics(pGraphics){
   return DllCall("gdiplus\GdipDeleteGraphics", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}
Gdip_DisposeImageAttributes(ImageAttr){
    return DllCall("gdiplus\GdipDisposeImageAttributes", A_PtrSize ? "UPtr" : "UInt", ImageAttr)
}
Gdip_DeleteFont(hFont){
   return DllCall("gdiplus\GdipDeleteFont", A_PtrSize ? "UPtr" : "UInt", hFont)
}
Gdip_DeleteStringFormat(hFormat){
   return DllCall("gdiplus\GdipDeleteStringFormat", A_PtrSize ? "UPtr" : "UInt", hFormat)
}
Gdip_DeleteFontFamily(hFamily){
   return DllCall("gdiplus\GdipDeleteFontFamily", A_PtrSize ? "UPtr" : "UInt", hFamily)
}
CreateCompatibleDC(hdc=0){
   return DllCall("CreateCompatibleDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}
SelectObject(hdc, hgdiobj){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("SelectObject", Ptr, hdc, Ptr, hgdiobj)
}
DeleteObject(hObject){
   return DllCall("DeleteObject", A_PtrSize ? "UPtr" : "UInt", hObject)
}
GetDC(hwnd=0){
    return DllCall("GetDC", A_PtrSize ? "UPtr" : "UInt", hwnd)
}
GetDCEx(hwnd, flags=0, hrgnClip=0){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("GetDCEx", Ptr, hwnd, Ptr, hrgnClip, "int", flags)
}
ReleaseDC(hdc, hwnd=0){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("ReleaseDC", Ptr, hwnd, Ptr, hdc)
}
DeleteDC(hdc){
   return DllCall("DeleteDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}
Gdip_SetClipRegion(pGraphics, Region, CombineMode=0){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipSetClipRegion", Ptr, pGraphics, Ptr, Region, "int", CombineMode)
}
CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    hdc2 := hdc ? hdc : GetDC()
    VarSetCapacity(bi, 40, 0)
    NumPut(w, bi, 4, "uint"), NumPut(h, bi, 8, "uint"), NumPut(40, bi, 0, "uint"), NumPut(1, bi, 12, "ushort"), NumPut(0, bi, 16, "uInt"), NumPut(bpp, bi, 14, "ushort")
    hbm := DllCall("CreateDIBSection", Ptr, hdc2, Ptr, &bi, "uint", 0, A_PtrSize ? "UPtr*" : "uint*", ppvBits, Ptr, 0, "uint", 0, Ptr)
    if !hdc
        ReleaseDC(hdc2)
    return hbm
}
Gdip_GraphicsFromImage(pBitmap){
    DllCall("gdiplus\GdipGetImageGraphicsContext", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "UInt*", pGraphics)
    return pGraphics
}
Gdip_GraphicsFromHDC(hdc){
    DllCall("gdiplus\GdipCreateFromHDC", A_PtrSize ? "UPtr" : "UInt", hdc, A_PtrSize ? "UPtr*" : "UInt*", pGraphics)
    return pGraphics
}
Gdip_GetDC(pGraphics){
    DllCall("gdiplus\GdipGetDC", A_PtrSize ? "UPtr" : "UInt", pGraphics, A_PtrSize ? "UPtr*" : "UInt*", hdc)
    return hdc
}
 
 
Gdip_Startup(){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    if !DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
        DllCall("LoadLibrary", "str", "gdiplus")
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
    DllCall("gdiplus\GdiplusStartup", A_PtrSize ? "UPtr*" : "uint*", pToken, Ptr, &si, Ptr, 0)
    return pToken
}
Gdip_TextToGraphics(pGraphics, Text, Options, Font="Arial", Width="", Height="", Measure=0){
    IWidth := Width, IHeight:= Height
    RegExMatch(Options, "i)X([\-\d\.]+)(p*)", xpos)
    RegExMatch(Options, "i)Y([\-\d\.]+)(p*)", ypos)
    RegExMatch(Options, "i)W([\-\d\.]+)(p*)", Width)
    RegExMatch(Options, "i)H([\-\d\.]+)(p*)", Height)
    RegExMatch(Options, "i)C(?!(entre|enter))([a-f\d]+)", Colour)
    RegExMatch(Options, "i)Top|Up|Bottom|Down|vCentre|vCenter", vPos)
    RegExMatch(Options, "i)NoWrap", NoWrap)
    RegExMatch(Options, "i)R(\d)", Rendering)
    RegExMatch(Options, "i)S(\d+)(p*)", Size)
    if !Gdip_DeleteBrush(Gdip_CloneBrush(Colour2))
        PassBrush := 1, pBrush := Colour2
    if !(IWidth && IHeight) && (xpos2 || ypos2 || Width2 || Height2 || Size2)
        return -1
    Style := 0, Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
    Loop, Parse, Styles, |
    {
        if RegExMatch(Options, "\b" A_loopField)
        Style |= (A_LoopField != "StrikeOut") ? (A_Index-1) : 8
    }
    Align := 0, Alignments := "Near|Left|Centre|Center|Far|Right"
    Loop, Parse, Alignments, |
    {
        if RegExMatch(Options, "\b" A_loopField)
            Align |= A_Index//2.1      ; 0|0|1|1|2|2
    }
    xpos := (xpos1 != "") ? xpos2 ? IWidth*(xpos1/100) : xpos1 : 0
    ypos := (ypos1 != "") ? ypos2 ? IHeight*(ypos1/100) : ypos1 : 0
    Width := Width1 ? Width2 ? IWidth*(Width1/100) : Width1 : IWidth
    Height := Height1 ? Height2 ? IHeight*(Height1/100) : Height1 : IHeight
    if !PassBrush
        Colour := "0x" (Colour2 ? Colour2 : "ff000000")
    Rendering := ((Rendering1 >= 0) && (Rendering1 <= 5)) ? Rendering1 : 4
    Size := (Size1 > 0) ? Size2 ? IHeight*(Size1/100) : Size1 : 12
    hFamily := Gdip_FontFamilyCreate(Font)
    hFont := Gdip_FontCreate(hFamily, Size, Style)
    FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000
    hFormat := Gdip_StringFormatCreate(FormatStyle)
    pBrush := PassBrush ? pBrush : Gdip_BrushCreateSolid(Colour)
    if !(hFamily && hFont && hFormat && pBrush && pGraphics)
        return !pGraphics ? -2 : !hFamily ? -3 : !hFont ? -4 : !hFormat ? -5 : !pBrush ? -6 : 0
    CreateRectF(RC, xpos, ypos, Width, Height)
    Gdip_SetStringFormatAlign(hFormat, Align)
    Gdip_SetTextRenderingHint(pGraphics, Rendering)
    ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
    if vPos
    {
        StringSplit, ReturnRC, ReturnRC, |
        if (vPos = "vCentre") || (vPos = "vCenter")
            ypos += (Height-ReturnRC4)//2
        else if (vPos = "Top") || (vPos = "Up")
            ypos := 0
        else if (vPos = "Bottom") || (vPos = "Down")
            ypos := Height-ReturnRC4
        CreateRectF(RC, xpos, ypos, Width, ReturnRC4)
        ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
    }
    if !Measure
        E := Gdip_DrawString(pGraphics, Text, hFont, hFormat, pBrush, RC)
    if !PassBrush
        Gdip_DeleteBrush(pBrush)
    Gdip_DeleteStringFormat(hFormat)
    Gdip_DeleteFont(hFont)
    Gdip_DeleteFontFamily(hFamily)
    return E ? E : ReturnRC
}
Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, ByRef RectF){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    if (!A_IsUnicode)
    {
        nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, 0, "int", 0)
        VarSetCapacity(wString, nSize*2)
        DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, &wString, "int", nSize)
    }
    return DllCall("gdiplus\GdipDrawString", Ptr, pGraphics, Ptr, A_IsUnicode ? &sString : &wString, "int", -1, Ptr, hFont, Ptr, &RectF, Ptr, hFormat, Ptr, pBrush)
}
Gdip_CreateLineBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode=1){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    CreatePointF(PointF1, x1, y1), CreatePointF(PointF2, x2, y2)
    DllCall("gdiplus\GdipCreateLineBrush", Ptr, &PointF1, Ptr, &PointF2, "Uint", ARGB1, "Uint", ARGB2, "int", WrapMode, A_PtrSize ? "UPtr*" : "UInt*", LGpBrush)
    return LGpBrush
}
Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode=1, WrapMode=1){
    CreateRectF(RectF, x, y, w, h)
    DllCall("gdiplus\GdipCreateLineBrushFromRect", A_PtrSize ? "UPtr" : "UInt", &RectF, "int", ARGB1, "int", ARGB2, "int", LinearGradientMode, "int", WrapMode, A_PtrSize ? "UPtr*" : "UInt*", LGpBrush)
    return LGpBrush
}
Gdip_CloneBrush(pBrush){
    DllCall("gdiplus\GdipCloneBrush", A_PtrSize ? "UPtr" : "UInt", pBrush, A_PtrSize ? "UPtr*" : "UInt*", pBrushClone)
    return pBrushClone
}
Gdip_FontFamilyCreate(Font){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    if (!A_IsUnicode)
    {
        nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, "uint", 0, "int", 0)
        VarSetCapacity(wFont, nSize*2)
        DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, Ptr, &wFont, "int", nSize)
    }
    DllCall("gdiplus\GdipCreateFontFamilyFromName", Ptr, A_IsUnicode ? &Font : &wFont, "uint", 0, A_PtrSize ? "UPtr*" : "UInt*", hFamily)
    return hFamily
}
Gdip_SetStringFormatAlign(hFormat, Align){
   return DllCall("gdiplus\GdipSetStringFormatAlign", A_PtrSize ? "UPtr" : "UInt", hFormat, "int", Align)
}
Gdip_StringFormatCreate(Format=0, Lang=0){
   DllCall("gdiplus\GdipCreateStringFormat", "int", Format, "int", Lang, A_PtrSize ? "UPtr*" : "UInt*", hFormat)
   return hFormat
}
Gdip_FontCreate(hFamily, Size, Style=0){
   DllCall("gdiplus\GdipCreateFont", A_PtrSize ? "UPtr" : "UInt", hFamily, "float", Size, "int", Style, "int", 0, A_PtrSize ? "UPtr*" : "UInt*", hFont)
   return hFont
}
Gdip_CreatePen(ARGB, w){
   DllCall("gdiplus\GdipCreatePen1", "UInt", ARGB, "float", w, "int", 2, A_PtrSize ? "UPtr*" : "UInt*", pPen)
   return pPen
}
Gdip_CreatePenFromBrush(pBrush, w){
    DllCall("gdiplus\GdipCreatePen2", A_PtrSize ? "UPtr" : "UInt", pBrush, "float", w, "int", 2, A_PtrSize ? "UPtr*" : "UInt*", pPen)
    return pPen
}
Gdip_BrushCreateSolid(ARGB=0xff000000){
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, A_PtrSize ? "UPtr*" : "UInt*", pBrush)
    return pBrush
}
Gdip_BrushCreateHatch(ARGBfront, ARGBback, HatchStyle=0){
    DllCall("gdiplus\GdipCreateHatchBrush", "int", HatchStyle, "UInt", ARGBfront, "UInt", ARGBback, A_PtrSize ? "UPtr*" : "UInt*", pBrush)
    return pBrush
}
CreateRectF(ByRef RectF, x, y, w, h){
   VarSetCapacity(RectF, 16)
   NumPut(x, RectF, 0, "float"), NumPut(y, RectF, 4, "float"), NumPut(w, RectF, 8, "float"), NumPut(h, RectF, 12, "float")
}
Gdip_SetTextRenderingHint(pGraphics, RenderingHint){
    return DllCall("gdiplus\GdipSetTextRenderingHint", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", RenderingHint)
}
Gdip_MeasureString(pGraphics, sString, hFont, hFormat, ByRef RectF){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    VarSetCapacity(RC, 16)
    if !A_IsUnicode
    {
        nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, "uint", 0, "int", 0)
        VarSetCapacity(wString, nSize*2)
        DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, &wString, "int", nSize)
    }
    DllCall("gdiplus\GdipMeasureString", Ptr, pGraphics, Ptr, A_IsUnicode ? &sString : &wString, "int", -1, Ptr, hFont, Ptr, &RectF, Ptr, hFormat, Ptr, &RC, "uint*", Chars, "uint*", Lines)
    return &RC ? NumGet(RC, 0, "float") "|" NumGet(RC, 4, "float") "|" NumGet(RC, 8, "float") "|" NumGet(RC, 12, "float") "|" Chars "|" Lines : 0
}
CreateRect(ByRef Rect, x, y, w, h){
    VarSetCapacity(Rect, 16)
    NumPut(x, Rect, 0, "uint"), NumPut(y, Rect, 4, "uint"), NumPut(w, Rect, 8, "uint"), NumPut(h, Rect, 12, "uint")
}
CreateSizeF(ByRef SizeF, w, h){
   VarSetCapacity(SizeF, 8)
   NumPut(w, SizeF, 0, "float"), NumPut(h, SizeF, 4, "float")
}
CreatePointF(ByRef PointF, x, y){
   VarSetCapacity(PointF, 8)
   NumPut(x, PointF, 0, "float"), NumPut(y, PointF, 4, "float")
}
Gdip_DrawArc(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipDrawArc", Ptr, pGraphics, Ptr, pPen, "float", x, "float", y, "float", w, "float", h, "float", StartAngle, "float", SweepAngle)
}
Gdip_DrawPie(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipDrawPie", Ptr, pGraphics, Ptr, pPen, "float", x, "float", y, "float", w, "float", h, "float", StartAngle, "float", SweepAngle)
}
Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipDrawLine", Ptr, pGraphics, Ptr, pPen, "float", x1, "float", y1, "float", x2, "float", y2)
}
Gdip_DrawLines(pGraphics, pPen, Points){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    StringSplit, Points, Points, |
    VarSetCapacity(PointF, 8*Points0)
    Loop, %Points0%
    {
        StringSplit, Coord, Points%A_Index%, `,
        NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
    }
    return DllCall("gdiplus\GdipDrawLines", Ptr, pGraphics, Ptr, pPen, Ptr, &PointF, "int", Points0)
}
Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipFillRectangle", Ptr, pGraphics, Ptr, pBrush, "float", x, "float", y, "float", w, "float", h)
}
Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r){
    Region := Gdip_GetClipRegion(pGraphics)
    Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
    Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
    Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
    Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
    E := Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
    Gdip_SetClipRegion(pGraphics, Region, 0)
    Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
    Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
    Gdip_FillEllipse(pGraphics, pBrush, x, y, 2*r, 2*r)
    Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y, 2*r, 2*r)
    Gdip_FillEllipse(pGraphics, pBrush, x, y+h-(2*r), 2*r, 2*r)
    Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
    Gdip_SetClipRegion(pGraphics, Region, 0)
    Gdip_DeleteRegion(Region)
    return E
}
Gdip_GetClipRegion(pGraphics){
    Region := Gdip_CreateRegion()
    DllCall("gdiplus\GdipGetClip", A_PtrSize ? "UPtr" : "UInt", pGraphics, "UInt*", Region)
    return Region
}
Gdip_SetClipRect(pGraphics, x, y, w, h, CombineMode=0){
   return DllCall("gdiplus\GdipSetClipRect",  A_PtrSize ? "UPtr" : "UInt", pGraphics, "float", x, "float", y, "float", w, "float", h, "int", CombineMode)
}
Gdip_SetClipPath(pGraphics, Path, CombineMode=0){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipSetClipPath", Ptr, pGraphics, Ptr, Path, "int", CombineMode)
}
Gdip_ResetClip(pGraphics){
   return DllCall("gdiplus\GdipResetClip", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}
Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipFillEllipse", Ptr, pGraphics, Ptr, pBrush, "float", x, "float", y, "float", w, "float", h)
}
Gdip_FillRegion(pGraphics, pBrush, Region){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipFillRegion", Ptr, pGraphics, Ptr, pBrush, Ptr, Region)
}
Gdip_FillPath(pGraphics, pBrush, Path){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipFillPath", Ptr, pGraphics, Ptr, pBrush, Ptr, Path)
}
Gdip_CreateRegion(){
    DllCall("gdiplus\GdipCreateRegion", "UInt*", Region)
    return Region
}
Gdip_DeleteRegion(Region){
    return DllCall("gdiplus\GdipDeleteRegion", A_PtrSize ? "UPtr" : "UInt", Region)
}
Gdip_CreateBitmap(Width, Height, Format=0x26200A){
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", 0, "int", Format, A_PtrSize ? "UPtr" : "UInt", 0, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
    Return pBitmap
}
Gdip_SetSmoothingMode(pGraphics, SmoothingMode){
   return DllCall("gdiplus\GdipSetSmoothingMode", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", SmoothingMode)
}
Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipDrawRectangle", Ptr, pGraphics, Ptr, pPen, "float", x, "float", y, "float", w, "float", h)
}
Gdip_DrawRoundedRectangle(pGraphics, pPen, x, y, w, h, r){
    Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
    Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
    Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
    Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
    E := Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
    Gdip_ResetClip(pGraphics)
    Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
    Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
    Gdip_DrawEllipse(pGraphics, pPen, x, y, 2*r, 2*r)
    Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y, 2*r, 2*r)
    Gdip_DrawEllipse(pGraphics, pPen, x, y+h-(2*r), 2*r, 2*r)
    Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
    Gdip_ResetClip(pGraphics)
    return E
}
Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    return DllCall("gdiplus\GdipDrawEllipse", Ptr, pGraphics, Ptr, pPen, "float", x, "float", y, "float", w, "float", h)
}
Gdip_CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff){
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "uint*", hbm, "int", Background)
    return hbm
}
SetImage(hwnd, hBitmap){
    SendMessage, 0x172, 0x0, hBitmap,, ahk_id %hwnd%
    E := ErrorLevel
    DeleteObject(E)
    return E
}
Gdip_FillPolygon(pGraphics, pBrush, Points, FillMode=0){
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    StringSplit, Points, Points, |
    VarSetCapacity(PointF, 8*Points0)
    Loop, %Points0%
    {
        StringSplit, Coord, Points%A_Index%, `,
        NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
    }
    return DllCall("gdiplus\GdipFillPolygon", Ptr, pGraphics, Ptr, pBrush, Ptr, &PointF, "int", Points0, "int", FillMode)
}

logtxt("Создание главного окна...")
Gui, -Caption +hwndmainwid
Gui, Show, x0 y0 NA, % " "
WinSet, TransParent, 0, ahk_id %mainwid%

Gui, -MinimizeBox +Caption
Gui, Color, White
Gui, Add, Progress, x-12 y-11 w500 h50 +c486a8d vHeaderColor, 100
Gui, Font, S13 CDefault, % fontname
Gui, Add, Text, x7 y5 w450 h30 +BackgroundTrans +Center +cWhite vHeaderText, % title
Gui, Show, w469 h375 Center, % title

logtxt("Показ анимации плавного появления главного окна...")
; Анимация появления окна
t = 0 ; transparent
loop {
	if t > 265
		break
	
	sleep 1
	WinSet, Transparent, % t, ahk_id %mainwid%
	t+=10
}

checkConfig:
gui, anim1:destroy
Gui, anim1:-caption +hwndanim1wid +parent1 +AlwaysOnTop
Gui, anim1:Color, White
Gui, anim1:Show, x0 y0 w469 h375, % title
WinSet, Transparent, 0, ahk_id %anim1wid%

logtxt("Обработка конфига...")

if ((token == "ERROR") || (trim(token) == "")) {
	MsgBox, 16, % title, Вставьте токен в исходный код программы (на 6 строке в кавычки).
	exitapp
}

logtxt("Показываем главное окно.")
Gui, anim1:Font, S15 CDefault bold , Segoe UI
Gui, anim1:Add, Text, x12 y69 w440 h30 +Center, Добро пожаловать в VK Sharp!
Gui, anim1:Font, S10 CDefault norm , Segoe UI
Gui, anim1:Add, Text, x12 y105 w440 +Center, С помощью этой программы Вы или Ваш друг сможет управлять Вашим компьютером.
Gui, anim1:Font, S9 CDefault , Segoe UI
Gui, anim1:Add, Link, x135 y349 h20 +cGray, Created by <a href="http://vk.com/strdev">Streleckiy Development</a>
Button.Push(New HB_Flat_Rounded_Button_Type_1(x:=132 , y := 309 , w := 190 , h := 30, Button_Color := "FFFFFF" , Button_Background_Color := "486A8D" , Text := "Далее" , Font := "Segoe UI" , Font_Size := "13", Font_Color_Top := "FFFFFF" , Font_Color_Bottom := "486A8D" , Window := "anim1" , Label := "checkAuth" , Default_Button := 1, Roundness:=0 ))

logtxt("Показ анимации плавного появления anim1...")
; Анимация anim1 
t = 0

loop {
	if t > 250
		break
	
	t+=10
	sleep 1
	WinSet, Transparent, % t, ahk_id %anim1wid%
}

logtxt("Анимация завершена.")
kwd = 0

loop {
	IfWinNotActive, ahk_id %mainwid%
		continue
	
	if (GetKeyState("Enter", "D")) {
		if (kwd == 1)
			break
		
		goto checkAuth
	}
}
return

checkAuth:
kwd = 1
ToolTip, Пожалуйста`, подождите...
logtxt("Токен обнаружен. Проверяем его актуальность...")
vk_api("users.get", token)
ToolTip
	
; vk_api() бы не пустил, если бы был не актуален =)

logtxt("Показ анимации сдвига влево anim1...")
anim1_x = 0
loop {
	anim1_x := anim1_x-20
	Gui, anim1:Show, % "x" anim1_x " y0 NA", % title
	sleep 1
	
	if anim1_x < -202
		break
}

logtxt("Анимация завершена.")
Gui, anim1:destroy

Gui, anim1:-caption +hwndanim1wid +parent1 +AlwaysOnTop
Gui, anim1:Color, White
Gui, anim1:Show, x0 y0 w469 h375, % title

WinSet, Transparent, 0, ahk_id %anim1wid%

Gui, anim1:Font, S14 CDefault bold, %fontname%
Gui, anim1:Add, Text, x7 y74 w450 h30 +Center, Укажите ссылку на страницу оператора VK
Gui, anim1:Font, S13 CDefault norm, % fontname
Gui, anim1:Add, Edit, x27 y114 w420 h25 +Center vOperatorVK, 
Gui, anim1:Font, S9 CDefault, % fontname
Gui, anim1:Add, Text, x27 y154 w420 h40 +Center +cGray vWhoOperator, Оператор получит полный доступ к Вашему компьютеру.
Button.Push(New HB_Flat_Rounded_Button_Type_1(x := 127 , y := 299 , w := 200 , h := 30, Button_Color := "FFFFFF" , Button_Background_Color := "486A8D" , Text := "Подключить" , Font := "Segoe UI" , Font_Size := "13", Font_Color_Top := "FFFFFF" , Font_Color_Bottom := "486A8D" , Window := "anim1" , Label := "Connect" , Default_Button := 1, Roundness:=0 ))
settimer, whoOperator, 500
	
ControlFocus, Edit1, ahk_id %anim1wid%

sleep 100

logtxt("Показ анимации плавного появления anim1...")
; Анимация anim1 
t = 0

loop {
	if t > 250
		break
	
	t+=10
	sleep 1
	WinSet, Transparent, % t, ahk_id %anim1wid%
}

logtxt("Анимация завершена.")

settimer, checkenterop, 1
return

checkenterop:
IfWinNotActive, ahk_id %mainwid%
	return

if (kwd == 2) {
	settimer, checkEnterOP, off
	return
}

if (GetKeyState("Enter", "P")) {
	gosub connect
	KeyWait, Enter, U
}
return

GuiClose:
logtxt("Завершение работы программы по просьбе пользователя: закрытие главного окна.")

logtxt("Показ анимации плавного затухания главного окна...")
; Анимация появления окна
t = 265 ; transparent
loop {
	if t < -15
		break
	
	sleep 1
	WinSet, Transparent, % t, ahk_id %mainwid%
	t-=15
}

logtxt("Анимация завершена.")

ExitApp
return

whoOperator:
gui, anim1:submit, nohide

GuiControlGet, whoOperator, anim1:, OperatorVK

if (whoOperator != owhoOperator) {
	owhoOperator := whoOperator
	checkOperator := whoOperator
	StringReplace, checkOperator, checkOperator, https://,
	StringReplace, checkOperator, checkOperator, http://,
	StringReplace, checkOperator, checkOperator, m.vk.com/,
	StringReplace, checkOperator, checkOperator, vk.com/,
	
	ignore_vkerrors = 1
	first_name := "", last_name := "", operatorID := ""
	vk_api("users.get&user_ids=" checkOperator "&fields=screen_name,photo_400_orig", token)
	try first_name := api.response.0.first_name
	try last_name := api.response.0.last_name
	try OperatorID := api.response.0.id
	try OperatorAVA := api.response.0.photo_400_orig
	
	if (trim(first_name) != "") {
		GuiControl, anim1:, whoOperator, %first_name% %last_name% получит полный доступ к Вашему компьютеру.
	}
	else {
		GuiControl, anim1:, whoOperator, Оператор получит полный доступ к Вашему компьютеру.
	}
}
return

Connect:
Gui, +OwnDialogs
GuiControlGet, whoOperator, anim1:, OperatorVK

if (trim(whoOperator) = "") {
	MsgBox, 16, % title, Укажите ссылку на оператора.
	return
}

if (trim(OperatorID) = "") {
	MsgBox, 16, % title, Укажите действительную ссылку на оператора.
	return
}

GuiControl, anim1:disable, OperatorVK
sleep 600

GuiControlGet, whoOperator, anim1:, OperatorVK

kwd = 2

logtxt("Показ анимации сдвига влево anim1...")
anim1_x = 0
loop {
	anim1_x := anim1_x-20
	Gui, anim1:Show, % "x" anim1_x " y0 NA", % title
	sleep 1
	
	if anim1_x < -202
		break
}

logtxt("Анимация завершена.")
Gui, anim1:destroy
Gui, anim2:destroy
sleep 100

Gui, anim2:-caption +hwndanim2wid +parent1 +AlwaysOnTop
Gui, anim2:Color, White
Gui, anim2:Show, x0 y0 w469 h375, % title

WinSet, Transparent, 0, ahk_id %anim2wid%

ToolTip, Пожалуйста`, подождите...
settimer, whoOperator, off

logtxt("Скачивание файла opava.jpg по URL: " operatorAVA)
URLDownloadToFile, % OperatorAVA, opava.jpg

ToolTip

Gui, 1:+MinimizeBox
Gui, 1:Add, Picture, x-1 y-1 w475 h380, opava.jpg
Gui, 1:Add, Picture, x-1 y-1 w475 h380 +BackgroundTrans, dark_layer.png
Gui, 1:Font, S12 CWhite, Segoe UI
Gui, 1:Add, Text, x12 y89 w450 h30 +Center +BackgroundTrans, Соединение с ВКонтакте установлено.
Gui, 1:Font, S9 CWhite, Segoe UI
Gui, 1:Add, Text, x12 y119 w450 h20 +Center +BackgroundTrans, %first_name% %last_name% имеет полный доступ к Вашему компьютеру
Gui, 1:Font, S9 CWhite underline, Segoe UI
Gui, Add, Text, x9 y339 w440 h20 +Center +BackgroundTrans gTrayHide, Скрыть в трее
Gui, 1:Font, S9 CWhite norm, Segoe UI

GuiControl, 1:, HeaderText, % title
GuiControl, 1:hide, HeaderColor
GuiControl, 1:hide, HeaderText
Gui, 1:Font, S12 CDefault, % fontname
Gui, 1:Add, Text, x7 y10 w450 h30 +BackgroundTrans +Center +cWhite, VK Sharp
Gui, 1:Hide
Gui, 1:Show

random, random_id, 1, 100000

started = 1
reply("%26#128373; Владелец машины '" A_UserName ":" A_ComputerName "' дал Вам доступ к управлению его ПК. Используйте /help для просмотра списка команд.")

settimer, control_vk, 400

cmd_list =
(
/winget - получить информацию о текущем окне.
/screen [<x>, <y>, <w>, <h>] - получить скриншот (если нужно определенный участок, то указывайте доп. аргументы) (например, /screen 100, 200, 500, 500).
/type <текст> - имитация печатания текста (если Вам нужно вызвать служ. клавиши, то впишите ее имя в "{" "}" (например, {Enter}).
/typem <текст> - аналогично, как и /type, но печать максимально быстрая.
/run <путь> - запустить программу по пути (с поддержкой аргументов).
/runbg <путь> - запустить программу в фоновом процессе.
/download <url>, <путь> - скачать файл по прямой ссылке и сохранить по указанному пути.
/mousemove <x>, <y> - передвинуть мышь по X и Y координате.
/renux <команда> - выполнить команду в Renux Shell.
)
return

control_vk:
vk_api("messages.getHistory&user_id=" OperatorID "&count=1", token)

try text_to_processs := api.response.items.0.text
catch e {
	logtxt("WARNING: не удалось получить текст последнего сообщения: " e.Message)
}

try this_msg_id := api.response.items.0.id
catch e {
	logtxt("WARNING: не удалось получить ID последнего сообщения: " e.Message)
}

if (this_msg_id > last_id_msg) {
	loop, parse, text_to_processs, `r`n
	{
		text_to_process := A_LoopField
		StringLower, text_to_process_low, text_to_process
		
		if (text_to_process_low = "/help") {
			reply("%26#128373; VK Sharp v" version "`nЕсли Вам нужно выполнить сразу несколько команд друг за другом, то просто пишите каждую на новой строке.`n`n" cmd_list)
			continue
		}
		
		if (text_to_process_low = "/winget") {
			WinGetActiveTitle, win_info_title
			WinGetActiveStats, A, win_info_w, win_info_h, win_info_x, win_info_y
			WinGetClass, win_info_class, A
			
			reply("%26#128373; Заголовок: " win_info_title "`nПозиция (W: " win_info_w "; H: " win_info_h "; X: " win_info_x "; Y: " win_info_y "`nКласс: " win_info_class)
			continue
		}
		
		if (text_to_process_low = "/screen") {
			SaveScreenshotToFile(0, 0, A_ScreenWidth, A_ScreenHeight, A_WorkingDir "\screen.png")
			reply("%26#128373; Пожалуйста, подождите. Обычно это занимает до 5 секунд.")
			
			vk_api("photos.getMessagesUploadServer&version=5.130", token)
			upload_url := api.response.upload_url
			
			file_path := A_WorkingDir "\screen.png"
			objParam := {photo: [file_path]}
			
			CreateFormData(PostData, hdr_ContentType, objParam)
			HTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			HTTP.Open("POST", upload_url, true)
			HTTP.SetRequestHeader("Content-Type", hdr_ContentType)
			HTTP.Send(PostData)
			HTTP.WaitForResponse()
			Response := HTTP.ResponseText
			RegexMatch(HTTP.responsetext, "\{""server"":(.+?),""photo"":""(.+?)"",""hash"":""(.+?)""", match)
			match2 := StrReplace(match2, "\""", """")
			
			vk_api("photos.saveMessagesPhoto&server=" match1 "&photo=" match2 "&hash=" match3 "&v=5.103", token)
			attachment := "photo" api.response.0.owner_id "_" api.response.0.id
			
			vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Скриншот успешно загружен. Держите.&attachment=" attachment "&message_id=" last_id_msg, token)
			FileDelete, % A_WorkingDir "\screen.png"
			continue
		}
		
		StringLeft, text_to_process_low_left, text_to_process_low, 8
		if (text_to_process_low_left = "/screen ") {
			RegExMatch(text_to_process, "i)/screen (.*),(.*),(.*),(.*)", outpos) 
			xpos := trim(outpos1)
			ypos := trim(outpos2)
			wpos := trim(outpos3)
			hpos := trim(outpos4)
			
			if xpos is not integer
			{
				reply("%26#128373; Эта функция принимает в аргументах только целые числа.")
				return
			}
			
			if ypos is not integer
			{
				reply("%26#128373; Эта функция принимает в аргументах только целые числа.")
				return
			}
			
			if wpos is not integer
			{
				reply("%26#128373; Эта функция принимает в аргументах только целые числа.")
				return
			}
			
			if hpos is not integer
			{
				reply("%26#128373; Эта функция принимает в аргументах только целые числа.")
				return
			}
			
			if ((wpos < 100) || (hpos < 100)) {
				reply("%26#128373; W и H координаты не могут быть меньше 100. Это сделано чтобы не было ошибок с отправкой скриншота.")
				return
			}
			
			SaveScreenshotToFile(xpos, ypos, wpos, hpos, A_WorkingDir "\screen.png")
			reply("%26#128373; Пожалуйста, подождите. Обычно это занимает до 5 секунд.")
			
			vk_api("photos.getMessagesUploadServer&version=5.130", token)
			upload_url := api.response.upload_url
			
			file_path := A_WorkingDir "\screen.png"
			objParam := {photo: [file_path]}
			
			CreateFormData(PostData, hdr_ContentType, objParam)
			HTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			HTTP.Open("POST", upload_url, true)
			HTTP.SetRequestHeader("Content-Type", hdr_ContentType)
			HTTP.Send(PostData)
			HTTP.WaitForResponse()
			Response := HTTP.ResponseText
			RegexMatch(HTTP.responsetext, "\{""server"":(.+?),""photo"":""(.+?)"",""hash"":""(.+?)""", match)
			match2 := StrReplace(match2, "\""", """")
		
			vk_api("photos.saveMessagesPhoto&server=" match1 "&photo=" match2 "&hash=" match3 "&v=5.103", token)
		
			attachment := "photo" api.response.0.owner_id "_" api.response.0.id
			
			vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Скриншот успешно загружен. Держите.&attachment=" attachment "&message_id=" last_id_msg, token)
			FileDelete, % A_WorkingDir "\screen.png"
			continue
		}
		
		StringLeft, text_to_process_low_left, text_to_process_low, 6
		if (text_to_process_low_left = "/type ") {
			RegExMatch(text_to_process, "i)\/type (.*)", out)
			if (trim(out1) != "")
			{
				Send, % StrReplace(StrReplace(StrReplace(StrReplace(out1, "#", "{#}"), "+", "{+}") "^", "{^}"), "!", "{!}")
				reply("%26#128373; Операция выполнена.")
				continue
			}
		}

		StringLeft, text_to_process_low_left, text_to_process_low, 7
		if (text_to_process_low_left = "/typem ") {
			RegExMatch(text_to_process, "i)\/typem (.*)", out)
			if (trim(out1) != "")
			{
				SendInput, % StrReplace(StrReplace(StrReplace(StrReplace(out1, "#", "{#}"), "+", "{+}") "^", "{^}"), "!", "{!}")
				reply("%26#128373; Операция выполнена.")
				continue
			}
		}
		
		StringLeft, text_to_process_low_left, text_to_process_low, 5
		if (text_to_process_low_left = "/run ") {
			RegExMatch(text_to_process, "i)\/run (.*)", out)
			if (trim(out1) != "")
			{
				try Run, % out1,, UseErrorLevel, PID
				if ErrorLevel
				{
					reply("%26#128373; Не удалось выполнить задачу. Убедитесь, что правильно указали путь к файлу.")
				}
				
				reply("%26#128373; Процесс успешно запущен. ID процесса: " PID ".")
				continue
			}
		}

		StringLeft, text_to_process_low_left, text_to_process_low, 7
		if (text_to_process_low_left = "/runbg ") {
			RegExMatch(text_to_process, "i)\/runbg (.*)", out)
			if (trim(out1) != "")
			{
				try Run, % out1,, UseErrorLevel Hide, PID
				if ErrorLevel
				{
					reply("%26#128373; Не удалось выполнить задачу. Убедитесь, что правильно указали путь к файлу.")
				}
				
				reply("%26#128373; Процесс успешно запущен в фоновом режиме. ID процесса: " PID ".")
				continue
			}
		}
		
		StringLeft, text_to_process_low_left, text_to_process_low, 7
		if (text_to_process_low_left = "/runbg ") {
			RegExMatch(text_to_process, "i)\/runbg (.*)", out)
			if (trim(out1) != "")
			{
				try Run, % out1,, UseErrorLevel Hide, PID
				if ErrorLevel
				{
					reply("%26#128373; Не удалось выполнить задачу. Убедитесь, что правильно указали путь к файлу.")
					continue
				}
				
				reply("%26#128373; Процесс успешно запущен в фоновом режиме. ID процесса: " PID ".")
				continue
			}
		}
		
		if (text_to_process_low == "/manualcrash") {
			e := {}
			e.Message	:= "Активировано по мануалу."
			e.What 		:= "MANUAL"
			e.Line 		:= 0
			
			error(e)
		}
	
		StringLeft, text_to_process_low_left, text_to_process_low, 6
		if (text_to_process_low_left = "/renux") {
			RegExMatch(text_to_process, "i)renux (.*)", out)
			if (trim(out1) != "") {
				reply("%26#128373; Пожалуйста, подождите...")
				ifnotexist, %A_AppData%\by.strdev\rshell.exe
				{
					vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Для этого нужно установить Renux Shell!&message_id=" last_id_msg, token)
					continue
				}
				
				sleep 333
				random, rid, 1000000, 9999999
				filedelete, %A_AppData%\by.strdev\script.rs
				filedelete, %A_AppData%\by.strdev\log.txt
				fileappend, звывод %A_AppData%\by.strdev\log.txt`n%out1%, %A_AppData%\by.strdev\script.rs
				
				vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Подождите, команда выполняется...%0A%0AПосле выполнения команды, это сообщение изменится и будет содержать лог выполнения команды (если он имеется).&message_id=" last_id_msg, token)
				
				Run, cmd.exe /c %A_AppData%\by.strdev\rshell.exe "%A_AppData%\by.strdev\script.rs",, UseErrorLevel Hide, PID
				if errorlevel
					return
				
				settimer, control_vk, off
				time = 0
				loop {
					sleep 500
					time+=1
					process, exist, % PID
					if (errorlevel != PID)
						break
					
					if (time > 60) {
						process, close, rshell.exe
						break
					}
					
					if (time == 20)
						vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Подождите, команда выполняется...%0A%0ARenux Shell долго не отвечает. Через 20 секунд Renux Shell будет автоматически закрыт.&message_id=" last_id_msg, token)
					
					if (time == 40)
						vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Подождите, команда выполняется...%0A%0ARenux Shell долго не отвечает. Через 10 секунд Renux Shell будет автоматически закрыт.&message_id=" last_id_msg, token)
				}
				
				fileread, renres, %A_AppData%\by.strdev\log.txt
				filedelete, %A_AppData%\by.strdev\script.rs
				
				renres := "`n`n" renres
				StringReplace, renres, renres, `%, `%25, All
				StringReplace, renres, renres, `&, `%26, All
				StringReplace, renres, renres, `n, `%0A, All
				
				if (time > 60) {
					r := vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Превышено время ожидания Renux Shell (ожидалось 30 секунд). Лог: " renres "&message_id=" last_id_msg, token)
					
					if (trim(r) == "") {
						vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Превышено время ожидания Renux Shell (ожидалось 30 секунд). Лог отобразить не получится, так как он слишком большой.&message_id=" last_id_msg, token)
						settimer, control_vk, on
						continue
					}
					
					if r contains error
					{
						vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Превышено время ожидания Renux Shell (ожидалось 30 секунд). Лог отобразить не получится, так как он слишком большой.&message_id=" last_id_msg, token)
					}
					
					settimer, control_vk, on
					continue
				}
				
				r := vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Команда выполнена успешно." renres "&message_id=" last_id_msg, token)
				if (trim(r) == "") {
					vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Команда выполнена успешно, но лог отобразить не получится, так как он слишком большой.&message_id=" last_id_msg, token)
					settimer, control_vk, on
					continue
				}
				
				if r contains error
				{
					vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Команда выполнена успешно, но лог отобразить не получится, так как он слишком большой.&message_id=" last_id_msg, token)
				}
				
				settimer, control_vk, on
				continue
			}
		}
			
		StringLeft, text_to_process_low_left, text_to_process_low, 10
		if (text_to_process_low_left = "/download ") {
			RegExMatch(text_to_process, "i)\/download (.*),(.*)", out)
			if ((trim(out1) = "") || (trim(out2) = "")) {
				reply("%26#128373; Ошибка: какой-то из аргументов не указан.")
				return
			}
			
			reply("%26#128373; Предварительный размер файла: " round(GetFileSizeFromInternet(out1)/1024) " кб. Начинаю скачивание и сохранение в файл: '" out2 "'...")
			FileDelete, % trim(out2)
			URLDownloadToFile, % trim(out1), % trim(out2)
			ifexist, % out2
			{
				vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Файл успешно скачан и сохранен по пути: '" out2 "'.&message_id=" last_id_msg, token)
			}
			else {
				vk_api("messages.edit&v=5.95&peer_id=" OperatorID "&message=%26#128373; Не удалось сохранить файл по пути: '" out2 "'.&message_id=" last_id_msg, token)
			}
			return
		}
		
		StringLeft, text_to_process_low_left, text_to_process_low, 11
		if (text_to_process_low_left = "/mousemove ") {
			RegExMatch(text_to_process, "i)\/mousemove (.*),(.*)", out)
			if ((trim(out1) = "") || (trim(out2) = "")) {
				reply("%26#128373; Ошибка: какой-то из аргументов не указан.")
				return
			}
			
			xpos := trim(out1)
			ypos := trim(out2)
			
			if xpos is not integer
			{
				reply("%26#128373; Эта функция принимает в аргументах только целые числа.")
				return
			}
			
			if ypos is not integer
			{
				reply("%26#128373; Эта функция принимает в аргументах только целые числа.")
				return
			}
			
			MouseMove, % xpos, % ypos
			reply("%26#128373; Операция выполнена.")
			return
		}

		reply("%26#128373; Команда '" text_to_process "' не распознана.")
	}
}
return

TrayHide:
Menu, Tray, NoStandard
Menu, Tray, DeleteAll
Menu, Tray, Add, Показать окно, TrayShow
Menu, Tray, Add, Выход из программы, exitapp
Menu, Tray, Default, Показать окно
Menu, Tray, Tip, % title
Menu, Tray, Click, 1
Menu, Tray, Icon

Gui, 1:Hide
return

TrayShow:
Gui, 1:Show
Menu, Tray, NoIcon
return

exitapp:
exitapp