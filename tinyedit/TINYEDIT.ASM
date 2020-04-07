; Studies for MenuetOS Tiny IDE
;	File: Source Editor
;	Home: as.modshack.co.uk
;--- REVISIONS ---
; ver. 0.0.1 - 19.02.2004 - pelaillo:
;	First working version
;.
;--- INSTRUCTIONS ---
; Please address comments and improvements
; on board.flatassembler.net
;.


format PE DLL GUI 4.0
entry DLLEntryPoint

include 'inc\win32a.inc'

struct TE_DISPLAY
	color_bg	dd 0
	color_text	dd 0
	font		dd 0
ends

struct TE_THEME
	plain		TE_DISPLAY
	select	TE_DISPLAY
	hwnd		dd 0
	margin	dd 0
	text		dd 0
ends

proc DLLEntryPoint,hInstDLL,fdwReason,lpvReserved
	cmp	[fdwReason],DLL_PROCESS_ATTACH
	jne	.done
	push	[hInstDLL]
	pop	[wc.hInstance]
	call	CreateFont,0,0,0,0,0,FALSE,FALSE,FALSE,ANSI_CHARSET,\
		OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,\
		FIXED_PITCH+FF_DONTCARE,NULL
	or	eax,eax
	jz	.failed
	mov	[sample.plain.font],eax
	mov	[sample.select.font],eax
	call	LoadCursor,0,IDC_IBEAM
	mov	[wc.hCursor],eax
	call	RegisterClassEx,wc
	or	eax,eax
	je	.failed
    .done:
	mov	eax,TRUE
	ret
    .failed:
	mov	eax,FALSE
	ret
endp

align 4
sample	TE_THEME
wc	WNDCLASSEX sizeof.WNDCLASSEX,\
	CS_PARENTDC+CS_GLOBALCLASS+CS_HREDRAW+CS_VREDRAW,\
	EditorProc,0,4,NULL,NULL,NULL,\
	COLOR_BTNFACE+1,NULL,_edit_class,NULL
_edit_class	db 'TINYEDIT',0
align 4

proc EditorProc,hwnd,wmsg,wparam,lparam
	locals
	  editor_screen dd ?
	  screen_width dd ?
	  screen_height dd ?
	
	  first_line dd ?
	  window_line dd ?
	  window_position dd ?
	  window_line_number dd ?
	
	  background_brush dd ?
	  font_height dd ?
	  editor dd ?
	  ps	PAINTSTRUCT
	  pt	POINT
	  rc	RECT
	  tm	TEXTMETRIC
	  sc	SCROLLINFO
	endl
	push	ebx esi edi ebp
	mov	eax,[wmsg]
	cmp	eax,WM_PAINT
	je	.wmpaint
;	cmp	eax,WM_HSCROLL
;	je	.wmhscroll
;	cmp	eax,WM_VSCROLL
;	je	.wmvscroll
	cmp	eax,WM_KEYDOWN
	je	.wmkeydown
	cmp	eax,WM_LBUTTONDOWN
	je	.wmlbuttondown
;	cmp	eax,WM_MOUSEWHEEL
;	je	.wmmousewheel
	cmp	eax,WM_SETFOCUS
	je	.wmsetfocus
	cmp	eax,WM_KILLFOCUS
	je	.wmkillfocus
	cmp	eax,WM_DESTROY
	je	.wmdestroy
	cmp	eax,WM_CREATE
	je	.wmcreate
.defwndproc:
	call	DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
	jmp	.finish
.wmcreate:
	mov	eax,[hwnd]
	mov	[sample.hwnd],eax
	call	SetWindowLong,eax,GWL_USERDATA,sample
	mov	[sample.text],_edit_class
	call	GetSysColor,COLOR_WINDOW
	mov	[sample.plain.color_bg],eax
	call	GetSysColor,COLOR_WINDOWTEXT
	mov	[sample.plain.color_text],eax
	call	GetSysColor,COLOR_HIGHLIGHT
	mov	[sample.select.color_bg],eax
	call	GetSysColor,COLOR_HIGHLIGHTTEXT
	mov	[sample.select.color_text],eax
	mov	[sample.margin],16
	jmp	.finish
.wmpaint:
	call	GetWindowLong,[hwnd],GWL_USERDATA
	or	eax,eax
	jz	.defwndproc
	mov	[editor],eax
	lea	eax,[ps]
	call	BeginPaint,[hwnd],eax
	mov	ebx,eax
	mov	esi,[editor]
	call	CreateSolidBrush,[esi+TE_THEME.plain.color_bg]
	mov	[background_brush],eax
	lea	eax,[ps.rcPaint]
	call	FillRect,ebx,eax,[background_brush]
;	call	SelectObject,ebx,[esi+TE_THEME.plain.font]
	call	SetBkColor,ebx,[esi+TE_THEME.plain.color_bg]
	call	SetTextColor,ebx,[esi+TE_THEME.plain.color_text]
;;;       mov     eax,[.font_width]
;;;       mul     ecx
;;;       add     eax,[.ps.rcPaint.left]
;;;       mov     [.ps.rcPaint.right],eax
	call	SetTextAlign,ebx,TA_UPDATECP
	lea	eax,[rc]
	call	GetClientRect,[hwnd],eax
	mov	eax,[esi+TE_THEME.margin]
	push	[rc.left] [rc.top]
	pop	[pt.y] [pt.x]
	add	[pt.x],eax
;;;       lea edx,[ps.rcPaint]
	mov edi,[esi+TE_THEME.text]
	call MoveToEx,ebx,[pt.x],[pt.y],NULL
	call TextOut,ebx,0,0,edi,4
;  .paint_line:
;	lodsb
;	or al,al
;	je .paint_line
;	cmp al,1Ah
;	jne .paint_ready
;	lodsb
;	movzx edi,al
;	add [pt.x],8
;	lea eax,[pt]
;	call MoveToEx,ebx,[pt.x],[pt.y],eax
;	call TextOut,ebx,0,0,esi,edi
;;       lea edx,[.rc]
;;       api DrawText,ebx,esi,edi,edx,DT_LEFT+DT_NOPREFIX+DT_SINGLELINE+DT_NOCLIP
;	add esi,edi
;	cmp byte [esi],0
;	jne .paint_line
;  .line_ready:
;	add [rc.top],18;eax
;	lea eax,[pt]
;	call MoveToEx,ebx,[rc.left],[rc.top],eax
;	jmp .paint_line
  .paint_ready:
	call	DeleteObject,[background_brush]
	lea eax,[ps]
	call EndPaint,[hwnd],eax
	xor	eax,eax
	jmp	.finish
.wmlbuttondown:
;	xor	eax,eax
;	mov	ax,word [lparam]
;	shr eax,3
;	shl eax,3
;	mov [pt.x],eax
;	mov ax,word [lparam+2]
;	shr eax,4
;	shl eax,4
;	mov [pt.y],eax
	jmp .moved_caret
.wmkeydown:
;	lea eax,[pt]
;	call GetCaretPos,eax
;	mov	eax,[wparam]
;	cmp	eax,VK_LEFT
;	je	.left
;	cmp	eax,VK_RIGHT
;	je	.right
;	cmp	eax,VK_UP
;	je	.up
;	cmp	eax,VK_DOWN
;	je	.down
	jmp	.ignore
  .left:
	cmp	[pt.x],8
	je	.ignore
	sub	[pt.x],8
	jmp	.moved_caret
  .right:
	cmp	[pt.x],100h
	je	.ignore
	add	[pt.x],8
	jmp	.moved_caret
  .up:
	cmp	[pt.y],0
	je	.ignore
	sub	[pt.y],16
	jmp	.moved_caret
  .down:
	cmp	[pt.y],100h
	je	.ignore
	add	[pt.y],16
	jmp	.moved_caret
.wmsetfocus:
;	call CreateCaret,[hwnd],NULL,2,16
;;       add [.pt.x],[esi+AG_EDITOR.margin]
;;       lea eax,[.pt]
;;       api SetCaretPos,[.pt.x],[.pt.y]
;	call SetCaretPos,16,0
;	call ShowCaret,[hwnd]
	jmp	.finish
.wmkillfocus:
	call DestroyCaret
	jmp	.finish
.wmhscroll:
;	mov	[sc.cbSize],sizeof.SCROLLINFO
;	mov	[sc.fMask],SIF_PAGE
;	lea eax,[sc]
;	call GetScrollInfo,[hwnd],SB_HORZ,eax
;	movzx eax,word [wparam]
;	cmp	eax,SB_LINEUP
;	je	.hscroll_left
;	cmp	eax,SB_LINEDOWN
;	je	.hscroll_right
;	cmp	eax,SB_THUMBTRACK
;	je	.hscroll_pos
;	cmp	eax,SB_PAGEUP
;	je	.hscroll_wleft
;	cmp	eax,SB_PAGEDOWN
;	je	.hscroll_wright
;    .hscroll_ignore:
;	jmp	.done
;    .hscroll_left:
;	cmp	[window_position],0
;	je	.hscroll_ignore
;	dec	[window_position]
;	jmp	.moved_window
;    .hscroll_right:
;	mov	eax,100h
;	sub	eax,[sc.nPage]
;	cmp	[window_position],eax
;	jge	.hscroll_ignore
;	inc	[window_position]
;	jmp	.moved_window
;    .hscroll_pos:
;	movzx	eax,word [wparam+2]
;	mov	[window_position],eax
;	jmp	.moved_window
;    .hscroll_wleft:
;	mov	eax,[sc.nPage]
;	sub	[window_position],eax
;	jnc	.moved_window
;	mov	[window_position],0
;	jmp	.moved_window
;    .hscroll_wright:
;	mov	eax,[sc.nPage]
;	mov	ecx,100h
;	sub	ecx,eax
;	add	[window_position],eax
;	cmp	[window_position],ecx
;	jbe	.moved_window
;	mov	[window_position],ecx
;	jmp	.moved_window
;.wmvscroll:
;	mov	[sc.cbSize],sizeof.SCROLLINFO
;	mov	[sc.fMask],SIF_ALL
;	lea eax,[.sc]
;	call	GetScrollInfo,[hwnd],SB_VERT,eax
;	movzx	eax,word [wparam]
;	cmp	eax,SB_LINEUP
;	je	.vscroll_up
;	cmp	eax,SB_LINEDOWN
;	je	.vscroll_down
;	cmp	eax,SB_THUMBTRACK
;	je	.vscroll_pos
;	cmp	eax,SB_PAGEUP
;	je	.vscroll_pageup
;	cmp	eax,SB_PAGEDOWN
;	je	.vscroll_pagedown
;    .vscroll_ignore:
;	jmp	.done
;    .vscroll_up:
;	mov	esi,[window_line]
;	mov	esi,[esi+4]
;	or	esi,esi
;	jz	.vscroll_ignore
;	dec	[window_line_number]
;	mov	[window_line],esi
;	jmp	.moved_window
;    .vscroll_down:
;	mov	eax,[sc.nPos]
;	add	eax,[sc.nPage]
;	cmp	eax,[sc.nMax]
;	ja	.vscroll_ignore
;	mov	esi,[window_line]
;	mov	esi,[esi]
;	or	esi,esi
;	jz	.vscroll_ignore
;	inc	[window_line_number]
;	mov	[window_line],esi
;	jmp	.moved_window
;    .vscroll_pos:
;	mov	eax,[sc.nTrackPos]
;	call .find_line
;	or	esi,esi
;	jz	.vscroll_ignore
;	mov	[window_line],esi
;	mov	[window_line_number],ecx
;	jmp	.moved_window
;    .vscroll_pageup:
;	mov	esi,[window_line]
;	mov	ecx,[sc.nPage]
;    .scroll_up:
;	mov	eax,[esi+4]
;	or	eax,eax
;	jz	.scroll_ok
;	dec	[window_line_number]
;	mov	esi,eax
;	loop	.scroll_up
;	jmp	.scroll_ok
;    .vscroll_pagedown:
;	mov	esi,[window_line]
;	mov	eax,[sc.nPos]
;	add	eax,[sc.nPage]
;	mov	ecx,[sc.nMax]
;	sub	ecx,eax
;	inc	ecx
;	cmp	ecx,[sc.nPage]
;	jbe	.scroll_down
;	mov	ecx,[sc.nPage]
;    .scroll_down:
;	mov	eax,[esi]
;	or	eax,eax
;	jz	.scroll_ok
;	inc	[window_line_number]
;	mov	esi,eax
;	loop .scroll_down
;    .scroll_ok:
;	mov	[window_line],esi
;	jmp	.moved_window
;.wmmousewheel:
;	mov	esi,[window_line]
;	mov	eax,[wparam]
;	sar	eax,16
;	cdq
;	mov	ecx,120
;	idiv	ecx
;	imul	eax,3;[wheel_scroll_lines]
;	mov	ecx,eax
;	cmp	ecx,0
;	jg	.scroll_up
;	neg	ecx
;	jnz	.scroll_down
	jmp	.done
.wmdestroy:
;       api     GlobalFree,[.editor_screen]
;       call    .release_editor_memory
;       api     SetWindowLong,[hwnd],GWL_USERDATA,0
	call	PostQuitMessage,0
	xor	eax,eax
	jmp	.finish
.moved_caret:
	call SetCaretPos,[pt.x],[pt.y]
.moved_window:
.done:
.ignore:
	call	ShowCaret,[hwnd]
	xor eax,eax
.finish:
	pop	ebp edi esi ebx
	ret
;.find_line:
;	mov	esi,[first_line]
;	mov	ecx,1
;	mov	edx,[window_line_number]
;	cmp	eax,edx
;	jae	.forward_from_window
;	sub	edx,eax
;	cmp	edx,eax
;	jb	.backward_from_window
;	jmp	.find_forward
;    .forward_from_window:
;	mov	esi,[window_line]
;	mov	ecx,edx
;    .find_forward:
;	cmp	ecx,eax
;	je	.line_found
;	cmp	[esi],dword 0
;	je	.line_found
;	inc	ecx
;	mov	esi,[esi]
;	jmp	.find_forward
;    .backward_from_window:
;	mov	esi,[window_line]
;	mov	ecx,[window_line_number]
;    .find_backward:
;	cmp	ecx,eax
;	je	.line_found
;	cmp	[esi+4],dword 0
;	je	.line_found
;	dec	ecx
;	mov	esi,[esi+4]
;	jmp	.find_backward
;    .line_found:
;	ret
endp

data import

library kernel,'KERNEL32.DLL',\
	user,'USER32.DLL',\
	gdi,'GDI32.DLL'

  import kernel,\
	CloseHandle,'CloseHandle',\
	CreateFile,'CreateFileA',\
	CreateProcess,'CreateProcessA',\
	CreateThread,'CreateThread',\
	ExitProcess,'ExitProcess',\
	ExitThread,'ExitThread',\
	FlushFileBuffers,'FlushFileBuffers',\
	GetCommandLine,'GetCommandLineA',\
	GetEnvironmentVariable,'GetEnvironmentVariableA',\
	GetExitCodeThread,'GetExitCodeThread',\
	GetFileSize,'GetFileSize',\
	GetFullPathName,'GetFullPathNameA',\
	GetModuleHandle,'GetModuleHandleA',\
	GetPrivateProfileString,'GetPrivateProfileStringA',\
	GetSystemTime,'GetSystemTime',\
	GetTickCount,'GetTickCount',\
	GlobalAlloc,'GlobalAlloc',\
	GlobalFree,'GlobalFree',\
	GlobalLock,'GlobalLock',\
	GlobalReAlloc,'GlobalReAlloc',\
	GlobalUnlock,'GlobalUnlock',\
	LoadLibrary,'LoadLibraryA',\
	ReadFile,'ReadFile',\
	SetCurrentDirectory,'SetCurrentDirectoryA',\
	SetEnvironmentVariable,'SetEnvironmentVariableA',\
	SetFilePointer,'SetFilePointer',\
	SetStdHandle, 'SetStdHandle', \
	SetThreadPriority,'SetThreadPriority',\
	TerminateProcess,'TerminateProcess',\
	TerminateThread,'TerminateThread',\
	VirtualAlloc,'VirtualAlloc',\
	VirtualFree,'VirtualFree',\
	WaitForSingleObject,'WaitForSingleObject',\
	WriteFile,'WriteFile',\
	WritePrivateProfileString,'WritePrivateProfileStringA'

  import user,\
	BeginPaint,'BeginPaint',\
	CharLower,'CharLowerA',\
	CheckDlgButton,'CheckDlgButton',\
	CheckMenuItem,'CheckMenuItem',\
	CloseClipboard,'CloseClipboard',\
	CreateCaret,'CreateCaret',\
	CreateWindowEx,'CreateWindowExA',\
	DefWindowProc,'DefWindowProcA',\
	DestroyCaret,'DestroyCaret',\
	DestroyWindow,'DestroyWindow',\
	DialogBoxParam,'DialogBoxParamA',\
	DispatchMessage,'DispatchMessageA',\
	DrawText,'DrawTextA',\
	EmptyClipboard,'EmptyClipboard',\
	EnableMenuItem,'EnableMenuItem',\
	EnableWindow,'EnableWindow',\
	EndDialog,'EndDialog',\
	EndPaint,'EndPaint',\
	FillRect,'FillRect',\
	GetClientRect,'GetClientRect',\
	GetClipboardData,'GetClipboardData',\
	GetCursorPos,'GetCursorPos',\
	GetDC,'GetDC',\
	GetDlgItem,'GetDlgItem',\
	GetDlgItemInt,'GetDlgItemInt',\
	GetDlgItemText,'GetDlgItemTextA',\
	GetKeyboardState,'GetKeyboardState',\
	GetMessage,'GetMessageA',\
	GetScrollInfo,'GetScrollInfo',\
	GetSubMenu,'GetSubMenu',\
	GetSysColor,'GetSysColor',\
	GetSystemMetrics,'GetSystemMetrics',\
	GetUpdateRect,'GetUpdateRect',\
	GetWindowLong,'GetWindowLongA',\
	GetWindowPlacement,'GetWindowPlacement',\
	GetWindowRect,'GetWindowRect',\
	HideCaret,'HideCaret',\
	InvalidateRect,'InvalidateRect',\
	IsClipboardFormatAvailable,'IsClipboardFormatAvailable',\
	IsDlgButtonChecked,'IsDlgButtonChecked',\
	LoadAccelerators,'LoadAcceleratorsA',\
	LoadBitmap,'LoadBitmapA',\
	LoadCursor,'LoadCursorA',\
	LoadIcon,'LoadIconA',\
	LoadMenu,'LoadMenuA',\
	MessageBox,'MessageBoxA',\
	MoveWindow,'MoveWindow',\
	OpenClipboard,'OpenClipboard',\
	PostMessage,'PostMessageA',\
	PostQuitMessage,'PostQuitMessage',\
	RegisterClassEx,'RegisterClassExA',\
	ReleaseCapture,'ReleaseCapture',\
	ReleaseDC,'ReleaseDC',\
	SendDlgItemMessage,'SendDlgItemMessageA',\
	SendMessage,'SendMessageA',\
	SetCapture,'SetCapture',\
	SetCaretPos,'SetCaretPos',\
	SetClipboardData,'SetClipboardData',\
	SetDlgItemText,'SetDlgItemTextA',\
	SetFocus,'SetFocus',\
	SetScrollInfo,'SetScrollInfo',\
	SetWindowLong,'SetWindowLongA',\
	SetWindowPlacement,'SetWindowPlacement',\
	SetWindowPos,'SetWindowPos',\
	SetWindowText,'SetWindowTextA',\
	ShowCaret,'ShowCaret',\
	ShowWindow,'ShowWindow',\
	ToAscii,'ToAscii',\
	TrackPopupMenu,'TrackPopupMenu',\
	TranslateAccelerator,'TranslateAccelerator',\
	TranslateMessage,'TranslateMessage',\
	UpdateWindow,'UpdateWindow',\
	WinHelp,'WinHelpA'

  import gdi,\
	CreateFont,'CreateFontA',\
	CreateSolidBrush,'CreateSolidBrush',\
	DeleteDC,'DeleteDC',\
	DeleteObject,'DeleteObject',\
	GetStockObject,'GetStockObject',\
	GetTextMetrics,'GetTextMetricsA',\
	MoveToEx,'MoveToEx',\
	SelectObject,'SelectObject',\
	SetBkColor,'SetBkColor',\
	SetTextAlign,'SetTextAlign',\
	SetTextColor,'SetTextColor',\
	TextOut,'TextOutA'

end data

data fixups
end data