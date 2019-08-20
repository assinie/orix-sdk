.include "telestrat.inc"

.export _strlen

.segment "CODE"



.proc _strlen
	ldy #$00
loop:
	lda (RES),y
	beq we_reach_zero
	iny
	bne loop

we_reach_zero:
	; Y contains the length
	rts
.endproc


