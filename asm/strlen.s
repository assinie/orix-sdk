.include "telestrat.inc"

.export _strlen

;.org $0801
.segment "CODE"



.proc _strlen
	ldy #$00
loop:	
	lda (RES),y
	beq we_reach_zero 
	iny
	jmp loop
we_reach_zero:
	; Y contains the length
	rts
.endproc
	
	
