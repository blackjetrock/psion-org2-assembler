	;; Some tests of the different syntax of the assembler.
	;;
	;; Based on the (XP?) Psion macro assembler.
	;;

	.INCLUDE        MOSVARS.INC
	.INCLUDE        MOSHEAD.INC
	.INCLUDE        MSWI.INC

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
	
	
	
