.export PrintRegs
.export PrintHexByte
.export PrintRegBits

.include "telestrat.inc"
.include "macros/SDK.mac"

;----------------------------------------------------------------------
; Utilitaires pour debug
;----------------------------------------------------------------------
.code

.proc PrintRegs
    sta TR0
    stx TR1
    sty TR2

    php
    pla
    sta TR3

    print msgPC, NOSAVE
    tsx
    lda $101,x

.if 0
    ; Si on veux l'adresse du jsr PrintRegs
    sec
    sbc #$02
    sta TR4
    lda $102,x
    sbc #$00
    jsr PrintHexByte
    lda TR4
    jsr PrintHexByte

.else
    ; Si on veux l'adresse de retour
    clc
    adc #$01
    sta TR4
    lda $102,x
    adc #$00
    jsr PrintHexByte
    lda TR4
    jsr PrintHexByte
.endif

    print msgRegA, NOSAVE

    lda TR0
    jsr PrintHexByte

    print msgRegX, NOSAVE
    lda TR1
    jsr PrintHexByte

    print msgRegY, NOSAVE
    lda TR2
    jsr PrintHexByte

    print msgRegP, NOSAVE

    lda TR3
    jsr PrintHexByte
    print #' ', NOSAVE

    ; Adresse du buffer
    lda #<msgBuffer
    ldy #>msgBuffer
    sta RES
    sty RES+1

    ; Adresse du masque
    lda #<msgStatusReg
    ldy #>msgStatusReg

    ; Valeur
    ldx TR3
    jsr PrintRegBits

    ; Restaure les registres
    lda TR3
    pha
    lda TR0
    ldx TR1
    ldy TR2
    plp

    rts

.rodata
msgPC:
    .asciiz "PC="
msgRegA:
    .asciiz " A="
msgRegX:
    .asciiz " X="
msgRegY:
    .asciiz " Y="
msgRegP:
    .asciiz " P="


msgStatusReg:
    ;        76543210
    .asciiz "NVxBDIZC"

.data
msgBuffer:
    .asciiz "xxxxxxxx"

.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.code
.proc PrintHexByte
    pha

    ; High nibble
    lsr
    lsr
    lsr
    lsr
    jsr Hex2Asc

    ; Low nibble
    pla
    and #$0f

Hex2Asc:
    ora #$30
    cmp #$3a
    bcc *+4
    adc #$06
    BRK_TELEMON XWR0
    rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc PrintRegBits
    ; Entrée:
    ;   X: Valeur
    ;   RES: Adresse du masque
    ;   RESB: Adresse du la chaine
    ;
    ; Sortie:
    ;   A: Inchangé
    ;   X: '-' ou 'x'
    ;   Y: $FF
    ;   RES, RESB: inchangés
    ;
    sta RESB
    sty RESB+1
    txa

    ldy #$07
@loop:
    ror
    pha
    lda #'-'
    bcc *+4
    lda (RESB),y
    sta (RES),y
    pla
    dey
    bpl @loop
    ; 1 décalage de plus pour remettre A dans son état initial
    ror

    ; Restaure les registres (sauf P)
    tax
    lda RESB
    ldy RESB+1

    print (RES)
    rts
.endproc

