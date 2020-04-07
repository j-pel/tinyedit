
; flat assembler interface for Win32
; Copyright (c) 1999-2003, Tomasz Grysztar.
; All rights reserved.

org 100h

macro clear reg
{
xor reg,reg
}

start:
	clear	eax
	mov	eax,\
	ebx
	mov	ebx,\
	;esi
	edi

