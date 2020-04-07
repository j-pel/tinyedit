; Studies for MenuetOS Tiny Browser
;  File: HTML manipulation class
;  Home: as.modshack.co.uk

struct TABLE_CLASS
  .Type       = TBW_TABLE
  .Handle	dd 0
  .Source	dd 0
  .Props	dd 0
  .Content	dd 0
ends

struct TR_CLASS
  .Type       = TBW_TR
  .Handle     dd 0
  .Source     dd 0
  .Props      dd 0
  .Content    dd 0
ends

struct TD_CLASS
  .Type       = TBW_TD
  .Handle     dd 0
  .Source     dd 0
  .Props      dd 0
  .Content    dd 0
ends

proc TABLE_CLASS.Create
	
	call	Alloc,TABLE_CLASS.size
	mov	ebx,eax
	mov	[ebx+TABLE_CLASS.Handle],eax
	mov	[ebx+TABLE_CLASS.Source],edi
	mov	[ebx+TABLE_CLASS.Props],esi
	mov	[ebx+TABLE_CLASS.Type],TBW_TABLE
	call  SeekToEndTag
	return
endp

proc TABLE_CLASS.Destroy
	
	xor eax,eax
	return
endp

proc TABLE_CLASS.Render
	
	xor eax,eax
	return
endp

proc TR_CLASS.Create
	
	call	Alloc,TR_CLASS.size
	mov	ebx,eax
	mov	[ebx+TR_CLASS.Handle],eax
	mov	[ebx+TR_CLASS.Source],edi
	mov	[ebx+TR_CLASS.Props],esi
	call	SeekToEndTag
	return
endp

proc TD_CLASS.Create
	
	call Alloc,TD_CLASS.size
	mov ebx,eax
	mov [ebx+TD_CLASS.Handle],eax
	mov [ebx+TD_CLASS.Source],edi
	mov [ebx+TD_CLASS.Props],esi
	call  SeekToEndTag
	return
endp
