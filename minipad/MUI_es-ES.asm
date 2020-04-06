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
       menuitem '&Archivo',0,MFR_POPUP
                menuitem '&Nuevo',IDM_NEW
                menuseparator
                menuitem '&Salir',IDM_EXIT,MFR_END
       menuitem 'A&yuda',0,MFR_POPUP + MFR_END
                menuitem '&Acerca de...',IDM_ABOUT,MFR_END

  resource  strings,\
    1,LANG_SPANISH+SUBLANG_DEFAULT,str_table

  resdata str_table
    du 7,  'MiniPad'
    du 17, 'Acerca de MiniPad'
    du 65, 'Este es un ejemplo de un programa Win32 creado con flat assembler.'
    du 32, 'No se pudo iniciar la aplicación.'
  endres

section '.reloc' fixups data readable discardable