;----------------------------------------------------------------------
;			cc65 includes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;			Orix Kernel includes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;			Orix Shell includes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;			Orix SDK includes
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Imports
;----------------------------------------------------------------------
; From userapp
.import ermtb
.importzp xtrk, psec
.import drive

.import seter1, prnamd, prfild
.import out1, crlf1

; From print1
.import print1

; From debug
.import out1, hnout1, hexout1, crlf1, print1

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export ermes

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.zeropage
	blss: .res 1

;----------------------------------------------------------------------
; Defines / Constants
;----------------------------------------------------------------------

;----------------------------------------------------------------------
; Variables et buffers
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Programme
;----------------------------------------------------------------------
.segment "CODE"
.reloc

;----------------------------------------------------------------------
;
; Entrée:
;	A: Code erreur
;		>= $80 -> erreur hardware
;	C: 0 -> pas d'erreur, 1 -> erreur
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------

.proc ermes
        bcc     erm9
        pha
        tay
        bpl     l_1              ;soft
        jsr     seter1          ;redirect to stdio
        and     #$f0
l_1:
        sta     blss
        ldy     #$ff
        bne     erm1
erm2:
        iny                     ;next message
        lda     ermtb,y
        bpl     erm2
erm1:
        iny
        lda     ermtb,y
        beq     erm10           ;end
        cmp     blss
        bne     erm2
erm10:
        iny                     ;print
        lda     ermtb,y
        bmi     erm11           ;end
        cmp     #10
        bcc     erm12
        jsr     out1
        bcc     erm10

erm12:
        sty     blss            ;subr print
        jsr     ermp
        ldy     blss
        bne     erm10

erm11:
        tay                     ;end message
        iny
        beq     l80            ;newline
        iny
        beq     l10            ;error
        iny
        beq     l_11            ;protected
        pla                     ;only number
        pha
        jsr     hexout1
l80:
        jsr     crlf1
        sec
        pla
erm9:
        rts

l10:
        jsr     print1
        .byte     " error",0
        bcc     l80

l_11:
        jsr     print1
        .byte     " protected",0
        bcc     l80

ermp:
        tay                     ;print subroutine
        dey
        beq     erm31           ;filespec
        dey
        beq     erm30           ;filename
        jsr     erspa           ;drive
        lda     drive
        jsr     hnout1
        dey
        bne     erm9
        jsr     ercol           ;read/write error
        lda     xtrk
        jsr     hexout1
        jsr     ercol
        lda     psec
        jmp     hexout1

erm30:
        jsr     prnamd          ;print filespec
        bcc     erspa
erm31:
        jsr     prfild          ;print filename
erspa:
        lda     #' '
        bne     lercol1
.endproc


ercol:
	lda #':'
lercol1:
	jmp out1


