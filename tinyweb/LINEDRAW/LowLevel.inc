;###########################################################################
;###########################################################################
; ABOUT LowLevel.inc:
;
; Description:
;	This include file contains ASM prototypes for routines to handle
;	the low level drawing stuff. These routines are meant to be used
;	from a C/C++ program, but can be used from assembly with this
;	include file.
;
;	NOTE: Each routine should be in a different assembly language 
;	source file. This is so when the linker links the libarary to the 
;	C project it will only pull in the functions that are used instead
;	of the entire library.
;
; Author: Chris Hobbs
;
; Date: 10-10-02
;
;###########################################################################
;###########################################################################

;########################################################################
; PROTOTYPES
;########################################################################

	;===================================
	; Line Drawing Fucntions
	;===================================
	DrawLine32		PROTO C :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

;########################################################################
; END PROTOTYPES
;########################################################################