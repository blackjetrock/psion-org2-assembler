	.INCLUDE        MOSVARS.INC
	.INCLUDE        MOSHEAD.INC
	.INCLUDE        MSWI.INC

;/** Macro definitions from OSHEAD.INC   ****/

	;/****************** MACRO DEFINITIONS ******************************/
	
BSET    .macro	mask, addr
	oim	#^B=mask=, addr
        .endm 	

BCLR    .macro	mask, addr
	aim	#^C^B=mask=, addr
        .endm	

BTGL    .macro	mask, addr
	eim	#mask, addr
        .endm

BTST    .macro	mask, addr
	tim	#mask, addr
        .endm

	.org $1000

	AIM #^x40, POB_PORT6

	os  POB_PORT6

	.org $300e


	BCLR 6,POB_PORT6
	BSET 3,POB_PORT6

	;; 
	;; 	BSET 3, POB_PORT6

	
