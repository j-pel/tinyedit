;###########################################################################
;###########################################################################
; ABOUT DrawLine32.asm:
;
; Description:
;	This source file contains the routine to draw a line on a 32-bit
;	surface.
;
; Author: Chris Hobbs
;
; Date: 10-10-02
;
;###########################################################################
;###########################################################################


;#######################################################################
;#######################################################################
; COMPILER OPTIONS
;#######################################################################
;#######################################################################

	;=======================================================
	; Case Sensitive, Extended Registers, Standard Calling
	; Convention, and Flat memory model
	;=======================================================
	.386
	.model flat, stdcall
	option casemap :none   


;#######################################################################
;#######################################################################
; INCLUDES
;#######################################################################
;#######################################################################

	;========================================================
	; Include our own prototypes, in case we ever need them
	;========================================================
	include LowLevel.inc


;########################################################################
; END INCLUDES
;########################################################################


;########################################################################
; GLOBALS AND EQUATES
;########################################################################
.data


;########################################################################
; END GLOBALS AND EQUATES
;########################################################################



;#################################################################################
;#################################################################################
; BEGIN THE CODE SECTION
;#################################################################################
;#################################################################################
.code

;########################################################################
; DrawLine32 Procedure
;########################################################################
DrawLine32 proc	C x1 :DWORD, y1 :DWORD, x2 :DWORD, y2 :DWORD, color :DWORD, buffer :DWORD, pitch :DWORD

	;==================================================================
	; This function draws a line on the given buffer from (x1,y1) to
	; (x2,y2). The pitch of the line is the number of BYTES needed
	; to get to the same x coordinate on the next scan line (y 
	; coordinate) of the buffer.
	;
	; All coordinates should be valid within the buffer. This routine 
	; does not perform clipping.
	;
	; This routine uses an optmized version of the Bresenham 
	; algorithm to draw the line.
	;
	; Speed:
	;	- 1k long diagonal line drawn at:
	;	- Random lines are drawn at:
	;
	; NOTE: These speeds are rough approximations and may vary machine
	;	to machine.
	;
	;==================================================================
	LOCAL	incX	:DWORD
	LOCAL	xStep	:DWORD

	;==================================================
	; Everything is always going to be draw top to 
	; bottom so swap the coordinates if needed
	;==================================================
	mov	ebx, y2
	mov	ecx, y1
	cmp	ebx, ecx
	jg	NoSwap
		;=======================================
		; Perform our swap of the coords since
		; y1 is greater than y2
		;=======================================
		mov	y1, ebx
		mov	y2, ecx
		mov	ebx, ecx
		push	x1
		mov	ecx, x2
		mov	x1, ecx
		pop	x2


	;===============================
	; At this point ebx has y2
	;===============================
NoSwap:
	;===================================
	; Calcuate our starting buffer 
	; position based on y1 and x1
	;===================================
	mov	eax, y1
	mov	ecx, pitch
	mul	ecx
	mov	ecx, x1
	shl	ecx, 2
	add	eax, ecx
	add	eax, buffer
	mov	esi, eax

	;=============================================
	; Calculate dy which will always be positive
	; because of the swap we performed at the 
	; start of the routine
	;=============================================
	mov	edx, ebx
	sub	edx, y1

	;=========================================
	; Calculate dx based on the line direction
	;=========================================
	mov	ebx, x2
	mov	ecx, x1
	cmp	ebx, ecx
	jge	X2Larger
		;====================================
		; x2 is smaller than x1
		;
		; Compute delta x and store -4 as
		; our x increment since the line
		; is a negative one and we are using
		; DWORDS
		;====================================
		mov	ebx, ecx
		sub	ebx, x2
		mov	incX, -4
		mov	xStep, -1
		jmp	DeltasDone

X2Larger:
		;====================================
		; x2 is larger than or equal to x1
		;
		; Compute delta x and store +4 as
		; our x increment since the line
		; is a positive one and we are using
		; DWORDS
		;====================================
		sub	ebx, ecx
		mov	incX, 4
		mov	xStep, 1

	;==============================================
	; At this point in the routine
	;	esi = buffer starting point
	;	edx = dy
	;	ebx = dx
	;==============================================
DeltasDone:

	;====================================================
	; No we can check for the special cases.  Lines that
	; are vertical, horizontal, or diagonal do not need
	; to have calculations done we already know how many
	; pixels to move in each direction
	;====================================================

	;====================================
	; Check if we have a vertical line
	;====================================
	cmp	ebx, 0
	jne	NoVertical
		;======================================
		; We have a vertical line to draw
		;======================================
		mov	ebx, color
	VertLoop:
		cmp	edx, 0
		je	VertDone
			;============================================
			; Store the color and head to the next pixel
			;============================================
			mov	DWORD PTR [esi], ebx
			dec	edx
			add	esi, pitch
		jmp	VertLoop

		;===========================
		; Done drawing the line
		;===========================
	VertDone:
		ret

	;===================================
	; The line to draw wasn't vertical
	;===================================
NoVertical:

	
	;====================================
	; Check if we have a horizontal line
	;====================================
	cmp	edx, 0
	jne	NoHorizontal
		;======================================
		; We have a horizontal line to draw
		;======================================
		mov	edx, color
	HorzLoop:
		cmp	ebx, 0
		je	HorzDone
			;============================================
			; Store the color and head to the next pixel
			;============================================
			mov	DWORD PTR [esi], edx
			dec	ebx
			add	esi, incX
		jmp	HorzLoop

		;===========================
		; Done drawing the line
		;===========================
	HorzDone:
		ret

	;===================================
	; The line to draw wasn't horizontal
	;===================================
NoHorizontal:


	;====================================
	; Check if we have a diagonal line
	;====================================
	cmp	ebx, edx
	jne	NoDiagonal
		;======================================
		; We have a diagonal line to draw
		;======================================
		mov	edx, color
		mov	eax, pitch
		add	eax, incX
	DiagLoop:
		cmp	ebx, 0
		je	DiagDone
			;============================================
			; Store the color and head to the next pixel
			;============================================
			mov	DWORD PTR [esi], edx
			dec	ebx
			add	esi, eax
		jmp	DiagLoop

		;===========================
		; Done drawing the line
		;===========================
	DiagDone:
		ret

	;===================================
	; The line to draw wasn't diagonal
	;===================================
NoDiagonal:

	;=======================================
	; If we have reached this point it
	; means we have a line that requires
	; Bresenhams algorithm in order to draw
	;=======================================

	;========================================
	; Use the flags from our compare to see
	; if we were diagonal to tell if
	; our line is x-major or y-major
	;========================================
	jl	YMajor
		;==========================================
		; The line is X Major which means we move
		; one pixel at a time along the X axis and
		; compute the best pixel to use for the Y
		; axis
		;==========================================

		;==========================================
		; Scale the Y length up by a factor of 2,
		; compute the error term and then scale
		; the Y length of by a factor of 2
		;==========================================
		shr	edx, 1
		mov	eax, edx
		sub	eax, ebx
		shr	ebx, 1

		;======================================
		; Grab our color and store in a reg
		;======================================
		mov	edi, color

		;======================================
		; Drop into our loop going from x1-x2
		;======================================
		mov	ecx, x1
	XLineLoop:
		cmp	ecx, x2
		je	XLineDone
			;===========================
			; Store the color
			;===========================
			mov	DWORD PTR [esi], edi

			;======================================
			; Is our error term greater than 0 yet
			;======================================
			cmp	eax, 0
			jl	XNotYetZero
				;================================
				; Error turned over move to next
				; Y pixel in the buffer
				;================================
				add	esi, pitch

				;===================================
				; Adjust back down by the scaled dx
				;===================================
				sub	eax, ebx
			
		XNotYetZero:
			;========================================
			; Add the scaled dy onto the error term
			;========================================
			add	eax, edx

			;==================================
			; Move to the next X coordinate
			; in our counter and the buffer
			;==================================
			add	ecx, xStep
			add	esi, incX
		jmp	XLineLoop
	XLineDone:

		;===========================
		; Plot the final pixel
		;===========================
		mov	DWORD PTR [esi], edi

		;=========================
		; Done drawing the line
		;=========================
		ret

YMajor:
		;==========================================
		; The line is Y Major which means we move
		; one pixel at a time along the Y axis and
		; compute the best pixel to use for the X
		; axis
		;==========================================

		;==========================================
		; Scale the X length up by a factor of 2,
		; compute the error term and then scale
		; the Y length of by a factor of 2
		;==========================================
		shr	ebx, 1
		mov	eax, ebx
		sub	eax, edx
		shr	edx, 1

		;======================================
		; Grab our color and store in a reg
		;======================================
		mov	edi, color

		;======================================
		; Drop into our loop going from y1-y2
		;======================================
		mov	ecx, y1
	YLineLoop:
		cmp	ecx, y2
		je	YLineDone
			;===========================
			; Store the color
			;===========================
			mov	DWORD PTR [esi], edi

			;======================================
			; Is our error term greater than 0 yet
			;======================================
			cmp	eax, 0
			jl	YNotYetZero
				;================================
				; Error turned over move to next
				; X pixel in the buffer
				;================================
				add	esi, incX

				;===================================
				; Adjust back down by the scaled dy
				;===================================
				sub	eax, edx
			
		YNotYetZero:
			;========================================
			; Add the scaled dx onto the error term
			;========================================
			add	eax, ebx

			;==================================
			; Move to the next Y coordinate
			; in our counter and the buffer
			;==================================
			inc	ecx
			add	esi, pitch
		jmp	YLineLoop
	YLineDone:

		;===========================
		; Plot the final pixel
		;===========================
		mov	DWORD PTR [esi], edi

	;======================
	; We are done drawing
	;======================
	ret

DrawLine32 ENDP
;########################################################################
; END DrawLine32
;########################################################################

;########################################################################
; END DrawLine32 Routines
;########################################################################
end