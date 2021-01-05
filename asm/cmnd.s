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
.import cmnd_null
.import comtb
.import svzp

;From sopt
.importzp mode, opt, tepo
.import bufkey1
.import setcbp, seter, ermes, calposp
.import sechar

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export cmnd2

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------

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
; No command found or comment
; Entrée:
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
; A : Dernnier caractère lu ($00 si fin de ligne, $3b si ';')
; X : $02 - Constanre à vérifier
; Y : $00 - Constante à vérifier
; Z : 1
;----------------------------------------------------------------------
comf9:
	;lda #e15
	;sec
	;jmp ermes
	jmp cmnd_null
	rts

;----------------------------------------------------------------------
;
; Entrée:
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
comf2:
	jsr comf1		; execute jump
	bcs ermese		; continue if ok

;----------------------------------------------------------------------
; Continue with next command
;
; Entrée:
;	AY: Adresse du tampon d'entrée*;
; Sortie:
;	C : 1 -> Erreur
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
cmnd2:
	jsr setcbp		; command interpretation
	ldx #$00		; Index au début de la liste des commandes
	beq comnex

ermese:
	jsr seter		; set error and print message
	jmp ermes

coma:
	jsr sechar		; selete spaces
	beq comf9		; no command
	cmp #';'		; comment line
	beq comf9
	dey
coma1:
	inx
	jsr bufkey1		; get next char
	cmp comtb,x
	bne comnex		; not equal
	dec mode		; dec ness. length
	bne coma1
comc:
	jsr bufkey1		; check other not ness. char
	beq comfou		; eoln
	inx
	cmp comtb,x		; compare other command char
	beq comc
comnex:
	dex			; search next command
com20:
	inx
	lda comtb,x		; end mark
	bpl com20
	sta opt		; command mode flags
	asl opt
	inx
	ldy comtb,x		; set jump address
	sty tepo
	inx
	ldy comtb,x
	sty tepo+1
	ldy #$00		; reset line pointer
	and #$0f
	sta mode		; length
	bne coma		; if not last

comfou:
	jsr calposp
	ldx #$00
	bit opt		; command flags
	stx opt		; default option clear
	bvs comf2		; i/o file command
	bpl comf1		; no zero page save
	jsr svzp
comf1:
	jmp (tepo)


