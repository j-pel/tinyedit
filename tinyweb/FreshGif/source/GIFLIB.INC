struc TGifInfo  {
;--- Header ---
  .GIFVersion    rb      3    ; 3 byte string (not 0-terminated) that identifies
                              ; the GIF Version (like 97a or 98a)
; --- Logical screen descriptor ---
  .dwLSWidth     dd      ?    ; Logical screen width
  .dwLSHeight    dd      ?    ; Logical screen height
                              ; NOTE: Use ImageWidth/Height to find the dimensions,
                              ; This one can be different from the logical screen
                              ; width and height.
; --- Color info ---
  .lpColorTable  dd      ?    ; Pointer to the color table
  .ColorCount    dd      ?    ; Number of colors in image (and color table)
  .fTransparent  dd      ?    ; if TRUE - the image have transparent color.
  .iTrasparentColor dd    ?    ; index of transparent color in the color table.

; --- Image info ---
  .dwImageWidth   dd      ?    ; Width of image
  .dwImageHeight  dd      ?    ; Height of image

; --- Image data ---
  .lpImageData   dd      ?    ; Pointer to the actual image data

; --- Input data ---
  .lpGIFData     dd      ?    ; Pointer to the GIF File data
  .dwGIFDataSize dd      ?    ; Size of GIF Data

; --- Internal data ---
; Don't touch this data below, it is used internally by GIFLIB
  .lpLZWTable      dd    ?    ; Pointer to LZW Table
  .dwLZWTableSize  dd    ?    ; Current maximum size of table
                              ; This size is dynamic and changes
                              ; if the codesize exceeds 9 bits

  .dwLZWTableCount dd      ?  ; Current nr of entries in the LZW table
  .fGlobalCTable   db      ?  ; If set, the GIF file has a global color table
  .dbGCTableSize   db      ?  ; Size of the global color table, if available
  .fLocalCTable    db      ?  ; If set, the first image has a local color table
  .dbLCTableSize   db      ?  ; Size of the local color table, if available
  .lpGIFImage      dd      ?  ; Pointer to the first real image data(Table based image data)
  .lpCurrentByte   dd      ?  ; Pointer to the current byte (used with decompression)
                              ; note: if this value is -1, end of the file is reached and
                              ; the code-supplier returns 0 as padding
  .dbBitsAvailable db      ?  ; Nr of codebits currently available
  .dbCurBitSize    db      ?  ; Current LZW code size
  .dbInitBitSize   db      ?  ; Initial LZW code size
  .lpLastEOSB      dd      ?  ; Pointer to end of current subblock (used with decompression)
  .dwLZWClear      dd      ?  ; Value of LZW Clear code (CC)
  .CurrentBits     dd      ?  ; Holds the current bits loaded
  .IsFirstCode     db      ?  ; Indicates if the first code is being read now
  .PixelCounter    dd      ?  ; Counts nr of PIXELS outputted
}
struct TGifInfo

EXTENSIONBLOCK           =  021h
IMAGEDESCRIPTOR          =  02Ch
GRAPHICCONTROLEXTENSTION =  0F9h
COMMENTEXTENSION         =  0FEh
PLAINTEXTEXTENSION       =  001h
APPLICATIONEXTENSION     =  0FFh 