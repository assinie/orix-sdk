;----------------------------------------------------------------------
;			cc6 includes
;----------------------------------------------------------------------
.include "telestrat.inc"

;----------------------------------------------------------------------
;			Orix Kernel includes
;----------------------------------------------------------------------
.include "kernel/src/include/kernel.inc"
.include "kernel/src/include/memory.inc"
.include "kernel/src/include/process.inc"
;.include "kernel/src/orix.inc"


;----------------------------------------------------------------------
;			Orix Shell includes
;----------------------------------------------------------------------
.include "shell/src/include/bash.inc"
.include "shell/src/include/orix.inc"


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
.segment "CODE"
.import _init_argv
.import _get_argv
.import _strcpy
.import _strlen

; From debug
.import PrintHexByte
.import PrintRegBits
.import PrintRegs

; From sopt
.import spar1
.import sopt1

.zeropage
.import cbp

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export _main
;.export _argc
;.export _argv

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

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.zeropage
t1 := userzp+12
t2 := userzp+14
t3 := userzp+16
t4 := userzp+18

;----------------------------------------------------------------------
;				Programme
;----------------------------------------------------------------------
.segment "CODE"
spar := spar1
sopt := sopt1

_main:
        ; rts
;        print BUFEDT
        BRK_ORIX XCRLF

        lda #>(BUFEDT+4)
        ldy #<(BUFEDT+4)
        jsr sopt
        .asciiz "DONT?"

        bcs err

        ; Sauvegarde le pointeur sur la ligne de commande
        ; Pour spar
        pha
        tya
        pha

        ; Affiche la valeur du code de retour en hexa (masque des options)
        txa
        and #08
	beq *+5
        jmp DisplayHelp

        txa
        jsr PrintHexByte
        print #' ', NOSAVE
;        lda #' '
;        BRK_ORIX XWR0

        ; Affiche la valeur du code de retour en bits (masque des options)
	; Buffer
	lda #<msgBuffer
	ldy #>msgBuffer
	sta RES
	sty RES+1
	; Masque
	lda #<msg_opts
	ldy #>msg_opts
        ;txa
        jsr PrintRegBits
;        lda #' '
;        BRK_ORIX XWR0

	txa
        pha             ; Sauvegarde X car détruit par XCRLF
        BRK_ORIX XCRLF
        pla             ; Restaure X
        tax

        ; Restaure le pointeur sur la ligne de commande
        pla
        tay
        pla
        ;lda #>(BUFEDT+4)
        ;ldy #<(BUFEDT+4)
        ; X:    b7: 1->décimal, 0->hexa
        ;       b6: 1-> '+'
        ;       b5: 1-> no clear
        ;
        ; Pas de tests sur la valeur maximale d'une valeur
        ; (fait un modulo 65536, ie: 123456 -> 1234 en hexa, 123456 -> 57920 en décimal)
        ;
;        ldx #$c0                ; +n,m
;        ldx #$80                ; n,m
;        ldx #$20                ; n,m no clear
;        ldx #$A0                ; n,m no clear
;        ldx #$E0                ; +n,m no clear
;        ldx #$00                ; n,m
;        ldx #($80+$40+$20)      ; +n,m no clear
        jsr spar
        .byte t1, t2, t3, 0
        bcs err

        ; Sauvegarde le pointeur sur la ligne de commande
        ; Pour affichage plus tard
        pha
        tya
        pha

        ; Affiche la valeur du code de retour en hexa (masque des valeurs)
        txa
        jsr PrintHexByte
        print #' ', NOSAVE
;        lda #' '
;        BRK_ORIX XWR0

        ; Affiche la valeur du code de retour en bits (masque des options)
	;RES est déjà à la bonne valeur
	lda #<msgBuffer
	ldy #>msgBuffer
	sta RES
	sty RES+1
	lda #<msg_vars
	ldy #>msg_vars
        ;txa
        jsr PrintRegBits
        print #' ', NOSAVE
;        lda #' '
;        BRK_ORIX XWR0
;        BRK_ORIX XCRLF

        ; Affiche la valeur de t1
        lda t1+1
        jsr PrintHexByte
        lda t1
        jsr PrintHexByte

        print #' ', NOSAVE
;        lda #' '
;        BRK_ORIX XWR0

        ; Affiche la valeur de t2
        lda t2+1
        jsr PrintHexByte
        lda t2
        jsr PrintHexByte

        print #' ',NOSAVE
;        lda #' '
;        BRK_ORIX XWR0

        ; Affiche la valeur de t3
        lda t3+1
        jsr PrintHexByte
        lda t3
        jsr PrintHexByte

        pla
        tay
        pla
        jsr DisplayCmdLine

@fin:
;        BRK_ORIX XCRLF

        rts

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
err:
        pha
        print errormsg, NOSAVE
        pla
        jsr PrintHexByte
;        BRK_ORIX XCRLF

;        lda cbp
;        ldy cbp+1
        jmp DisplayCmdLine

;        BRK_ORIX XCRLF
;        rts

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
DisplayHelp:
        print helpmsg, NOSAVE
        ; Dépile le pointeur sur la ligne de commande
        pla
        pla
        rts

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
DisplayCmdLine:
;        lda #' '
;        BRK_ORIX XWR0
        BRK_ORIX XCRLF
        BRK_ORIX XCRLF

        ; Affiche la position courante dans la ligne de commande
;        pla
;        tay
;        pla

;        tax
;        tya
        lda cbp+1
        jsr PrintHexByte
;        txa
        lda cbp
        jsr PrintHexByte

        print #':', NOSAVE
;        BRK_ORIX XCRLF

        ; Affiche la fin de la ligne de commande

        print (cbp), NOSAVE
        BRK_ORIX XCRLF
    rts

;----------------------------------------------------------------------
;				DATAS
;----------------------------------------------------------------------
.segment "RODATA"
helpmsg:
    .byte $0a, $0d
    .byte   "sopt test utility", $0a, $0a, $0d
    .byte   "Syntax  : sopt [-DONT?] [+[v1,v2,v3]]", $0a, $0a, $0d
    .byte   "Options : -D : Decimal values (default: hexa)", $0a, $0d
    .byte   "          -O : Optional values (default mandatory)", $0a, $0d
    .byte   "          -N : No variables clear (default: clear)", $0a, $0d
    .byte   "          -T : nothing :)", $0a, $0d
    .byte   "          -? : display this message", $0a, $0d
    .byte   "Notes   : Optional values need a '+' in front of the first one",$0a, $0d
    .byte   "          If mandatory, at least 1 value must be present", $0a, $0d
    .byte $00

errormsg:
    .asciiz "Erreur de parametres: "

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.segment "DATA"
msg_vars:
    .asciiz "123xxxxx"

msg_opts:
    .asciiz "dont?xxx"

msgBuffer:
    .asciiz "++++++++"


