GifLib:

;===============================================================================
;       GIFLIB v1.0 - (C) Copyright by Exagone
;===============================================================================
; The included Fresh artistic license (see license.txt) applies to this source
; code. By using this code, you agree to the terms of the license.
;
; Original source code by Exagone
; http://exagone.cjb.net | http://www.exagone.org
; _thomas_@mailroom.com
;===============================================================================
; (c)2004 John Found - Port for FASM/Fresh cleanup and improvements. For details
;                      see the file 'history.txt'.
; http://flatassembler.net
; http://fresh.flatassembler.net
;===============================================================================

proc ImageList_LoadGif, hInst, ptrName, width
.gifinfo TGifInfo
.bitmapinfo BITMAPINFOHEADER
.result     dd ?
begin
        push    esi edi ebx
        mov     [.result], 0

        lea     edi, [.gifinfo]
        lea     esi, [.bitmapinfo]

        stdcall GIFLoadResource, edi, [hInst], [ptrName]
        jz      .quit

        stdcall GIFLoadHeader, edi
        jz      .quit

        stdcall GIFInitalizeDecoder, edi
        jz       .quit

        stdcall GIFFillBitmapInfoStruct, edi, esi

        lea     eax, [edi+TGifInfo.lpImageData]
        invoke  CreateDIBSection, NULL, esi, DIB_RGB_COLORS, eax, NULL, NULL
        test    eax, eax
        jz      .quit

        mov     ebx, eax

        stdcall GIFDecompress, edi
        jz      .quit

        stdcall GIFCleanup, edi

        mov     eax, [edi+TGifInfo.dwImageWidth]
        cmp     [width], -1
        jne     @f

        mov     [width], eax
@@:
        invoke  ImageList_Create, [width], [edi+TGifInfo.dwImageHeight],  ILC_COLOR32 or ILC_MASK, 0, 1
        test    eax, eax
        jz      .quitclean

        mov     [.result], eax

        mov     ecx, $ff010101
        cmp     [edi+TGifInfo.fTransparent], 0
        je      @f
        mov     ecx, [edi+TGifInfo.iTrasparentColor]
        lea     ecx, [ecx+2*ecx]
        add     ecx, [edi+TGifInfo.lpColorTable]
        mov     ecx, [ecx]
;        bswap   ecx
;        shr     ecx, 8
        and ecx, $00ffffff
@@:
        invoke  ImageList_AddMasked, eax, ebx, ecx

.quitclean:
        invoke  DeleteObject, ebx
.quit:
        mov     eax, [.result]
        pop     ebx edi esi
        return
endp




;===============================================================================
;       GIFLoadResource
;===============================================================================
; Loads gif data from a resource (of type RT_RCDATA)
; lpName:pointer to a resource name OR resource ID
proc GIFLoadResource, lpGifInfo, hInst, lpName
begin
        push    esi edi ebx
        mov     esi, [lpGifInfo]

        invoke  FindResource, [hInst], [lpName], RT_RCDATA
        test    eax,eax
        jz      .exit

        mov     ebx, eax

        invoke  LoadResource, [hInst], eax
        test    eax, eax
        jz      .exit

        mov     [esi+TGifInfo.lpGIFData], eax

        invoke  SizeofResource, [hInst], ebx
        test    eax, eax
        jz      .exit

        mov     [esi+TGifInfo.dwGIFDataSize], eax
        xor     eax, eax
        inc     eax

.exit:
        pop     ebx edi esi
        return
endp

;===============================================================================
;       GIFLoadFile
;===============================================================================
; Loads gif data from a file
; SHOULD CLEANUP POINTER AFTERWARDS (globalalloc)
proc GIFLoadFile, lpGifInfo, lpFile
.hFile  dd  ?
.bRead  dd  ?
begin
        mov     esi, [lpGifInfo]
        invoke  CreateFile, [lpFile], GENERIC_READ, FILE_SHARE_READ, NULL, \
                                      OPEN_EXISTING, NULL, NULL
        cmp     eax, INVALID_HANDLE_VALUE
        je      .false

        mov     [.hFile], eax
        invoke  GetFileSize, eax, NULL
        cmp     eax, -1
        je      .closefalse

        mov     [esi+TGifInfo.dwGIFDataSize], eax

        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, 0, [esi+TGifInfo.dwGIFDataSize]
        test    eax, eax
        jz      .closefalse

        mov     [esi+TGifInfo.lpGIFData], eax
        lea     eax, [.bRead]
        invoke  ReadFile, [.hFile], [esi+TGifInfo.lpGIFData], [esi+TGifInfo.dwGIFDataSize], eax, NULL
        test    eax, eax
        jz      .closefalse

        invoke  CloseHandle, [.hFile]
        xor             eax, eax
        inc             eax
        return

.closefalse:
        invoke  CloseHandle, [.hFile]
.false:
        xor     eax, eax
        return
endp



;===============================================================================
;       GIFCleanup
;===============================================================================
; Cleanup
;
proc GIFCleanup, lpGifInfo
begin
        push    esi
        mov     esi, [lpGifInfo]
        invoke  GetProcessHeap
        invoke  HeapFree, eax, 0, [esi+TGifInfo.lpLZWTable]
        pop     esi
        return
endp



;===============================================================================
;       GIFFillBitmapInfoStruct
;===============================================================================
;  Fills a bitmap info structure width the given properties or automatically
proc GIFFillBitmapInfoStruct, lpGifInfo, lpBIH
begin
        push    esi edi
        mov     esi, [lpGifInfo]
        mov     edi, [lpBIH]

        mov     [edi+ BITMAPINFOHEADER.biSize], sizeof.BITMAPINFOHEADER
        mov     eax, [esi+TGifInfo.dwImageHeight]
        mov     ecx, [esi+TGifInfo.dwImageWidth]
        neg     eax                                     ;negative because it outputs a top-down bitmap
        mov     [edi+BITMAPINFOHEADER.biWidth], ecx
        mov     [edi+BITMAPINFOHEADER.biHeight], eax

        mov     [edi+BITMAPINFOHEADER.biPlanes], 1
        mov     [edi+BITMAPINFOHEADER.biBitCount], 32
        xor     eax, eax
        mov     [edi+BITMAPINFOHEADER.biCompression], BI_RGB
        mov     [edi+BITMAPINFOHEADER.biSizeImage], eax
        mov     [edi+BITMAPINFOHEADER.biXPelsPerMeter], eax
        mov     [edi+BITMAPINFOHEADER.biYPelsPerMeter], eax
        mov     [edi+BITMAPINFOHEADER.biClrUsed], eax
        mov     [edi+BITMAPINFOHEADER.biClrImportant], eax

        pop     edi esi
        return
endp




;===============================================================================
;       GIFDecompress
;===============================================================================
; Decompresses the gif and outputs
; returns:
; 0  - color format not allowed
; 1  - success
; -1 - failed
proc GIFDecompress, lpGifInfo
begin
        push    esi edi ebx

        mov     esi, [lpGifInfo]
        mov     edi, [esi+TGifInfo.lpImageData]

        ; --- Initially, load 4 bytes ---
        mov     [esi+TGifInfo.CurrentBits], 0
        mov     [esi+TGifInfo.dbBitsAvailable], 0

        mov     ebx, 4
.while:
        stdcall LoadNextByte, esi
        dec     ebx
        jne     .while

        stdcall DECInitialize, esi
        stdcall DECDecodeGIF, [lpGifInfo]

        xor     eax, eax
        inc     eax
        pop     ebx edi esi
        return

.qfalse:
        xor     eax, eax
        pop     ebx edi esi
        return
endp

;===============================================================================
;       DECDecodeGIF
;===============================================================================
; The actual decoder
;
proc DECDecodeGIF, lpGifInfo
 .OldCode            dd ?
 .FirstCharOfOldCode db ?
 .FirstCharOfCode    db ?
 .dummyalign         dw ?
 .NrCodesToOutput    dd ?
begin
        push    esi edi ebx

        mov     esi, [lpGifInfo]

        ; --- set counters ---
        mov     [esi+TGifInfo.PixelCounter], 0   ;0 codes outputted
        mov     eax, [esi+TGifInfo.dwImageWidth]
        mul     [esi+TGifInfo.dwImageHeight]
        mov     [.NrCodesToOutput], eax    ;this is an OUTPUT CODE counter, not nr of compressed codes

; LZW Decompression
;     [1] Initialize string table;
;     [2] get first code: <code>;
;     [3] output the string for <code> to the charstream;
;     [4] <old> = <code>;
;     [5] <code> <- next code in codestream;
;     [6] does <code> exist in the string table?
;      (yes: output the string for <code> to the charstream;            (A)
;            [...] <- translation for <old>;                            (B)
;            K <- first character of translation for <code>;            (C)
;            add [...]K to the string table;                            (D)
;                        <old> <- <code>;  )                            (E)
;      (no: [...] <- translation for <old>;                             (F)
;           K <- first character of [...];                              (G)
;           output [...]K to charstream and add it to string table;     (H)
;           <old> <- <code>                                             (I)
;      )
;     [7] go to [5];

.mainloop:
        mov     eax, [.NrCodesToOutput]
        cmp     eax, [esi+TGifInfo.PixelCounter]
        je      .endloop

        stdcall GetNextCode, esi                        ; [1] and [5]
        mov     ebx, eax
        cmp     ebx, [esi+TGifInfo.dwLZWClear]          ; Check for clearcode
        jne     .noclear

        stdcall DECResetLZW, esi                ; Reset LZW
        jmp     .mainloop

.noclear:
       cmp      [esi+TGifInfo.IsFirstCode], 1   ; Checks if steps [1]-[4] have to be done
       jne      .notfirst

       dec      [esi+TGifInfo.IsFirstCode]      ;[2]
       stdcall  DECOutputString, esi, ebx       ;[3]
       mov      [.FirstCharOfOldCode], al       ; saved for (G)
       mov      [.OldCode], ebx                 ;[4]
       jmp      .mainloop

.notfirst:
       cmp     [esi+TGifInfo.dwLZWTableCount], ebx  ; [6]   ; DECIsCodeInTable replacement
       jbe     .notintable

       stdcall  DECOutputString, esi, ebx           ;(B)
       mov      [.FirstCharOfCode], al              ;(C)
       mov      [.FirstCharOfOldCode], al           ; saved for (G)
       stdcall  DECAddToTable, esi, [.OldCode], eax ;(D)
       mov      [.OldCode], ebx
       jmp      .mainloop

.notintable:                                        ;(F)-(I)
       mov      al, [.FirstCharOfOldCode]           ; (G)
       stdcall  DECAddToTable, esi, [.OldCode], eax ;(H)
       stdcall  DECOutputString, esi, ebx           ;(H)
       mov      [.FirstCharOfOldCode], al           ; saved for (G)
       mov      [.OldCode], ebx
       jmp      .mainloop

.endloop:
       xor     eax, eax
       inc     eax
       pop     ebx edi esi
       return
endp


;===============================================================================
; DECAddToTable
;===============================================================================
; Adds an entry to the LZW Table
; The enry consists of a prefix and a suffix (size is calculated automatically)
; returns the code for the new entry
proc DECAddToTable, lpGifInfo, dwPrefix, dbSuffix
begin
        push    esi edi ebx

        mov     esi, [lpGifInfo]

        ; --- Check if enough space in the table left
        mov     ecx, [esi+TGifInfo.dwLZWTableSize]
        mov     ebx, [esi+TGifInfo.dwLZWTableCount]

        push    ebx
        shl     ebx, 2

        ; --- If no space left, make the table bigger:
        cmp     ebx, ecx
        jne     .sizeok

        shl     ecx, 1          ;Table size doubles
        mov     [esi+TGifInfo.dwLZWTableSize], ecx

        ; --- Reallocate memory ---
        push    ecx
        invoke  GetProcessHeap
        invoke  HeapReAlloc, eax, 0, [esi+TGifInfo.lpLZWTable] ; size is in the stack
        mov     [esi+TGifInfo.lpLZWTable], eax

.sizeok:
        ; --- Create pointer to first free entry ---
        add     ebx, [esi+TGifInfo.lpLZWTable]

        ; --- Find out the size of the string ---
        mov     eax, [dwPrefix]
        shl     eax, 2
        add     eax, [esi+TGifInfo.lpLZWTable]
        mov     eax, [eax]
        shr     eax, 8
        and     eax, 0FFFh      ;eax now holds the size of the prefix string
        inc     eax

        ; --- Create the entry DWORD ---
        ; (see DECResetLZW for the format)
        mov     ecx, [dwPrefix]
        shl     ecx, 20
        shl     eax, 8
        or      ecx, eax
        mov     eax, [dbSuffix]
        and     eax, 0ffh
        or      ecx, eax

        ; --- Store entry ---
        mov     [ebx], ecx

        inc     [esi+TGifInfo.dwLZWTableCount]

        pop     ebx     ;get saved code of new entry

        mov     cl, [esi+TGifInfo.dbCurBitSize]
        xor     eax, eax
        inc     eax
        shl     eax, cl
        dec     eax
        cmp     eax, ebx
        jne     @f

        ;bitsize should be increased
        inc     [esi+TGifInfo.dbCurBitSize]   ;increase bitsize

@@:
        mov     eax, ebx
        pop     ebx edi esi
        return
endp


;===============================================================================
; DECOutputString
;===============================================================================
; Writes the string of dwCode to the output stream
; returns the first character of the string in al
;
proc DECOutputString, lpGifInfo, dwCode
.LastChar     db ?
begin
        push    esi edi ebx

        mov     esi, [lpGifInfo]
        mov     edi, [esi+TGifInfo.lpLZWTable]  ; --- Set basepointer ---

        mov     eax, [dwCode]                   ; --- Get entry ---

        mov     ebx, [edi+4*eax]                ; --- Get size of string ---
        shr     ebx, 8                          ; See the description of LZW table below.
        and     ebx, $0fff

; --- Output all codes backwards ---
        mov     edx, [esi+TGifInfo.PixelCounter]
        shl     edx, 2
        add     edx, [esi+TGifInfo.lpImageData]         ; edx is base pointer in the image data.

        add     [esi+TGifInfo.PixelCounter], ebx        ; update the pixel counter.
        dec     ebx                                     ; ebx is the counter and index in image data.

        mov     esi, [esi+TGifInfo.lpColorTable]        ; We don't need TGifInfo anymore.

.outloop:
        mov     eax, [edi+4*eax]
        mov     [.LastChar], al

; Get the color from the color table - esi points to 3 byte  palette array.
        movzx   ecx, al
        lea     ecx, [ecx+2*ecx]  ; = 3*ecx
        mov     ecx, [esi+ecx]
        bswap   ecx
        shr     ecx, 8

; Draw the pixel.
        mov     [edx+4*ebx], ecx

        shr     eax, 20         ; Get the prefix index in the LZW table.
        and     eax, $0fff

        dec     ebx
        jns     .outloop

        mov     al, [.LastChar]
        pop     ebx edi esi
        return
endp



;===============================================================================
; GetNextCode
;===============================================================================
; retrieves the next code from the compressed data stream and loads new bits
; if needed.
proc GetNextCode, lpGifInfo
begin
        push    esi edi ebx

        mov     esi, [lpGifInfo]
        mov     ebx, [esi+TGifInfo.CurrentBits]

        ; --- Create bitmask for current nr of bits ---
        mov     cl, [esi+TGifInfo.dbCurBitSize]
        xor     eax, eax
        inc     eax
        shl     eax, cl
        dec     eax

        ; --- AND ebx with bitmask ---
        and     ebx, eax

        ; --- Shift used bits ---
        mov     cl, [esi+TGifInfo.dbCurBitSize]
        shr     [esi+TGifInfo.CurrentBits], cl

        ; --- Decrease # of bits available ---
        sub     [esi+TGifInfo.dbBitsAvailable], cl

        ; --- Load as many bits as possible ---
.while:
        cmp     [esi+TGifInfo.dbBitsAvailable], 24
        ja      .endwhile
        stdcall LoadNextByte, esi
        jmp     .while

.endwhile:
        ; --- Return bits ---
        mov     eax, ebx
        pop     ebx edi esi
        return
endp


;===============================================================================
; LoadNextByte
;===============================================================================
; Loads the currentbits entry with new bits
;
proc LoadNextByte, lpGifInfo
begin
        push    esi edi ebx
        mov     esi, [lpGifInfo]

        ; --- Get next byte from datastream ---
        mov     edi, [esi+TGifInfo.lpCurrentByte]
        cmp     edi, -1
        jne     .notend

;end of data already reached
        xor     al, al  ;return 0 as padding
        jmp     .gotbyte

;End of subblock reached?
.notend:
        cmp      edi, [esi+TGifInfo.lpLastEOSB]
        jne      .noteosb

        xor      eax, eax
        mov      al, [edi]       ; new subblock size
        test     al,al
        jnz      .sizeok

        ; if size=0, end of data
        mov      [esi+TGifInfo.lpCurrentByte], -1 ;EOF indicator
        jmp      .gotbyte

.sizeok:
        inc      edi             ; new subblock with size al
        add      eax, edi
        mov      [esi+TGifInfo.lpLastEOSB], eax  ;set new end of subblock
        add      [esi+TGifInfo.lpCurrentByte], 2
        mov      al, [edi]
        jmp      .gotbyte

.noteosb:
        mov      al, [edi]                       ;get next byte
        inc      [esi+TGifInfo.lpCurrentByte]    ;increase for next read

        ; --- Got the new byte from the datasteam ---
.gotbyte:
        mov      cl, [esi+TGifInfo.dbBitsAvailable] ;Get nr of bits available
        mov      edx, [esi+TGifInfo.CurrentBits]    ;Get current bits
        and      eax, 0ffh                          ;eax = al
        shl      eax, cl                            ;Shift bits to right position
        or       edx, eax                           ;OR new bits with current bits
        mov      [esi+TGifInfo.CurrentBits], edx    ;Save bits
        add      [esi+TGifInfo.dbBitsAvailable], 8  ;Set new bits avaialble

        pop     ebx edi esi
        return
endp


;===============================================================================
;       DECInitialize
;===============================================================================
; Initializes the decoder (table for LZW etc)
;
proc DECInitialize, lpGifInfo
begin
        push    esi edi

        mov     esi, [lpGifInfo]
        mov     edi, [esi+TGifInfo.lpGIFImage]

        ; --- Get initial LZW code size ---
        mov     cl, [edi]
        inc     cl
        mov     [esi+TGifInfo.dbInitBitSize], cl

        ; --- Set current bit size to initial bitsize ---
        mov     [esi+TGifInfo.dbCurBitSize], cl

        ; --- Set size of LZW table ---

        cmp     cl, 8
        jae     @f    ;if initial code size is less than 8-bits,
        mov     cl, 8 ;set to 8-bits, if higher, don't change it
@@:
        ; Calculate size of codetable:
        xor     eax, eax
        inc     eax
        add     cl, 2           ; bitsize + 2
        shl     eax, cl         ; eax = 2 ^ (bitsize + 2) = 4 * (2^bitsize)
        mov     [esi+TGifInfo.dwLZWTableSize], eax

        ; --- Allocate memory for LZW Table and store pointer ---
        push    eax
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, 0 ; the size is in the stack.
        mov     [esi+TGifInfo.lpLZWTable], eax

        ; --- Reset LZW ---
        stdcall DECResetLZW, esi

        xor     eax, eax
        inc     eax
        pop     edi esi
        return
endp



;===============================================================================
; DECResetLZW
;===============================================================================
; Resets the LZW Table and variables (this is the proper action for a clear
; code (CC) in data
proc DECResetLZW, lpGifInfo
begin
        push    esi edi ebx
        mov     esi, [lpGifInfo]

; The LZW table has the following format:
; An array of DWORDS represents an array of string entries
; One entry consists of a prefix code (which is an index to
; another entry that should prefix the entry), a string length,
; and the suffix byte (this byte should be added to the prefix
; to get the full string).
; DWORD:
; | AAAA AAAA | AAAA BBBB | BBBB BBBB | CCCC CCCC |
; ^                                               ^
; MSB                                           LSB
; AAAAAAAAAAAA:  12-bit index in the LZW Table that indicates the prefix
; BBBBBBBBBBBB:  12-bit length of the string
; CCCCCCCC    :   8-bit suffix byte

        ; --- reset LZW Table ---
        ; Reset bit size:

        mov     cl, [esi+TGifInfo.dbInitBitSize]
        mov     [esi+TGifInfo.dbCurBitSize], cl

        ; Get initial nr of entries
        ;mov            eax, [esi].ColorCount
        ;NOTE: THE LINE ABOVE WAS PREVIOUSLY USED TO GET THE NR OF ROOT ENTRIES
        ; THIS DIDN'T WORK BECAUSE 1-BIT GIF'S ARE FOR AN UNKNOWN REASON CODED
        ; AS 2-BIT GIFS, SO THE NR OF ROOT ENTRIES HAS TO BE DETERMINED FROM THE
        ; INITIAL BITSIZE
        dec     cl
        xor     eax, eax
        inc     eax
        shl     eax, cl         ; 2**codesize
        add     eax, 2
        mov     [esi+TGifInfo.dwLZWTableCount], eax
        mov     edx, [esi+TGifInfo.lpLZWTable]
        ; Fill first {2**codcesize+2} entries
        shl     eax, 2
        add     eax, edx
        xor     ecx, ecx
        inc     ch                      ;size of sting is set to 1

.fill:
        mov     [edx], ecx
        inc     cl
        add     edx, 4
        cmp     edx, eax
        jb      .fill

        ; --- set clear code ---
        mov     eax, [esi+TGifInfo.dwLZWTableCount]
        sub     eax, 2
        mov     [esi+TGifInfo.dwLZWClear], eax
        mov     [esi+TGifInfo.IsFirstCode], 1

        ;lpLZWTable             dd      ?   ; Pointer to LZW Table
        ;dwLZWTableSize         dd      ?   ; Current maximum size of table
        ;dwLZWTableCount        dd      ?   ; Current nr of entries in the LZW table
        ;dbCurBitSize           db      ?   ; Current LZW code size
        ;dbInitBitSize          db      ?   ; Initial LZW code size
        ;dwLZWClear             dd      ?   ; Value of LZW Clear code (CC)

        xor     eax, eax
        inc     eax
        pop     ebx edi esi
        return
endp



;===============================================================================
;       GIFLoadHeader
;===============================================================================
; Loads header and logical screen descriptor
;
proc GIFLoadHeader, lpGifInfo
begin
        push    esi edi ebx
        mov     esi, [lpGifInfo]

        ; --- EDI points to GIF Data, EBX is size of data ---
        mov     edi, [esi+TGifInfo.lpGIFData]
        mov     ebx, [esi+TGifInfo.dwGIFDataSize]

        cmp     ebx, 11
        jb      .failed ; ebx smaller than header & Logical screen descr. -> invalid GIF

        ; --- Check first 3 bytes ("GIF" signature) ---
        mov     eax, [edi]
        and     eax, $00ffffff
        cmp     eax, 'GIF'
        jne     .failed

        ; --- Copy version number ---
        lea     ecx, [esi+TGifInfo.GIFVersion]
        mov     ax, [edi+3]
        mov     [ecx], ax
        mov     al, [edi+5]
        mov     [ecx+2], al

        ; --- Copy logical screen sizes ---
        xor     eax, eax
        mov     ax, [edi+6]                     ;Get Logical screen width
        mov     [esi+TGifInfo.dwLSWidth], eax
        mov     ax, [edi+8]                     ;Get Logical screen width
        mov     [esi+TGifInfo.dwLSHeight], eax

        ; --- Set global color table flag and size ---
        mov     cl, [edi+10]
        mov     al, cl
        rol     al, 1
        and     al, 1
        mov     [esi+TGifInfo.fGlobalCTable], al
        and     cl, 111b
        mov     [esi+TGifInfo.dbGCTableSize], cl

        xor     eax, eax
        inc     eax
        pop     ebx edi esi
        return

.failed:
        xor     eax, eax
        pop     ebx edi esi
        return
endp



;===============================================================================
;       GIFInitalizeDecoder
;===============================================================================
; Initializes decoder
;
proc GIFInitalizeDecoder, lpGifInfo
begin
        push    esi edi ebx
        mov     esi, [lpGifInfo]

        ; --- EDI points to GIF Data, EBX to end of data ---
        mov     edi, [esi+TGifInfo.lpGIFData]
        mov     ebx, [esi+TGifInfo.dwGIFDataSize]
        add     ebx, edi

        add     edi, 13         ; skip header and local screen descriptor

        ; --- Get global color tablesize in bytes ---
        mov     cl, [esi+TGifInfo.dbGCTableSize]
        inc     cl
        xor     eax, eax
        inc     eax
        shl     eax, cl
        mov     ecx, eax
        shl     ecx, 1          ;--+--> ecx * 3
        add     ecx, eax        ;--+

        ; --- Skip global color table if available ---
        cmp     [esi+TGifInfo.fGlobalCTable], 0
        je      @f
        add     edi, ecx
@@:
        cmp     edi, ebx
        jae     .failed

        ; --- Search through the GIF blocks for the first graphic block ---
.scanloop:
        cmp     edi, ebx
        jae     .failed

        mov     al, [edi]
        cmp     al, EXTENSIONBLOCK
        jne     .maybe

        stdcall SkipExtension, edi, ebx
        mov     edi, eax
        jmp     .scanloop

.maybe:
        cmp     al, IMAGEDESCRIPTOR
        jne     .scanloop               ; BUG: loop forever on some circumstances...

        stdcall ProcessImageDescriptor, [lpGifInfo], edi, ebx
        add     edi, 11
        stdcall SkipSubBlocks, edi

        xor     eax, eax
        inc     eax
.quit:
        pop     ebx edi esi
        return

.failed:
        xor     eax, eax
        jmp     .quit
endp



;===============================================================================
; ProcessImageDescriptor
;===============================================================================
; Processes an image desriptor block
proc ProcessImageDescriptor, lpGIFInfo, lpStart, lpEOF
begin
        push    esi edi
        mov     esi, [lpGIFInfo]

        mov     edx, [lpStart]
        xor     eax, eax

        ; --- copy image width & height ---
        mov     ax, [edx+5]
        mov     [esi+TGifInfo.dwImageWidth], eax
        mov     ax, [edx+7]
        mov     [esi+TGifInfo.dwImageHeight], eax

        ; --- look for local color table ---
        mov     cl, [edx+9]
        mov     al, cl
        rol     cl, 1
        and     cl, 1
        mov     [esi+TGifInfo.fLocalCTable], cl
        and     al, 111b
        mov     [esi+TGifInfo.dbLCTableSize], al

        ; --- Find out which color table to use ---
        cmp     cl, 1
        jne     .setglobal

        ;local color table available
        ; --- Set color count ---
        mov     cl, [esi+TGifInfo.dbLCTableSize]
        inc     cl
        xor     eax, eax
        inc     eax
        shl     eax, cl
        mov     [esi+TGifInfo.ColorCount], eax
        ; --- Set color table pointer ---
        mov     eax, edx
        add     eax, 10 ;move to the local color table
        mov     [esi+TGifInfo.lpColorTable], eax
        jmp     .ctableok

.setglobal:
        ;no local color table, use global color table
        ; --- Set color count ---
        mov     cl, [esi+TGifInfo.dbGCTableSize]
        inc     cl
        xor     eax, eax
        inc     eax
        shl     eax, cl
        mov     [esi+TGifInfo.ColorCount], eax
        ; --- Set color table pointer ---
        mov     eax, [esi+TGifInfo.lpGIFData]
        add     eax, 13 ;move to the global color table (at offset 13 in file)
        mov     [esi+TGifInfo.lpColorTable], eax

.ctableok:
        ; --- Set pointer to real image data (table based image data)
        mov     eax, edx
        add     eax, 10                                 ;Skip image descriptor

        cmp     [esi+TGifInfo.fLocalCTable], 0
        je      .setptr

        mov     ecx, [esi+TGifInfo.ColorCount]   ;-+
        add     eax, ecx                         ; + add size of colortable
        shl     ecx, 1                           ; + (colorcount * 3)
        add     eax, ecx                         ;-+

.setptr:
        mov     [esi+TGifInfo.lpGIFImage], eax

        ; --- Set some pointers to initialize the decompressor
        inc     eax
        mov     [esi+TGifInfo.lpLastEOSB], eax
        mov     [esi+TGifInfo.lpCurrentByte], eax

        xor     eax, eax
        inc     eax
        pop     edi esi
        return
endp



;=====================================================================
; Skips an extension block that starts at lpStart. EOF is at lpEnd.
; returns pointer to the end of block + 1
; or 0 if failed
; esi points at TGifInfo structure.
proc SkipExtension, lpStart, lpEnd
begin
        ; --- Get type of extension ---
        mov     edx, [lpStart]
        mov     al, [edx+1]

        ; --- Skip each type seperately ---
        cmp     al, GRAPHICCONTROLEXTENSTION
        jne     @f

        ; Get transparent color and flag.
        movzx   eax, byte [edx+3]
        and     eax, 1
        mov     [esi+TGifInfo.fTransparent], eax
        mov     al, [edx+6]
        mov     [esi+TGifInfo.iTrasparentColor], eax

        ; Graphic control extension, has a fixed size of 8 bytes
        add     edx, 8
        mov     eax, edx
        jmp     .endext

@@:
        cmp     al, COMMENTEXTENSION
        jne     @f

        ; Comment extension, consists of subblocks of text
        add     edx, 2  ;move to first subblock
        stdcall SkipSubBlocks, edx
        jmp     .endext

@@:
        cmp     al, PLAINTEXTEXTENSION
        jne     @f

        ; Plain text extension, 15 header bytes and subblocks follow
        add     edx, 15
        stdcall SkipSubBlocks, edx
        jmp     .endext

@@:
        cmp     al, APPLICATIONEXTENSION
        jne     .endext

        ; Application extension, 14 header bytes and subblocks follow
        add     edx, 14
        stdcall SkipSubBlocks, edx
.endext:
        return
endp


;===============================================================================
;       SkipSubBlocks
;===============================================================================
; Skips a sequence of subblocks until a block-terminator is found.
; returns a pointer to the end of the block + 1.
; lpStart points to the start of the subblocks
;
proc SkipSubBlocks, lpStart
begin
        mov     eax, [lpStart]
        xor     ecx, ecx
.skiploop:
        mov     cl, [eax]       ; get size of subblock
        test    cl, cl
        jz      .endloop   ; size=0 means terminator
        inc     eax
        add     eax, ecx        ; add size to pointer
        jmp     .skiploop

.endloop:
        inc     eax
        return
endp


DispSize 'GifLib', $ - GifLib
 