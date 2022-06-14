; vim: set ft=asm6502-2 ts=8 et:

.ifndef CH376_INC

	;=======================================================================
        ;
        ;			Adresse de l'interface CH376
        ; déclaré dans telestrat.inc (cc65)
	;=======================================================================
        ; CH376_COMMAND   = $0341
        ; CH376_DATA      = $0340

	;=======================================================================
	;
	;			Codes commande du CH376
	;
	;=======================================================================
        CH376_GET_IC_VER	= $01
        CH376_SET_BAUDRATE	= $02
        CH376_ENTER_SLEEP	= $03

        ;	CH376_UNDEF_FUNCTION	= $04 SET_USB_SPEED

        CH376_RESET_ALL		= $05
        CH376_CHECK_EXIST	= $06

        ;	CH376_UNDEF_FUNCTION	= $07
        ;	CH376_UNDEF_FUNCTION	= $08
        ;	CH376_UNDEF_FUNCTION	= $09

        CH376_READ_VAR8         = $0A           ; si var=$07 -> GET_DEV_RATE
        CH376_WRITE_VAR8	= $0B           ; si var=$16 -> SET_SD0_INT, var=$25 -> SET_RETRY
        CH376_READ_VAR32	= $0C           ; si var=$68 -> GET_FILE_SIZE
        CH376_WRITE_VAR32	= $0D           ; si var=$68 -> SET_FILE_SIZE

        ;	CH376_UNDEF_FUNCTION	= $0E
        ;	CH376_UNDEF_FUNCTION	= $0F DELAY_100US
        ;	CH376_UNDEF_FUNCTION	= $10
        ;	CH376_UNDEF_FUNCTION	= $11
        ;	CH376_UNDEF_FUNCTION	= $12 SET_USB_ID (CH375)

        CH376_SET_USB_ADDR	= $13

        ;	CH376_UNDEF_FUNCTION	= $14

        CH376_SET_USB_MODE	= $15

        ;	CH376_UNDEF_FUNCTION	= $16 TEST_CONNECT
        ;	CH376_UNDEF_FUNCTION	= $17 ABORT_NAK
        ;	CH376_UNDEF_FUNCTION	= $18 SET_ENDP2 (CH375)
        ;	CH376_UNDEF_FUNCTION	= $19 SET_ENDP3  "
        ;	CH376_UNDEF_FUNCTION	= $1A SET_ENDP4  "
        ;	CH376_UNDEF_FUNCTION	= $1B SET_ENDP5  "

        CH376_SET_ENDP6		= $1C
        CH376_SET_ENDP7		= $1D

        ;	CH376_UNDEF_FUNCTION	= $1E
        ;	CH376_UNDEF_FUNCTION	= $1F
        ;	CH376_UNDEF_FUNCTION	= $20
        ;	CH376_UNDEF_FUNCTION	= $21

        CH376_GET_STATUS	= $22

        ;	CH376_UNDEF_FUNCTION	= $23
        ;	CH376_UNDEF_FUNCTION	= $24
        ;	CH376_UNDEF_FUNCTION	= $25 DIRTY_BUFFER
        ;	CH376_UNDEF_FUNCTION	= $26

        CH376_RD_USB_DATA0	= $27
        CH376_RD_USB_DATA	= $28

        ;	CH376_UNDEF_FUNCTION	= $29 WR_USB_DATA3 (CH375)
        ;	CH376_UNDEF_FUNCTION	= $2A WR_USB_DATA5   "

        CH376_WR_USB_DATA7	= $2B
        CH376_WR_USB_DATA	= $2C
        CH376_WR_REQ_DATA	= $2D
        CH376_WR_OFS_DATA	= $2E

        ;Host file mode
        CH376_SET_FILENAME	= $2F
        CH376_DISK_CONNECT	= $30
        CH376_DISK_MOUNT	= $31
        CH376_FILE_OPEN		= $32
        CH376_FILE_ENUM_GO	= $33
        CH376_FILE_CREATE	= $34
        CH376_FILE_ERASE	= $35
        CH376_FILE_CLOSE	= $36
        CH376_DIR_INFO_READ	= $37
        CH376_DIR_INFO_SAVE	= $38
        CH376_BYTE_LOCATE	= $39
        CH376_BYTE_READ		= $3A
        CH376_BYTE_RD_GO	= $3B
        CH376_BYTE_WRITE	= $3C
        CH376_BYTE_WR_GO	= $3D
        CH376_DISK_CAPACITY	= $3E
        CH376_DISK_QUERY	= $3F
        CH376_DIR_CREATE	= $40

        ;	CH376_UNDEF_FUNCTION	= $41 CLR_STALL
        ;	CH376_UNDEF_FUNCTION	= $42
        ;	CH376_UNDEF_FUNCTION	= $43
        ;	CH376_UNDEF_FUNCTION	= $44

        CH376_SET_ADDRESS	= $45
        CH376_GET_DESCR		= $46

        ;	CH376_UNDEF_FUNCTION	= $47
        ;	CH376_UNDEF_FUNCTION	= $48

        CH376_SET_CONFIG	= $49
        CH376_SEC_LOCATE	= $4A
        CH376_SEC_READ		= $4B
        CH376_SEC_WRITE		= $4C

        ;	CH376_UNDEF_FUNCTION	= $4D AUTO_SETUP
        ;	CH376_UNDEF_FUNCTION	= $4E ISSUE_TKN_X

        CH376_ISSUE_TOKEN	= $4F

        ; Host mode (USB uniquemnt)
        CH376_DISK_BOC_CMD	= $50

        ;	CH376_UNDEF_FUNCTION	= $51 DISK_INIT
        ;	CH376_UNDEF_FUNCTION	= $52 DISK_RESET
        ;	CH376_UNDEF_FUNCTION	= $53 DISK_SIZE (CH375)

        CH376_DISK_READ		= $54
        CH376_DISK_RD_GO	= $55
        CH376_DISK_WRITE	= $56
        CH376_DISK_WR_GO	= $57

        ;	CH376_DISK_INQUIRY	= $58
        ;	CH376_DISK_READY	= $59
        ;	CH376_DISK_R_SENSE	= $5A
        ;	CH376_RD_DISK_SEC	= $5B
        ;	CH376_WR_DISK_SEC	= $5C
        ;	CH376_DISK_MAX_LUN	= $5D

                ;---------------------------------------------------------------
                ;                       Pour compatibilité
                ;---------------------------------------------------------------
        CH376_SET_SD0_INT	= $0B
        CH376_GET_FILE_SIZE	= $0C


	;=======================================================================
	;
	;			Modes du CH376
	;
	;=======================================================================
        CH376_MODE_USB_DEVICE_OUTER_FW  = $01
        CH376_MODE_USB_DEVICE_INNER_FW  = $02
	CH376_MODE_SDCARD               = $03
        CH376_MODE_INVALID_USB_HOST     = $04
	CH376_MODE_USB_HOST_NO_SOF      = $05
	CH376_MODE_USB_HOST             = $06
        CH376_MODE_USB_HOST_RESET       = $07


	;=======================================================================
	;
	;			Codes d'erreur du CH376
	;
	;=======================================================================
        ; 00 - 0F: Interruption state of USB device (cf CH372)
        ; 10 - 1F: Interruption state in SD or USB-HOST mode
        ; 20 - 3F: Failure operation of USB-HOST
        ;               7 6 5 4 3 2 1 0
        ;               | | | | |     |
        ;               | | | | +-----+--> USB device failure (1010-> NAK, 1110-> STALL, XX00-> timeout, other-> PID of device)
        ;               | | | +----------> Synchronous sign of IN  transaction (data may be invalid if 0)
        ;               | | +------------> 1
        ;               +-+--------------> Reserved 00
        ; 40 - 4F: File system notice code
        ; 80 - BF: File system error code

	; SUCCESS        = $12

        ; 10 - 1F
	CH376_USB_INT_SUCCESS   = $14           ; Success of SD or USB transaction
        CH376_USB_INT_CONNECT 	= $15           ; Detection of USB device attachment
        CH376_USB_INT_DISCONNECT= $16           ; Detection of device detachment
        CH376_USB_INT_BUF_OVER 	= $17           ; Data error or Buffer overfow
        CH376_USB_INT_USB_READY = $18           ; USB device initialized
	CH376_USB_INT_DISK_READ = $1D           ; Read operation
	CH376_USB_INT_DISK_WRITE= $1E           ; Write operation
        CH376_USB_INT_DISK_ERR 	= $1F           ; Failure of USB storage device


        ; File system notice code
        ; 40 - 4F
	CH376_ERR_OPEN_DIR      = $41           ; Open directory
        CH376_ERR_MISS_FILE     = $42           ; File not found
        CH376_ERR_FOUND_NAME	= $43           ; File or Directory found

        CH376_RET_SUCCESS       = $51           ;
	CH376_RET_ABORT         = $5F           ;

        ; File system error code
        ; 80 - BF
        CH376_ERR_DISK_DISCON   = $82           ; Disk doesn't connect
        CH376_ERR_LARGE_SECTOR  = $84           ; Fan too big (only 512 bytes)
        CH376_ERR_TYPE_ERROR    = $92           ; Disk partition error

        CH376_ERR_BPB_ERROR     = $A1           ; Disk format error

        CH376_ERR_DISK_FULL     = $B1           ; Disk full
        CH376_ERR_FDT_OVER      = $B2           ; Too many files in directory
                                                ; (max 512 in FAT12/FAT16)
        CH376_ERR_FILE_CLOSE    = $B4           ; File is closed, re-open file


	;=======================================================================
        ;
        ;                               Variables
        ;
	;=======================================================================

                ;---------------------------------------------------------------
                ;               Variables 8 bits
                ;---------------------------------------------------------------

        CH376_VAR_SYS_BASE_INFO = $20           ; Informations de base du système actuel
                                                ;           Le bit 6 est utilisé pour indiquer la sous-classe SubClass-Code du périphérique de stockage USB, si le bit 6 est 0, cela signifie que la sous-classe est 6, et si le bit 6 est 1, il signifie que la sous-classe est une valeur autre que 6
                                                ;           Le bit 5 est utilisé pour indiquer l'état de la configuration USB en mode périphérique USB et l'état de la connexion du périphérique USB en mode hôte USB
                                                ;           En mode périphérique USB, si le bit 5 est 1, la configuration USB est terminée, et si le bit 5 est 0, alors la configuration USB est terminée. Non configuré
                                                ;           En mode hôte USB, si le bit 5 est 1, il y a un périphérique USB sur le port USB, et si le bit 5 est à 0, il n'y a pas de périphérique USB dans le port USB.
                                                ;           Le bit 4 est utilisé pour indiquer l'état de verrouillage du tampon en mode périphérique USB, si le bit 4 est à 1, cela signifie que le tampon USB est verrouillé, si le bit 6 est à 1, cela signifie qu'il a été libéré
                                                ;           Autres bits, réservés, ne pas modifier

        CH376_VAR_RETRY_TIMES	= $25           ; Le nombre de tentatives pour l'opération de transaction USB
                                                ;           Si le bit 7 est 0, il ne réessayera pas lors de la réception de NAK, si le bit 7 est 1, si le bit 6 est 0, il réessayera indéfiniment lors de la réception de NAK (vous pouvez utiliser la commande CMD_ABORT_NAK pour abandonner la nouvelle tentative), si le bit 7 correspond à 1, le bit 6 correspond à 1 Réessayez pendant 3 secondes maximum lorsque NAK est reçu
                                                ;           Bit 5~bit 0 est le nombre de tentatives après expiration du délai

        CH376_VAR_FILE_BIT_FLAG = $26           ; indicateurs binaires en mode fichier hosts
                                                ;           Bit 1 et Bit 0, indicateur de système de fichiers FAT du disque logique, 00-FAT12, 01-FAT16, 10-FAT32, 11-Illegal
                                                ;           Bit 2, si les données de la table FAT dans le tampon actuel ont été modifiées, 0-non modifié, 1-modifié
                                                ;           Bit 3, la longueur du fichier doit être modifiée, le fichier actuel est ajouté avec des données, 0 - aucune modification n'est requise, 1 - a été ajouté et doit être modifié
                                                ;           Autres bits, réservés, ne pas modifier

        CH376_VAR_DISK_STATUS	= $2B           ; État du disque et du fichier en mode fichier hôte

        CH376_VAR_SD_BIT_FLAG	= $30           ; Indicateurs binaires pour la carte SD en mode fichier hôte
                                                ;           Bit 0, version de la carte SD, 0-prend en charge la première version SD uniquement, 1-prend en charge la deuxième version SD
                                                ;           Bit 1, identification automatique, carte 0-SD, carte 1-MMC
                                                ;           Bit 2, identification automatique, 0 carte SD de capacité standard, 1 carte SD de haute capacité (HC-SD)
                                                ;           Bit 4, temporisation de la commande ACMD41
                                                ;           Bit 5, temporisation de la commande CMD1
                                                ;           Bit 6, temporisation de la commande CMD58
                                                ;           Autres bits, réservés, ne pas modifier

        CH376_VAR_UDISK_TOGGLE  = $31           ; Indicateur de synchronisation pour les terminaux BULK-IN/BULK-OUT des périphériques de stockage USB
                                                ;           Bit 7, indicateur de synchronisation pour le point de terminaison Bulk-In
                                                ;           Bit 6, indicateur de synchronisation pour le point de terminaison Bulk-In
                                                ;           Bit 5~Bit 0, doit être 0

        CH376_VAR_UDISK_LUN	= $34           ; Numéro d'unité logique du périphérique de stockage USB
                                                ;           Bit 7 ~ bit 4, le numéro d'unité logique actuel du périphérique de stockage USB, après que CH376 initialise le périphérique de stockage USB, la valeur par défaut est d'accéder à l'unité logique 0 #
                                                ;           Bit 3~Bit 0, le numéro d'unité logique maximum du périphérique de stockage USB, plus 1 est égal au nombre d'unités logiques

        CH376_VAR_SEC_PER_CLUS  = $38           ; Le nombre de secteurs par cluster du disque logique

        CH376_VAR_FILE_DIR_INDEX= $3B           ; Le numéro d'index des informations actuelles du répertoire de fichiers dans le secteur

        CH376_VAR_CLUS_SEC_OFS  = $3C           ; Le décalage de secteur du pointeur de fichier actuel dans le cluster, s'il est 0xFF, il pointe vers la fin du fichier, la fin du cluster


                ;---------------------------------------------------------------
                ;               Variables 32 bits/4 octets
                ;---------------------------------------------------------------

        CH376_VAR_DISK_ROOT	= $44           ; Pour le disque FAT16, c'est le nombre de secteurs occupés par le répertoire racine, et pour le disque FAT32, c'est le numéro de cluster de départ du répertoire racine (longueur totale 32 bits, octet de poids faible en premier)

        CH376_VAR_DSK_TOTAL_CLUS= $48           ; Le nombre total de clusters du disque logique (longueur totale 32 bits, octet de poids faible en premier)

        CH376_VAR_DSK_START_LBA = $4C           ; Le numéro de secteur absolu de départ LBA du disque logique (longueur totale 32 bits, octet de poids faible en premier)

        CH376_VAR_DSK_DAT_START = $50           ; Le LBA de départ de la zone de données du disque logique (longueur totale 32 bits, octet de poids faible en premier)

        CH376_VAR_LBA_BUFFER	= $54           ; LBA correspondant aux données dans le tampon de données du disque actuel (longueur totale 32 bits, octet de poids faible en premier)

        CH376_VAR_LBA_CURRENT	= $58           ; L'adresse LBA de démarrage du disque de lecture et d'écriture actuelle (longueur totale 32 bits, octet de poids faible en premier)

        CH376_VAR_FAT_DIR_LBA	= $5C           ; L'adresse LBA du secteur où se trouvent les informations actuelles du répertoire de fichiers (longueur totale 32 bits, octet de poids faible en premier)

        CH376_VAR_START_CLUSTER = $60           ; Le numéro de cluster de départ du fichier ou du répertoire (dossier) actuel (la longueur totale est de 32 bits, octet de poids faible en premier)

        CH376_VAR_CURRENT_CLUST = $64           ; Le numéro de cluster actuel du fichier actuel (la longueur totale est de 32 bits, octet de poids faible en premier)

        CH376_VAR_FILE_SIZE	= $68           ; La longueur du fichier actuel (longueur totale 32 bits, octet de poids faible en premier)

        CH376_VAR_CURRENT_OFFSET= $6C           ; Le pointeur de fichier actuel, le décalage d'octet de la position de lecture et d'écriture actuelle (longueur totale 32 bits, octet de poids faible en premier)


	;=======================================================================
        ;
	;=======================================================================
	CH376_INC = 1

.endif


