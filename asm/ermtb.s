; vim: set ft=asm6502-2 ts=8:

;----------------------------------------------------------------------
;			Orix SDK includes
;----------------------------------------------------------------------
.include "include/errors.inc"

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export ermtb

;----------------------------------------------------------------------
;				TABLES
;----------------------------------------------------------------------
.segment "RODATA"

	ermtb:
		;/!\ ATTENTION la longueur totale de la table ne doit pas
		;    être > 255 octets

                ; code erreur, "message"
                ;
                ; caractère: >= $80: fin du message
                ;           $ff -> Cr/Lf
                ;           $fe -> " error"
                ;           $fd -> " protected"
                ;           autre -> n° erreur (BCD)
                ;        <  $80:
                ;           >=10 -> affiche le caractère
                ;           <10 -> sous message
                ;             1 -> print filespec (drive ':' repertoire '/' fichier
                ;             2 -> print filename
                ;             3 -> print drive ':' track ':' sector
                ;           >=4 -> print drive
	        .byte     e1,"Mem. full",$ff
	        .byte     e2,"Disk full",$ff
	        .byte     e3,"BOF",$ff
	        .byte     e4,"EOF",$ff
	        .byte     e10,"Filename",$fe
	        .byte     e11,"Device",$fe
	        .byte     e12,"Filename missing",$ff
	        .byte     e13,2,"not found",$ff
	        .byte     e15,"Option",$fe
	        .byte     e16,"Data",$fe
	        ;.byte     e20,"No more entries",$ff
	        .byte     e21,1,"open file",$ff
	        .byte     e25,1,"delete",$fd
	        .byte     e26,1,"write",$fd
	        .byte     e27,1,"read",$fd
	        .byte     e28,1,"permission denied",$ff
	        .byte     e29,1,"incorrect format",$ff

	        .byte     e30,"File not open",$ff
	        .byte     e31,"Fd",$fe

	        .byte     $80,"Write",3,$fe
	        .byte     $90,"Read",3,$fe
	        .byte     $b0,"Dr:tr:sc",3,$fe
	        .byte     $c0,"Drive",4," not ready",$ff
	        .byte     $d0,"Disk",4,$fd
	        .byte     0,"Error ",$fc

