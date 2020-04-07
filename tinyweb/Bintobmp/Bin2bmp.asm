format PE GUI 4.0
entry start

include '%fasminc%\win32a.inc'
include '%fasminc%\macro\if.inc'

DIB_RGB_COLORS=0

section '.data' data readable writeable

pBitmap		FILE 'Fish.bmp'
caption		db 'Bitmap from memory',0
class		db 'BitmapClass',0

mainhwnd	dd ?
hinstance		dd ?
hBitmap		dd ?
ppvBits		dd ?
msg		MSG
wc		WNDCLASS

section '.code' code readable executable

  start:

	invoke	GetModuleHandle,0
	mov	[hinstance],eax
	invoke	LoadIcon,0,IDI_APPLICATION
	mov	[wc.hIcon],eax
	invoke	LoadCursor,0,IDC_ARROW
	mov	[wc.hCursor],eax
	mov	[wc.style],0
	mov	[wc.lpfnWndProc],WindowProc
	mov	[wc.cbClsExtra],0
	mov	[wc.cbWndExtra],0
	mov	eax,[hinstance]
	mov	[wc.hInstance],eax
	mov	[wc.hbrBackground],COLOR_WINDOW+1
	mov	[wc.lpszMenuName],0
	mov	[wc.lpszClassName],class
	invoke	RegisterClass,wc

	invoke	CreateWindowEx,0,class,caption,WS_VISIBLE+WS_DLGFRAME+WS_SYSMENU,\
		CW_USEDEFAULT,CW_USEDEFAULT,250,150,NULL,NULL,[hinstance],NULL
	mov	[mainhwnd],eax

  msg_loop:
	invoke	GetMessage,msg,NULL,0,0
	or	eax,eax
	jz	end_loop
	invoke	TranslateMessage,msg
	invoke	DispatchMessage,msg
	jmp	msg_loop

  end_loop:
	invoke	ExitProcess,[msg.wParam]

proc WindowProc, hWnd,uMsg,wParam,lParam
  ps PAINTSTRUCT
  hdc dd ?
  hMemDC dd ?
  enter
   .if [uMsg],e,WM_CREATE
      	lea	eax,[pBitmap+14] ; start of BITMAPINFOHEADER header
      	invoke	CreateDIBSection,0,eax,DIB_RGB_COLORS,ppvBits,0,0
      	mov	[hBitmap],eax
      	lea	eax,[pBitmap+54] ; + sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER)
      	stdcall	MemCopy,eax,[ppvBits],30854-54 ; copy bitmap's bit values

   .elseif [uMsg],e,WM_PAINT
      	lea	eax,[ps]
      	invoke	BeginPaint,[hWnd],eax
      	mov	[hdc],eax
      	invoke	CreateCompatibleDC,eax
      	mov	[hMemDC],eax
      	invoke	SelectObject,eax,[hBitmap]
      	invoke	BitBlt,[hdc],0,0,102,100,[hMemDC],0,0,SRCCOPY
      	invoke	DeleteDC,[hMemDC]
      	lea	eax,[ps]
      	invoke	EndPaint,[hWnd],eax

   .elseif [uMsg],e,WM_DESTROY
      	invoke	DeleteObject,[hBitmap]
      	invoke	PostQuitMessage,NULL

   .else
      	invoke	DefWindowProc,[hWnd],[uMsg],[wParam],[lParam]		
      	return

   .endif
	xor	eax,eax
	return
endp

proc MemCopy,Source,Dest,ln   ; procedure from masm32 library

	cld
	mov esi, [Source]
	mov edi, [Dest]
	mov ecx, [ln]
	shr ecx, 2
	rep movsd
	mov ecx, [ln]
	and ecx, 3
	rep movsb
	return
endp

section '.idata' import data readable writeable

  library kernel32,'kernel32.dll',\
          user32,'user32.dll',\
          gdi32,'gdi32.dll'

  import kernel32,\
         ExitProcess,'ExitProcess',\
         GetModuleHandle,'GetModuleHandleA'

  import user32,\
         BeginPaint,'BeginPaint',\
         CreateWindowEx,'CreateWindowExA',\
         DefWindowProc,'DefWindowProcA',\
         DispatchMessage,'DispatchMessageA',\
         EndPaint,'EndPaint',\
         GetMessage,'GetMessageA',\
         LoadCursor,'LoadCursorA',\
         LoadIcon,'LoadIconA',\
         PostQuitMessage,'PostQuitMessage',\
         RegisterClass,'RegisterClassA',\
         TranslateMessage,'TranslateMessage'

  import gdi32,\
         BitBlt,'BitBlt',\
         CreateCompatibleDC,'CreateCompatibleDC',\
         CreateDIBSection,'CreateDIBSection',\
         DeleteDC,'DeleteDC',\
         DeleteObject,'DeleteObject',\
         SelectObject,'SelectObject'
