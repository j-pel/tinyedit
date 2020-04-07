; Studies for MenuetOS Tiny Browser
;	File: Win32 Canvas class
;	Home: as.modshack.co.uk

BASE_WIDTH	= 160
BASE_HEIGHT = 320

struct CANVAS_CLASS
  .WorkDC	dd 0
  .ShowDC	dd 0
  .WorkBmp	dd 0
  .ShowBmp	dd 0
  .WorkDIB	dd 0
  .ShowDIB	dd 0
  .PrevWidth	dd 0
  .PrevHeight dd 0
  .Background dd 0
  .MainFont	dd 0
ends

struc BITMAPINFOHEADER width,height
 {
  .biSize	dd BITMAPINFOHEADER.size
  .biWidth	dd width
  .biHeight	dd height
  .biPlanes	dw 1
  .biBitCount	dw 32
  .biCompression	dd BI_RGB
  .biSizeImage	dd 0
  .biXPelsPerMeter dd 0
  .biYPelsPerMeter dd 0
  .biClrUsed	dd 0
  .biClrImportant	dd 0
  local name
	virtual at 0
		name BITMAPINFOHEADER
		sizeof.BITMAPINFOHEADER = $ - name
		BITMAPINFOHEADER.size = $ - name
	end virtual 
 }

canvas CANVAS_CLASS
WorkBmpInfo BITMAPINFOHEADER 4*BASE_WIDTH,2*BASE_HEIGHT
ShowBmpInfo BITMAPINFOHEADER 2*BASE_WIDTH,BASE_HEIGHT
