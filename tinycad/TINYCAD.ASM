; Studies for MenuetOS Tiny CAD
;	File: CAD engine
;	Home: as.modshack.co.uk
;--- REVISIONS ---
; ver. 0.0.1 - 19.02.2004 - pelaillo:
;	First working version
;.
;--- INSTRUCTIONS ---
; Please address comments and improvements
; on board.flatassembler.net
;.

format PE GUI 4.0
entry Start

include 'inc\win32.inc'

;--- CONSTANTS ---

DEBUGGING = 0

APP_ERROR_READ	= 1
APP_ERROR_PARAM	= 2
APP_ERROR_MEM	= 2

;.

section '.code' code readable executable

include 'C:\Datos\Projects\SimCad\fasm.ver\racad.inc'

proc Start
;	call	CommandLine
;	or	eax,eax
;	je	.welcome
;	new	cur_html,HTML_CLASS,eax
;	or	eax,eax
;	je	.error_read
;	objc cur_html,ReadIt
	call	CreateTestground
	or	eax,eax
	je	.error_memory
  .msg_loop:
	call	GetMessage,msg,NULL,0,0
	or	eax,eax
	jz	.terminate
	call	TranslateMessage,msg
	call	DispatchMessage,msg
	jmp	.msg_loop
  .error_read:
;	objc cur_html,Destroy
	call	MessageBox,0,_Error_Read,_title,MB_OK+MB_ICONERROR
	mov	eax,APP_ERROR_READ
	jmp	.terminate
  .error_memory:
;	objc cur_html,Destroy
	call	MessageBox,0,_Error_Mem,_title,MB_OK+MB_ICONERROR
	mov	eax,APP_ERROR_MEM
	jmp	.terminate
  .welcome:
	call	AboutBox,NULL
  .terminate:
	call	ExitProcess,eax
	return
endp

proc CreateTestground
  .wc WNDCLASSEX
	enter
	call	InstallRACad
	call	GetModuleHandle,0
	mov	[hInstance],eax
	mov	[.wc.hInstance],eax
	mov	[.wc.cbSize],WNDCLASSEX.size
	mov	[.wc.style],CS_HREDRAW or CS_VREDRAW
	mov	[.wc.hbrBackground],COLOR_WINDOW
	call	LoadIcon,NULL,IDI_APPLICATION
	mov	[.wc.hIcon],eax
	mov	[.wc.lpfnWndProc],WinProc
	mov	[.wc.lpszClassName],_work
	mov	[.wc.cbClsExtra],NULL
	mov	[.wc.cbWndExtra],4
	mov	[.wc.lpszMenuName],NULL
	mov	[.wc.hIcon],NULL
	mov	[.wc.hIconSm],NULL
	call	LoadCursor,0,IDC_ARROW
	mov	[.wc.hCursor],eax
	lea	eax,[.wc]
	call	RegisterClassEx,eax
	or	eax,eax
	je	.done
	call	CreateWindowEx,0,_work,NULL,\ ;WS_EX_TOPMOST
			WS_POPUP+WS_THICKFRAME+WS_VISIBLE,\
			340,80,326,206,NULL,NULL,[hInstance],NULL
	mov	[hwin_main],eax
  .done:
	return
endp

proc CommandLine
	; returns pointer to filename or 0 if not arguments.
	
	call	GetCommandLine
	mov	esi,cmd_test;eax
	mov	ah,'"'
	lodsb
	or		al,al
	je		.no_arguments
	cmp	al,ah
	je		.pass_quoted_path
	mov	ah,' '
  .pass_quoted_path:
	lodsb
	or		al,al
	je		.no_arguments
	cmp	al,0Dh
	je		.no_arguments
	cmp	al,ah
	jne	.pass_quoted_path
  .find_arguments:
	lodsb
	or		al,al
	je		.no_arguments
	cmp	al,'"'
	je		.get_quoted_arg
	cmp	al,' '
	je		.find_arguments
	mov	ah,' '
	dec	esi
	push	esi
  .get_arg:
	lodsb
	or		al,al
	je		.arg_ready
	cmp	al,ah
	jne	.get_arg
  .arg_ready:
	mov	byte [esi-1],0
	pop	eax
	jmp	.done
  .get_quoted_arg:
	push	esi
	mov	ah,'"'
	jmp	.get_arg
  .no_arguments:
	xor	eax,eax
  .done:
	return
endp

proc AboutBox,hwnd
	enter
	call	MessageBox,NULL,_title,_title,MB_OK
	return
endp

proc WinProc,hwnd,wmsg,wparam,lparam
	.rc RECT
	enter
	push	ebx esi edi
	mov	eax,[wmsg]
;	cmp	eax,WM_PAINT
;	je	.wm_paint
	cmp	eax,WM_KEYDOWN
	je	.wm_keydown
	cmp	eax,WM_RBUTTONDOWN
	je	.wm_rbuttondown
	cmp	eax,WM_LBUTTONDOWN
	je	.wm_lbuttondown
	cmp	eax,WM_DESTROY
	je	.wm_destroy
	cmp	eax,WM_CREATE
	je	.wm_create
  .defwndproc:
	call	DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
	jmp	.finish
  .wm_paint:
	xor	eax,eax
	jmp	.finish
  .wm_create:
;	call	SetWindowLong,[hwnd],GWL_USERDATA,canvas
	call	CreateWindowEx,WS_EX_CLIENTEDGE,CadClass,NULL,\
			WS_CHILD+WS_CLIPCHILDREN+WS_VISIBLE+\
			WS_CLIPSIBLINGS+WS_VSCROLL+WS_HSCROLL,\
			0,16,320,184,[hwnd],NULL,[hInstance],NULL
	mov	[hcad],eax
	xor	eax,eax
	jmp	.finish
  .wm_rbuttondown:
;	lea	ebx,[.rc]
;	call	GetWindowRect,[hwnd],ebx
;	movsx esi,word [lparam]
;	movsx edi,word [lparam+2]
;	add	esi,[.rc.left]
;	add	edi,[.rc.top]
;	call	SetWindowPos,[hmenu],HWND_TOPMOST,esi,edi,\
;		0,0,SWP_SHOWWINDOW+SWP_NOSIZE
	xor	eax,eax
	jmp	.finish
  .wm_lbuttondown:
	call	SendMessage,[hwnd],WM_NCLBUTTONDOWN,HTCAPTION,0
	xor	eax,eax
	jmp	.finish
  .wm_keydown:
	mov	eax,[wparam]
	cmp	eax,VK_RETURN
	je	.vkreturn
	cmp	eax,VK_F1
	je	.vkf1
	cmp	eax,VK_F2
	je	.vkf2
	cmp	eax,VK_F3
	je	.vkf3
	cmp	eax,VK_F4
	je	.vkf4
	cmp	eax,VK_F5
	je	.vkf5
	cmp	eax,VK_F6
	je	.vkf6
	cmp	eax,VK_F7
	je	.vkf7
	cmp	eax,VK_F8
	je	.vkf8
	cmp	eax,VK_ESCAPE
	je	.vkescape
	cmp	eax,VK_HOME
	je	.vkhome
	cmp	eax,VK_PGUP
	je	.vkpgup
	cmp	eax,VK_PGDN
	je	.vkpgdn
	jmp	.finish
  .vkreturn:
	xor	eax,eax
	jmp	.finish
  .vkf1:
	mov	[ncadbox],0
	xor	eax,eax
	jmp	.finish
  .vkf2:
	mov	[ncadbox],1
	xor	eax,eax
	jmp	.finish
  .vkf3:
	mov	[ncadbox],2
	xor	eax,eax
	jmp	.finish
  .vkf4:
	mov	[ncadbox],3
	xor	eax,eax
	jmp	.finish
  .vkf5:
	mov	[ncadbox],4
	xor	eax,eax
	jmp	.finish
  .vkf6:
	mov	[ncadbox],5
	xor	eax,eax
	jmp	.finish
  .vkf7:
	mov	[ncadbox],6
	xor	eax,eax
	jmp	.finish
  .vkf8:
	mov	[ncadbox],7
	xor	eax,eax
	jmp	.finish
  .vkhome:
	call	SendMessage,[hcad],CM_ZOOMFIT,NULL,NULL
	xor	eax,eax
	jmp	.finish
  .vkpgup:
	call	SendMessage,[hcad],CM_ZOOMIN,NULL,NULL
	xor	eax,eax
	jmp	.finish
  .vkpgdn:
	call	SendMessage,[hcad],CM_ZOOMOUT,NULL,NULL
	xor	eax,eax
	jmp	.finish
  .vkescape:
	call	SendMessage,[hwnd],WM_CLOSE,NULL,NULL
	xor	eax,eax
	jmp	.finish
  .wm_destroy:
	call	PostQuitMessage,0
	xor	eax,eax
  .finish:
	pop	edi esi ebx
	return
endp

align 4
_work		db 'TINYCAD',0
_edit		db 'EDIT',0
_title	db 'Testing Ground for Tiny CAD - MenuetOS CAD',0
_main_face	db 'Verdana',0
_Error_Mem	db 'There is not enough memory.',0Dh,0Ah
		db 'Window could not be created.',0
_Error_Read	db 'File not found or read error.',0
cmd_test	db 'this.exe test.cad',0
szToolTip	db 'RACad control',0
szName	db 'IDC_CAD',0
szCap		db 0

section '.data' data readable writeable

szText.size	= 400h
szText	rb szText.size
dimtxt	rb 100h
hInstance	dd ?
hwin_main	dd ?
hcad		dd ?
sel		dd ?
initcreate	dd ?
rpsize	dd ?
ncadbox 	dd ?
hClip		dd ?
msg		MSG
selrect 	RECT
lastpos 	POINT
lastmov 	POINT
mpt		POINT
curpos	POINT
dimobj	OBJECT

section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL',\
	user32,'USER32.DLL',\
	gdi32,'GDI32.DLL'

import kernel32,\
	ExitProcess,'ExitProcess',\
	GetCommandLine,'GetCommandLineA',\
	GetLocaleInfo,'GetLocaleInfoA',\
	GetModuleHandle,'GetModuleHandleA',\
	GetUserDefaultLCID,'GetUserDefaultLCID',\
	GlobalAlloc,'GlobalAlloc',\
	GlobalFree,'GlobalFree',\
	GlobalLock,'GlobalLock',\
	GlobalUnlock,'GlobalUnlock',\
	RtlMoveMemory,'RtlMoveMemory',\
	lstrcpy,'lstrcpy',\
	lstrlen,'lstrlenA'

import user32,\
	BeginPaint,'BeginPaint',\
	CloseClipboard,'CloseClipboard',\
	CopyRect,'CopyRect',\
	CreateWindowEx,'CreateWindowExA',\
	DefWindowProc,'DefWindowProcA',\
	DestroyWindow,'DestroyWindow',\
	DispatchMessage, 'DispatchMessageA', \
	DrawFocusRect,'DrawFocusRect',\
	EmptyClipboard,'EmptyClipboard',\
	EndPaint,'EndPaint',\
	FillRect,'FillRect',\
	GetCapture,'GetCapture',\
	GetClientRect,'GetClientRect',\
	GetClipboardData,'GetClipboardData',\
	GetCursor,'GetCursor',\
	GetCursorPos,'GetCursorPos',\
	GetDC,'GetDC',\
	GetMessage, 'GetMessageA', \
	GetParent,'GetParent',\
	GetScrollInfo,'GetScrollInfo',\
	GetSysColor, 'GetSysColor', \
	GetWindowLong,'GetWindowLongA',\
	GetWindowRect, 'GetWindowRect', \
	InvalidateRect,'InvalidateRect',\
	IsClipboardFormatAvailable,'IsClipboardFormatAvailable',\
	LoadBitmap,'LoadBitmapA',\
	LoadCursor,'LoadCursorA',\
	LoadIcon, 'LoadIconA', \
	MessageBox, 'MessageBoxA', \
	MoveWindow,'MoveWindow',\
	PostQuitMessage, 'PostQuitMessage', \
	OpenClipboard,'OpenClipboard',\
	RegisterClassEx,'RegisterClassExA',\
	RegisterClipboardFormat,'RegisterClipboardFormatA',\
	ReleaseCapture,'ReleaseCapture',\
	ReleaseDC,'ReleaseDC',\
	ScreenToClient,'ScreenToClient',\
	ScrollWindow,'ScrollWindow',\
	SendMessage,'SendMessageA',\
	SetCapture,'SetCapture',\
	SetClipboardData,'SetClipboardData',\
	SetCursor,'SetCursor',\
	SetScrollInfo,'SetScrollInfo',\
	SetWindowLong,'SetWindowLongA',\
	ShowWindow,'ShowWindow',\
	TranslateMessage, 'TranslateMessage', \
	UpdateWindow,'UpdateWindow'

import gdi32,\
	Arc,'Arc',\
	BitBlt,'BitBlt',\
	CreateCompatibleBitmap,'CreateCompatibleBitmap',\
	CreateCompatibleDC,'CreateCompatibleDC',\
	CreatePen,'CreatePen',\
	CreateSolidBrush,'CreateSolidBrush',\
	DeleteDC,'DeleteDC',\
	DeleteObject,'DeleteObject',\
	EndDoc,'EndDoc',\
	EndPage,'EndPage',\
	GetBitmapBits,'GetBitmapBits',\
	GetDeviceCaps,'GetDeviceCaps',\
	GetObject,'GetObjectA',\
	GetStockObject,'GetStockObject',\
	LineTo,'LineTo',\
	MoveToEx,'MoveToEx',\
	SelectObject,'SelectObject',\
	SetPixel,'SetPixel',\
	StartDoc,'StartDocA',\
	StartPage,'StartPage'

;section '.reloc' fixups data discardable
