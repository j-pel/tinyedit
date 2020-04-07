; Studies for MenuetOS Tiny Browser
;	File: HTML manipulation class
;	Home: as.modshack.co.uk

struct BODY_CLASS
  .Type       = TBW_BODY
  .Handle	dd 0
  .Source	dd 0
  .Props	dd 0
  .Content	dd 0
;	.Functions	= 3
;	.Properties = 4
;	rd .Properties*4
ends


struct P_CLASS
  .Type       = TBW_P
  .Handle	dd 0
  .Source	dd 0
  .Props	dd 0
  .Content	dd 0
ends

proc BODY_CLASS.Create
	
	call	Alloc,BODY_CLASS.size
	mov	ebx,eax
	mov	[ebx+BODY_CLASS.Handle],eax
	mov	[ebx+BODY_CLASS.Source],edi
	mov	[ebx+BODY_CLASS.Props],esi
	add	eax,BODY_CLASS.size
	mov	[ebx+BODY_CLASS.Content],eax
	call	SeekPastEndTag
	return
endp

proc BODY_CLASS.Destroy
	
	xor	eax,eax
	return
endp

proc BODY_CLASS.Render
	
	xor	eax,eax
	return
endp

proc P_CLASS.Create
	
	call	Alloc,P_CLASS.size
	mov	ebx,eax
	mov	[ebx+P_CLASS.Handle],eax
	mov	[ebx+P_CLASS.Source],edi
	mov	[ebx+P_CLASS.Props],esi
	mov	[ebx+P_CLASS.Type],TBW_P
	call	SeekToEndTag
	return
endp

proc P_CLASS.Destroy
	
	xor	eax,eax
	return
endp

proc P_CLASS.Render
	
	xor	eax,eax
	return
endp

