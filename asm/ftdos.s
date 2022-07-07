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
.import _ReadSector, _ReadSector3
.importzp Track, Sector

.import BUF_SECTOR
;.import NS,NP

; From debug
;.import PrintHexByte

; From sopt
;.import loupch1

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export ftdos_cat
.export CAT_Entry		; TEMPORAIRE POUR LS
.export DU

;----------------------------------------------------------------------
; Defines / Constants
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.zeropage

;----------------------------------------------------------------------
; Variables et buffers
;----------------------------------------------------------------------
.segment "DATA"

	; Utilisé par ftdos_cat & sedoric_dir
	I: .res 1

	; Nombre de secteurs libres pour FTDOS
	DU: .res 2,0

	; --------------------------------------------------------------------
	; Variables FTDOS
	; --------------------------------------------------------------------
	; *=$048C
	; NLU: .res 1
	; NP et NS doivent être sur 2 octets car utilisés comme paramètres
	; pour spar
	;NP: .res 2
	;NS: .res 2

	DEFAFF_save: .byte ' '

;----------------------------------------------------------------------
;				Programme
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
; Lecture du catalogue d'une image FTDOS
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
.proc ftdos_cat
	lda DEFAFF
	sta DEFAFF_save

	BRK_KERNEL XCRLF

	; Replissage avec des ' '
	lda #' '
	sta DEFAFF

	; Lecture Secteur Bitmap
	lda #20
	sta Track
										; NS = 2;
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
	;bne CAT_End
	bcs CAT_End

	print volume
	lda #>BUF_SECTOR
	ldy #$f8
	; Affiche le nom du volume
	ldx #$08
	jsr PrintAY

	BRK_KERNEL XCRLF
	BRK_KERNEL XCRLF

	; 1er secteur du catalogue
										; NP = 20;
	;lda #20
	;sta NP
										; NS = 2;
	;lda #2
	;sta NS
	inc Sector
										; BUFFER_PTR =## BUF_SECTOR;
;	lda #<BUF_SECTOR
;	sta BUFFER_PTR
;	lda #>BUF_SECTOR
;	sta BUFFER_PTR+1
										; REPEAT;
ZZ0011:
										; DO;
										; CALL _ReadSector; " Dure environ 62000 cycles";
	jsr _ReadSector3
										; IFF .A ^= #CH376_USB_INT_SUCCESS THEN CAT_End;
	;cmp #CH376_USB_INT_SUCCESS
	; Secteur non trouvé
	;bne CAT_End
	bcs CAT_End

	; Traitement du secteur du catalogue
	; Dure 583 cycles sans l'affichage
	;FOR I=4 TO 238 BY 18
										; I = 4;
	lda #4
	sta I
										; REPEAT;
ZZ0012:
										; DO;
	; Optimisation: supprimer le lda I inutile, deja fait
										; IF BUF_SECTOR[I] ^= $FF THEN
	lda I
	tay
	lda #$FF
	cmp BUF_SECTOR,Y
	bne  *+5
	jmp ZZ0013
										; DO;
	jsr CAT_Entry

	BRK_KERNEL XCRLF

	jsr StopOrCont
	bcs CAT_End

										; END;
										; I = I+18;
ZZ0013:
	lda I
	clc
	adc #18
	sta I
										; END;
										; UNTIL .Z;
	bne ZZ0012

	; Passage au secteur suivant
										; .Y = 2;
	ldy #2
										; NP = BUF_SECTOR[.Y]; " .A = ZP_PTR[.Y]; NP = .A;";
	lda BUF_SECTOR,Y
	sta Track
										; INC .Y;
	iny
										; NS = BUF_SECTOR[.Y]; " .A = ZP_PTR[.Y]; NS = .A;";
	lda BUF_SECTOR,Y
	sta Sector
	; NS=0 si dernier secteur du catalogue atteint
										; END;
										; UNTIL .Z;
	bne ZZ0011

	; Affiche le nombre de secteurs libres
	BRK_KERNEL XCRLF
	print margin

	sec
	lda #<(1394-2)
	sbc DU
	pha
	lda #>(1394-2)
	sbc DU+1
	tay
	pla
	ldx #02
	BRK_KERNEL XDECIM
	print f_sectors_free

	; Indique que tout s'est bien passe
										; .A = #CH376_USB_INT_SUCCESS;
	lda #CH376_USB_INT_SUCCESS
										;CAT_End:
CAT_End:
	pha
	lda DEFAFF_save
	sta DEFAFF
	pla
										;RETURN;
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
.proc CAT_Entry
	; Ici .Y = I
	; On saute la piste et le secteur du FCB
	;lda BUF_SECTOR,y
	;jsr PrintHexByte
	;lda BUF_SECTOR+1,y
	;jsr PrintHexByte

	iny
	iny

	print margin, SAVE

	; Octet de verrouillage
;	tya
;	pha
	lda BUF_SECTOR,y
	BRK_KERNEL XWR0
	print margin, SAVE
;	pla
;	tay
	iny

	; Adresse du nom de fichier dans AY
;	tya
;	ldy #>BUF_SECTOR
	lda #>BUF_SECTOR

	; Affiche l'entree du catalogue
	ldx #12
	jsr PrintAY

	; Affiche le type de fichier
;	tya
;	pha
	print margin, SAVE
	lda BUF_SECTOR+12,y
	BRK_KERNEL XWR0
;	pla
;	tay

	; Taille
;	lda #$01	; LSB
;	ldy #$02	; MSB
;	ldx #$00
;	BRK_KERNEL XDECIM

;	tay

	tya
	pha
	print margin
	print margin
	print margin
	pla
	tay

	lda BUF_SECTOR+13,y
	pha
	; additionne la taille du fichier au nombre total de secteurs
	clc
	adc DU
	sta DU
	lda BUF_SECTOR+14,y
	tay
	adc DU+1
	sta DU+1
	pla
	ldx #$02
	BRK_KERNEL XDECIM
	print sectors, SAVE

	rts
.endproc




;----------------------------------------------------------------------
;				DATAS
;----------------------------------------------------------------------
.segment "RODATA"

	margin:
		.asciiz "  "

	volume:
		.asciiz "     VOLUME : "

	sectors:
		.asciiz " SECTORS"

	f_sectors_free:
		.byte " SECTORS FREE",$0d,$0a,$00

