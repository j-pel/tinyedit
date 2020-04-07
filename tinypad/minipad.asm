
; Simple text editor - fasm example program

format PE GUI 4.0
entry start

include 'win32w.inc'
include 'resources.inc'

LOCALE_NAME_MAX_LENGTH = 85
LOCALE_SNAME = 5Ch
LOCALE_NAME_USER_DEFAULT = NULL

LOAD_LIBRARY_AS_DATAFILE       = 02h
LOAD_LIBRARY_AS_IMAGE_RESOURCE = 20h

struct MUI  ; Multilingual User Interface
  hInstance     dd ?
  lpName        du 'MUI_'
  lpLocaleName  rb LOCALE_NAME_MAX_LENGTH
  lpFallback    du 'MUI_en-US',0
ends

section '.text' code readable executable

  start:

        invoke  GetModuleHandle,0
        mov     [wc.hInstance],eax

        invoke  LoadIcon,eax,IDR_ICON
        mov     [wc.hIcon],eax
        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],eax
        invoke  RegisterClass,wc
        test    eax,eax
        jz      error

        invoke  GetUserDefaultLocaleName,mui.lpLocaleName,LOCALE_NAME_MAX_LENGTH
        invoke  LoadLibraryEx,mui.lpName,NULL,LOAD_LIBRARY_AS_DATAFILE+LOAD_LIBRARY_AS_IMAGE_RESOURCE
        test    eax,eax
        jne     ok_library
        mov     edi,mui.lpLocaleName+6
        mov     esi,_wildcard
        mov     ecx,3
        rep     movsd
        invoke  FindFirstFileEx,mui.lpName,0,fd,0,NULL,0
        cmp     eax,INVALID_HANDLE_VALUE
        je      get_alternative_lang
        mov     eax,fd.cFileName
        invoke  LoadLibraryEx,eax,NULL,LOAD_LIBRARY_AS_DATAFILE+LOAD_LIBRARY_AS_IMAGE_RESOURCE
        test    eax,eax
        jne     ok_library
  get_alternative_lang:
        invoke  LoadLibraryEx,mui.lpFallback,NULL,LOAD_LIBRARY_AS_DATAFILE+LOAD_LIBRARY_AS_IMAGE_RESOURCE
        test    eax,eax
        je      error_library_missing
  ok_library:
        mov     [mui.hInstance],eax

        invoke  LoadMenu,[mui.hInstance],IDR_MENU
        invoke  CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_OVERLAPPEDWINDOW,144,128,256,256,NULL,eax,[wc.hInstance],NULL
        test    eax,eax
        jz      error

  msg_loop:
        invoke  GetMessage,msg,NULL,0,0
        cmp     eax,1
        jb      end_loop
        jne     msg_loop
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     msg_loop

  error_library_missing:
        invoke  MessageBox,NULL,_mui_error,_title,MB_ICONERROR+MB_OK
        jmp     end_loop
  error:
        invoke  LoadString,[mui.hInstance],0,buffer1,sizeof.buffer
        invoke  LoadString,[mui.hInstance],3,buffer2,sizeof.buffer
        invoke  MessageBox,NULL,buffer2,buffer1,MB_ICONERROR+MB_OK

  end_loop:
        invoke  ExitProcess,[msg.wParam]

proc WindowProc hwnd,wmsg,wparam,lparam
        push    ebx esi edi
        mov     eax,[wmsg]
        cmp     eax,WM_CREATE
        je      .wmcreate
        cmp     eax,WM_SIZE
        je      .wmsize
        cmp     eax,WM_SETFOCUS
        je      .wmsetfocus
        cmp     eax,WM_COMMAND
        je      .wmcommand
        cmp     eax,WM_DESTROY
        je      .wmdestroy
  .defwndproc:
        invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
        jmp     .finish
  .wmcreate:
        invoke  GetClientRect,[hwnd],client
        invoke  CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+WS_HSCROLL+WS_VSCROLL+ES_AUTOHSCROLL+ES_AUTOVSCROLL+ES_MULTILINE,[client.left],[client.top],[client.right],[client.bottom],[hwnd],0,[wc.hInstance],NULL
        or      eax,eax
        jz      .failed
        mov     [edithwnd],eax
        invoke  CreateFont,16,0,0,0,0,FALSE,FALSE,FALSE,ANSI_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH+FF_DONTCARE,NULL
        or      eax,eax
        jz      .failed
        mov     [editfont],eax
        invoke  SendMessage,[edithwnd],WM_SETFONT,eax,FALSE
        xor     eax,eax
        jmp     .finish
      .failed:
        or      eax,-1
        jmp     .finish
  .wmsize:
        invoke  GetClientRect,[hwnd],client
        invoke  MoveWindow,[edithwnd],[client.left],[client.top],[client.right],[client.bottom],TRUE
        xor     eax,eax
        jmp     .finish
  .wmsetfocus:
        invoke  SetFocus,[edithwnd]
        xor     eax,eax
        jmp     .finish
  .wmcommand:
        mov     eax,[wparam]
        and     eax,0FFFFh
        cmp     eax,IDM_NEW
        je      .new
        cmp     eax,IDM_ABOUT
        je      .about
        cmp     eax,IDM_EXIT
        je      .wmdestroy
        jmp     .defwndproc
      .new:
        invoke  SendMessage,[edithwnd],WM_SETTEXT,0,0
        jmp     .finish
      .about:
        invoke  LoadString,[mui.hInstance],1,buffer1,sizeof.buffer
        invoke  LoadString,[mui.hInstance],2,buffer2,sizeof.buffer
        invoke  MessageBox,[hwnd],buffer2,buffer1,MB_OK
        jmp     .finish
  .wmdestroy:
        invoke  DeleteObject,[editfont]
        invoke  PostQuitMessage,0
        xor     eax,eax
  .finish:
        pop     edi esi ebx
        ret
endp

section '.data' data readable writeable

  buffer1 rw 100h
  buffer2 rw 100h
  sizeof.buffer = $-buffer2
  mui MUI
  fd WIN32_FIND_DATA
  wc WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,_class
  edithwnd dd ?
  editfont dd ?

  msg MSG
  client RECT

  _wildcard TCHAR '*.dll',0
  _class TCHAR 'MINIPAD32',0
  _title TCHAR 'MiniPad',0
  _edit TCHAR 'EDIT',0
  _mui_error TCHAR 'Language libraries missing',0

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
          user,'USER32.DLL',\
          gdi,'GDI32.DLL'

  import kernel,\
         FindFirstFileEx,'FindFirstFileExW',\
         GetModuleHandle,'GetModuleHandleW',\
         GetLocaleInfoEx,'GetLocaleInfoEx',\
         GetUserDefaultLocaleName,'GetUserDefaultLocaleName',\
         ExitProcess,'ExitProcess',\
         LoadLibraryEx,'LoadLibraryExW'

  import user,\
         RegisterClass,'RegisterClassW',\
         CreateWindowEx,'CreateWindowExW',\
         DefWindowProc,'DefWindowProcW',\
         SetWindowLong,'SetWindowLongW',\
         RedrawWindow,'RedrawWindow',\
         GetMessage,'GetMessageW',\
         TranslateMessage,'TranslateMessage',\
         DispatchMessage,'DispatchMessageW',\
         SendMessage,'SendMessageW',\
         LoadCursor,'LoadCursorW',\
         LoadIcon,'LoadIconW',\
         LoadMenu,'LoadMenuW',\
         LoadString,'LoadStringW',\
         GetClientRect,'GetClientRect',\
         MoveWindow,'MoveWindow',\
         SetFocus,'SetFocus',\
         MessageBox,'MessageBoxW',\
         PostQuitMessage,'PostQuitMessage'

  import gdi,\
         CreateFont,'CreateFontW',\
         DeleteObject,'DeleteObject'

section '.rsrc' resource data readable

  ; resource directory

  directory RT_ICON,icons,\
            RT_GROUP_ICON,group_icons,\
            RT_VERSION,versions

  ; resource subdirectories

  resource icons,\
           1,LANG_NEUTRAL,icon_data

  resource group_icons,\
           IDR_ICON,LANG_NEUTRAL,main_icon

  resource versions,\
           1,LANG_NEUTRAL,version

  icon main_icon,icon_data,'minipad.ico'

  versioninfo version,VOS__WINDOWS32,VFT_APP,VFT2_UNKNOWN,LANG_ENGLISH+SUBLANG_DEFAULT,0,\
              'FileDescription','MiniPad - example program',\
              'LegalCopyright','No rights reserved.',\
              'FileVersion','1.0',\
              'ProductVersion','1.0',\
              'OriginalFilename','MINIPAD.EXE'
