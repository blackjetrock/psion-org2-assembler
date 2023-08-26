	;; Some tests of the different syntax of the assembler.
	;;
	;; Based on the (XP?) Psion macro assembler.
	;;

	.INCLUDE        MOSVARS.INC
	.INCLUDE        MOSHEAD.INC
	.INCLUDE        MSWI.INC

VALUE1  .EQU  		10	
VALUE2  .EQU  		20
VALUE3  .EQU  		30	
	
	;; ----------------------------------------
	;; Macro syntax
	;; ----------------------------------------
	
BSET    .macro	mask, addr
	oim	#^B=mask=, addr
        .endm 	

BCLR    .macro	mask, addr
	aim	#^C^B=mask=, addr
        .endm	

	;; ----------------------------------------

	;; Simple assignments

	;; Decimal
	LDAA    #12

	;; $ hex 
	LDAA    #$12

	;; Psion style hex
	LDAA    #^x12

	;; C style hex
	LDAA    #0x12

	;; Using Tcl expressions. int() is necessary for
	;; floating point expressions

	LDAA    #int(100*sin(1))

	LDAA    #(1<<6)
	LDAA	#int(3*log(exp(1)))

	LDAA    #[set ::PASS]

	;; equates
	LDAA    #VALUE1
	LDAA    #VALUE1 + VALUE2
	LDAA    #VALUE1/4

	;; Psion operators
	;; Bit masks using a number
	
	LDAA    #^B=5=
	LDAA    #^B?5?

MASK1   .EQU    (1<<1)
MASK2   .EQU    (1<<2)

	LDAA    #MASK1 | MASK2
	
	
	
	
