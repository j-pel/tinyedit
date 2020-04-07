
; macroinstruction for making import section

macro library [name,string]
{
  forward
	local _label
	if ~ name#.redundant
		dd RVA name,0,0,RVA _label,RVA name
	end if
  common
	dd 0,0,0,0,0
  forward
	if ~ name#.redundant
		_label db string,0
	end if
}

macro import name,[label,string]
{
  common
	name:
  forward
	if used label
		API.#label = TRUE
		if string eqtype ''
			local _label
			label dd RVA _label
		else
			label dd 80000000h + string
		end if
	end if
	common
	if $ > name
		name#.redundant = 0
		dd 0
	else
		name#.redundant = 1
	end if
  forward
	if used label & string eqtype ''
		_label dw 0
		db string,0
	end if
}
