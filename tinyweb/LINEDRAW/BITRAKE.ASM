; X increases with each loop

GRADIENT_Y	EQU <eax>
COLOR		EQU <ebx>
INDEX		EQU <ecx>
TEMP		EQU <edx>
BUFFER		EQU <edi>
PITCH		EQU <esi>
DELTA_YoX	EQU <ebp>

; INDEX = x2 - x1 ; x2 < x1
; BUFFER = {memory} + y2 - INDEX
; DELTA_YoX = 2^32 * [ ABS(y1-y2) / (x1-x2) ]
; GRADIENT_Y = 0
; PITCH = -pitch if y2 < y1 else pitch
_3:
	add GRADIENT_Y, DELTA_YoX
	sbb TEMP, TEMP

	mov [BUFFER + INDEX*4], COLOR

	and TEMP, PITCH
	inc INDEX

	lea BUFFER, [BUFFER + TEMP]
	jne _3




; Y increase / decreases with each loop

GRADIENT_X	EQU <eax>
COLOR		EQU <ebx>
INDEX		EQU <ecx>
BUFFER		EQU <edi>
PITCH		EQU <esi>
DELTA_XoY	EQU <ebp>

; INDEX = x2 - x1 ; x2 < x1
; BUFFER = {memory} + y2 - INDEX
; DELTA_XoY = 2^32 * [ ABS(x1-x2) / (y1-y2) ]
; GRADIENT_X = 0
; PITCH = -pitch if y2 < y1 else pitch
_3:
	mov [BUFFER + INDEX*4], COLOR
	add BUFFER, PITCH

	add GRADIENT_X, DELTA_XoY
	adc INDEX, 0
	jne _3


;#############################
; Anti-Aliased Versions:

; Blend two pixels, writing the result in the destination
Pixel_Blend MACRO Dest, Source
ENDM

; X increases with each loop

GRADIENT_Y	EQU <eax>
COLOR		EQU <ebx>
INDEX		EQU <ecx>
TEMP		EQU <edx>
BUFFER		EQU <edi>
PITCH		EQU <esi>
DELTA_YoX	EQU <ebp>

; INDEX = x2 - x1 ; x2 < x1
; BUFFER = {memory} + y2 - INDEX
; DELTA_Y = 2^32 * [ ABS(y1-y2) / (x1-x2) ]
; GRADIENT_Y = 0
; PITCH = -pitch if y2 < y1 else pitch
_3:
	add GRADIENT_Y, DELTA_YoX
	sbb TEMP, TEMP

mov COLOR_A, GRADIENT_Y
and COLOR_A, 0FF000000h
or COLOR_A, COLOR
push COLOR_A
xor COLOR_A, 0FF000000h

Pixel_Blend [BUFFER + INDEX*4], COLOR_A

pop COLOR_A
lea TEMP_2, [BUFFER + PITCH]
Pixel_Blend [TEMP_2 + INDEX*4], COLOR_A

	and TEMP, PITCH
	inc INDEX

	lea BUFFER, [BUFFER + TEMP]
	jne _3


