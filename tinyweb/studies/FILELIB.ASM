file_handler:
 .position=0
 .size=4
 .flags=8
 .operation=12
 .first_block=16
 .n_blocks=20
 .bufer=24
 .work_area=28
 .name=32
 .st_size=132

open: ;esi=name_string
      ;retorna eax
	pushad
	push dword [work_area]
	mov ecx,512 ;bufer
	call malloc
	push edi
	mov ecx,file_handler.st_size
	call mallocz
	pop dword[edi+file_handler.bufer]
	pop dword[edi+file_handler.work_area]
	mov [esp+28],edi
	mov ecx,100
	add edi,file_handler.name
	call movedata
	mov edi,[esp+28]
	mov dword[edi+file_handler.n_blocks],1
	mov dword[edi+file_handler.flags],1
	mov  eax,58
	lea  ebx,[edi+file_handler.operation]
	push edi
	int  0x40
	pop edi
	test eax,eax
	jnz close.b
	mov [edi+file_handler.size],ebx
	clc
	popad
	ret

close:
	pushad
     .b:
	mov eax,[esp+28]
	mov edi,[eax+file_handler.bufer]
	call free
	mov edi,[eax+file_handler.work_area]
	call free
	mov edi,eax
	call free
	popad
	xor eax,eax
	ret

read:     ;(f,bufer,nbytes)  eax,edi,ecx ncr retorna bytes leidos en cx y cf si error
	pushad
	mov edx,[eax+file_handler.size]
	sub edx,[eax+file_handler.position]
	cmp edx,ecx
	jnc .nb_ok
	mov ecx,edx
	mov [esp+24],edx
      .nb_ok:
	push ecx
	push edi
	mov dword [eax+file_handler.operation],0
    .inicio:
	test byte[eax+file_handler.flags],1
	jz .readblocks
	mov ecx,[eax+file_handler.position]
	mov edx,ecx
	shr ecx,9
	cmp ecx,[eax+file_handler.first_block]
	jne .readblocks
	mov esi,[eax+file_handler.bufer]
	and edx,511
	mov ecx,512
	add esi,edx
	mov edi,[esp]
	sub ecx,edx
	cmp ecx,[esp+4]
	jna .l1
	mov ecx,[esp+4]
      .l1:
	add [eax+file_handler.position],ecx
	sub [esp+4],ecx
	add [esp],ecx
	call movedata
.readblocks:
	mov ecx,[esp+4]
	shr ecx,9
	jz .ultimo
	and byte[eax+file_handler.flags],0feh
	mov [eax+file_handler.n_blocks],ecx
	mov ecx,[eax+file_handler.position]
	shr ecx,9
	mov [eax+file_handler.first_block],ecx
	mov edi,[esp]
	xchg edi,[eax+file_handler.bufer]
	push edi
		lea ebx,[eax+file_handler.operation]
		mov  eax,58
		int  0x40
	pop edi
	cmp eax,0fffffff0h
	jnc .end
	mov eax,[esp+8+28]
	xchg edi,[eax+file_handler.bufer]
	mov ecx,[eax+file_handler.n_blocks]
	shl ecx,9
	sub [esp+4],ecx
	add [esp],ecx
	add [eax+file_handler.position],ecx
     .ultimo:
	mov ecx,[esp+4]
	and ecx,511
	jz .end
	mov edx,[eax+file_handler.position]
	shr edx,9
	mov dword[eax+file_handler.first_block],edx
	mov dword [eax+file_handler.n_blocks],1
	lea ebx,[eax+file_handler.operation]
	mov  eax,58
	int  40h
	cmp eax,0fffffff0h
	jnc .end
	mov eax,[esp+28+8]
	or byte[eax+file_handler.flags],1
	jmp .inicio
     .end:
	pop edi
	pop ecx
	sub [esp+24],ecx
	popad
	ret

   .error:
	add esp,8
	popad
	xor ecx,ecx
	stc
	ret

ftell:  mov edx,[eax+file_handler.position]
	ret
lseek: ;eax=file edx=pos
	mov [eax+file_handler.position],edx
	ret
skip:   ;eax=file edx=bytes to skip
	add [eax+file_handler.position],edx
	ret




