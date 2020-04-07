; Macros for manipulation of constant
; strings and srting tables
;  Home: as.modshack.co.uk

;--- REVISIONS ---
; ver. 0.0.1 - 25.03.2004 - pelaillo:
;   First working version
;.
;--- INSTRUCTIONS ---
; Please address comments and improvements
; on board.flatassembler.net
;
; This is a simple implementation of
; constant string functions.
; The goal is to avoid using the slower
; zero terminated strings, not needed
; in assembly programming.
;.

macro CSTR [name,arg]
 {
	forward
	label name
	db arg
	name#.size = $-name
 }

macro CSTR_LIST name,[arg]
; This macro builds a named list
; containing pairs of byte sizes and tokens
 {
	local size
	common
	name:
	forward
	db size-$-1
	db arg
	label size
 }

macro CSTR_SYMBOL_TABLE name,[arg,index]
; This macro builds a named table
; containing triads of byte sizes
; token and internal symbol index 
 {
	local size
	common
	name:
	forward
	db size-$-1
	db arg
	label size
	db index
	common
	dd 0
 }

macro CSTR_JMP_TABLE name,[arg,jump]
; This macro builds a named table
; containing triads of byte sizes
; token and jump addresses 
 {
	local size
	common
	name:
	forward
	db size-$-1
	db arg
	label size
	dd reserved.#jump;-reserved
 }

macro CSTR_TABLE name,[arg]
; This macro builds a named table
; containing pairs of byte sizes and tokens
; and address table for all of them 
 {
	local size
	common
	name:
 	i = $
 	j = 0
	forward
	j = j + 1
	db size-$-1
	db arg
	label size
	common
	align 4
	name#.index = $
	name#.count = j
	forward
	dd i
	virtual at 0
		db 0
		db arg
		next = $
		i = i + next
	end virtual
 }

