In small 128/512 bytes intro for DOS...


code:--------------------------------------------------------------------------------
;cx-X0
;dx-Y0
;si-X1
;bx-Y1
proc DrawLine
		imul	di,dx,XSize
		add	di,cx		; DI = X + Y * XSize
		sub	si,cx
		jge	dlXGr
		neg	si		; |dX|
		std			; mX = -1
dlXGr:		mov	bp,XSize	; mY = XSize
		sub	bx,dx
		jge	dlYGr
		neg	bx		; |dY|
		neg	bp		; mY = -XSize
dlYGr:		xor	dx,dx		; U=0
		cmp	si,bx		; |dX|<|dY|
		jl	dlDYGr
		mov	cx,si		; cx=|dX|
		inc	cx
dlLopX: 	stosb			; DI += mX
		sub	dx,bx		; U -= |dY|
		jge	dlOnlX
		add	di,bp		; DI += mY
		add	dx,si		; U += |dX|
dlOnlX: 	loop	dlLopX
		cld
		ret
dlDYGr: 	mov	cx,bx		; cx=|dY|
		inc	cx
dlLopY: 	mov	[es:di],al
		add	di,bp		; DI += mY
		sub	dx,si		; U -= |dX|
		jge	dlOnlY
		scasb			; DI += mX
		add	dx,bx		; U += |dY|
dlOnlY: 	loop	dlLopY
		cld
		ret
endp
--------------------------------------------------------------------------------


For linear interpolation may be used MMX:

code:--------------------------------------------------------------------------------
macro LineMMX
	movq	mm0,[p0]	; {y0,x0}
	movq	mm1,[p1]	; {y1,x1}
	movq	mm3,mm0
	pcmpeqd mm7,mm7
	psrld	mm7,31
	pcmpgtd mm3,mm1
	por	mm3,mm7 	; {sign(y1-y0),sign(x1-x0)}
	psubd	mm1,mm0
	movq	mm2,mm1
	psrad	mm2,31
	pxor	mm1,mm2
	psubd	mm1,mm2 	; {abs(y1-y0),abs(x1-x0)}
	pxor	mm7,mm7
	movq	mm5,mm3
	punpckldq mm5,mm7	; {addY,0}
	punpckhdq mm7,mm3	; {0,addX}
	movq	mm4,mm1
	punpckhdq mm4,mm4
	movd	ecx,mm1 	; dX
	movd	edx,mm4 	; dY
	cmp	ecx,edx
	jl	@@YL
macro _Line dXc, dYy, addX, addY
local @@lp,@@u
	push	dXc
	add	dYy,dYy
	mov	eax,dYy
	sub	eax,dXc 	; u=2*dY-dX
	lea	ebx,[dXc+dXc]
@@lp:	movq	[edi+8*dXc],mm0
	add	eax,dYy 	; u=u+2*dY
	jle	@@u
	sub	eax,ebx 	; u=u-2*dX
	paddd	mm0,addY	; p=p+{addY,0}
@@u:	paddd	mm0,addX	; p=p+{0,addX}
	dec	dXc
	jns	@@lp
	pop	eax
	inc	eax
	ret
endm
	_Line ecx,edx,mm5,mm7
@@YL:	_Line edx,ecx,mm7,mm5
endm
