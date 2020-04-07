; Studies for MenuetOS Tiny Browser
;	File: HTML manipulation class
;	Home: as.modshack.co.uk

struct HEAD_CLASS
  .Type	= TBW_HEAD
  .Handle	dd 0
  .Title	dd 0
  .Source	dd 0
  .Props	dd 0
;	.Functions	= 3
;	.Properties = 4
;	rd .Properties*4
ends

struct TITLE_CLASS
  .Type	= TBW_TITLE
  .Handle	dd 0
  .Content	dd 0
  .Source	dd 0
  .Props	dd 0
;	.Functions	= 3
;	.Properties = 4
;	rd .Properties*4
ends

proc HEAD_CLASS.Create
	call	Alloc,HEAD_CLASS.size
	mov	ebx,eax
	mov	[ebx+HEAD_CLASS.Handle],eax
	mov	[ebx+HEAD_CLASS.Source],edi
	mov	[ebx+HEAD_CLASS.Props],esi
	call	SeekToEndTag
	return
endp

proc TITLE_CLASS.Create
	call	Alloc,HEAD_CLASS.size
	mov	ebx,eax
	mov	[ebx+TITLE_CLASS.Handle],eax
	mov	[ebx+TITLE_CLASS.Source],edi
	mov	[ebx+TITLE_CLASS.Props],esi
	
	; Under construction:
	; There is needed a html string conversion
	; routine to manage special formatting.
	; The following is a very simplified stripper

	call	SeekPastEndTag
 	call	SkipWhitespace
	mov	[ebx+TITLE_CLASS.Content],esi
	mov	edx,esi
	call	SeekToEndTag
	push	esi
  .trim:
	dec	esi
	cmp	byte [esi],' '
	je	.trim
	cmp	byte [esi],09h
	je	.trim
	cmp	byte [esi],0Dh
	je	.trim
	cmp	byte [esi],0Ah
	je	.trim
	inc	esi
	mov	byte [esi],0
	mov	eax,esi
	sub	eax,edx
	mov	byte [edx-1],al ; string size
	pop	esi
	call	SeekToEndTag
	return
endp
