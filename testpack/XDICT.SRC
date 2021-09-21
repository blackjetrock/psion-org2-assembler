/******************************************************************************/
/*									      */
/*	written on........11/APR/85					      */
/*	written by........COLLY/Martin					      */
/*	version no........1.0						      */
/*									      */
/*	Contains dictionary software					      */
/******************************************************************************/

	.nlist
#include "oshead.inc"
#include "osvars.inc"
#include "swi.inc"

; ============================
; Zero page variable declarations

$org	equ	zpg_free

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

	.list

	.asect

	org	^X2000		; Make sure code is not in zero page.

				; Header for BLDPACK
	.ascii	"ORG"
	.word	%prgend-%xx
	.byte	^xFF

xx:	.byte	^x46		; PACK BOOTABLE, WRITE AND COPY PROTECTED
	.byte	^x04		; 32K PACK
	.byte	1		; DEVICE AND CODE
	.byte	10		; DEVICE NUMBER
	.byte	0		; DEVICE VERSION NUMBER
	.byte	10		; PRIORITY NUMBER
	.word	%root-%xx-2	; ROOT OVERLAY ADDRESS
	.byte	^Xff		; N/C
	.byte	^Xff		; N/C
	.byte	^X09
	.byte	^X81
	.ascii	"MAIN    "
	.byte	^X90
	.byte	^x02
	.byte	^x80
	.word	%prgend-%root+2 ; size of code

;==========================================================================
	.over	root

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
vectable:
	.word	install		;install
	.word	remove		;remove
	.word	lang	   	;language
ditem:
	.ascic	"DICT"
	.word	dicmain
install:
	ldx	#ditem
	lda	b,0,x
	add	b,#3
	clr	a
	std	utw_s0:
	ldd	#rtb_bl
	os	ut$cpyb
	lda	b,#^XFF
	os	tl$addi
	rts
remove:
	lda	a,^Xffe9
	cmp	a,#^X22
	bhi	1$

	ldx	#2$
	pshx
	ldx	^X835e
	lda	b,#^X118-^XFD
	abx
	pshx
	ldx	#ditem
   	rts

1$:	ldx	#ditem
   	os	tl$deli
2$:	clc
	rts
lang:
	sec
	rts
dicmain:
	clr	a
	lda	b,bdevice
	os	pk$setp
	bcc	1$
2$:
	os	er$mess
	rts
1$:
	ldx	#%prgend-%xx
	clr	b
	os	pk$sadd
	ldx	#decode
	ldd	#8
	os	pk$read			; read in 8 bytes
	bcs	2$
    	ldd	#%prgend+10-%xx
	std	btext
	addd	decode
	std	decode
	addd	bind1
	std	bind1
	addd	bind2
	std	bind2
	addd	ends
	std	ends

	ldx	decode
	clr	b
	os	pk$sadd
	ldx	#decbuf
	ldd	#60
	os	pk$read			; read in the huffman decode
	bcs	2$
rst:
	os	ut$disp
	.byte	12
	.ascii	"DICT:"
	.byte	0
    	clr	a
	sta	a,clen:
	sta	a,flag:
	sta	a,vchar:
; MAIN LOOP
dicloop:
	lda	a,clen:
	add	a,#5
	lda	b,dpb_cust:
	ora	b,#CURS_ON
	os	dp$stat
	os	kb$getk			; get a character
	sta	b,char:			; save it
	lda	a,flag:			; set if bottom line has error mess
	beq	keytst
	sta	a,vchar:		; no valid word yet
	ldx	dpb_cpos:
	lda	a,#D_CB			; clear the bottom line
	os	dp$emit
	xgdx
	os	dp$stat
	clr	a
	sta	a,flag:
	lda	b,char:
keytst:
	cmp	b,#K_AC
	bne	noac
	ldd	dpb_cpos:
	cmp	a,#5
	bne	rst			; clear the display
	and	b,#^C<CURS_ON>		; else leave
	os	dp$stat
	rts

; Set carry if not alpha
isalpha:
	cmp	b,#^a/A/
	bcc	2$
1$:
	sec
	rts
2$:
	cmp	b,#^a/[/
	bcs	10$
	cmp	b,#^a/a/
	bcs	1$
	cmp	b,#^a/{/
	bcc	1$
10$:
	ora	b,#^X20
	clc
	rts
; Not ALL CLEAR
noac:
	jsr	isalpha
	bcc	is_alph
	cmp	b,#K_DEL
	bne	11$
	jmp	dodel
11$:
	cmp	b,#K_UP
	bne	12$
	jmp	doup
12$:
	cmp	b,#K_DOWN
	bne	13$
	jmp	dodown
13$:
	cmp	b,#K_EXE
	bne	ch_err
	jmp	doexe
ch_err:
	os	bz$bell			; error key
xdicloop:
	bra	dicloop

; Alpha has been received
is_alph:
	lda	a,clen:
	cmp	a,#10
	bcc	ch_err
	clr	a
	sta	a,vchar:
	lda	a,char:
	os	dp$emit
	tba
	ldx	#tbuf
	lda	b,clen:			; save the character in the buffer
	abx
	sta	a,0,x
	inc	b
	sta	b,clen:
	cmp	b,#3
	bcs	xdicloop
getst:
	jsr	getfst			; get/reget first word
	bra	xdicloop
;
dodel:
	lda	a,vchar:
	beq	10$
	dec	a
	sta	a,vchar:
	os	ut$disp
	.byte	32,8,0
	ldx	dpb_cpos:
	lda	a,#D_CB			; clear the bottom line
	os	dp$emit
	xgdx
	os	dp$stat
10$:
	lda	b,clen:
	bne	1$
	os	bz$bell
	jmp	dicloop
1$:
	dec	b
	sta	b,clen:
	bsr	delc
	lda	b,clen:
	cmp	b,#3
	bcs	2$
	jmp	getst
2$:
	ldx	dpb_cpos:
	lda	a,#D_CB			; clear the bottom line
	os	dp$emit
	xgdx
	os	dp$stat
	jmp	dicloop
;
delc:
	os	ut$disp
	.byte	D_BS,32,D_BS,0
	rts

; Get next word if possible
dodown:
doexe:
	lda	a,vchar:
	bne	godic
	lda	a,clen:
	cmp	a,#3
	bcs	godic
	jsr	get_nwrd
	bcs	getst
 	jsr	disp

; Go to main loop
godic:
	jmp	dicloop

; Get previous word
doup:
	lda	a,vchar:
	bne	godic			; No word displayed
	lda	a,clen:
	cmp	a,#3
	bcs	godic			; word too short
	bsr	getprv
	bra	godic
;
getprv:
	ldx	wrd_c
	bne	1$
	os	bz$bell
	rts
1$:
	dex
	stx	twrd_c
	jsr	firstw			;get the first word again
2$:
	ldx	twrd_c
	cpx	wrd_c
	beq	3$
	jsr	get_nwrd
	bcs	xerr
	bra	2$
3$:
	jmp	disp

; Get the next word
getnxt:
	jsr	get_nwrd		; get next word
	bra	dall

; Get the first word
getfst:
	jsr	firstw			; get first word
dall:
	bcc	allok
xerr:
	tst	b
	beq	dnfd
derror:
	psh	b			; general error encountered
	os	dp$save
	pul	b
	os	er$mess
	os	dp$rest
	rts

dnfd:
	ldx	dpb_cpos:		; word not found
	pshx
	os	ut$disp
	.byte	D_BL,D_CB
	.asciz	"NOT FOUND"
	lda	a,#1
	sta	a,flag
	pulx
	xgdx
	dec	a
	psh	a
	sub	a,#5
	sta	a,clen:
	pul	a
	os	dp$stat
	rts
allok:
	jmp	disp

; Get the first word to match the current word
firstw:
	ldx	dpb_cpos:
	lda	a,#D_CB			; clear the bottom line
	os	dp$emit
	xgdx
	os	dp$stat
	clr	a
	sta	a,blen:
	sta	a,ctextx:
	lda	b,tbuf			; first letter
	sta	b,buf
	and	b,#^x1f
    	dec	b
	asl	b
	asl	b
	ldx	bind1
	abx
	clr	b
	os	pk$sadd
	os	pk$rwrd
	psh	b			; ??? swap bytes
	tab
	pul	a
	psh	b
	and	b,#^x07
	sta	b,cind2x:
	pul	b
	lsrd
	lsrd
	lsrd
	std	cind2y:
	os	pk$rwrd
	psh	b
	tab
	pul	a
	std	ctexty:
	os	pk$rwrd
	os	pk$rwrd
	psh	b
	tab
	pul	a
	std	etexty

	ldd	cind2y:
 	addd	bind2			; add the base
	xgdx
	lda	b,cind2x:
	jsr	xbfill
	bsr	get_five
	sta	b,buf+1
	bsr	get_five
	sta	b,buf+2
	bsr	get_ten
3$:
	lda	b,buf+1
	cmp	b,tbuf+1
	bne	1$
	lda	b,buf+2
	cmp	b,tbuf+2
	beq	indxfnd
1$:
	bsr	get_five
	cmp	b,#^a/{/
	bne	2$
	bsr	get_five
	sta	b,buf+1
	bsr	get_five
2$:
	sta	b,buf+2
	bsr	get_ten
	addd	ctexty:
	std	ctexty:
	cmp	a,etexty
	bcs	3$
	cmp	b,etexty+1
	beq	notfnd
	bcs	3$
notfnd:	
	clr	b
	sec
	rts
indxfnd:
	ldd	ctexty:
    	addd	btext
	xgdx
	lda	b,ctextx:
	jsr	xbfill
1$:
	bsr	get_nwrd
	bcs	notfnd
	jsr	comp				; compare with target word
	bne	1$
	clr	a
	clr	b
	std	wrd_c				; word counter
	clc
	rts

get_five:
	lda	b,#5
	jsr	rdbits
 	tab
	add	b,#^x60
	rts
	
get_ten:
	lda	b,#2
	jsr	rdbits
	psh	a
	lda	b,#8
	jsr	rdbits
	tab
	pul	a
x_rts:
	clc				; clear carry
	rts

; Get next word
get_nwrd:
	ldx	wrd_c
	inx
	stx	wrd_c
	clr	a
	sta	a,endflg:
	sta	a,ebufc
	lda	b,blen:
	add	b,#3			; add base
	sta	b,lcnt:
4$:
	tst	blen
	bpl	5$
	sec
	rts
5$:
	bsr	xget_huff
	cmp	b,#^x60
	beq	x_rts			; word ended
	cmp	b,#^a/|/
	bne	2$
	inc	blen			; extra repeated character
	bra	5$
2$:
	cmp	b,#^a/{/
	bne	3$
	dec	blen			; one less repeated character
	bra	5$
3$:
	tba
	ldx	#buf-1
	lda	b,lcnt:
	inc	b
	sta	b,lcnt:
	abx
	sta	a,0,x
	bra	4$

xget_huff:
	lda	a,endflg:
	beq	1$
3$:
	lda	b,ebufc
	inc	b
	sta	b,ebufc
	ldx	#ebuf-1
	abx
	lda	b,0,x
	rts
1$:
	bsr	get_huff
	cmp	b,#^a/}/		; ending flag
	bne	2$
	bsr	get_end
	bra	3$
2$:
	rts
	
; Get the next character
get_huff:
	ldx	#decbuf
1$:
	lda	a,0,x
	lda	b,1,x
	psh	b
	psh	a
	pshx
	lda	b,#1
	jsr	rdbits
	pulx
	pul	a
	pul	b
	bne	2$
	tab
2$:
	tst	b
	bmi	3$
	abx
	bra	1$
3$:
	and	b,#^x7f
	rts

; Get the word ending
get_end:
	lda	b,#^x60
	sta	b,ebuf			; save eow for no ending case
	lda	b,#2
	jsr	rdbits
	cmp	a,#3
	beq	1$
	psh	a
	lda	b,#8
	jsr	rdbits
	tab
	pul	a			; now have a 10 bit ending number
	bsr	getend2
1$:
	lda	b,#1
	sta	b,endflg:
	rts
; Get the ending into memory
getend2:
	sta	b,x2:			; multiply by 2.5
	std	x1:
	asld
	asld
	addd	x1:
	lsrd
	addd	ends
	xgdx
	clr	b
	os	pk$sadd
	ldx	#endbuf
	ldd	#4
	os	pk$read
	clr	x1
	lda	a,endbuf
	lda	b,x2:
	and	b,#1
	beq	2$
	lda	b,#4
	sta	b,x1:
	asl	a
	asl	a
	asl	a
	asl	a
2$:
	sta	a,x3+1:
	ldx	#endbuf
	stx	x2:
	clr	b
4$:
	psh	b
	bsr	xgetend
	pul	b
	inc	b
	ora	a,#^x60
	ldx	#ebuf-1
	abx
	sta	a,0,x
	cmp	b,#4
	bne	4$
3$:
	lda	a,#^x60
	sta	a,1,x	
	rts
; get the next character of the ending
xgetend:
	clr	a
	sta	a,x3:			; cwrd
	lda	b,#5
2$:
	psh	b
	lda	b,x1:			; bits
	cmp	b,#8
	bne	1$
	ldx	x2:
	inx
	lda	b,0,x
	stx	x2:
	sta	b,x3+1:
	clr	b
1$:
	inc	b
	sta	b,x1:
	ldd	x3:			; cwrd
	asld
	std	x3:
	pul	b
	dec	b
	bne	2$
	lda	a,x3:
	rts

; Display the word
disp:
	ldx	dpb_cpos:
	pshx
	lda	b,lcnt:
    	cmp	b,#17
	bcc	1$
	ldx	#buf
	abx
	clr	0,x
	ldd	#dbuf
	os	ut$ddsp
	bra	2$
1$:
	ldd	#4
	std	utw_s0:
	inc	a			; bottom line
	lda	b,lcnt:
	ldx	#buf
	os	dp$view
	os	kb$uget			; return key to buffer
2$:
	pulx
	xgdx
	os	dp$stat
	rts
;
xbfill:
	sta	b,nbit:
	pshx
	xgdx
	addd	#^x100
	std	cpos:
	pulx
	clr	b
	os	pk$sadd
	ldx	#loadt
	stx	nbyt:
	ldd	#^x100
	os	pk$read
	ldx	nbyt:
	lda	a,0,x
    	lda	b,nbit:
	inx
	stx	nbyt:
2$:
	dec	b
	bmi	1$
	asl	a
	bra	2$
1$:
	sta	a,cwrd+1:
 	lda	b,#8
    	sub	b,nbit:
    	sta	b,nbit:
	rts


bfill:
	ldx	cpos:
	pshx
	xgdx
	addd	#^x100
	std	cpos:
	pulx
	clr	b
	os	pk$sadd
	ldx	#loadt
	stx	nbyt:
	ldd	#^x100
	os	pk$read
	rts


; Get B bits in B reg
rdbits:
	clr	a
	sta	a,cwrd:
rloop:
	psh	b
	lda	b,nbit:
	bne	2$
	ldx	nbyt:
	cpx	#loade
	bcs	1$
	bsr	bfill
	ldx	nbyt:
1$:
	lda	b,#8
	lda	a,0,x
	inx
	stx	nbyt:
	sta	a,cwrd+1:
2$:
	dec	b
	sta	b,nbit:
	ldd	cwrd:
	asld
	std	cwrd:
	pul	b
	dec	b
	bne	rloop
	lda	a,cwrd:
	rts

; compares the existing with the target
comp:
	lda	a,clen:
	sub	a,#2
	ldx	#buf+3
	stx	x1:
	ldx	#tbuf+3
	stx	x2:
2$:
	dec	a
	beq	1$			; match
	ldx	x1:
	lda	b,0,x
	inx
	stx	x1:
	ldx	x2:
	cmp	b,0,x
	bne	1$
	inx
	stx	x2:
	bra	2$
1$:
	rts

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
	.over	prgend
	.eover
	.end
