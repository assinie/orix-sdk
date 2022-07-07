;======================================================================
;
;======================================================================

;----------------------------------------------------------------------
;			cc65 includes
;----------------------------------------------------------------------
.include "telestrat.inc"
.macpack longbranch

;----------------------------------------------------------------------
;			Orix Kernel includes
;----------------------------------------------------------------------
.include "kernel/src/include/kernel.inc"
.include "kernel/src/include/ch376.inc"

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
.import PrintAY, StopOrCont
.import _ReadSector, _ReadSector2, _ReadSector3
.importzp Track, Sector

.import BUF_SECTOR
;.import NS,NP

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export sedoric_dir, sedoric_getdskInfo, sedoric_calcTrackSide
.export dir_entry		; TEMPORAIRE POUR LS

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.zeropage

;----------------------------------------------------------------------
; Variables et buffers
;----------------------------------------------------------------------
.segment "DATA"

	; Utilisé par CAT & sedoric_dir
	I: .res 1

	; Flag pour l'affichage sedoric_dir (Sedoric)
	s_odd_even: .byte 0

	DEFAFF_save: .byte ' '

	sedoric_side1_offset: .byte 0

;----------------------------------------------------------------------
;				Programme
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
; Lecture du catalogue d'une image Sedoric
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
	rts
										;sedoric_dir:
.proc sedoric_dir
	lda DEFAFF
	sta DEFAFF_save

	lda #$00
	sta s_odd_even

	BRK_KERNEL XCRLF

	lda #' '
	sta DEFAFF

	jsr sedoric_getdskInfo
	bcc getBitMap

 error:
	pha
	lda DEFAFF_save
	sta DEFAFF
	pla
	sec
	rts

 getBitMap:
	; Lecture Secteur Bitmap
	lda #20
	sta Track
										; NS = 1;
;	lda #1
;	sta NS
	ldx #1
										; BUFFER_PTR =## BUF_SECTOR;
;	lda #<BUF_SECTOR
;	sta BUFFER_PTR
;	lda #>BUF_SECTOR
;	sta BUFFER_PTR+1
	lda #<BUF_SECTOR
	ldy #>BUF_SECTOR

	jsr _ReadSector
										; IFF .A ^= #CH376_USB_INT_SUCCESS THEN CAT_End;
	;cmp #CH376_USB_INT_SUCCESS
	; Secteur non trouvé
	;bne sedoric_dir-1
	bcs error

	print drive

	; $00: Master
	; $01: Slave
	lda BUF_SECTOR+$16
	bne _slave
	print master
	jmp suite
_slave:
	print master

suite:
	lda #>BUF_SECTOR
	ldy #$09
	; Affiche le nom du volume
	ldx #$15
	jsr PrintAY

	BRK_KERNEL XCRLF


	; 1er secteur du catalogue
										; NP = 20;
	;lda #20
	;sta NP
										; NS = 4;
	lda #4
	sta Sector
										; BUFFER_PTR =## BUF_SECTOR;
;	lda #<BUF_SECTOR
;	sta BUFFER_PTR
;	lda #>BUF_SECTOR
;	sta BUFFER_PTR+1
										; REPEAT;
ZZ0014:
										; DO;
										; CALL _ReadSector; " Dure environ 62000 cycles";
	jsr _ReadSector3
										; IFF .A ^= #CH376_USB_INT_SUCCESS THEN sedoric_dir_End;
	;cmp #CH376_USB_INT_SUCCESS
	; Secteur non trouvé
	;bne sedoric_dir-1
	bcs error
	; Traitement du secteur du catalogue
										; I = 16;
	lda #16
	sta I
										; REPEAT;
ZZ0015:
										; DO;
										; CLEAR .C;
	clc
										; .A+13;
	adc #13
										; .Y = .A;
	tay
										; IF BUF_SECTOR[.Y] ^= $00 THEN
	lda #$00
	cmp BUF_SECTOR,Y
	bne  *+5
	jmp ZZ0016
										; DO;
	; Adresse du nom de fichier dans AY
										; .A = I;
;	lda I
	ldy I
										; .Y = #>BUF_SECTOR;
;	ldy #>BUF_SECTOR
	jsr dir_entry

	lda #$ff
	eor s_odd_even
	sta s_odd_even
	bne skip
	BRK_KERNEL XCRLF
skip:
	jsr StopOrCont
	bcs sedoric_dir_End

										; I = I+16;
ZZ0016:
	lda I
	clc
	adc #16
	sta I
										; END;
										; UNTIL .Z;
	bne ZZ0015
	; Passage au secteur suivant
										; .Y = 0;
	ldy #0
										; NP = BUF_SECTOR[.Y]; " .A = ZP_PTR[.Y]; NP = .A;";
	lda BUF_SECTOR,Y
	jsr sedoric_calcTrackSide										; INC .Y;
	sta Track
	iny
										; NS = BUF_SECTOR[.Y]; " .A = ZP_PTR[.Y]; NS = .A;";
	lda BUF_SECTOR,Y
	sta Sector
	; NS=0 si dernier secteur du catalogue atteint
										; END;
										; UNTIL .Z;
	bne ZZ0014

	lda s_odd_even
	beq skip2
	BRK_KERNEL XCRLF

skip2:
	BRK_KERNEL XCRLF

	jsr Sedoric_epilogue

	; Indique que tout s'est bien passe
										; .A = #CH376_USB_INT_SUCCESS;
	lda #CH376_USB_INT_SUCCESS
										;sedoric_dir_End:
sedoric_dir_End:
										;RETURN;
	pha
	lda DEFAFF_save
	sta DEFAFF
	pla
	rts
.endproc

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
.proc dir_entry
	; x x x x x x x x x x x x p s t l
	; |                     | | | | +-> b7 b6 => Lock, b5-b0 => poids fort taille du fichier
	; |                     | | | +---> Poids faible taille du fichier
	; |                     | | +-----> Secteur FCB
	; |                     | +-------> Piste FCB
	; +---------------------+---------> Nom du fichier
	; Ici .Y = I

	print margin, SAVE

	lda #>BUF_SECTOR

	; Affiche l'entree du catalogue
	; 'FILENAMEX'
	ldx #$09
	jsr PrintAY

	; '.'
	pha
	tya
	pha
	lda #'.'
	BRK_KERNEL XWR0

	; 'EXT'
	pla
	clc
	adc #$09
	tay
	pla
	ldx #$03
	jsr PrintAY

	; Affiche la taille du fichier
;	tay
	lda BUF_SECTOR+14-9,y
	pha
	lda BUF_SECTOR+15-9,y
	and #$3f
	tay
	pla
	ldx #$02
	BRK_KERNEL XDECIM

	rts
.endproc

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
.proc Sedoric_epilogue
	; Lecture des infos de format de la disquette
;	lda #20
;	sta NP
	ldy #20
										; NS = 2;
;	lda #2
;	sta NS
	ldx #2
										; BUFFER_PTR =## BUF_SECTOR;
;	lda #<BUF_SECTOR
;	sta BUFFER_PTR
;	lda #>BUF_SECTOR
;	sta BUFFER_PTR+1

	jsr _ReadSector2
										; IFF .A ^= #CH376_USB_INT_SUCCESS THEN CAT_End;
	;cmp #CH376_USB_INT_SUCCESS
	; Secteur non trouvé
	;bne epilogue_end
	jcs epilogue_end

	print margin

	; Nombre de secteurs libres
	lda #'*'
	sta DEFAFF

	lda BUF_SECTOR+2
	ldy BUF_SECTOR+3
	ldx #$02
	BRK_KERNEL XDECIM

	print s_sectors_free

	; Format: S ou D
	ldy #'S'
	lda BUF_SECTOR+6
	ora #$80
	cmp BUF_SECTOR+9
	bne _single
	ldy #'D'
_single:
	tya
	BRK_KERNEL XWR0

	; Remplissage par des ' '
	;lda #' '
	;sta DEFAFF

	; Nombre de pistes
	lda #'/'
	BRK_KERNEL XWR0
	lda BUF_SECTOR+6
	ldy #$00
	ldx #$00
	BRK_KERNEL XDECIM

	; Nombre de secteurs
	lda #'/'
	BRK_KERNEL XWR0
	lda BUF_SECTOR+7
	ldy #$00
	ldx #$00
	BRK_KERNEL XDECIM

	print rparent

	; Nombre de fichiers
	lda #' '
	sta DEFAFF

	lda BUF_SECTOR+4
	ldy BUF_SECTOR+5
	ldx #$01
	BRK_KERNEL XDECIM

	print files

epilogue_end:
	rts

.endproc


;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	A: Code erreur si C=1
;	C: 0->Ok, 1->Erreur
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc sedoric_getdskInfo
	; Lecture Piste 20, Secteur 2
	lda #$14
	sta Track
	lda #<BUF_SECTOR
	ldy #>BUF_SECTOR
	ldx #$02
	jsr _ReadSector
	bcs error

	; Nombre de pistes par face
	lda BUF_SECTOR+6
	sta sedoric_side1_offset
	;lsr sedoric_side1_offset

	; Disquette double face?
	ora #$80
	cmp BUF_SECTOR+9
	beq fin

	; Disquette simple face
	; On met 0 dans l'offset pour la face B
	lda #$00
	sta sedoric_side1_offset
  fin:
	clc

  error:
	rts

.endproc


;----------------------------------------------------------------------
;
; Entrée:
;	A: Track
; Sortie:
;	A: Track
;	C: 0->Ok, 1->Erreur
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		sedoric_side1_offset
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc sedoric_calcTrackSide
	bpl fin
	clc
	and #$7f
	adc sedoric_side1_offset

  fin:
	clc
	rts

.endproc


;----------------------------------------------------------------------
;				DATAS
;----------------------------------------------------------------------
.segment "RODATA"

	margin:
		.asciiz "  "

	drive:
		.asciiz "  Drive A V3 "

	master:
		.asciiz "(Mst) "
	slave:
		.asciiz "(Slv) "

	s_sectors_free:
		.asciiz " sectors free ("

	rparent:
		.asciiz ") "

	files:
		.byte " Files",$0d,$0a,$00

