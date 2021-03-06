uglobal
  hMainWindow     dd 0  ; MainWindow handle.
  hIml  dd ?
endg


iglobal
  cClassName db 'MAINCLASS',0
  cMainTitle   db  "FreshGif file test program",0
;  cGifFileName db  "test image.gif",0       ;!!!! The gif filename
endg


;**************************************************
; Creates form for main window.
;**************************************************
proc InitMainWindow, hOwner
.wc WNDCLASS
begin
        xor     ebx, ebx

        mov     [.wc.hIcon],ebx
        invoke  LoadCursor,ebx,IDC_ARROW
        mov     [.wc.hCursor],eax
        mov     [.wc.style],CS_OWNDC
        mov     [.wc.lpfnWndProc], MainWindowProc
        mov     [.wc.cbClsExtra],ebx
        mov     [.wc.cbWndExtra], 32
        mov     eax,[hInstance]
        mov     [.wc.hInstance],eax
        mov     [.wc.hbrBackground],COLOR_BTNFACE+1
        mov     [.wc.lpszMenuName],ebx
        mov     [.wc.lpszClassName],cClassName

        lea     eax, [.wc]
        invoke  RegisterClass, eax

        invoke  CreateWindowEx, 0, cClassName, cMainTitle,              \
                                WS_VISIBLE or WS_OVERLAPPEDWINDOW or WS_SYSMENU,      \
                                0, 0, 320, 240, NULL, NULL, [hInstance], NULL

        mov     [hMainWindow], eax
        return
endp




proc MainWindowProc, hwnd, wmsg, wparam, lparam
.hDC    dd ?
.ps     PAINTSTRUCT
.rect   RECT
.cx     dd ?
.cy     dd ?
begin
        push    esi edi ebx
        mov     ebx, [wmsg]
        call    JumpTo
        MessageList             \
        WM_CREATE, .wmcreate,   \
        WM_PAINT,  .wmpaint,    \
        WM_DESTROY, .wmdestroy, \
        WM_SIZE,    .wmsize

.default:
        invoke  DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
        pop     ebx edi esi
        return

;------ WM_CREATE --------------

.wmcreate:
; Create imagelist object from resource GIF image.
        stdcall ImageList_LoadGif, [hInstance], 801, -1   ; 800 is the ID of the gif resource.
        mov     [hIml], eax

        xor      eax, eax
        pop     ebx edi esi
        return

;----- WM_PAINT ----------------

.wmpaint:
        lea     eax, [.ps]
        invoke  BeginPaint, [hwnd], eax
        mov     [.hDC], eax

; Compute coordinates of the image in the center of the window
        lea     eax, [.rect]
        invoke  GetClientRect, [hwnd], eax

        invoke  MoveToEx, [.hDC], [.rect.left], [.rect.top], NULL
        invoke  LineTo, [.hDC], [.rect.right], [.rect.bottom]
        invoke  MoveToEx, [.hDC], [.rect.left], [.rect.bottom], NULL
        invoke  LineTo, [.hDC], [.rect.right], [.rect.top]

        lea     ecx, [.cx]
        lea     eax, [.cy]
        invoke  ImageList_GetIconSize, [hIml], ecx, eax

        mov     eax, [.rect.right]
        mov     ecx, [.rect.bottom]
        sub     eax, [.cx]
        sub     ecx, [.cy]
        shr     eax, 1
        shr     ecx, 1

; Draw image from image list in the window DC.
        invoke  ImageList_Draw, [hIml], 0, [.hDC], eax, ecx, ILD_NORMAL

        lea     eax, [.ps]
        invoke  EndPaint, [hwnd], eax
        jmp     .qfalse

;------ WM_DESTROY -----------------

.wmdestroy:
        invoke  ImageList_Destroy, [hIml]
        invoke  PostQuitMessage, 0
        jmp     .default

;----- WM_SIZE ---------------------

.wmsize:
        invoke  InvalidateRect, [hwnd], NULL, TRUE

.qfalse:
        xor     eax, eax
        pop     ebx edi esi
        return
endp 