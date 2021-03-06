format PE GUI 4.0
stack 0x1000

entry start

..ShowSkipped equ ON
..ShowSizes equ ON

include '%finc%\win32\win32a.inc'
include '%finc%\libs\msgutils.inc'

include 'source\giflib.inc'


section '.code' code readable executable

uglobal
  hInstance       dd 0  ; Instance handle for common use.
endg


include '%finc%\libs\msgutils.asm'

include 'MainWindow.asm'
include 'source\giflib.asm'

start:
; Main init sequence
        invoke  GetModuleHandle,0
        mov     [hInstance],eax

; Startup windows creation
        call    InitMainWindow  ; Create main window.

include '%finc%\libs\MainLoop.asm'



;*****************************************************************
; Main static data section.
; Actually this is the only data section in the program.
;*****************************************************************
section '.data' data readable writeable
  IncludeAllGlobals


section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL',    \
          gdi32,'gdi32.dll',      \
          comctl32,'comctl32.dll',\
          comdlg32,'comdlg32.dll',\
          shell32, 'shell32.dll', \
          ole32,   'ole32.dll'

  include '%finc%\win32\apia\kernel32.inc'
  include '%finc%\win32\apia\user32.inc'
  include '%finc%\win32\apia\gdi32.inc'
  include '%finc%\win32\apia\ComCtl32.inc'
  include '%finc%\win32\apia\ComDlg32.inc'
  include '%finc%\win32\apia\Shell32.inc'
  include '%finc%\win32\apia\ole32.inc'

section '.rsrc' resource from 'GifTest.res' data readable 