..Open = 0

; When some procedure is not finished with 'endp' macro,
; "Unexpected end of file" error, occur without any info, where is error.
; in this case, comment following 2 rows and uncomment next two.
; proc_used and endp_used are optimized versions of the macroses.
; proc_debug and endp_debug are debug versions. When you use debug
; versions, error message will show you where is missing 'endp'.
;
; Don't forget to recompile with *_used versions, to get optimised
; binary with all not used procedure excluded.

proc fix proc_used
endp fix endp_used
;proc fix proc_debug
;endp fix endp_debug

macro proc_used name,[arg] 
{		      ; define procedure
common
  if ~ used name
;    display 'Procedure skiped: ',`name, $0d, $0a
  else
    name:
    virtual at ebp+8
      if ~ arg eq
	forward
	  local ..arg
	  ..arg dd ?
	  arg equ ..arg
	common
      end if
      ..ret = $ - (ebp+8)
    end virtual
    local ..dynamic_data,..dynamic_size
    dynamic_data equ ..dynamic_data
    dynamic_size equ ..dynamic_size
    virtual at ebp - dynamic_size
      dynamic_data:
}


macro proc_debug name,[arg] 
{		       ; define procedure
common
  if ..Open > 0
    Error! Missing 'endp' before procedure ^name
  end if

  ..Open = ..Open+1

  name:
  virtual at ebp+8
    if ~ arg eq
      forward
	local ..arg
	..arg dd ?
	arg equ ..arg
      common
    end if
    ..ret = $ - (ebp+8)
  end virtual
  local ..dynamic_data,..dynamic_size
  dynamic_data equ ..dynamic_data
  dynamic_size equ ..dynamic_size
  virtual at ebp - dynamic_size
    dynamic_data:
}

macro begin  {				 ; begin procedure instructions
      ; continue from "proc" macro.
      rb (4 - ($-dynamic_data) and 11b) and 11b ; align the stack at dword.
      dynamic_size = $ - dynamic_data
    end virtual

    if (dynamic_size = 0)
      if ..ret <> 0
	push ebp		     ; smaller is dynamic_size = 0
	mov  ebp, esp
      end if
    else
      enter dynamic_size, 0
    end if
}

macro return 
{				; return from procedure
    ; continue from "enter" macro.
    if ..ret <> 0
      leave
      ret ..ret
    else
      if dynamic_size <> 0
	leave
      end if
      ret
    end if
}

macro endp_used 
{
  end if
}

macro endp_debug 
{
  ..Open = ..Open - 1
}

macro _reversepusharg [arg] 
{
  reverse
    pushd arg
}

; Integrated call macro
; by Kevin_Zheng
macro call proc,[arg]
{
  reverse
	if  arg eq
	else
		pushd arg
	end if
  common
    if	defined API.#proc
		call [proc]
    else
		call proc
	end if
}

macro thiscall proc,object,[arg]
{ if ~ arg eq
    _reversepusharg arg
   end if
   lea ecx,[object]
   common
    call proc 
}

macro fastcall proc,arg1,arg2,[arg]
{ if ~ arg eq
   _reversepusharg arg
  end if
  if ~ arg2 eq
    mov   edx,arg2
  end if
  if ~ arg1 eq
    mov   ecx,arg1
  end if
  common
   call proc 
}

;macro stdcall proc,[arg] {		; call procedure
;common
;  if ~ arg eq
;    _reversepusharg arg
;  end if
;  call proc
;}
;
;macro invoke proc,[arg] {		; api invoke procedure (indirect)
;common
;  stdcall [proc],arg
;}
;
