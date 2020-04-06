format PE GUI 4.0 DLL

include 'win32w.inc'
include 'resources.inc'

section '.rsrc' resource data readable

  ; resource directory

  directory RT_MENU,menus,\
    RT_STRING,strings

  ; resource subdirectories

  resource menus,\
           IDR_MENU,LANG_SPANISH+SUBLANG_DEFAULT,main_menu

  menu main_menu
       menuitem '&File',0,MFR_POPUP
                menuitem '&Nuovo',IDM_NEW
                menuseparator
                menuitem '&Esci',IDM_EXIT,MFR_END
       menuitem '&Aiuto',0,MFR_POPUP + MFR_END
                menuitem '&Informazioni su...',IDM_ABOUT,MFR_END

  resource  strings,\
    1,LANG_SPANISH+SUBLANG_DEFAULT,str_table

  resdata str_table
    du 7,  'MiniPad'
    du 17, 'Informazioni su MiniPad'
    du 65, "Questo è un'essempio d'applicazione Win32 creato con flat assembler."
    du 32, "Avvio dell'applicazione non riuscita."
  endres

section '.reloc' fixups data readable discardable