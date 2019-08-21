;----------------------------------------------------------------------
;			cc65 includes
;----------------------------------------------------------------------
.include "telestrat.inc"

;----------------------------------------------------------------------
;			Orix Kernel includes
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;			Orix Shell includes
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;				Imports
;----------------------------------------------------------------------
;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export sopt1
.export spar1
.export cbp

;**********************************************************************
;               page 0 used by command interpreter
;**********************************************************************
.zeropage
;t1:     .res     2               ;parameters
;t2:     .res     2
;t3:     .res     2
;t4:     .res     2

tepo:   .res     2              ;opt/param, text output (saved)
opp:    .res     2              ;option param. pointer
cbp:    .res     2              ;command buffer pointer

opt:    .res     1              ;options mask
mode:   .res     1              ;param. mask

;**********************************************************************
;               DOS65 errors values
;**********************************************************************
e15      =      $15             ;option
e16      =      $16             ;hex/dec data

;**********************************************************************
;               DOS65 work memory
;**********************************************************************
.bss
inbuf:  .res     80             ;command input buffer (max 80 char)

hdx:    .res     1              ;save X hex <> dec conv.



;**********************************************************************
;               Programm
;**********************************************************************
.code
tincr:
        ldx     #tepo
incr:
        inc     0,x             ;incr ,X
        bne     l1
        inc     1,x
l1:
        lda     (0,x)
        rts

ascdh:
        bit     mode            ;asc - dec/hex
        bmi     l2

;----------------------------------------------------------------------
;               convert ascii to hex
;----------------------------------------------------------------------
aschex1:
        cmp     #'F'+1          ;convert ascii hex C=0
        bcs     l9
        cmp     #'A'
        bcs     l3
l2:
        eor     #'0'
        cmp     #9+1
        bcc     l9
        eor     #'0'
l9:
        rts                     ;non ascii => C=1
l3:
        sbc     #'A'-10
        clc
        rts

;----------------------------------------------------------------------
;               convert hexadecimal to decimal
;----------------------------------------------------------------------
hexdec1:
        stx     hdx             ;A hex => A dec (no error)
        clc
        tax
        beq     dech4
        lda     #0
        sed
hexd1:
        adc     #1
        dex
        bne     hexd1
dech3:
        cld
dech4:
        ldx     hdx
        rts

;----------------------------------------------------------------------
;               convert decimal to hexadecimal
;----------------------------------------------------------------------
dechex1:
        stx     hdx             ;A dec => A hex
        ldx     #$ff
        sec
        sed
dech1:
        inx
        sbc     #1
        bcs     dech1
        txa
        bcc     dech3

bufkey1:
        iny                     ;get next character
bufkey:
        lda     (cbp),y
        cmp     #' '            ;space terminator
        beq     bk9

;----------------------------------------------------------------------
;               convert lower to uppercase
;----------------------------------------------------------------------
loupch1:
        cmp     #'a'
        bcc     bk2
        cmp     #'z'+1
        bcs     bk2             ;check eoln
        eor     #'a'-'A'
        rts

;----------------------------------------------------------------------
;               get character from commandline
;----------------------------------------------------------------------
getbuf1:
        lda     inbuf,y         ;inputbuffer,Y
bk2:
        cmp     #0              ;check eoln
        beq     bk9
        cmp     #$0d            ;test <cr> ('\r')
bk9:
        clc                     ;clear carry
        rts

setcbp:
        sty     cbp             ;set string address
        sta     cbp+1
        ldy     #0
        jsr     calposp         ;skip spaces
        ldy     #$ff            ;-1

sech1:
        iny                     ;next
sechar:
        lda     (cbp),y         ;skip spaces
        cmp     #' '
        beq     sech1
        bne     bk2

;************************************************************
;               parameter option scanning
;************************************************************
spar1:
        stx     mode            ;bit 7:decimal, 6:+option
        sec                     ;    5:no clear
        bcs     l11
sopt1:
        clc                     ;get options => X
l11:
        php
        jsr     setcbp          ;set line address
        plp
        pla
        sta     opp             ;return address
        sta     tepo
        pla
        sta     opp+1
        sta     tepo+1
sopt0:
        jsr     tincr           ;search new return address
        bne     sopt0
        lda     tepo+1
        pha                     ;set return address
        lda     tepo
        pha
        lda     (cbp),y
        bcc     sopt10          ;-options
;----------------------------------------------------------------------
;               scan parameters
;----------------------------------------------------------------------
        sty     tepo
        sty     tepo+1          ;clear param
        bit     mode            ;mode
        bvc     spar22
        cmp     #'+'            ;check + option
        beq     spar21
        inc     mode            ;flag no param
        dey
spar21:
        iny
spar22:
        sec
spar2:
        ror     tepo+1          ;clear param
        ldx     #opp
        jsr     incr            ;set next
        beq     spar8           ;till last
        tax                     ;set page 0 X
        lda     #$20
        and     mode            ;clear current par
        bne     spar20          ;no
        sta     0,x
        sta     1,x
spar20:
        lda     mode            ;scan enabled
        lsr
        bcc     spar40
        dey
spar26:
        iny
spar25:
        clc
        bcc     spar2           ;continue

spar3:
        jsr     inshf
        iny
spar40:
        jsr     bufkey          ;while no terminator
        beq     spar2
        jsr     ascdh           ;and hex
        bcc     spar3
        cmp     #','            ;parameter terminator
        beq     spar26

spar9:
        lda     #e16            ;error data
        sec
        rts

spar8:
        ldx     tepo
        stx     mode
        bcc     calposp         ;calc next

;----------------------------------------------------------------------
;               scan options
;----------------------------------------------------------------------
sopt10:
        sty     opt
        cmp     #'-'
        beq     sopt6
        bne     sopt8           ;no
sopt4:
        sta     tepo+1
        tya                     ;save Y
        tax
        ldy     #0
sopt3:
        iny
        lda     (opp),y
        beq     sopt9           ;err
        eor     tepo+1
        bne     sopt3           ;test option table
        sec
sopt5:
        ror                     ;shift bit in A
        dey
        bne     sopt5           ;until Y equal start
        ora     opt             ;set bit in OPT
        sta     opt
        txa
        tay
sopt6:
        jsr     bufkey1         ;get next char
        bne     sopt4           ;check option
sopt8:
        ldx     opt

;----------------------------------------------------------------------
;               skip spaces and calculate new address
;----------------------------------------------------------------------
calposp:
        jsr     sechar
calpoin:
        tya                     ;calc address
        clc
        adc     cbp
        tay
        lda     cbp+1
        adc     #0
        sty     cbp
        sta     cbp+1
        rts

sopt9:
        lda     #e15            ;option error
        sec
        rts

;----------------------------------------------------------------------
;               shift and add to current parameter
;----------------------------------------------------------------------
inshf:
        pha                     ;save
        lda     tepo            ;test first number
        bit     tepo+1
        bne     inshf1
        ora     tepo+1          ;set mask bit
        sta     tepo
        lda     #0
        sta     0,x
        sta     1,x
inshf1:
        lda     1,x             ;get *1
        pha
        lda     0,x
        asl     0,x             ;set *4
        rol     1,x
        asl     0,x
        rol     1,x
        bit     mode
        bmi     inshf2
        pla                     ;get *4
        lda     1,x
        pha
        lda     0,x
inshf2:
        clc                     ;calc *5 or *8
        adc     0,x
        sta     0,x
        pla
        adc     1,x
        sta     1,x
        asl     0,x             ;set *10 or *16
        rol     1,x
        clc
        pla                     ;add
        adc     0,x
        sta     0,x
        bcc     inshf3
        inc     1,x
inshf3:
        rts

