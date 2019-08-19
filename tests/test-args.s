.include "telestrat.inc"

.include "kernel/src/include/kernel.inc"
.include "kernel/src/include/memory.inc"
.include "kernel/src/include/process.inc"
;

.include "shell/src/include/bash.inc"
.include "shell/src/include/orix.inc"

; .reloc nécessaire parce que le dernier segment de orix.inc est .bss et qu'il
; y a des .org xxxx dans les fichiers .inc...
.reloc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.include "macros/SDK.mac"
.include "include/SDK.inc"


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
.export _argc
.export _argv

;----------------------------------------------------------------------
;				ORIXHDR
;----------------------------------------------------------------------
MODULE __MAIN_START__, __MAIN_LAST__, _main

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
	;lda #<BUFEDT
	;ldy #>BUFEDT
	strlen BUFEDT
	iny				; Longueur de BUFEDT +1 pour le \0 final
	tya

;	jsr PrintRegs
;	print CRLF

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

	jsr PrintRegs
	print CRLF

	malloc (userzp+4)

	sta _argv			; Sauvegarde le pointeur malloc
	sty _argv+1

	jsr PrintRegs
	print CRLF

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
;	lda userzp
;	ldy userzp+1
;	sta RES
;	sty RES+1

;	lda userzp+2
;	ldy userzp+3
;	sta RESB
;	sty RESB+1

;	jsr _init_argv
	init_argv (_argv), (userzp+2)

	; --------------------------------------------------------------------
	;			Initialise AY et X
	; --------------------------------------------------------------------
;	tax				; Nombre d'arguments
;	lda RES			; Adresse ARGV[]
;	ldy RES+1

	; --------------------------------------------------------------------
	;			Programme de test
	; --------------------------------------------------------------------

	jsr PrintRegs
	print CRLF

	ldx _argc

  @loop:
  	print ARGN
	txa
	jsr PrintHexByte
	print #' '

;	lda userzp
;	ldy userzp+1
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

