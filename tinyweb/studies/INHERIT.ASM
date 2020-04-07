include '%fasminc%\win32.inc'

struc TBase {
  .parent	dd	$
}
struct TBase

struc TCommonFile {
  . TBase
  .type 	dd	?
  .hFileName	dd	?
  .hashFileName dd	?

  .fLoaded	dd	?
  .fNeverSaved	dd	?
}
struct TCommonFile

struc TFormSource {
  . TCommonFile
  .ptrFormFile	dd	?
}
struct TFormSource

struc TBinaryForm {
  . TCommonFile
  .ptrBaseWin  dd	?	; pointer to the TBaseWin of the form.
}
struct TBinaryForm

struc TTripleForm {
  . TBinaryForm
  .ptrBaseWin  dd	?	; pointer to the TBaseWin of the form.
}
struct TTripleForm

; now you can use the structures followind way:

BinaryForm TBinaryForm

	mov	eax, [esi+TCommonFile.hFileName]
	mov	ebx, [esi+TFormSource..hFileName]
	mov	ecx, [esi+TBinaryForm..hashFileName]
	mov	esi, [esi+TBinaryForm.ptrBaseWin]
	cmp	[BinaryForm..fLoaded], FALSE

cuco TTripleForm

mov eax,[esi+TTripleForm...hFileName]