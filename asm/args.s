.include "telestrat.inc"

.include "include/SDK.inc"
;----------------------------------------------------------------------
;				Imports
;----------------------------------------------------------------------
.import _argc
.import _argv

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export _init_argv
.export _get_argv

; ============================================================================
;				Paramétrage
; ============================================================================
WITH_FENCE .set 0				; Si 1 -> place un pointeur nul dans ARGV
						; pour indiquer la fin du tableau
						; Nécessite la place pour un pointeur
						; de plus en fin de ARGV


;MAX_BUFEDT_LENGTH = 127			; Inutile ici, pas de vérification possible!
;MAX_ARGS = 5					; Nombre total d'arguments (nom de fichier inclus), maximum: 127

.code

.ifdef ARGS_TEST
	; ============================================================================
	;				Variables systèmes
	; ============================================================================
	RES = 0						; Pointeur vers ARGS
	RESB = 2					; Pointeur vers struct ARGV
	TR0 = $0C					; TR0-TR1: Travail
	TR1 = $0D

	; ============================================================================
	;			Début du programme de test
	; ============================================================================
		;.org $1000


		lda #<BUFEDT
		ldy #>BUFEDT
		sta RESB
		sty RESB+1

		lda #<ARGV
		ldy #>ARGV
		sta RES
		sty RES+1

		jsr _init_argv

		lda #<ARGV
		ldy #>ARGV
		ldx #$02
		jsr _get_argv
		rts

	; ============================================================================
	;			Variables du programme de test
	; ============================================================================

	; ----------------------------------------------------------------------------
	;				Simulation BUFEDT
	; ----------------------------------------------------------------------------
	BUFEDT:
		.asciiz "exec    bank 3   4"

	; ----------------------------------------------------------------------------
	;			Simulation malloc(struct)
	; ----------------------------------------------------------------------------
		;	ARGS+0 => ARGC
		;	ARGS+1 => ARGV[0]
		;	ARGS+3 => ARGV[1]

	ARGV:
		.res 1, $ff
		.res MAX_ARGS*2, $ff

		.if WITH_FENCE
			.res 2,$ff			; Dernier pointeur (mis à $0000 par la routine)
		.endif
.endif

; ============================================================================
;				Routine INIT_ARGV
; ----------------------------------------------------------------------------
; Rempli le tableau ARGV avec une liste de pointeurs vers chaque argument
; de la ligne de commande (le délimiteur est l'espace)
;
; Remarque:
;	Ne prend pas en compte les caracrères ' et " pour délimiter une
;	chaîne contenant des délimiteurs
; ----------------------------------------------------------------------------
; Taille: 84 octets sans FENCE, 88 avec
; ----------------------------------------------------------------------------
; Entrée:
;	AY: Adresse de la ligne de commande
;	X : Nombre maximal d'arguments
;
; Sortie:
;	A : Indice dernier arguments
;	X : Offset dernier pointeur dans ARGV +2 (ie: sizeof(ARGV)+1)
;	Y : $00
;
;	RES : Adresse ARGV
;	RESB: Si plus d'arguments que MAX_ARGS:
;			=> Adresse dernier octet du dernier argument trouvé +1
;		Sinon:
;			=> Adresse début dernier argument
; ----------------------------------------------------------------------------
; Test possible en sortie:
;	Si (RESB) != ARGV[ARGC] -> Trop d'arguments
; ============================================================================
.proc _init_argv

;	sta RESB				; Pointeur vers BUFEDT
;	sty RESB+1
						; Simulation malloc()
;	lda #<ARGV
;	ldy #>ARGV

;	sta RES
;	sty RES+1

	txa					; MAX_ARGS*2+1
	asl
	tax
	inx
	stx TR0

	ldy #01				; ARGV[0] := BUFEDT
	lda RESB
	sta (RES),y
	iny
	lda RESB+1
	sta (RES),y

	ldx #$04				; X pointe vers ARGV[1] (poids fort)
L0:
	ldy #$ff


	; --------------------------------------------------------------------
	;		Recherche la fin de l'argument
	;
	; (Mettre le délimiteur dans une variable)
	; --------------------------------------------------------------------
L1:
	iny
	; beq string_too_long
	; ou
	; bne *+4
	; inc RESB+1
	lda (RESB),y
	beq eol
	cmp #' '
	bne L1

	lda #$00				; Met un 0 pour signaler la fin de l'argument
	sta (RESB),y

	.if !::WITH_FENCE
		; Mettre le "cpx" ici permet de se passer
		; du "garde-fou"
		cpx #(MAX_ARGS*2)+1		; +3 si MAX_ARGS ne compte pas le nom du programme
		bcs max_args_reached
	.endif

	; --------------------------------------------------------------------
	;		Saute les ' ' éventuels à la fin de l'argument
	;
	; (Ajouter un test pour sauter cette boucle si le délimiteur
	;  n'est pas un espace?)
	; --------------------------------------------------------------------
L2:
	iny					; Saute les espaces
	; beq string_too_long
	; ou
	; bne *+4
	; inc RESB+1
	lda (RESB),y
	beq eol
	cmp #' '
	beq L2

	; --------------------------------------------------------------------
	;			Mets à joour RESB
	; --------------------------------------------------------------------
	clc					; Ajuste RESB pour pointer vers le début de l'arguemnt suivant
	tya
	adc RESB
	pha
	sta RESB
	lda #$00
	adc RESB+1
	pha
	sta RESB+1

	; --------------------------------------------------------------------
	;			Mets à jour le tableau ARGV
	; --------------------------------------------------------------------
	txa					; Met à jour le pointeur dans ARGV[]
	tay
	pla
	sta (RES),y				; Poids fort
	dey					; -1
	pla
	sta (RES),y				; Poids faible
	iny					; +1
	tya
	tax


	; --------------------------------------------------------------------
	;	Ajustement et vérification du nombre d'arguments trouvés
	; --------------------------------------------------------------------
	inx					; Ajuste X pour pointer vers le prochain ARGV[]
	inx

	.if ::WITH_FENCE
		; Si on met le "cpx" ici, il faut laisser le code pour
		; le pointeur "garde-fou"

		cpx #(MAX_ARGS*2)+1
		bcc L0				; <
overflow:
	.else
		bne L0
	.endif

max_args_reached:

	; --------------------------------------------------------------------
	;	Fin de ligne atteinte, mise à jour de ARGC
	; --------------------------------------------------------------------
eol:
	txa					; Dernier pointeur dans ARGV[] := 0
	tay

	.if ::WITH_FENCE
		;
		; Met le pointeur "garde-fou" à 0
		;
		lda #$00
		sta (RES),y			; Poids fort
		dey
		sta (RES),y			; Poids faible
		dey				; Peut éventuellement être supprimé (Y sera impair mais on fait une division entière par 2)
	.else
		dey
		dey
	.endif

	dey					; Ajustement ARGC
	dey					; Y := indice du dernier pointeur dans ARGV, si on enleve les 'dey' => Y:= nombre total d'éléments dans ARGV
	tya
	lsr
	ldy #$00
	sta (RES),y

	rts
.endproc

; ============================================================================
;				Routine GET_ARGV
; ----------------------------------------------------------------------------
; Retourne l'adresse d'un argument
;
; Entrée:
;	AY: Adresse de ARGV[]
;	X : N° de l'argument
;
; Sortie:
;	X : Inchangé
;	C : 1->Ok
;		AY: Adresse de l'argument
;	C : 0->Erreur (compatibilté _orix_get_opt)
;		AY: Adresse de ARGV[]
;
; ============================================================================
.proc _get_argv
	lda _argv
	ldy _argv+1

  _get_argv_ay:
	sta TR0
	sty TR1

	txa					; Index
	ldy #$00
	cmp (TR0),y
	bcc @Ok				; Index <= -> Ok
	beq @Ok

	lda TR0				; Restaure AY
	ldy TR1
	clc					; > -> Indique Erreur
	rts

  @Ok:
	asl					; Index x2
	tay
	iny					; +1 (pour sauter ARGC)

	lda (TR0),y				; Poids faible argument
	pha
	iny
	lda (TR0),y				; Poids fort argument
	tay
	pla

	sec					; Indique OK
	rts
.endproc

