
; Win32 programming headers (ASCII)


include '%fasminc%/macro/stdcall.inc'
include '%fasminc%/macro/cdecl.inc'
include 'import.inc'
include '%fasminc%/macro/export.inc'
include '%fasminc%/macro/resource.inc'
include '%fasminc%/macro/fixes.inc'
include 'struct.inc'
include 'call.inc'
include 'oop.inc'
include 'cstr.inc'

struc CHAR count { rb count }

include '%fasminc%/equates/kernel32.inc'
include '%fasminc%/equates/user32.inc'
include '%fasminc%/equates/gdi32.inc'
include '%fasminc%/equates/comctl32.inc'
include '%fasminc%/equates/comdlg32.inc'
include '%fasminc%/equates/shell32.inc'
include '%fasminc%/equates/wsock32.inc'
include 'EquatesEx.inc'