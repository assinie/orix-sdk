;======================================================================
;
;======================================================================

;----------------------------------------------------------------------
;			cc65 includes
;----------------------------------------------------------------------
.include "telestrat.inc"

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
.include "macros/types.mac"
.include "include/errors.inc"

.reloc

;----------------------------------------------------------------------
;				Imports
;----------------------------------------------------------------------
;.import NS,NP

.import BUF_DSK

.ifdef DEBUG_LOW_LEVEL
.import PrintRegs
.endif

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export _ReadSector, _ReadSector2, _ReadSector3

; TEMPORAIRE
.export WaitResponse

.exportzp Track, Head, Sector, Size
.export CRC

;----------------------------------------------------------------------
; Defines / Constants
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.zeropage
	; Utilisés par _ReadSector
	Track: .res 1
	Head: .res 1
	Sector: .res 1
	Size: .res 1

	; Utilisés par GetByte et ReadUSBData
	PTR: .res 1
	PTR_MAX: .res 1

	; / \ ATTENTION
	; Re-utilise l'emplacement de PTW ($F5)
	; ZP_PTR: Utilisé par ReadSector
	PTW: .res 1
	ZP_PTR=PTW

;----------------------------------------------------------------------
; Variables et buffers
;----------------------------------------------------------------------
.segment "DATA"
	yio: .res 1

	; Utilisés par TrackOffset et ByteLocate
	OFFSET: .res 4,0

	; Utilisés par _ReadSector
	CRC: .res 2

	;NP: .res 1
	NS: .res 1

	; Retry pour le ByteLocate
	; retry: .res 1

;----------------------------------------------------------------------
; Defines / Constants
;----------------------------------------------------------------------
	TrackSize=6400


;----------------------------------------------------------------------
;				Programme
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; ReadSectotr
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
; Entree:
; Le fichier .dsk doit avoir ete ouvert
; NP: N° de la piste
; NS: N° du secteur
;BUFFER_PTR: Adresse du buffer pour le secteur a lire
;
;	AY: Adresse du buffer pour le secteur (A: LSB, Y:MSB)
;	X: N° de secteur
;	NP: N° de piste
;
; Sortie:
; AY: Code erreur CH376 ($14 si Ok)
;----------------------------------------------------------------------
										;_ReadSector:
_ReadSector:
	; Entrée: AY = Adresse buffer, X=NS
	sta ZP_PTR
	sty ZP_PTR+1
	ldy Track

_ReadSector2:
	; Entrée: X=NS, Y=NP
	sty Track
	stx Sector

_ReadSector3:
	; Entrée: NS & NP => Ok
	ldx Sector
	stx NS
										; .A = NP;
	lda Track

										; CALL TrackOffset;
	jsr TrackOffset

.ifdef DEBUG_LOW_LEVEL
	jsr debug_hts
.endif
										; CALL ByteLocate;
	jsr ByteLocate
	;IFF ^.Z THEN RS_End;" " Trop loin sans les optimisations
										; IF ^.Z THEN GOTO RS_End;
; Optimisation
;	beq ZZ0019
	; Erreur ByteLocate
;	jmp RS_End
	bcs error
										; .A = #<TrackSize;
ZZ0019:
	lda #<TrackSize
										; .Y = #>TrackSize;
	ldy #>TrackSize
										; CALL SetByteRead;
	jsr SetByteRead
	; Erreur SetByteRead?
										; IFF ^.Z THEN RS_End;
	bcs error
										; .A = #<BUF_DSK;
	lda #<BUF_DSK
										; .Y = #>BUF_DSK;
	ldy #>BUF_DSK
										; CALL ReadUSBData;
	jsr ReadUSBData
	;IFF .Y = 0 THEN Error;
										; ZP_PTR <- BUF_DSK_PTR;
;	lda BUF_DSK_PTR
;	sta ZP_PTR
;	lda BUF_DSK_PTR+1
;	sta ZP_PTR+1
										; CLEAR .V;
	clv
										; REPEAT;
ZZ0020:
										; BEGIN;
	; GAP1 / GAP4 / GAP2 / GAP5
	;Remplacer beq *+5 / jmp ZZxxxx par bne ZZxxxx
										; REPEAT;
ZZ0021:
										; BEGIN;
										; CALL GetByte;
	jsr GetByte
	; Si fin du fichier, on force la sortie
										; IF .O THEN .A = $FE;
	bvc ZZ0022
	lda #$FE
										; END;
ZZ0022:
										; UNTIL .A = $FE;
	cmp #$FE
; Optimisation
;	beq  *+5
;	jmp ZZ0021
	bne ZZ0021
										; IF ^.O THEN
	bvs ZZ0023
										; DO;
	; ID Field
										; CALL GetByte; Track = .A;
	jsr GetByte
	sta Track
										; CALL GetByte; Head = .A;
	jsr GetByte
	sta Head
										; CALL GetByte; Sector = .A;
	jsr GetByte
	sta Sector
										; CALL GetByte; Size = .A;
	jsr GetByte
	sta Size
										; CALL GetByte; CRC_L = .A;
	jsr GetByte
	sta CRC
										; CALL GetByte; CRC_H = .A;
	jsr GetByte
	sta CRC+1

.ifdef DEBUG_LOW_LEVEL
	jsr debug_hts_found
.endif

	; GAP 3
	;Remplacer beq *+5 / jmp ZZxxxx par bne ZZxxxx
										; REPEAT; CALL GetByte; UNTIL .A = $FB;
ZZ0024:
	jsr GetByte
	cmp #$FB
;Optimisation
;	beq  *+5
;	jmp ZZ0024
	bne ZZ0024

	; Data (lecture de 256 octets)
	; Ne tient pas compte de Size
	; A voir pour sauter plus rapidement les 256 octets
	; du secteur si ce n'est pas le bon
										; .Y = 0;
	ldy #0
										; REPEAT;
ZZ0025:
										; BEGIN;
										; CALL GetByte;
	jsr GetByte
										; 'sta (ZP_PTR),Y';
	sta (ZP_PTR),Y
										; INC .Y;
	iny
										; END;
										; UNTIL .Z;
	bne ZZ0025
	; Data CRC
										; CALL GetByte; CRC_L = .A;
	jsr GetByte
	sta CRC
										; CALL GetByte; CRC_H = .A;
	jsr GetByte
	sta CRC+1
	; Secteur trouve, on sort
	;Remplacer beq *+5 / jmp ZZxxxx par bne ZZxxxx
										; IF Sector = NS THEN CALL SEV;
	lda NS
	cmp Sector
; Optimisation
;	beq  *+5
;	jmp ZZ0026
	bne ZZ0026

	jsr SEV
										; END;
ZZ0026:
										; END;
ZZ0023:
										; UNTIL .O;
	bvc ZZ0020
	; On arrive ici avec .A = $FE ou Sector = NS (et .A = Sector)
	;CALL FileClose;
	; Si le secteur n'a pas ete trouve, on indique une erreur
	; Sinon le code de retour est celui de FileClose soit $14
	; normalement (a modifier eventuellement au cas ou le
	; FileClose se passe mal?)
										; .Y = #CH376_USB_INT_SUCCESS;
	;ldy #CH376_USB_INT_SUCCESS
										; IF Sector ^= NS THEN .Y = $FF;
	lda NS
	cmp Sector
; Optimisation
;	bne  *+5
;	jmp ZZ0027
	;beq ZZ0027

	; Remet NS dans Sector pour les messages d'erreurs
	sta Sector

	;ldy #$FF
	bne error90
.ifdef DEBUG_LOW_LEVEL
	jsr debug_hts_found
.endif
	clc
	rts
										; .A = .Y;
;ZZ0027:
	;tya
										;RS_End:
error90:
	lda #$90		; Read dr:tr:sc error
	sec
error:										;RETURN;
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
										;SEV:
SEV:
										; 'BIT *-1';
	bit *-1
										;RETURN;
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
; TrackOffset:
;
; Calcule l'offset d'une piste = Piste * 25 + 256
; (6400 = 25 * 256)
;
; Entree:
; ACC: N? de piste
;
; Sortie:
; ACC: Poids faible du resultat -1
; OFFSET: Resultat sur 16 bits
;
; Utilise:
; OFFSET: 16 bits, resultat
;
; La valeur sur 32 bits: 0 total_h total_l 0
; Pas de debordement sur le 4ieme octet tant que
; le n? de piste < 2622 (=65535/25)
;
; En principe tous les clc sont inutiles
;
; Voir routine optimisee plus bas
;----------------------------------------------------------------------
										;TrackOffset:
.proc TrackOffset
	; STACK A;"; " Si on ne veut pas utiliser .Y
	;Initialise OFFSET[]
										; .Y = 0; " Remplacer .Y par .A si on veut conserver .Y ";
	ldy #0
										; OFFSET_0 = .Y;
	sty OFFSET
										; OFFSET_L = .A;
	sta OFFSET+1
										; OFFSET_H = .Y;
	sty OFFSET+2
										; OFFSET_3 = .Y;
	sty OFFSET+3
	; x2
										; SHIFT LEFT OFFSET_L;
	asl OFFSET+1
										; ROTATE LEFT OFFSET_H;
	rol OFFSET+2
	; +1 -> x3
										; staCK .A;
	pha
										; CLEAR .C;
	clc
										; .A + OFFSET_L; OFFSET_L = .A;
	adc OFFSET+1
	sta OFFSET+1
										; IF .C THEN INC OFFSET_H;
	bcc ZZ0028
	inc OFFSET+2
	; x8 -> x24
ZZ0028:
										; SHIFT LEFT OFFSET_L;
	asl OFFSET+1
										; ROTATE LEFT OFFSET_H;
	rol OFFSET+2
										; SHIFT LEFT OFFSET_L;
	asl OFFSET+1
										; ROTATE LEFT OFFSET_H;
	rol OFFSET+2
										; SHIFT LEFT OFFSET_L;
	asl OFFSET+1
										; ROTATE LEFT OFFSET_H;
	rol OFFSET+2
	; +1 -> x25
										; UNstaCK .A;
	pla
										; CLEAR .C;
	clc
										; .A + OFFSET_L; OFFSET_L = .A;
	adc OFFSET+1
	sta OFFSET+1
										; IF .C THEN INC OFFSET_H;
	bcc ZZ0029
	inc OFFSET+2
	; +256
ZZ0029:
										; INCW OFFSET_L;
	inc OFFSET+1
	bne ZZ0030
	inc OFFSET+1+1
ZZ0030:
	;.A = OFFSET_L
	;.Y = OFFSET_H
										;RETURN;
	rts
.endproc

;===========================================================================
;
;===========================================================================
										;'#include "lib/CH376.s"';
;#include "lib/CH376.s"
;----------------------------------------------------------------------
; Issus de lib/CH376.s
;----------------------------------------------------------------------
;----------------------------------------------------------------------
; GetByte:
; Lit le prochain caractere du buffer
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
; Entree:
;
; Sortie:
; ACC: Caractere lu
; X : Modifie (0 si appel a ReadUSBData2)
; Y : Inchange
; V : 1 Fin du fichier atteinte
; Z,N: Fonction du caractere lu
;
;----------------------------------------------------------------------
GetByte:
                                                                                ; yio = .Y;
        sty yio
                                                                                ; .Y = PTR;
        ldy PTR
                                                                                ; IFF .Y ^= PTR_MAX THEN GetByte2;
        cpy PTR_MAX
        bne GetByte2
                                                                                ; CALL ByteRdGo;
        jsr ByteRdGo
                                                                                ; IFF .A = $14 THEN GetByteErr;
        cmp #$14
        beq GetByteErr
                                                                                ; CALL ReadUSBData2;
        jsr ReadUSBData2
                                                                                ; PTR_MAX = .Y;
        sty PTR_MAX
                                                                                ; .Y = 0;
        ldy #0
                                                                                ; PTR = .Y;
        sty PTR
                                                                                ;GetByte2:
GetByte2:
                                                                                ; .A = @PTR_READ_DEST[.Y];
        lda (PTR_READ_DEST),Y
                                                                                ; STACK .P; " Sauvegarde P sinon il est modifie par le .Y = yio ";
        php
                                                                                ; INC PTR;
        inc PTR
                                                                                ; .Y = yio;
        ldy yio
                                                                                ; UNSTACK .P;
        plp
                                                                                ;RETURN;
        rts
                                                                                ;GetByteErr:
GetByteErr:
                                                                                ; 'BIT *-1';
        bit *-1
                                                                                ; .Y = yio;
        ldy yio
                                                                                ;RETURN;
        rts
                                                                                ;'#endif';

;----------------------------------------------------------------------
; ReadUSBData:
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
; Entree:
; AY : Adresse du tampon destination
;
; Sortie:
; ACC: Dernier octet lu ou 0 ou $27
; X : 0
; Y : Nombre d'octets lus ou 0
; Z : 1
;----------------------------------------------------------------------
ReadUSBData:
                                                                                ; PTR_READ_DEST <- .AY;
        sta PTR_READ_DEST
        sty PTR_READ_DEST+1
                                                                                ;ReadUSBData2:
ReadUSBData2:
                                                                                ; .Y = 0;
        ldy #0
                                                                                ; PTR = .Y; "Pointeur pour GetByte";
        sty PTR
                                                                                ; CH376_COMMAND = $27;
        lda #$27
        sta CH376_COMMAND
                                                                                ; .X = CH376_DATA;
        ldx CH376_DATA
                                                                                ; IF ^.Z THEN
        beq ZZZ002
                                                                                ; BEGIN;
                                                                                ; REPEAT;
ZZZ003:
                                                                                ; DO;
                                                                                ; .A = CH376_DATA;
        lda CH376_DATA
        ;&PTR_READ_DEST[.Y] = CH376_COMMAND;
                                                                                ; 'STA (PTR_READ_DEST),Y';
        sta (PTR_READ_DEST),Y
                                                                                ; .Y+1;
        iny
                                                                                ; .X-1;
        dex
                                                                                ; END;
                                                                                ; UNTIL .Z;
        bne ZZZ003
                                                                                ; PTR_MAX = .Y; "Pour GetByte";
        sty PTR_MAX
                                                                                ; END;
                                                                                ;RETURN;
ZZZ002:
        rts


;----------------------------------------------------------------------
; SetByteRead
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
; Entree:
; AY: Nombre d'octets a lire (.A = LSB, .Y = MSB)
;
; Sortie:
; ACC: 0
; X,Y: Modifies
;----------------------------------------------------------------------
.proc SetByteRead
                                                                                ; STACK .A;
        pha
                                                                                ; CH376_COMMAND = $3A;
        lda #$3A
        sta CH376_COMMAND
                                                                                ; UNSTACK .A;
        pla
                                                                                ; CH376_DATA = .A;
        sta CH376_DATA
                                                                                ; CH376_DATA = .Y;
        sty CH376_DATA
                                                                                ; CH376_DATA = 0;
;        lda #0
;        sta CH376_DATA
                                                                                ; CH376_DATA = 0;
;        lda #0
;        sta CH376_DATA
                                                                                ; CALL WaitResponse;
        jsr WaitResponse
                                                                                ; 'CMP #CH376_USB_INT_DISK_READ';
        cmp #CH376_USB_INT_DISK_READ
	bne error
	clc
                                                                                ;RETURN;
        rts

 error:
	; /!\ TEMPORAIRE POUR DEBUG
	; Drive not ready
	lda #$c0
	sec
	rts
.endproc


;----------------------------------------------------------------------
; ByteLocate
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
; Entree:
; AY: Offset
;
; Sortie:
; A,X,Y: Modifies
;
;----------------------------------------------------------------------
.proc ByteLocate

;	jsr ByteLocate_rewind
;	bcc suite
;	rts
;suite:
;	; Ou
	; [--
        lda #$39
        sta CH376_COMMAND
                                                                                ; CH376_DATA = OFFSET_0;
        lda #$00
        sta CH376_DATA
        sta CH376_DATA
        sta CH376_DATA
        sta CH376_DATA

        jsr WaitResponse
                                                                                ; 'CMP #CH376_USB_INT_SUCCESS';
        cmp #CH376_USB_INT_SUCCESS
	bne error
	; --]

                                                                                ; CH376_COMMAND = $39;
        lda #$39
        sta CH376_COMMAND
                                                                                ; CH376_DATA = OFFSET_0;
        lda OFFSET
        sta CH376_DATA
                                                                                ; CH376_DATA = OFFSET_L;
        lda OFFSET+1
        sta CH376_DATA
                                                                                ; CH376_DATA = OFFSET_H;
        lda OFFSET+2
        sta CH376_DATA
                                                                                ; CH376_DATA = OFFSET_3;
        lda OFFSET+3
        sta CH376_DATA
                                                                                ; CALL WaitResponse;
        jsr WaitResponse
                                                                                ; 'CMP #CH376_USB_INT_SUCCESS';
        cmp #CH376_USB_INT_SUCCESS
	bne error
;	jsr prtregs
;	bne _retry
                                                                                ;RETURN;

	; Lecture de la position
;	lda #$27
;	sta CH376_COMMAND
;	ldx CH376_DATA
	; 4 octets à lire
;	jsr prtregs
;	beq error0

;	cpx #$04
;	bne loop

;	lda CH376_DATA
;	dex
;	jsr prtregs
;	cmp OFFSET
;	;bne loop

;	lda CH376_DATA
;	dex
;	jsr prtregs
;	cmp OFFSET+1
;	;bne loop

;	lda CH376_DATA
;	dex
;	jsr prtregs
;	cmp OFFSET+2
;	;bne loop

;	lda CH376_DATA
;	dex
;	jsr prtregs
;	cmp OFFSET+3
;	;bne _retry

	; Sortie: Z=1 (pour compatibilité), C=0
	clc
        rts

; loop:
;	; Vide le tampon
;	lda CH376_DATA
;	dex
;	bne loop
;	beq _retry

; error0:
;	; Device error
;	lda #e11
;	.byte $2c

error:
	; Sortie: Z=0, C=1
	; Dr:tr:sc xx xx xx error
	lda #$b0
	sec
	rts
.endproc


;----------------------------------------------------------------------
; ByteLocate_rewind
;
; Entrée:
;	-
; Sortie:
;	C=0 -> Ok, C=1 -> Erreur
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	WaitResponse
;----------------------------------------------------------------------
;.proc ByteLocate_rewind
;        lda #$39
;        sta CH376_COMMAND
                                                                                ; CH376_DATA = OFFSET_0;
;        lda #$00
;        sta CH376_DATA
;        sta CH376_DATA
;        sta CH376_DATA
;        sta CH376_DATA

;        jsr WaitResponse
                                                                                ; 'CMP #CH376_USB_INT_SUCCESS';
;        cmp #CH376_USB_INT_SUCCESS
;	bne error
;	clc
;	rts

;error:
	; Code erreur spécifique
;	lda #$40
;	sec
;	rts
;.endproc



;----------------------------------------------------------------------
; WaitResponse:
; A voir si il faut preserver X et Y
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
; Entree:
;
; Sortie:
; Z: 0 -> ACC: Status du CH376
; Z: 1 -> Timeout
; X,Y: Modifies
;----------------------------------------------------------------------
WaitResponse:
                                                                                ; .Y = $FF;
        ldy #$FF
                                                                                ; REPEAT;
ZZZ009:
                                                                                ; DO;
                                                                                ; .X=$FF;
        ldx #$FF
                                                                                ; REPEAT;
ZZZ010:
                                                                                ; DO;
                                                                                ; .A = CH376_COMMAND;
        lda CH376_COMMAND
                                                                                ; IF + THEN
        bmi ZZZ011
                                                                                ; BEGIN;
                                                                                ; CH376_COMMAND = $22;
        lda #$22
        sta CH376_COMMAND
                                                                                ; .A = CH376_DATA;
        lda CH376_DATA
                                                                                ; RETURN;
        rts
                                                                                ; END;
                                                                                ; DEC .X;
ZZZ011:
        dex
                                                                                ; END;
                                                                                ; UNTIL .Z;
        bne ZZZ010
                                                                                ; DEC .Y;
        dey
                                                                                ; END;
                                                                                ; UNTIL .Z;
        bne ZZZ009
                                                                                ;RETURN;
        rts

;----------------------------------------------------------------------
; ByteRdGo
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
; Ok -> INT_DISK_READ ($1d)
; Plus de donnees -> INT_SUCCESS ($14)
; X,Y: Modifies
;----------------------------------------------------------------------
ByteRdGo:
                                                                                ; CH376_COMMAND = $3B;
        lda #$3B
        sta CH376_COMMAND
                                                                                ; CALL WaitResponse;
        jsr WaitResponse
                                                                                ; 'CMP #INT_DISK_READ';
        cmp #CH376_USB_INT_DISK_READ
                                                                                ;RETURN;
        rts

										;EXIT;



;----------------------------------------------------------------------
; DEBUG
;----------------------------------------------------------------------
.ifdef DEBUG_LOW_LEVEL
.feature string_escapes

.import PrintHexByte

.proc debug_hts
	php
	pha
	tya
	pha
	txa
	pha

	print hts_msg, NOSAVE
	;lda Head
	;jsr PrintHexByte
	print #'x', NOSAVE
	print #'x', NOSAVE
	print #':', NOSAVE
	lda Track
	jsr PrintHexByte
	print #':', NOSAVE
	lda Sector
	jsr PrintHexByte
	print #' ', NOSAVE

	; Force Head:Track:Sector à $FF pour détecter une erreur
	; lors de la recherche du secteur par ReadSector
	lda #$ff
	sta Head
	sta Track
	sta Sector

	ldx #$03
 loop:
	lda OFFSET,x
	jsr PrintHexByte
	dex
	bpl loop

	print hts_msg2, NOSAVE

	pla
	tax
	pla
	tay
	pla
	plp
	rts
.endproc

.proc debug_hts_found
	php
	pha
	tya
	pha
	txa
	pha

	; print found_hts_msg
	lda Head
	jsr PrintHexByte
	;print #'x', NOSAVE
	;print #'x', NOSAVE
	print #':', NOSAVE
	lda Track
	jsr PrintHexByte
	print #':', NOSAVE
	lda Sector
	jsr PrintHexByte
	BRK_KERNEL XCRLF

	pla
	tax
	pla
	tay
	pla
	plp
	rts
.endproc

.proc prtregs
	php
	pha
	jsr PrintRegs
	BRK_KERNEL XCRLF
	pla
	plp
	rts
.endproc

.segment "RODATA"
	hts_msg:
		.asciiz "\r\nSearch: "
	hts_msg2:
		.asciiz " -> "
.endif
