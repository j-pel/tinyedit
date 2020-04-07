; Simple FASM OOP Model
;  File: Macro definitions for basic OOP
;  Home: as.modshack.co.uk

;--- REVISIONS ---
; ver. 0.0.1 - 25.03.2004 - pelaillo:
;   First working version
;.
;--- INSTRUCTIONS ---
; Please address comments and improvements
; on board.flatassembler.net
;
; This is a very early implementation of
; Object Oriented Programming in FASM
; The goal is to avoid overhead while
; keeping it simple. 
; Basic encapsulation, inheritance and
; polymorphism are supported but
; there are not control mechanisms nor
; verifications. User must keep implementation
; safely.
;
; ebx is used to keep an instance of the object
; in memory.
;
; Macros:
; new object,class,[args]
;   Call procedure class.create with args
;   ebx points to instance in memory
;   object variable is related to instance
;
; e.g.
;   new  dog,Animal
;   new  cat,Animal
;   objc dog.bites,cat
;	objc cat.jump,tree
;   objc dog.drink,water
;.

macro new object,class,[args]
 {
	call class#.Create,args
	mov  [object],ebx
	OBJ.object fix class#.
 }

macro objc object,method,[args]
 {
	mov  ebx,[object]
	call OBJ.object#method,args
 }

; These macros are under work, do not use
; them yet:

macro prop object,property,value
 {
;	mov  ebx,[object]
	mov  [ebx+OBJ.object#property],value
 }

macro getp reg,object,property
 {
;	mov  ebx,[object]
	mov  reg,[ebx+OBJ.object#property]
 }

