; Additional equates for Win32 Programming 

MAX_PATH = 200h

HTCAPTION = 2

LOCALE_IMEASURE = 0Dh
LOGPIXELSX = 58h
LOGPIXELSY = 5Ah

BIF_RETURNONLYFSDIRS   =    1
BIF_DONTGOBELOWDOMAIN  =    2
BIF_STATUSTEXT         =    4
BIF_RETURNFSANCESTORS  =    8
BIF_EDITBOX            =   10h
BIF_VALIDATE           =   20h
BIF_BROWSEFORCOMPUTER  = 1000h
BIF_BROWSEFORPRINTER   = 2000h
BIF_BROWSEINCLUDEFILES = 4000h

DIB_RGB_COLORS      = 0
DIB_PAL_COLORS      = 1
DIB_PAL_INDICES     = 2
DIB_PAL_PHYSINDICES = 2
DIB_PAL_LOGINDICES  = 4

struc BROWSEINFO
 {
	.hwndOwner dd ?
	.pidlRoot dd ?
	.pszDisplayName dd ?
	.lpszTitle dd ?
	.ulFlags dd ?
	.lpfn dd ?
	.lParam dd ?
	.iImage dd ?
 }
struct BROWSEINFO

struc TV_ITEMEX
{
  .imask	     dd ?
  .hItem	     dd ?
  .state	     dd ?
  .stateMask	     dd ?
  .pszText	     dd ?
  .cchTextMax	     dd ?
  .iImage	     dd ?
  .iSelectedImage    dd ?
  .cChildren	     dd ?
  .lParam	     dd ?
  .iIntegral	     dd ?
}
struct TV_ITEMEX

struc TV_INSERTSTRUCT
{
  .hParent	 dd ?
  .hInsertAfter  dd ?
  .item TV_ITEMEX
}
struct TV_INSERTSTRUCT

struc NM_TREEVIEW
{
  .hdr	     NMHDR
  .action    dd ?
  .itemOld   TV_ITEMEX
  .itemNew   TV_ITEMEX
  .ptDrag    POINT
}
struct NM_TREEVIEW

struc TV_DISPINFO
{
  .hdr		NMHDR
  .item 	TV_ITEMEX
}
struct TV_DISPINFO

struc TV_HITTESTINFO
{
  .pt	     POINT
  .flags     dd ?
  .hItem     dd ?
}
struct TV_HITTESTINFO

struc EDITSTREAM
{
	.dwCookie dd ?
	.dwError dd ?
	.pfnCallback dd ?
}
struct EDITSTREAM

struc DOCINFO
{
	.cbSize dd ?
	.lpszDocName  dd ?
	.lpszOutput dd ?
	.lpszDatatype dd ?
	.fwType dd ?
}
struct DOCINFO

