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
