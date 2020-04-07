; Studies for MenuetOS Tiny Browser
;	File: HTML manipulation class
;	Home: as.modshack.co.uk

TBW_SYMBOL_SIZE	= 1 ; size in bytes

; Internal symbol constants
TBW_NONE		= 0
TBW_HTML		= 1
TBW_HEAD		= 2
TBW_BODY		= 3
TBW_TITLE		= 4
TBW_P			= 5
TBW_TABLE		= 6
TBW_TR		= 7
TBW_TD		= 8

include 'head.inc'
include 'body.inc'
include 'table.inc'

struct HTML_CLASS
  .Type	= TBW_HTML
  .Handle	dd 0
  .FileName	dd 0
  .FileSize	dd 0
  .Source	dd 0
  .Head	dd 0
  .Body	dd 0
  .Style	dd 0

;	.Name	dd 0
;	.Child	dd 0
;	.Object	dd 0

;	.Create	= HTML_CLASS.Create
;	.Destroy	= HTML_CLASS.Destroy
;	.Render	= HTML_CLASS.Render
;	.ReadIt	= HTML_CLASS.ReadIt
;	.Functions	= 4
;	.Properties = 4
;	rd .Properties*4
ends

proc HTML_CLASS.Create,filename
	call	Alloc,HTML_CLASS.size
	or	eax,eax
	je	.mem_error
	mov	ebx,eax
	mov	[ebx+HTML_CLASS.Handle],eax
	mov	eax,[filename]
	mov	[ebx+HTML_CLASS.FileName],eax
	lea	ecx,[ebx+HTML_CLASS.FileSize]
	call	LoadSource,eax,ecx
	or	eax,eax
	je	.read_error
	mov	[ebx+HTML_CLASS.Source],eax
	return
  .read_error:
	call	HTML_CLASS.Destroy
  .mem_error:
	return
endp

proc HTML_CLASS.Destroy
	call	Free,[ebx+HTML_CLASS.Source]
	xor	eax,eax
	return
endp

proc HTML_CLASS.GetTitle
	mov	eax,[ebx+HTML_CLASS.Head]
	mov	eax,[eax+HEAD_CLASS.Title]
	mov	eax,[eax+TITLE_CLASS.Content]
	return
endp

proc HTML_CLASS.Render,hdc
  .rc 		RECT
  .pen_dark		dd ?
  .pen_light	dd ?
  .this		dd ?
	enter
	mov	[.this],ebx
	mov	ebx,[hdc]

	call	CreatePen,PS_SOLID,1,0FF0000h
	mov	[.pen_dark],eax
	call	SelectObject,ebx,eax
	call	MoveToEx,ebx,5,200,NULL
	call	LineTo,ebx,5,75
	call	LineTo,ebx,630,75
	call	CreatePen,PS_SOLID,1,0FFh
	mov	[.pen_light],eax
	call	SelectObject,ebx,eax
	call	LineTo,ebx,630,200
	call	LineTo,ebx,5,200
	
	mov	esi,[.this]
	mov	edi,[esi+HTML_CLASS.FileName]
	movzx	eax,byte [edi-1]
	call	TextOut,ebx,5,30,edi,eax

	mov	edi,[esi+HTML_CLASS.Head]
	mov	edi,[edi+HEAD_CLASS.Title]
	mov	edi,[edi+TITLE_CLASS.Content]
	movzx	eax,byte [edi-1]
	call	TextOut,ebx,5,50,edi,eax

	if DEBUGGING=0
		nop ;
		nop ; ...work in
		nop ; progress...
		nop ;
		int3
	end if

	mov	edi,[esi+HTML_CLASS.Body]
	mov	edi,[edi+BODY_CLASS.Content]
	mov	eax,[edi+P_CLASS.Type]
	cmp	eax,TBW_TABLE
	je	.is_table
	cmp	eax,TBW_P
	jne	.done
  .is_p:
	mov	edi,[edi+P_CLASS.Content]
;	movzx	eax,byte [edi-1]
	call	TextOut,ebx,10,80,is_p,is_p.size
	jmp	.done
  .is_table:
	call	TextOut,ebx,10,80,is_table,is_table.size
	mov	edi,[edi+TABLE_CLASS.Content]
;	movzx	eax,byte [edi-1]
;	call	TextOut,ebx,10,80,is_table,is_table.size
  .done:
	call	DeleteObject,[.pen_light]
	call	DeleteObject,[.pen_dark]
	mov	ebx,[.this]
	return
endp

; Important: keep these encapsulated
;	Following procedures relies on:
;	esi pointing to source file
;	ecx count remaining bytes

proc HTML_CLASS.ReadIt
	mov	esi,[ebx+HTML_CLASS.Source]
	mov	ecx,[ebx+HTML_CLASS.FileSize]
  .get_tag:
	call	GetNextTag
	cmp	eax,TBW_HTML
	je	.html
	cmp	eax,TBW_HEAD
	je	.head
	cmp	eax,TBW_TITLE
	je	.title
	cmp	eax,TBW_BODY
	je	.body
	cmp	eax,TBW_P
	je	.p
	cmp	eax,TBW_TABLE
	je	.table
	cmp	eax,TBW_TR
	je	.tr
	cmp	eax,TBW_TD
	je	.td
  .skip_props:
	call	SeekToEndTag
	return

  .html:
	call	SeekToEndTag
	jmp	.get_tag
  .head:
	push	ebx
	new	cur_head,HEAD_CLASS
	pop	ebx
	mov	[ebx+HTML_CLASS.Head],eax
	jmp	.get_tag
  .title:
	push	ebx
	new	dummy_obj,TITLE_CLASS
	pop	ebx
	mov	edx,[ebx+HTML_CLASS.Head]
	mov	eax,[dummy_obj]
	mov	[edx+HEAD_CLASS.Title],eax
	jmp	.get_tag
  .body:
	push	ebx
	new	cur_body,BODY_CLASS
	pop	ebx
	mov	eax,[cur_body]
	mov	[ebx+HTML_CLASS.Body],eax
	call	SkipWhitespace
	cmp	byte [esi],'<'
	jne	.p ; default in html is paragraph
	jmp	.get_tag
  .p:
	push	ebx
	new	dummy_obj,P_CLASS
	pop	ebx
	jmp	.get_tag
  .table:
	push	ebx
	new	dummy_obj,TABLE_CLASS
	mov	[ebx+TABLE_CLASS.Content],eax
	pop	ebx
	jmp	.get_tag
  .tr:
	push	ebx
	new	dummy_obj,TR_CLASS
	mov	[ebx+TR_CLASS.Content],eax
	pop	ebx
	jmp	.get_tag
  .td:
	push	ebx
	new	dummy_obj,TD_CLASS
	mov	[ebx+TD_CLASS.Content],eax
	pop	ebx
	call	SkipWhitespace
	cmp	byte [esi],'<'
	jne	.p ; default in html is paragraph
	jmp	.get_tag
  .other:
  .unknown:
	jmp	.get_tag
endp

proc GetNextTag
  .get_next_tag:
	mov	ah,'<'
	call	SeekPastChar
	cmp	byte [esi],'?'
	jne	.no_comment
	call	SkipComment
  .no_comment:
	cmp	byte [esi],'!'
	je	.no_tag
	cmp	byte [esi],'/'
	jne	.get_tag
  .no_tag:
	call	SeekToEndTag
	loop .get_next_tag
  .parsing_done:
	mov	eax,TBW_NONE
  .done:
	return

  .get_tag:
	mov	edx,esi
  .tag_loop:
	mov	al,[edx]
	cmp	al,' '
	je	.tag_done
	cmp	al,09h
	je	.tag_done
	cmp	al,0Ah
	je	.tag_done
	cmp	al,0Dh
	je	.tag_done
	cmp	al,'>'
	je	.tag_done
	or	al,al
	je	.tag_done
	and	al,40h	; convert to lcase
	shr	al,1	; because html is
	or	[edx],al ; case insensitive
	inc	edx
	loop .tag_loop
	jmp	.parsing_done

  .tag_done:
	sub	edx,esi
	push	ecx
	mov	edi,html_reserved_words
  .find_word_size:
	mov	al,[edi]
	or	al,al
	je	.no_more_words
	cmp	al,dl
	je	.find_keyword
  .check_another:
	movzx eax,byte[edi]
	add	edi,eax
	add	edi,TBW_SYMBOL_SIZE+1
	jmp	.find_word_size
  .find_keyword:
	xor	ecx,ecx
  .keyword_loop:
	mov	al,[esi+ecx]
	mov	ah,[edi+ecx+1]
	inc	ecx
	cmp	ecx,edx
	ja	.word_found
	cmp	al,ah
	jne	.check_another
	jmp	.keyword_loop
  .word_found:
	movzx eax,byte[edi+ecx]
	add	esi,edx
	pop	ecx
	jmp	.done
  .no_more_words:
	pop	ecx
	jmp	.parsing_done
endp

proc SeekToNextLine
  .seek:
	cmp	byte [esi],0Ah
	je	.eol
	cmp	byte [esi],0Dh
	je	.eol
	inc	esi
	loop	.seek
	jmp	.done
  .eol:
	cmp	byte [esi],0Ah
	je	.not_next
	cmp	byte [esi],0Dh
	jne	.done
  .not_next:
	inc	esi
	loop	.eol
  .done:
	return
endp

proc SkipWhitespace
	cmp	byte [esi],' '
	je	.skip
	cmp	byte [esi],09h
	je	.skip
	cmp	byte [esi],0Dh
	je	.skip
	cmp	byte [esi],0Ah
	jne	.done
  .skip:
	inc	esi
	loop	SkipWhitespace
  .done:
	return
endp

proc SkipComment
	inc	esi
	cmp	word [esi],'?>'
	je	.done
	loop SkipComment
  .done:
	return
endp

proc SeekToChar
	cmp	byte [esi],ah
	je	.done
	cmp	byte [esi],0
	je	.done
	inc	esi
	loop SeekToChar
  .done:
	return
endp

proc SeekPastChar
	dec	ecx
  .seek:
	lodsb
	cmp	al,ah
	je	.done
	or	al,al
	je	.done
	loop .seek
  .done:
	return
endp

proc SeekToWhitespace
	dec	ecx
  .seek:
	lodsb
	cmp	al,' '
	je	.done
	cmp	al,09h
	je	.done
	cmp	al,0Ah
	je	.done
	cmp	al,0Dh
	je	.done
	cmp	al,ah
	je	.done
	or	al,al
	je	.done
	loop .seek
  .done:
	return
endp

proc SeekToEndTag
  .seek:
	cmp	byte [esi],'>'
	je	.done
	cmp	byte [esi],'<'
	je	.done
	cmp	byte [esi],0
	je	.done
	inc	esi
	loop .seek
  .done:
	return
endp

proc SeekPastEndTag
  .seek:
	lodsb
	cmp	al,'>'
	je	.done
	cmp	al,'<'
	je	.done
	cmp	al,0
	je	.done
	loop .seek
  .done:
	return
endp

; NOTE: static data kept in code section. 
; The follwing data is used within this class.

CSTR_SYMBOL_TABLE html_reserved_words,\
		'p',TBW_P,\
		'td',TBW_TD,\
		'tr',TBW_TR,\
		'body',TBW_BODY,\
		'head',TBW_HEAD,\
		'html',TBW_HTML,\
		'table',TBW_TABLE,\
		'title',TBW_TITLE

;; Full HTML Reserved words
		
;CSTR_SYMBOL_TABLE html_reserved_words,\
;\;		'a',a,\
;\;		'b',other,\
;\;		'i',other,\
;		'p',TBW_P,\
;\;		'q',other,\
;\;		's',other,\
;\;		'u',other,\
;\;		'br',other,\
;\;		'dd',other,\
;\;		'dl',other,\
;\;		'dt',other,\
;\;		'em',other,\
;\;		'h1',other,\
;\;		'h2',other,\
;\;		'h3',other,\
;\;		'h4',other,\
;\;		'h5',other,\
;\;		'h6',other,\
;\;		'hr',other,\
;\;		'li',other,\
;\;		'ol',other,\
;		'td',TBW_TD,\
;\;		'th',other,\
;		'tr',TBW_TR,\
;\;		'tt',other,\
;\;		'ul',other,\
;\;		'bdo',other,\
;\;		'big',other,\
;\;		'col',other,\
;\;		'del',other,\
;\;		'dfn',other,\
;\;		'dir',other,\
;\;		'div',other,\
;\;		'img',other,\
;\;		'ins',other,\
;\;		'kbd',other,\
;\;		'map',other,\
;\;		'pre',other,\
;\;		'sub',other,\
;\;		'sup',other,\
;\;		'var',other,\
;\;		'abbr',other,\
;\;		'area',other,\
;\;		'base',other,\
;		'body',TBW_BODY,\
;\;		'cite',other,\
;\;		'code',other,\
;\;		'font',other,\
;\;		'form',other,\
;		'head',TBW_HEAD,\
;		'html',TBW_HTML,\
;\;		'link',link,\
;\;		'menu',menu,\
;\;		'meta',other,\
;\;		'samp',other,\
;\;		'span',other,\
;\;		'frame',other,\
;\;		'input',other,\
;\;		'label',other,\
;\;		'param',other,\
;\;		'small',other,\
;\;		'style',other,\
;		'table',TBW_TABLE,\
;\;		'tbody',other,\
;\;		'tfoot',other,\
;\;		'thead',other,\
;		'title',TBW_TITLE;,\
;\;		'applet',other,\
;\;		'button',other,\
;\;		'center',other,\
;\;		'iframe',other,\
;\;		'legend',other,\
;\;		'object',other,\
;\;		'option',other,\
;\;		'script',other,\
;\;		'select',other,\
;\;		'strike',other,\
;\;		'strong',other,\
;\;		'acronym',other,\
;\;		'address',other,\
;\;		'caption',other,\
;\;		'isindex',other,\
;\;		'basefont',other,\
;\;		'colgroup',other,\
;\;		'fieldset',other,\
;\;		'frameset',other,\
;\;		'noframes',other,\
;\;		'noscript',other,\
;\;		'optgroup',other,\
;\;		'textarea',other,\
;\;		'blockquote',other

;CSTR_SYMBOL_TABLE html_props,\
;		'width',width,\
;		'height',height,\
;		'border',border,\
;		'bgcolor',bgcolor,\
;		'background',background,\
;		'cellpadding',cellpadding,\
;		'cellspacing',cellspacing
;