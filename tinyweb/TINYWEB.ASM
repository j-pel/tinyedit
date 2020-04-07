; Studies for MenuetOS Tiny Browser
;	File: HTML parser Testground
;	Home: as.modshack.co.uk

;--- REVISIONS ---
; ver. 0.0.5 - 15.06.2004 - pelaillo:
;	Rendering. Early approach
; ver. 0.0.4 - 15.04.2004 - pelaillo:
;   Antialiased rendering
;   Backbuffer to avoid flickering
; ver. 0.0.3 - 25.03.2004 - pelaillo:
;	Early OOP approach
;	Parsing improved 
; ver. 0.0.2 - 23.02.2004 - pelaillo:
;	Case insensitivity
;	Tokens instead of sz strings
;	Draft of browser gdi
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

DEBUGGING = 1

APP_ERROR_READ	= 1
APP_ERROR_PARAM	= 2
APP_ERROR_MEM	= 2

section '.code' code readable executable

; MAIN CODE:
; The following is platform independient code

include 'html.inc'

; INTERFACE:
; The following is Win32 specific code

proc Start
	call	CommandLine
	or	eax,eax
	je	.welcome
	new	cur_html,HTML_CLASS,eax
	or	eax,eax
	je	.error_read
	objc	cur_html,ReadIt
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
	objc	cur_html,Destroy
	call	MessageBox,0,_Error_Read,_title,MB_OK+MB_ICONERROR
	mov	eax,APP_ERROR_READ
	jmp	.terminate
  .error_memory:
	objc	cur_html,Destroy
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
	.wc	WNDCLASSEX
	enter
;	call	InitCommonControls
	call	GetModuleHandle,0
	mov	[hInstance],eax
	mov	[.wc.hInstance],eax
	mov	[.wc.cbSize],WNDCLASSEX.size
	mov	[.wc.hbrBackground],COLOR_WINDOW
	mov	[.wc.style],0
	call	LoadIcon,NULL,IDI_APPLICATION
	mov	[.wc.hIcon],eax
	mov	[.wc.hIconSm],NULL
	call	LoadCursor,NULL,IDC_ARROW
	mov	[.wc.hCursor],eax
	mov	[.wc.lpfnWndProc],BrowserProc
	mov	[.wc.cbClsExtra],0
	mov	[.wc.cbWndExtra],0
	mov	[.wc.lpszMenuName],0
	mov	[.wc.lpszClassName],_class
	lea	eax,[.wc]
	call	RegisterClassEx,eax
	or	eax,eax
	je	.done
	call	CreateWindowEx,0,_class,NULL,\ ;WS_EX_TOPMOST
			WS_POPUP+WS_THICKFRAME+WS_VISIBLE,\
			340,80,326,206,NULL,NULL,[hInstance],NULL
	mov	[hbrowser],eax
;	call	CreateWindowEx,0,_tree,NULL,\
;			WS_POPUP+WS_SIZEBOX+WS_VISIBLE+TVS_HASLINES\
;			+TVS_HASBUTTONS+TVS_EDITLABELS+TVS_LINESATROOT\
;			+TVS_DISABLEDRAGDROP+TVS_SHOWSELALWAYS,\
;			20,80,320,320,NULL,NULL,[hInstance],NULL
;	mov	[htree],eax
;	call	SetWindowLong,eax,GWL_WNDPROC,TreeWndProc
;	mov	[OldTreeProc],eax
	call	CreateWindowEx,NULL,_edit,NULL,WS_BORDER+WS_POPUP\
			+ES_AUTOHSCROLL+ES_AUTOVSCROLL+ES_MULTILINE,\
			0,0,200,120,NULL,NULL,[hInstance],NULL
	mov	[hmenu],eax
	call	SetWindowLong,eax,GWL_WNDPROC,MenuWndProc
	mov	[OldMenuProc],eax
  .done:
	return
endp

proc CommandLine
	; returns pointer to filename or 0 if not arguments.
	call	GetCommandLine
	mov	esi,cmd_test;eax
	mov	ah,'"'
	lodsb
	or	al,al
	je	.no_arguments
	cmp	al,ah
	je	.pass_quoted_path
	mov	ah,' '
  .pass_quoted_path:
	lodsb
	or	al,al
	je	.no_arguments
	cmp	al,0Dh
	je	.no_arguments
	cmp	al,ah
	jne	.pass_quoted_path
  .find_arguments:
	lodsb
	or	al,al
	je	.no_arguments
	cmp	al,'"'
	je	.get_quoted_arg
	cmp	al,' '
	je	.find_arguments
	mov	ah,' '
	dec	esi
	mov	edi,esi
  .get_arg:
	lodsb
	or	al,al
	je	.arg_ready
	cmp	al,ah
	jne	.get_arg
  .arg_ready:
;	mov	byte [esi-1],0
	mov	eax,esi
	sub	eax,edi
	dec	eax
	mov	byte [edi-1],al
	mov	eax,edi ; return filename
	jmp	.done
  .get_quoted_arg:
	mov	edi,esi
	mov	ah,'"'
	jmp	.get_arg
  .no_arguments:
	xor	eax,eax
  .done:
	return
endp

proc Alloc,size
	enter
	mov	eax,[next_alloc]
	or	eax,eax
	je	.alloc_it
  .done:
	push	eax
	add	eax,[size]
	mov	[next_alloc],eax
	pop	eax
	return
  .alloc_it:
;	call	VirtualAlloc,NULL,2000h,MEM_COMMIT,PAGE_READWRITE
	mov	eax,temp_alloc
	jmp	.done
endp

proc Free,location
	enter
	call	HeapFree,[hheap],HEAP_NO_SERIALIZE,[location]
;	call	VirtualFree,[ebx+HTML_CLASS.Handle],2000h,MEM_DECOMMIT
	return
endp

proc LoadSource,FileName,FileSize
  ; Returns FileBuffer in eax or zero if error
  ; Provides full compatibility with fasm paths
  ; This proc needs a external buffer:
  ; path_buf rb MAX_SIZE
	enter
	push	esi edi ebx
	mov	esi,[FileName]
	mov	edi,path_buf
  .parse_path:
	lodsb
	cmp	al,'%'
	je	.get_environment_var
	cmp	al,'/'
	jne	.valid_sep
	mov	al,'\'
  .valid_sep:
	stosb
	or	al,al
	jne	.parse_path 
	jmp	.path_done
  .get_environment_var:
	push	MAX_PATH edi esi ; for GetEnvironmentVariable call	
  .var_loop:
	lodsb
	or	al,al
	je	.var_ready
	cmp	al,'%'
	jne	.var_loop
  .var_ready:
	mov	byte [esi-1],0
	call	GetEnvironmentVariable
	add	edi,eax
	jmp	.parse_path
  .path_done:
	call	CreateFile,path_buf,GENERIC_READ,0,NULL,\
			OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	cmp	eax,INVALID_HANDLE_VALUE
	jz	.error_read
	mov	ebx,eax
	call	GetFileSize,ebx,NULL
	or	eax,eax
	jz	.error_read
	mov	edi,eax
	push	eax ; for HeapAlloc
	call	GetProcessHeap
	mov	[hheap],eax
	call	HeapAlloc,eax,HEAP_ZERO_MEMORY
	test	eax,eax
	jz	.error_read
	mov	esi,eax
	call	ReadFile,ebx,esi,edi,io_bytes,NULL
	test	eax,eax
	jz	.error_read
	cmp	edi,[io_bytes]
	jnz	.error_read
	call	CloseHandle,ebx
	mov	eax,[FileSize]
	mov	[eax],edi
	mov	eax,esi
	jmp	.done
  .error_read:
	xor	eax,eax
.done:
	pop	ebx edi esi
	return
endp

proc CopyObject,object,size
	enter
	push	ecx esi edi
	mov	esi,[object]
	mov	edi,[next_obj]
	mov	ecx,[size]
	shr	ecx,2
  .copy_mem:
	lodsd
	stosd
	loop	.copy_mem
	mov	eax,[next_obj]
	mov	[next_obj],edi
	pop	edi esi ecx
	return
	endp

proc BrowserProc,hwnd,wmsg,wparam,lparam
  .rc RECT
  .ps PAINTSTRUCT
  .hdc	dd ?
  .hcdc dd ?
  .hbm	dd ?
  .pen_dark	dd ?
  .pen_light	dd ?
  .background_brush	dd ?

	enter
	push	ebx esi edi
	mov	eax,[wmsg]
	cmp	eax,WM_PAINT
	je	.wm_paint
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
	lea	eax,[.ps]
	call	BeginPaint,[hwnd],eax
	mov	ebx,eax
	lea	eax,[.rc]
	call	GetClientRect,[hwnd],eax
	call	GetWindowLong,[hwnd],GWL_USERDATA
	call	BitBlt,ebx,0,0,320,200,\
		[canvas.ShowDC],0,0,SRCCOPY
	lea	eax,[.ps]
	call	EndPaint,[hwnd],eax
	xor	eax,eax
	jmp	.finish
  .wm_create:
	call	SetWindowLong,[hwnd],GWL_USERDATA,canvas
	lea	eax,[.rc]
	call	GetClientRect,[hwnd],eax
	call	GetDC,[hwnd]
	mov	[.hdc],eax
	call	CreateCompatibleDC,NULL
	mov	ebx,eax
	mov	[canvas.WorkDC],eax
	call	CreateDIBSection,ebx,WorkBmpInfo,DIB_RGB_COLORS,\
		canvas.WorkDIB,NULL,0
	mov	[canvas.WorkBmp],eax
	call	SelectObject,ebx,eax
	call	CreateDIBSection,[.hdc],ShowBmpInfo,DIB_RGB_COLORS,\
		canvas.ShowDIB,NULL,0
	mov	[canvas.ShowBmp],eax
	call	CreateCompatibleDC,NULL
	mov	[canvas.ShowDC],eax
	call	SelectObject,eax,[canvas.ShowBmp]
	call	CreateFont,24,0,0,0,0,FALSE,FALSE,FALSE,\
			ANSI_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,\
			DEFAULT_QUALITY,FIXED_PITCH+FF_DONTCARE,_main_face
	mov	[canvas.MainFont],eax
	call	SelectObject,ebx,eax
	call	GetSysColor,COLOR_WINDOW
	call	CreateSolidBrush,eax
	call	SelectObject,ebx,eax

	call	GetSysColor,COLOR_BTNHIGHLIGHT
	call	CreatePen,PS_SOLID,1,eax
	mov	[.pen_light],eax
	call	GetSysColor,COLOR_BTNSHADOW
	call	CreatePen,PS_SOLID,1,eax
	mov	[.pen_dark],eax
	call	SelectObject,ebx,eax
	mov	[.rc.right],4*BASE_WIDTH
	mov	[.rc.bottom],2*BASE_HEIGHT
	call	Rectangle,ebx,[.rc.left],[.rc.top],\
		[.rc.right],[.rc.bottom]
	call	SelectObject,ebx,[.pen_light]
	dec	[.rc.right]
	dec	[.rc.bottom]
	call	MoveToEx,ebx,[.rc.left],[.rc.bottom],NULL
	call	LineTo,ebx,[.rc.right],[.rc.bottom]
	call	LineTo,ebx,[.rc.right],[.rc.top]
	call	SetBkMode,ebx,TRANSPARENT
	call	TextOut,ebx,5,5,welcome,welcome.size
	call	DeleteObject,[.pen_light]
	call	DeleteObject,[.pen_dark]
	call	DeleteObject,[.background_brush]

	objc	cur_html,Render,[canvas.WorkDC]

	call	Resample,[canvas.WorkDIB],[canvas.ShowDIB],\
		4*BASE_WIDTH,2*BASE_HEIGHT
	call	ReleaseDC,[hwnd],[canvas.WorkDC]
	call	InvalidateRect,[hwnd],NULL,FALSE
	xor	eax,eax
	jmp	.finish
  .wm_rbuttondown:
	lea	ebx,[.rc]
	call	GetWindowRect,[hwnd],ebx
	movsx esi,word [lparam]
	movsx edi,word [lparam+2]
	add	esi,[.rc.left]
	add	edi,[.rc.top]
	call	SetWindowPos,[hmenu],HWND_TOPMOST,esi,edi,\
		0,0,SWP_SHOWWINDOW+SWP_NOSIZE
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
	cmp	eax,VK_ESCAPE
	je	.vkescape
	jmp	.finish
  .vkreturn:
	xor	eax,eax
	jmp	.finish
  .vkf1:
	xor	eax,eax
	jmp	.finish
  .vkf2:
	xor	eax,eax
	jmp	.finish
  .vkf3:
	xor	eax,eax
	jmp	.finish
  .vkf4:
	xor	eax,eax
	jmp	.finish
  .vkescape:
	call	SendMessage,[hwnd],WM_CLOSE,NULL,NULL
	xor	eax, eax
	jmp	.finish
  .wm_destroy:
	call	DeleteObject,[canvas.MainFont]
	call	DeleteObject,[canvas.WorkBmp]
	call	DeleteDC,[canvas.WorkDC]
	call	DeleteObject,[canvas.ShowBmp]
	call	DeleteDC,[canvas.ShowDC]
	call	PostQuitMessage,0
	xor	eax,eax
  .finish:
	pop	edi esi ebx
	return
endp

proc TreeWndProc,hwnd,wmsg,wparam,lparam
  .tvhit	TV_HITTESTINFO
  .rc		RECT
	enter
	push	ebx esi edi
	mov	eax,[wmsg]		; <-- assembles short on each cmp
;	cmp	eax,WM_LBUTTONDOWN
;	je	.wm_lbuttondown
	cmp	eax,WM_RBUTTONDOWN
	je	.wm_rbuttondown
	cmp	eax,WM_LBUTTONDOWN
	je	.wm_lbuttondown
	cmp	eax,WM_LBUTTONDBLCLK
	je	.wm_lbuttondblclk
	cmp	eax,WM_NOTIFY
	je	.wm_notify
;	cmp	eax,WM_GETMINMAXINFO
;	je	.wm_getminmaxinfo
;	cmp	eax,WM_ACTIVATE
;	je	.wm_create
	cmp	eax,WM_DESTROY
	je	.wm_destroy
	cmp	eax,WM_KEYDOWN
	jne	.default
  .wm_keydown:
;--------------------------
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
	cmp	eax,VK_ESCAPE
	jne	.default
  .vkescape:
	call		SendMessage,[hwnd],WM_CLOSE,NULL,NULL
	xor	eax, eax
	jmp	.endwndproc
  .vkreturn:
	xor	eax, eax
	jmp	.endwndproc
  .vkf1:
	xor	eax, eax
	jmp	.endwndproc
  .vkf2:
;	call	MessageBox,NULL,cmd_test,cmd_test,MB_OK
;	call	VirtualAlloc,0,1000h,MEM_COMMIT,PAGE_READWRITE
;	mov	esi,eax
;	mov	[ofn.lpstrFile],buf;esi
;	mov	[ofn.nMaxFile],1000h
;	mov	byte [esi],0
;	mov	[ofn.Flags],OFN_FILEMUSTEXIST+OFN_PATHMUSTEXIST+\
;	OFN_EXPLORER+OFN_HIDEREADONLY+OFN_LONGNAMES
;	call	GetOpenFileName,ofn
	lea	eax,[buffer]
;	call	BrowseForFolder,[hwnd],_title,eax
	call	MessageBox,[hwnd],buffer,_title,MB_OK
	xor	eax,eax
	jmp	.endwndproc
  .vkf3:
;	call	FillTree
;	call	SetWindowText,[hwnd],_title
	xor	eax,eax
	jmp	.endwndproc
  .vkf4:
;	call	SetWindowText,[hwnd],_WndError
	xor	eax,eax
	jmp	.endwndproc
;.
  .wm_create:
;--------------------------
;	call	MessageBox,NULL,cmd_test,cmd_test,MB_OK
	xor	eax,eax
	jmp	.endwndproc
;.
  .wm_rbuttondown:
	lea	ebx,[.rc]
	call	GetWindowRect,[hwnd],ebx
	movsx esi,word [lparam]
	movsx edi,word [lparam+2]
	add	esi,[.rc.left]
	add	edi,[.rc.top]
	call	SetWindowPos,[hmenu],HWND_TOPMOST,esi,edi,\
		0,0,SWP_SHOWWINDOW+SWP_NOSIZE
	xor	eax,eax
	jmp	.endwndproc
  .wm_lbuttondown:
;--------------------------
	; This is for window dragging
	call	SendMessage,[hwnd],WM_NCLBUTTONDOWN,HTCAPTION,0
	jmp	.default
;.-------------------------
  .wm_lbuttondblclk:
;--------------------------
	; This is for item identification
	mov	eax,[lparam]
	xor	ebx,ebx
	mov	bx,ax
	mov	[.tvhit.pt.x],ebx
	shr eax,16
	mov	[.tvhit.pt.y],eax
	lea	edi,[.tvhit]
	call	SendMessage,[htree],TVM_HITTEST,NULL,edi
	or eax,eax
	je	.default
	mov	edi,[.tvhit.flags]
	cmp	edi,TVHT_ONITEMLABEL
	jne	.default

;	mov	edi,[eax+10h] ; undocumented: I don't know why
;	mov	eax,edi
;	inc	eax
;	mov	eax,[edi+XML_TAG.Object]
;	mov	eax,[eax+HTML_BODY.Test_msg]
;	call	MessageBox,NULL,eax,.tit01,MB_OK
	jmp	.default
	.tit01 db 'wm_lbuttondblclk',0
	.msg01 db 'wm_lbuttondown',0
;.-------------------------
  .wm_notify:
;--------------------------
	mov	edx, [lparam]
	mov	eax, [edx+NMHDR.code]
;	cmp	eax, TTN_NEEDTEXT
;	je	.ttn_needtext
	cmp	eax, NM_RDBLCLK
	je	.tvn_selchanged
	cmp	eax, TVN_BEGINLABELEDIT
	je	.tvn_beginlabeledit
	cmp	eax, TVN_BEGINDRAG
	je	.tvn_begindrag
	cmp	eax, TVN_ENDLABELEDIT
	je	.tvn_endlabeledit
	cmp	eax, TVN_ITEMEXPANDED
	je	.tvn_itemexpanded
	cmp	eax, TVN_SELCHANGED
	jne	.default
	.tvn_selchanged:
;		call	SendMessage,[htree],TVM_EXPAND,TVE_EXPAND,\
;		[edx+NM_TREEVIEW.itemNew.hItem]	; expand new
;		call	redraw_images
		jmp	.endwndproc
	.tvn_beginlabeledit:
;		call	SendMessage,[htree], TVM_GETEDITCONTROL,\
;		ebx, ebx
;		mov	[htedit], eax
;		call	SendMessage, eax, EM_SETLIMITTEXT, 127, ebx
		jmp	.endwndproc
	.tvn_endlabeledit:
;		mov	[htedit], ebx
;		call	redraw_images
;		mov	eax, [lparam]
;		cmp	[eax+TV_DISPINFO.item.pszText], ebx
;		je	.not_modified
;		inc	[b_modified]
;	.not_modified:
		mov	eax,1
		jmp	.endwndproc
;	.ttn_needtext:
;		mov	eax, [edx+NMHDR.idFrom]
;		sub eax, IDM_TOOLBAR
;		push	dword [eax*4+lp_tips]
;		pop	dword [edx+TOOLTIPTEXT.lpszText]
;		jmp	.endwndproc
	.tvn_itemexpanded:
;		call	redraw_images
		jmp	.default
	.tvn_begindrag:
;		mov	eax, [edx+NM_TREEVIEW.itemNew.hItem]
;		mov	[h_src], eax
;		call	SendMessage, [htree], TVM_CREATEDRAGIMAGE, ebx, eax
;		mov	[h_dragimagelist],eax
;		call	ImageList_BeginDrag,[h_dragimagelist],ebx,8,8
;		call	ImageList_DragEnter,[htree], [edx+NM_TREEVIEW.ptDrag.x], [edx+NM_TREEVIEW.ptDrag.y]
;		call	SetCapture,esi
;		call	SendMessage,[htree], TVM_SELECTITEM, TVGN_DROPHILITE, [h_src]
;		mov	[b_dragmode],TRUE
		jmp	.endwndproc
;.
  .wm_getminmaxinfo:
	mov	ecx,[lparam]
	mov	[ecx+MINMAXINFO.ptMinTrackSize.x], 500
	mov	[ecx+MINMAXINFO.ptMinTrackSize.y], 380
	jmp	.endwndproc
  .wm_destroy:
	call	PostQuitMessage, 0
	xor	eax, eax
	jmp	.endwndproc
  .default:
	call	CallWindowProc,[OldTreeProc],[hwnd],[wmsg],\
		[wparam],[lparam]
  .endwndproc:
	pop	edi esi ebx
	return
endp

proc MenuWndProc,hwnd,wmsg,wparam,lparam
	enter
	push	ebx esi edi
	mov	eax,[wmsg]		; <-- assembles short on each cmp
	cmp	eax,WM_RBUTTONDOWN
	je	.wm_rbuttondown
	cmp	eax,WM_LBUTTONDOWN
	je	.wm_lbuttondown
	cmp	eax,WM_ACTIVATE
	je	.wm_activate
	cmp	eax,WM_DESTROY
	je	.wm_destroy
	cmp	eax,WM_KEYDOWN
	jne	.default
  .wm_keydown:
;--------------------------
	mov	eax,[wparam]
	cmp	eax,VK_RETURN
	je	.vkreturn
	cmp	eax,VK_ESCAPE
	jne	.default
  .vkescape:
	call		ShowWindow,[hwnd],SW_HIDE
	xor	eax, eax
	jmp	.endwndproc
  .vkreturn:
	xor	eax, eax
	jmp	.endwndproc
  .wm_rbuttondown:
	xor	eax,eax
	jmp	.endwndproc
  .wm_lbuttondown:
	xor	eax,eax
	jmp	.endwndproc
  .wm_activate:
	cmp	word [wparam],WA_INACTIVE
	jne	.default
	call		ShowWindow,[hwnd],SW_HIDE
	jmp	.default
  .wm_destroy:
	call		PostQuitMessage, 0
	xor	eax, eax
	jmp	.endwndproc
  .default:
	call		CallWindowProc,[OldMenuProc],[hwnd],[wmsg],\
		[wparam],[lparam]
  .endwndproc:
	pop	edi esi ebx
	return
endp

proc AboutBox,hwnd
	enter
	call	MessageBox,NULL,_title,_title,MB_OK
	return
endp

proc InsertTreeNode,hParent,hInsertAfter,pToken,lparam
	.tvis TV_INSERTSTRUCT
	enter
	push	ecx edx
	mov	eax,[hParent]
	mov	[.tvis.hParent],eax
	mov	[.tvis.item.lParam],eax
	mov	eax,[hInsertAfter]
	mov	[.tvis.hInsertAfter],eax
	mov	[.tvis.item.imask],TVIF_TEXT+TVIF_PARAM+TVIF_IMAGE+\
	TVIF_SELECTEDIMAGE
	mov	eax,[pToken]
	inc	eax
	mov	[.tvis.item.pszText],eax
	mov	eax,[lparam]
	mov	[.tvis.item.lParam],eax
	mov	[.tvis.item.iImage],eax
	mov	[.tvis.item.iSelectedImage],eax
	lea	eax,[.tvis]
;	call	SendMessage,[htree],TVM_ENSUREVISIBLE,NULL,[hParent]
	call	SendMessage,[htree],TVM_INSERTITEM,NULL,eax
	pop	edx ecx
	return
endp

proc BrowseForFolder,hwnd,lptitle,lpbuffer
	.bi BROWSEINFO
	enter
	mov	eax,[hwnd]
	mov	[.bi.hwndOwner],eax
	mov	eax,[lptitle]
	mov	[.bi.lpszTitle],eax
	mov	[.bi.pszDisplayName],NULL
	mov	[.bi.ulFlags],BIF_RETURNONLYFSDIRS+BIF_DONTGOBELOWDOMAIN
	mov	[.bi.pidlRoot],NULL
	mov	[.bi.lpfn],NULL ; BrowseCallback
	lea	eax,[.bi]
	call	SHBrowseForFolder,eax
	or eax,eax
	je	.canceled
	push	eax ; for CoTaskMemFree
	call	SHGetPathFromIDList,eax,[lpbuffer]
	call	CoTaskMemFree
	mov	eax,TRUE
  .canceled:
	return
	endp

proc BrowseCallback,hwnd,wmsg,wparam,lparam
	enter
	xor	eax,eax
	return
	endp

proc Resample,lpSrc,lpDest,dwWidth,dwHeight
; Procedure written by Thomas
; http://www.madwizard.org
; This snippet rescales bitmap data (32-bits per pixel) into
; a bitmap of half the size. 
; lpSrc is a pointer to the source bitmap data 
; lpDest is a pointer for the output data 
; dwWidth is the width of the source bitmap 
; dwHeight is the height of the source bitmap. 
; It resamples the bitmap which means it calculates one output
; pixel by averaging four input pixels. The algorithm uses MMX,
; the width should be a multiple of 4, height should be a
; multiple of 2.
	enter 
	push	edi esi ebx
	mov	esi, [lpSrc] 
	mov	edi, [lpDest] 
	mov	edx, [dwWidth] 
	shr	edx, 1 
	
	mov	ecx, [dwWidth] 
	
	pxor	MM4, MM4	
	
	mov	ebx, [dwHeight] 
	shr	ebx, 1 
	align 16 
	.nextline: 
	
	mov	edx, ecx 
	shr	edx, 2 
	align 16 
	.nextpixel: 
		movq	MM0, [esi]		; MM0: X2 R2 G2	B2-X1 R1 G1	B1 
		movq	MM1, [esi+8]	; MM1: X4 R4 G4	B4-X3 R3 G3	B3 
		movq	MM2, [esi+4*ecx]	; MM2: X6 R6 G6	B6-X5 R5 G5	B5 
		movq	MM3, [esi+4*ecx+8]	; MM3: X8 R8 G8	B8-X7 R7 G7	B7 
		
		movq	MM5, MM0 
		movq	MM6, MM2 
		
		punpckhbw	MM0, MM4		; MM0: 00 X2 00	R2-00 G2 00	B2 
		punpckhbw	MM2, MM4		; MM2: 00 X6 00	R6-00 B6 00	B6 
		punpcklbw	MM5, MM4		; MM5: 00 X1 00	R1-00 G1 00	B1 
		punpcklbw	MM6, MM4		; MM6: 00 X5 00	R5-00 G5 00	B5 
		
		paddw	MM0, MM2 
		paddw	MM0, MM5 
		paddw	MM0, MM6 
		psrlw	MM0, 2		
		
		; second pixel: 
		
		movq	MM5, MM1 
		movq	MM6, MM3 
		
		punpckhbw	MM1, MM4		; MM1: 00 X4 00	R4-00 G4 00	B4 
		punpckhbw	MM3, MM4		; MM3: 00 X8 00	R8-00 B8 00	B8 
		punpcklbw	MM5, MM4		; MM5: 00 X3 00	R3-00 G3 00	B3 
		punpcklbw	MM6, MM4		; MM6: 00 X7 00	R7-00 G7 00	B7 
		
		paddw	MM1, MM3 
		paddw	MM1, MM5 
		paddw	MM1, MM6 
		psrlw	MM1, 2		
		
		; now:	MM0: 00	XQ 00 RQ-00	GQ 00 BQ ;where	Q is the first mixed pixel 
		; now:	MM1: 00	XP 00 RP-00	GP 00 BP ;where	P is the second	mixed pixel 
		; output should	be:	BQ GQ RQ XQ-BP GP RP XP	(in	mem) 
		;			XP RP GP BP	XQ RQ GQ BQ	(in	reg) 
		
		packuswb	MM0, MM1 
		movq	[edi], MM0 
		
		
		add	esi, 16 
		add	edi, 8 
		dec	edx 
		jnz	.nextpixel	
	
	lea	esi, [esi+4*ecx] 
	dec	ebx 
	jnz	.nextline 
	emms
	pop	ebx esi edi
	return
endp

CSTR	welcome,'MenuetOS Tiny Browser - Under Construction',\
	is_p,'Paragraph',\
	is_table,'Table'

_edit		db 'EDIT',0
_tree		db 'SysTreeView32',0
_class	db 'TinyBrowser',0
_title	db 'Testing Ground for Tiny Page - MenuetOS Browser',0
_main_face	db 'Verdana',0
_Error_Mem	db 'There is not enough memory.',0Dh,0Ah
		db 'Window could not be created.',0
_Error_Read	db 'File not found or read error.',0

section '.data' data readable writeable

temp_alloc	rb 400h
cmd_test	db 'this.exe simple.html',0

align 4
io_bytes	dd ?
hInstance	dd ?
hheap		dd ?
main_font	dd ?
htree		dd ?
hmenu		dd ?
hbrowser	dd ?
OldTreeProc	dd ?
OldMenuProc	dd ?
next_alloc	dd ?

; Objects
cur_html	dd ?
cur_head	dd ?
cur_body	dd ?
dummy_obj	dd ?

msg MSG
;ofn OPENFILENAME
buffer rb MAX_PATH
path_buf rb MAX_PATH

include 'canvas.inc'

section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL',\
	user32,'USER32.DLL',\
	gdi32,'GDI32.DLL',\
	comctl32,'COMCTL32.DLL',\
	shell32,'SHELL32.DLL',\
	ole32,'OLE32.DLL'

import kernel32,\
	CloseHandle,'CloseHandle',\
	CreateFile,'CreateFileA',\
	ExitProcess,'ExitProcess',\
	GetCommandLine,'GetCommandLineA',\
	GetEnvironmentVariable,'GetEnvironmentVariableA',\
	GetFileSize,'GetFileSize',\
	GetModuleHandle,'GetModuleHandleA',\
	GetProcessHeap,'GetProcessHeap',\
	GetStdHandle,'GetStdHandle',\
	HeapAlloc,'HeapAlloc',\
	HeapFree,'HeapFree',\
	LoadLibraryEx,'LoadLibraryExA',\
	ReadFile,'ReadFile',\
	VirtualAlloc,'VirtualAlloc',\
	VirtualFree,'VirtualFree',\
	WriteFile,'WriteFile'
	
  import gdi32,\
	BitBlt,'BitBlt',\
	CreateCompatibleDC,'CreateCompatibleDC',\
	CreateCompatibleBitmap,'CreateCompatibleBitmap',\
	CreateDIBSection,'CreateDIBSection',\
	CreateFont,'CreateFontA',\
	CreatePen,'CreatePen',\
	CreateSolidBrush,'CreateSolidBrush',\
	DeleteDC,'DeleteDC',\
	DeleteObject,'DeleteObject',\
	GetStockObject,'GetStockObject',\
	GetTextMetrics,'GetTextMetricsA',\
	LineTo,'LineTo',\
	MoveToEx,'MoveToEx',\
	Rectangle,'Rectangle',\
	SelectObject,'SelectObject',\
	SetBkColor,'SetBkColor',\
	SetBkMode,'SetBkMode',\
	SetTextColor,'SetTextColor',\
	TextOut,'TextOutA'

import comctl32,\
	CreateStatusWindow, 'CreateStatusWindowA', \
	CreateToolbarEx, 'CreateToolbarEx', \
	InitCommonControls, 'InitCommonControls', \
	ImageList_LoadImage, 'ImageList_LoadImage', \
	ImageList_enterDrag, 'ImageList_enterDrag', \
	ImageList_DragEnter, 'ImageList_DragEnter', \
	ImageList_DragMove, 'ImageList_DragMove', \
	ImageList_DragShowNolock, 'ImageList_DragShowNolock', \
	ImageList_DragLeave, 'ImageList_DragLeave', \
	ImageList_EndDrag, 'ImageList_EndDrag', \
	ImageList_Destroy, 'ImageList_Destroy'

import user32,\
	BeginPaint, 'BeginPaint', \
	CallWindowProc, 'CallWindowProcA', \
	CheckDlgButton, 'CheckDlgButton', \
	CheckRadioButton, 'CheckRadioButton', \
	ClientToScreen, 'ClientToScreen', \
	ClipCursor, 'ClipCursor', \
	CreateWindowEx, 'CreateWindowExA', \
	DefWindowProc, 'DefWindowProcA', \
	DestroyWindow, 'DestroyWindow', \
	DialogBoxParam, 'DialogBoxParamA', \
	DispatchMessage, 'DispatchMessageA', \
	DrawFocusRect, 'DrawFocusRect', \
	EnableMenuItem, 'EnableMenuItem', \
	EnableWindow, 'EnableWindow', \
	EndDialog, 'EndDialog', \
	EndPaint, 'EndPaint', \
	FillRect, 'FillRect', \
	GetClientRect, 'GetClientRect', \
	GetDC, 'GetDC', \
	GetDlgItem, 'GetDlgItem', \
	GetDlgItemText, 'GetDlgItemTextA', \
	GetFocus, 'GetFocus', \
	GetMenu, 'GetMenu', \
	GetMessage, 'GetMessageA', \
	GetSysColor, 'GetSysColor', \
	GetWindowLong, 'GetWindowLongA', \
	GetWindowRect, 'GetWindowRect', \
	InvalidateRect, 'InvalidateRect', \
	IsClipboardFormatAvailable, 'IsClipboardFormatAvailable', \
	IsDlgButtonChecked, 'IsDlgButtonChecked', \
	KillTimer, 'KillTimer', \
	LoadAccelerators, 'LoadAcceleratorsA', \
	LoadCursor, 'LoadCursorA', \
	LoadIcon, 'LoadIconA', \
	LoadImage, 'LoadImageA', \
	LockWindowUpdate, 'LockWindowUpdate', \
	MessageBox, 'MessageBoxA', \
	MoveWindow, 'MoveWindow', \
	PostQuitMessage, 'PostQuitMessage', \
	RegisterClassEx,'RegisterClassExA',\
	ReleaseCapture, 'ReleaseCapture', \
	ReleaseDC, 'ReleaseDC', \
	ScreenToClient, 'ScreenToClient', \
	SendDlgItemMessage, 'SendDlgItemMessageA', \
	SendMessage, 'SendMessageA', \
	SetCapture, 'SetCapture', \
	SetCursor, 'SetCursor', \
	SetDlgItemText, 'SetDlgItemTextA', \
	SetFocus, 'SetFocus', \
	SetTimer, 'SetTimer', \
	SetWindowLong, 'SetWindowLongA', \
	SetWindowPos,'SetWindowPos',\
	SetWindowText, 'SetWindowTextA', \
	ShowWindow, 'ShowWindow', \
	SystemParametersInfo, 'SystemParametersInfoA',\
	TranslateAccelerator, 'TranslateAccelerator', \
	TranslateMessage, 'TranslateMessage', \
	UpdateWindow, 'UpdateWindow'
	
import shell32,\
	SHBrowseForFolder,'SHBrowseForFolder',\
	SHGetPathFromIDList,'SHGetPathFromIDList'

import ole32,\
	CoTaskMemFree,'CoTaskMemFree'

;section '.rsrc' resource from 'text_htm.res' data readable discardable

;section '.reloc' fixups data discardable

