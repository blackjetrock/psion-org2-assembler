
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
	.word   op00
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

	CLR     POB_DDR2                ; make port 2 inputs again
 
        AIM     #^COE,POB_PORT6       ; SET SOE_B LOW
        OIM     #CS3,POB_PORT6      ; DESELECT THE SLOT AGAIN

	RTS

opaa:	ldaa    #$AA
	JSR     outpico
	CLC
	RTS

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

	;; ======================================================================
	;; 
	;; Main routine called by menu item
	;;
	
;; dicmain:
;; 	clra
;; 	ldab    bdevice
;; 	os	pk$setp
;; 	bcc	1$
;; 2$:
;; 	os	er$mess
;; 	rts
;; 1$:
;; 	ldx	#%prgend-%xx
;; 	clrb
;; 	os	pk$sadd
;; 	ldx	#decode
;; 	ldd	#8
;; 	os	pk$read			; read in 8 bytes
;; 	bcs	2$
;;     	ldd	#%prgend+10-%xx
;; 	std	btext
;; 	addd	decode
;; 	std	decode
;; 	addd	bind1
;; 	std	bind1
;; 	addd	bind2
;; 	std	bind2
;; 	addd	ends
;; 	std	ends

;; 	ldx	decode
;; 	clrb
;; 	os	pk$sadd
;; 	ldx	#decbuf
;; 	ldd	#60
;; 	os	pk$read			; read in the huffman decode
;; 	bcs	2$
;; rst:
;; 	os	ut$disp
;; 	.byte	12
;; 	.ascii	"DICT:"
;; 	.byte	0
;;     	clra
;; 	staa clen
;; 	staa flag
;; 	staa vchar
	
;; ; MAIN LOOP
;; dicloop:
;; 	ldaa clen
;; 	adda #5
;; 	ldab dpb_cust
;; 	orab #CURS_ON
;; 	os	dp$stat
;; 	os	kb$getk			; get a character
;; 	stab  char			; save it
;; 	ldaa  flag			; set if bottom line has error mess
;; 	beq	keytst
;; 	staa vchar		; no valid word yet
;; 	ldx	dpb_cpos
;; 	ldaa #D_CB			; clear the bottom line
;; 	os	dp$emit
;; 	xgdx
;; 	os	dp$stat
;; 	clra
;; 	staa flag
;; 	ldab char
;; keytst:
;; 	cmpb    #K_AC
;; 	bne	noac
;; 	ldd	dpb_cpos
;; 	cmpa    #5
;; 	bne	rst			; clear the display
;; 	andb #^CCURS_ON		; else leave
;; 	os	dp$stat
;; 	rts

;; ; Set carry if not alpha
;; isalpha:
;; 	cmpb #^a/A/
;; 	bcc	2$
;; 1$:
;; 	sec
;; 	rts
;; 2$:
;; 	cmpb #^a/[/
;; 	bcs	10$
;; 	cmpb #^a/a/
;; 	bcs	1$
;; 	cmpb #^a/{/
;; 	bcc	1$
;; 10$:
;; 	orab #^X20
;; 	clc
;; 	rts
;; ; Not ALL CLEAR
;; noac:
;; 	jsr	isalpha
;; 	bcc	is_alph
;; 	cmpb #K_DEL
;; 	bne	11$
;; 	jmp	dodel
;; 11$:
;; 	cmpb #K_UP
;; 	bne	12$
;; 	jmp	doup
;; 12$:
;; 	cmpb #K_DOWN
;; 	bne	13$
;; 	jmp	dodown
;; 13$:
;; 	cmpb #K_EXE
;; 	bne	ch_err
;; 	jmp	doexe
;; ch_err:
;; 	os	bz$bell			; error key
;; xdicloop:
;; 	bra	dicloop

;; ; Alpha has been received
;; is_alph:
;; 	ldaa clen
;; 	cmpa #10
;; 	bcc	ch_err
;; 	clra
;; 	staa vchar
;; 	ldaa char
;; 	os	dp$emit
;; 	tba
;; 	ldx	#tbuf
;; 	ldab clen			; save the character in the buffer
;; 	abx
;; 	staa 0,x
;; 	incb
;; 	stab clen
;; 	cmpb #3
;; 	bcs	xdicloop
;; getst:
;; 	jsr	getfst			; get/reget first word
;; 	bra	xdicloop
;; ;
;; dodel:
;; 	ldaa vchar
;; 	beq	10$
;; 	deca
;; 	staa vchar
;; 	os	ut$disp
;; 	.byte	32,8,0
;; 	ldx	dpb_cpos
;; 	ldaa #D_CB			; clear the bottom line
;; 	os	dp$emit
;; 	xgdx
;; 	os	dp$stat
;; 10$:
;; 	ldab clen
;; 	bne	1$
;; 	os	bz$bell
;; 	jmp	dicloop
;; 1$:
;; 	decb
;; 	stab clen
;; 	bsr	delc
;; 	ldab clen
;; 	cmpb #3
;; 	bcs	2$
;; 	jmp	getst
;; 2$:
;; 	ldx	dpb_cpos
;; 	ldaa #D_CB			; clear the bottom line
;; 	os	dp$emit
;; 	xgdx
;; 	os	dp$stat
;; 	jmp	dicloop
;; ;
;; delc:
;; 	os	ut$disp
;; 	.byte	D_BS,32,D_BS,0
;; 	rts

;; ; Get next word if possible
;; dodown:
;; doexe:
;; 	ldaa vchar
;; 	bne	godic
;; 	ldaa clen
;; 	cmpa #3
;; 	bcs	godic
;; 	jsr	get_nwrd
;; 	bcs	getst
;;  	jsr	disp

;; ; Go to main loop
;; godic:
;; 	jmp	dicloop

;; ; Get previous word
;; doup:
;; 	ldaa vchar
;; 	bne	godic			; No word displayed
;; 	ldaa clen
;; 	cmpa #3
;; 	bcs	godic			; word too short
;; 	bsr	getprv
;; 	bra	godic
;; ;
;; getprv:
;; 	ldx	wrd_c
;; 	bne	1$
;; 	os	bz$bell
;; 	rts
;; 1$:
;; 	dex
;; 	stx	twrd_c
;; 	jsr	firstw			;get the first word again
;; 2$:
;; 	ldx	twrd_c
;; 	cpx	wrd_c
;; 	beq	3$
;; 	jsr	get_nwrd
;; 	bcs	xerr
;; 	bra	2$
;; 3$:
;; 	jmp	disp

;; ; Get the next word
;; getnxt:
;; 	jsr	get_nwrd		; get next word
;; 	bra	dall

;; ; Get the first word
;; getfst:
;; 	jsr	firstw			; get first word
;; dall:
;; 	bcc	allok
;; xerr:
;; 	tstb
;; 	beq	dnfd
;; derror:
;; 	pshb			; general error encountered
;; 	os	dp$save
;; 	pulb
;; 	os	er$mess
;; 	os	dp$rest
;; 	rts

;; dnfd:
;; 	ldx	dpb_cpos		; word not found
;; 	pshx
;; 	os	ut$disp
;; 	.byte	D_BL,D_CB
;; 	.asciz	"NOT FOUND"
;; 	ldaa #1
;; 	stqa flag		;special opcode
;; 	pulx
;; 	xgdx
;; 	deca
;; 	psha
;; 	suba #5
;; 	staa clen
;; 	pula
;; 	os	dp$stat
;; 	rts
;; allok:
;; 	jmp	disp

;; ; Get the first word to match the current word
;; firstw:
;; 	ldx	dpb_cpos
;; 	ldaa #D_CB			; clear the bottom line
;; 	os	dp$emit
;; 	xgdx
;; 	os	dp$stat
;; 	clra
;; 	staa blen
;; 	staa ctextx
;; 	ldab tbuf			; first letter
;; 	stab buf
;; 	andb #^x1f
;;     	decb
;; 	aslb
;; 	aslb
;; 	ldx	bind1
;; 	abx
;; 	clrb
;; 	os	pk$sadd
;; 	os	pk$rwrd
;; 	pshb			; ??? swap bytes
;; 	tab
;; 	pula
;; 	pshb
;; 	andb #^x07
;; 	stab cind2x
;; 	pulb
;; 	lsrd
;; 	lsrd
;; 	lsrd
;; 	std	cind2y
;; 	os	pk$rwrd
;; 	pshb
;; 	tab
;; 	pula
;; 	std	ctexty
;; 	os	pk$rwrd
;; 	os	pk$rwrd
;; 	pshb
;; 	tab
;; 	pula
;; 	std	etexty

;; 	ldd	cind2y
;;  	addd	bind2			; add the base
;; 	xgdx
;; 	ldab cind2x
;; 	jsr	xbfill
;; 	bsr	get_five
;; 	stab buf+1
;; 	bsr	get_five
;; 	stab buf+2
;; 	bsr	get_ten
;; 3$:
;; 	ldab buf+1
;; 	cmpb tbuf+1
;; 	bne	1$
;; 	ldab buf+2
;; 	cmpb tbuf+2
;; 	beq	indxfnd
;; 1$:
;; 	bsr	get_five
;; 	cmpb #^a/{/
;; 	bne	2$
;; 	bsr	get_five
;; 	stab buf+1
;; 	bsr	get_five
;; 2$:
;; 	stab buf+2
;; 	bsr	get_ten
;; 	addd	ctexty
;; 	std	ctexty
;; 	cmpa etexty
;; 	bcs	3$
;; 	cmpb etexty+1
;; 	beq	notfnd
;; 	bcs	3$
;; notfnd:	
;; 	clrb
;; 	sec
;; 	rts
;; indxfnd:
;; 	ldd	ctexty
;;     	addd	btext
;; 	xgdx
;; 	ldab ctextx
;; 	jsr	xbfill
;; 1$:
;; 	bsr	get_nwrd
;; 	bcs	notfnd
;; 	jsr	comp				; compare with target word
;; 	bne	1$
;; 	clra
;; 	clrb
;; 	std	wrd_c				; word counter
;; 	clc
;; 	rts

;; get_five:
;; 	ldab #5
;; 	jsr	rdbits
;;  	tab
;; 	addb #^x60
;; 	rts
	
;; get_ten:
;; 	ldab #2
;; 	jsr	rdbits
;; 	psha
;; 	ldab #8
;; 	jsr	rdbits
;; 	tab
;; 	pula
;; x_rts:
;; 	clc				; clear carry
;; 	rts

;; ; Get next word
;; get_nwrd:
;; 	ldx	wrd_c
;; 	inx
;; 	stx	wrd_c
;; 	clra
;; 	staa endflg
;; 	staa ebufc
;; 	ldab blen
;; 	addb #3			; add base
;; 	stab lcnt
;; 4$:
;; 	tst	blen
;; 	bpl	5$
;; 	sec
;; 	rts
;; 5$:
;; 	bsr	xget_huff
;; 	cmpb #^x60
;; 	beq	x_rts			; word ended
;; 	cmpb #^a/|/
;; 	bne	2$
;; 	inc	blen			; extra repeated character
;; 	bra	5$
;; 2$:
;; 	cmpb #^a/{/
;; 	bne	3$
;; 	dec	blen			; one less repeated character
;; 	bra	5$
;; 3$:
;; 	tba
;; 	ldx	#buf-1
;; 	ldab lcnt
;; 	incb
;; 	stab lcnt
;; 	abx
;; 	staa 0,x
;; 	bra	4$

;; xget_huff:
;; 	ldaa endflg
;; 	beq	1$
;; 3$:
;; 	ldab ebufc
;; 	incb
;; 	stab ebufc
;; 	ldx	#ebuf-1
;; 	abx
;; 	ldab 0,x
;; 	rts
;; 1$:
;; 	bsr	get_huff
;; 	cmpb #^a/}/		; ending flag
;; 	bne	2$
;; 	bsr	get_end
;; 	bra	3$
;; 2$:
;; 	rts
	
;; ; Get the next character
;; get_huff:
;; 	ldx	#decbuf
;; 1$:
;; 	ldaa 0,x
;; 	ldab 1,x
;; 	pshb
;; 	psha
;; 	pshx
;; 	ldab #1
;; 	jsr	rdbits
;; 	pulx
;; 	pula
;; 	pulb
;; 	bne	2$
;; 	tab
;; 2$:
;; 	tstb
;; 	bmi	3$
;; 	abx
;; 	bra	1$
;; 3$:
;; 	andb #^x7f
;; 	rts

;; ; Get the word ending
;; get_end:
;; 	ldab #^x60
;; 	stab ebuf			; save eow for no ending case
;; 	ldab #2
;; 	jsr	rdbits
;; 	cmpa #3
;; 	beq	1$
;; 	psha
;; 	ldab #8
;; 	jsr	rdbits
;; 	tab
;; 	pula			; now have a 10 bit ending number
;; 	bsr	getend2
;; 1$:
;; 	ldab #1
;; 	stab endflg
;; 	rts
;; ; Get the ending into memory
;; getend2:
;; 	stab x2			; multiply by 2.5
;; 	std	x1
;; 	asld
;; 	asld
;; 	addd	x1
;; 	lsrd
;; 	addd	ends
;; 	xgdx
;; 	clrb
;; 	os	pk$sadd
;; 	ldx	#endbuf
;; 	ldd	#4
;; 	os	pk$read
;; 	clr	x1
;; 	ldaa endbuf
;; 	ldab x2
;; 	andb #1
;; 	beq	2$
;; 	ldab #4
;; 	stab x1
;; 	asla
;; 	asla
;; 	asla
;; 	asla
;; 2$:
;; 	staa x3+1
;; 	ldx	#endbuf
;; 	stx	x2
;; 	clrb
;; 4$:
;; 	pshb
;; 	bsr	xgetend
;; 	pulb
;; 	incb
;; 	oraa #^x60
;; 	ldx	#ebuf-1
;; 	abx
;; 	staa 0,x
;; 	cmpb #4
;; 	bne	4$
;; 3$:
;; 	ldaa #^x60
;; 	staa 1,x	
;; 	rts
;; ; get the next character of the ending
;; xgetend:
;; 	clra
;; 	staa x3			; cwrd
;; 	ldab #5
;; 2$:
;; 	pshb
;; 	ldab x1			; bits
;; 	cmpb #8
;; 	bne	1$
;; 	ldx	x2
;; 	inx
;; 	ldab 0,x
;; 	stx	x2
;; 	stab x3+1
;; 	clrb
;; 1$:
;; 	incb
;; 	stab x1
;; 	ldd	x3			; cwrd
;; 	asld
;; 	std	x3
;; 	pulb
;; 	decb
;; 	bne	2$
;; 	ldaa x3
;; 	rts

;; ; Display the word
;; disp:
;; 	ldx	dpb_cpos
;; 	pshx
;; 	ldab lcnt
;;     	cmpb #17
;; 	bcc	1$
;; 	ldx	#buf
;; 	abx
;; 	clr	0,x
;; 	ldd	#dbuf
;; 	os	ut$ddsp
;; 	bra	2$
;; 1$:
;; 	ldd	#4
;; 	std	utw_s0
;; 	inca			; bottom line
;; 	ldab lcnt
;; 	ldx	#buf
;; 	os	dp$view
;; 	os	kb$uget			; return key to buffer
;; 2$:
;; 	pulx
;; 	xgdx
;; 	os	dp$stat
;; 	rts
;; ;
;; xbfill:
;; 	stab nbit
;; 	pshx
;; 	xgdx
;; 	addd	#^x100
;; 	std	cpos
;; 	pulx
;; 	clrb
;; 	os	pk$sadd
;; 	ldx	#loadt
;; 	stx	nbyt
;; 	ldd	#^x100
;; 	os	pk$read
;; 	ldx	nbyt
;; 	ldaa 0,x
;;     	ldab nbit
;; 	inx
;; 	stx	nbyt
;; 2$:
;; 	decb
;; 	bmi	1$
;; 	asla
;; 	bra	2$
;; 1$:
;; 	staa cwrd+1
;;  	ldab #8
;;     	subb nbit
;;     	stab nbit
;; 	rts


;; bfill:
;; 	ldx	cpos
;; 	pshx
;; 	xgdx
;; 	addd	#^x100
;; 	std	cpos
;; 	pulx
;; 	clrb
;; 	os	pk$sadd
;; 	ldx	#loadt
;; 	stx	nbyt
;; 	ldd	#^x100
;; 	os	pk$read
;; 	rts


;; ; Get B bits in B reg
;; rdbits:
;; 	clra
;; 	staa cwrd
;; rloop:
;; 	pshb
;; 	ldab nbit
;; 	bne	2$
;; 	ldx	nbyt
;; 	cpx	#loade
;; 	bcs	1$
;; 	bsr	bfill
;; 	ldx	nbyt
;; 1$:
;; 	ldab #8
;; 	ldaa 0,x
;; 	inx
;; 	stx	nbyt
;; 	staa cwrd+1
;; 2$:
;; 	decb
;; 	stab nbit
;; 	ldd	cwrd
;; 	asld
;; 	std	cwrd
;; 	pulb
;; 	decb
;; 	bne	rloop
;; 	ldaa cwrd
;; 	rts

;; ; compares the existing with the target
;; comp:
;; 	ldaa clen
;; 	suba #2
;; 	ldx	#buf+3
;; 	stx	x1
;; 	ldx	#tbuf+3
;; 	stx	x2
;; 2$:
;; 	deca
;; 	beq	1$			; match
;; 	ldx	x1
;; 	ldab 0,x
;; 	inx
;; 	stx	x1
;; 	ldx	x2
;; 	cmpb 0,x
;; 	bne	1$
;; 	inx
;; 	stx	x2
;; 	bra	2$
;; 1$:
;; 	rts

	
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
	

