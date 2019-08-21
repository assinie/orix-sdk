;----------------------------------------------------------------------
;			cc65 includes
;----------------------------------------------------------------------
.include "telestrat.inc"

;----------------------------------------------------------------------
;			Orix Kernel includes
;----------------------------------------------------------------------
; nécessaire pour KERNEL_MAX_PATH_LENGTH dans process.inc
.include "kernel/src/include/kernel.inc"

; nécessaire pour kernel_process_struct dans orix.inc
.include "kernel/src/include/process.inc"

; nécessaire pour ORIX_MALLOC_FREE_FRAGMENT_MAX dans orix.inc
.include "kernel/src/include/memory.inc"

; nécessaire pour kernel/src/orix.inc (certains labels sans ':')
.feature labels_without_colons

; nécessaire pour userzp
.include "kernel/src/orix.inc"


;----------------------------------------------------------------------
;			Orix Shell includes
;----------------------------------------------------------------------
; nécessaire pour BASH_MAX_BUFEDT_LENGTH dans shell/src/include/orix.inc
;.include "shell/src/include/bash.inc"
; nécessaire pour userzp
;.include "shell/src/include/orix.inc"


;----------------------------------------------------------------------
;			Orix SDK includes
;----------------------------------------------------------------------
.include "macros/SDK.mac"
.include "include/SDK.inc"

; .reloc nécessaire parce que le dernier segment de orix.inc est .bss et qu'il
; y a des .org xxxx dans les fichiers .inc...
.reloc

;----------------------------------------------------------------------
;				Imports
;----------------------------------------------------------------------
;.reloc
;From orix
.import _init_argv
.import _get_argv
.import _strcpy
.import _strlen

; From debug
.import PrintHexByte
.import PrintRegs

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export _main
.export _argc
.export _argv

;----------------------------------------------------------------------
;				ORIXHDR
;----------------------------------------------------------------------
; MODULE __MAIN_START__, __MAIN_LAST__, _main

;----------------------------------------------------------------------
;			Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

;----------------------------------------------------------------------
;				Programme
;----------------------------------------------------------------------
_main:

	; --------------------------------------------------------------------
	;		Placer toute cette partie dans "STARTUP"
	; --------------------------------------------------------------------
	lda #((MAX_ARGS*2)+1)
	sta userzp+2
	lda #$00
	sta userzp+3

	; --------------------------------------------------------------------
	;			Calcule la longueur de BUFEDT
	; --------------------------------------------------------------------
	strlen BUFEDT
	iny				; Longueur de BUFEDT +1 pour le \0 final
	tya

	; --------------------------------------------------------------------
	;		Alloue un tampon pour BUFEDT+ARGV
	; --------------------------------------------------------------------
	ldy #$00
	clc
	adc #((MAX_ARGS*2)+1)
	bcc *+3
	iny
	sta userzp+4
	sty userzp+5

	malloc (userzp+4)

	sta _argv			; Sauvegarde le pointeur malloc
	sty _argv+1

	; --------------------------------------------------------------------
	;		Copie de BUFEDT dans le tampon
	; --------------------------------------------------------------------
	clc				; Sauvegarde le pointeur vers la copie de BUFEDT
	adc userzp+2
	sta userzp+2
	tya
	adc userzp+3
	sta userzp+3

	strcpy (userzp+2), BUFEDT		; Copie BUFEDT dans le tampon

	; --------------------------------------------------------------------
	;		Initialise la structure ARGV
	; --------------------------------------------------------------------
	init_argv (_argv), (userzp+2)


	; ====================================================================
	;			Programme de test
	; ====================================================================

	;jsr PrintRegs
	;print CRLF

	ldx _argc

  @loop:
  	print ARGN
	txa
	jsr PrintHexByte
	print #' '

	get_argv
	; bcc @end

	stx userzp+4

	.byte $00, XWSTR0
	print CRLF

	ldx userzp+4
	dex
	bpl @loop

	; --------------------------------------------------------------------
	;			Libère ARGV
	; --------------------------------------------------------------------
  @end:
	mfree (_argv)

	rts


;----------------------------------------------------------------------
;				DATAS
;----------------------------------------------------------------------
.segment "RODATA"
CRLF:
	.byte $0d,$0a,$00

ARGN:
	.asciiz "Arg "

;----------------------------------------------------------------------
;		Placer ces variables dans la librairie
;----------------------------------------------------------------------
.segment "DATA"
_argc:
	.res 1
_argv:
	.res 2

