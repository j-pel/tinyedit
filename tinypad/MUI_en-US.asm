format PE GUI 4.0 DLL

include 'win32w.inc'
include 'resources.inc'

section '.rsrc' resource data readable

  ; resource directory

  directory RT_MENU,menus,\
    RT_STRING,strings

  ; resource subdirectories

  resource menus,\
           IDR_MENU,LANG_ENGLISH+SUBLANG_DEFAULT,main_menu

  menu main_menu
       menuitem '&File',0,MFR_POPUP
                menuitem '&New',IDM_NEW
                menuseparator
                menuitem 'E&xit',IDM_EXIT,MFR_END
       menuitem '&Help',0,MFR_POPUP + MFR_END
                menuitem '&About...',IDM_ABOUT,MFR_END

  resource  strings,\
    1,LANG_ENGLISH+SUBLANG_DEFAULT,str_table  

  resdata str_table
    du 7,  'MiniPad'
    du 13, 'About MiniPad'
    du 59, 'This is a Win32 example program created with flat assembler.'
    du 16, 'Startup failed.'
  endres

section '.reloc' fixups data readable discardable