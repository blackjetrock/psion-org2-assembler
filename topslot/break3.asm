
	;; .nlist
	.INCLUDE MOSHEAD.INC
	.INCLUDE MOSVARS.INC
	.INCLUDE MSWI.INC

; ============================
; Zero page variable declarations

;; $org	equ	zpg_free

nbit	equ	zpg_free
clen	equ	nbit+1
flag	equ	clen+1
char	equ	flag+1
vchar	equ	char+1
nbyt	equ	vchar+1
cpos	equ	nbyt+2
cwrd	equ	cpos+2

ctextx	equ	cwrd+2
ctexty	equ	ctextx+1
cind2x	equ	ctexty+2
cind2y	equ	cind2x+1

lcnt	equ	cind2y+2
blen	equ	lcnt+1
endflg	equ	blen+1
x1	equ	endflg+1
x2	equ	x1+2
x3	equ	x2+2

	;; .list

	;; .asect

	.org	$2000		; Make sure code is not in zero page.

				; Header for BLDPACK
	;; .ascii	"ORG"
	;; .word	%prgend-%xx
	;; .byte	^xFF

xx:	.byte	^x46		; PACK BOOTABLE, WRITE AND COPY PROTECTED
	.byte	^x04		; 32K PACK
	.byte	1		; DEVICE AND CODE
	.byte	10		; DEVICE NUMBER
	.byte	0		; DEVICE VERSION NUMBER
	.byte	10		; PRIORITY NUMBER                     
        .word	%root-%xx	; ROOT OVERLAY ADDRESS
	;; .word	start		;
	.byte	^Xff		; N/C
	.byte	^Xff		; N/C
	.byte	^X09
	.byte	^X81
	.ascii	"MAIN    "
	.byte	^X90
	.byte	^x02
	.byte	^x80
	.word	%prgend-%root   ; size of code

;==========================================================================
	
        .over   root
start:	
codelen:
	.word	0000
bdevice:
	.byte	00
devnum:
	.byte	10   
vernum:
	.byte	0         
maxvec:
	.byte	3

	;; Vector Table
vectable:
	.word	install		;install
	.word	remove		;remove
	.word	lang	   	;language

	;; Menu items
;; ditem:
;; 	.ascic	"DICT"
;; 	.word	dicmain		;Execution address
 olitmaa:	
 	.ascic  "LATOUTAA"
 	.word   lataa

 olitm00:	
 	.ascic  "LATOUT00"
 	.word   lat00

 olitmff:	
 	.ascic  "LATOUTFF"
 	.word   latff

ilitm:	
	.ascic  "LATIN"
	.word   latin
opaaitm:	
	.ascic  "PICOOUTAA"
	.word   opaa
op00itm:	
	.ascic  "PICOOUT00"
	.word   op00
opffitm:	
	.ascic  "PICOOUTFF"
	.word   opff
ipitm:	
	.ascic  "PICOIN"
	.word   op00
	
install:
	 LDX	#olitmaa       ;Copy menu item to buffer ready to insert in menu
         JSR     insitm

	 LDX	#olitm00	;Copy menu item to buffer ready to insert in menu
         JSR     insitm

	 LDX	#olitmff	;Copy menu item to buffer ready to insert in menu
         JSR     insitm

	LDX     #ilitm
	JSR     insitm

	LDX     #opaaitm
	JSR     insitm

	LDX     #op00itm
	JSR     insitm

	LDX     #opffitm
	JSR     insitm

	LDX     #ipitm
	JSR     insitm

	RTS
	
insitm:	
	LDAB    0,X		;Get length
	ADDB    #3			;Add 3 bytes
	CLRA
	STD	utw_s0		;
	LDD	#rtb_bl
	os	ut$cpyb
	LDAB    #^XFF		;Before OFF
	os	tl$addi
	RTS

remove:
	;; remove menu items
	LDX	#olitmaa       ;Copy menu item to buffer ready to insert in menu
	os	tl$deli

	LDX	#olitm00	;Copy menu item to buffer ready to insert in menu
	os	tl$deli

	LDX	#olitmff	;Copy menu item to buffer ready to insert in menu
	os	tl$deli		

	LDX     #ilitm
	os	tl$deli

	LDX     #opaaitm
	os	tl$deli

	LDX     #op00itm
	os	tl$deli

	LDX     #opffitm
	os	tl$deli

	LDX     #ipitm
	os	tl$deli

	clc
	rts
lang:
	sec
	rts

	;; ======================================================================
	;; 
	;; output a number to the Pico IO port
	;; A holds value to output
	;; 
outpico:
	PSHA			; Save data for later
	CLRA
        LDAB    #PAKD
        os      pk$setp                 ; SELECT DATAPACK AS NORMAL
        OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT

	;; Make port 2 outputs
        LDAA    #$FF	
        STAA    POB_DDR2             ; make port 2 output
        PULA                          ; get data back
        STAA    POB_PORT2            ; data on data bus
 
        OIM     #OE,POB_PORT6           ; SET SOE_B HIGH
	AIM     #^CMR,POB_PORT6           ; SMR LOW
        AIM     #^CCS3,POB_PORT6	; SELECT THE SLOT AGAIN
        AIM     #^CCS3,POB_PORT6	; SELECT THE SLOT AGAIN
        AIM     #^CCS3,POB_PORT6	; SELECT THE SLOT AGAIN
        AIM     #^CCS3,POB_PORT6	; SELECT THE SLOT AGAIN

				; hardware now selected, it will write data bus value
	;; to Pico port
        ; THE CONTROL LINES ARE IN STATE 1 OR 2

	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT
	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT
	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT
	
	CLR     POB_DDR2                ; make port 2 inputs again
 
        AIM     #^COE,POB_PORT6       ; SET SOE_B LOW
        OIM     #CS3,POB_PORT6      ; DESELECT THE SLOT AGAIN

	RTS

opaa:	ldaa    #$AA
	JSR     outpico
	CLC
	RTS

	;; --------------------------------------------------

readil:
	CLRA
        LDAB    #PAKD
        os      pk$setp                 ; SELECT DATAPACK AS NORMAL
        OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT

	;; Make port 2 outputs
        LDAA    #$FF	
        CLR     POB_DDR2             ; make port 2 inputs
 
        AIM     #^COE,POB_PORT6           ; SET SOE_B LOW
	OIM     #MR,POB_PORT6           ; SMR HIGH
	AIM     #^CCLK, POB_PORT6       ; CLK low
	
        AIM     #^CCS3,POB_PORT6	; SELECT THE SLOT AGAIN
        AIM     #^CCS3,POB_PORT6	; SELECT THE SLOT AGAIN
        AIM     #^CCS3,POB_PORT6	; SELECT THE SLOT AGAIN
        AIM     #^CCS3,POB_PORT6	; SELECT THE SLOT AGAIN

	;; Hardware in state 4, the input latch will be on the bus
	LDAA    POB_PORT2
	PSHA
	
	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT
	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT
	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT
	
	CLR     POB_DDR2                ; make port 2 inputs again
 
        AIM     #^COE,POB_PORT6       ; SET SOE_B LOW
        OIM     #CS3,POB_PORT6      ; DESELECT THE SLOT AGAIN

	PULA
	RTS
	
	;; --------------------------------------------------
	;; Read the input latch and display the value read
	;; on the screen
	
latin:

	
	LDX     #0              ; No cursor, pos 0
	os      dp$stat
				;read the latch
        LDAA    #^xAA
	JSR     readil
	
	;; Display it
	PSHA                    ;Push it on to stack
	os ut$disp
	.byte   D_FF
	.asciz  "ILAT:%y"

	;; Get key
	os kb$test
	TSTB
	BEQ   latin
	
	CLC
	RTS

	;; --------------------------------------------------
	
op00:	ldaa    #$00
	JSR     outpico
	CLC
	RTS

opff:	ldaa    #$FF
	JSR     outpico
	CLC
	RTS


	;; ======================================================================
	;; 
	;; output a number to the Pico IO port
	;; A holds value to output
	;; 
latcho:
	PSHA			; Save data for later
	CLRA
        LDAB    #PAKD
        os      pk$setp                 ; SELECT DATAPACK AS NORMAL
        OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT

	;; Make port 2 outputs
        LDAA    #$FF	
        STAA    POB_DDR2             ; make port 2 output
        PULA                          ; get data back
        STAA    POB_PORT2            ; data on data bus
 
        OIM     #OE,POB_PORT6           ; SET SOE_B HIGH
	OIM     #MR,POB_PORT6           ; SMR HIGH
	OIM     #CLK,POB_PORT6		  ; SCLK HIGH (don't care)
        AIM     #^CCS3,POB_PORT6      ; SELECT THE SLOT AGAIN
        AIM     #^CCS3,POB_PORT6      ; SELECT THE SLOT AGAIN
        AIM     #^CCS3,POB_PORT6      ; SELECT THE SLOT AGAIN

	; hardware now selected, it will write data bus value
	;; to output latch
        ; THE CONTROL LINES ARE IN STATE 1 OR 2

	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT
	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT
	OIM     #CS3,POB_PORT6          ; DESELECT THE SLOT	

	CLR     POB_DDR2                ; make port 2 inputs again
 
        AIM     #^COE,POB_PORT6       ; SET SOE_B LOW
        OIM     #CS3,POB_PORT6        ; DESELECT THE SLOT AGAIN

	RTS

lataa:	ldaa    #$AA
	JSR     latcho
	CLC
	RTS

lat00:	ldaa    #$00
	JSR     latcho
	CLC
	RTS

latff:	ldaa    #$FF
	JSR     latcho
	CLC
	RTS

	
;
ebufc:	.byte	0
btext:	.word	0

etexty:	.word	0

wrd_c:	.word	0
twrd_c:	.word	0
decode:	.word	0
bind1:	.word	0
bind2:	.word	0
ends:	.word	0
endbuf:	.blkb	4
decbuf:	.blkb	60
dbuf:	.byte	D_CB
buf:	.blkb	54
tbuf:	.blkb	12
ebuf:	.blkb	5
loadt:	.blkb	256
loade:
				;
	.eover

	.over  prgend
	.eover
;; prgend:				
	

