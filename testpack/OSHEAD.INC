/******************************************************************************/
/*									      */
/*	written on........28/OCT/85					      */
/*	written by........BILL						      */
/*	version no........1.0	(FROM V3.7 ORG II O.S.)			      */
/*									      */
/*	Contains constants and macros for the LZ operating system.            */
/*									      */
/******************************************************************************/

/*
#define	DP_DEBUG
#define	XT_DEBUG
#define	FL_DEBUG
*/

#define	MLANG
#define	BUILDLA
#define	BUILDXP
#define LADDR 1
#define RAMPAK 1
#define	REMOVE_INFO		/* to save space */
#define	REMOVE_MK1


/*************************** MODEL DEFINITIONS ********************************/

/*
#define	TI_CUSTOM
*/

#ifdef	BUILDLP				/* LZ64 */
#define	RAM_64K
#define	BNK_START	<^x0000>	/* start at beginning of bank ram   */
#define	MK2_MODEL	<^x0D>		/* 64k rom 64k ram - examine id2    */
#define	MK2_ID2		<^xC0>		/* Cyclops id, new foreign char LCD */
#else
#define	BNK_START	<^x8000>	/* start in cell (no bank ram)	    */
#define	MK2_MODEL	<^x0E>		/* 64k rom 32k ram - examine id2    */
#define	MK2_ID2		<^xC0>		/* LZ id, new foreign char LCD      */
#endif


#define	MK2_VERSION	<^x42>		/* 2nd release level version 4.2    */
#define	MK2_ROMLANG	<^x81>		/* Multi-ling English/French/German */
#define	MK2_LANGUAGE	0		/* initially ENGLISH for MLOS */



/***************************** MACRO DEFINITIONS ******************************/
.macro	MBSET	mask,addr
.if	equal	%locate(<:>,addr)-%length(addr)
	oim	#mask,addr:
.if_false
	oim	#mask,addr
.endc
.endm 	mbset
.macro	MBCLR	mask,addr
.if	equal	%locate(<:>,addr)-%length(addr)
	aim	#^C<mask>,addr:
.if_false
	aim	#^C<mask>,addr
.endc
.endm	mbclr
.macro	MBTGL	mask,addr
.if	equal	%locate(<:>,addr)-%length(addr)
	eim	#mask,addr:
.if_false
	eim	#mask,addr
.endc
.endm
.macro	MBTST	mask,addr
.if	equal	%locate(<:>,addr)-%length(addr)
	tim	#mask,addr:
.if_false
	tim	#mask,addr
.endc
.endm

$mt	equ	0
$mtr0	equ	1
$mtr1	equ	2
$mtr2	equ	4
$mtr3	equ	8
$mtr4	equ	16
$mtr5	equ	32
$mtr6	equ	64

.macro	mpshos	p0,p1,p2,p3,p4,p5,p6
	os	bt$pprg
	.byte	$mt'p0 ! $mt'p1 ! $mt'p2 ! $mt'p3 ! $mt'p4 ! $mt'p5 ! $mt'p6
.endm mpshos

.macro	mpsh	p0,p1,p2,p3,p4,p5,p6
	.extrnw	bt_pprg

	jsr	bt_pprg
	.byte	$mt'p0 ! $mt'p1 ! $mt'p2 ! $mt'p3 ! $mt'p4 ! $mt'p5 ! $mt'p6
.endm mpsh

.macro	mpulos	p0,p1,p2,p3,p4,p5,p6
	os	bt$pprg
	.byte	^x80!$mt'p0!$mt'p1!$mt'p2!$mt'p3!$mt'p4!$mt'p5!$mt'p6
.endm mpulos

.macro	mpul	p0,p1,p2,p3,p4,p5,p6
	.extrnw	bt_pprg

	jsr	bt_pprg
	.byte	^x80!$mt'p0!$mt'p1!$mt'p2!$mt'p3!$mt'p4!$mt'p5!$mt'p6
.endm mpul

;jsr to zero page
.macro	jsrzp	addr
	jsr	addr:
.endm

/* UDGS and ICONS */
/******************/

#define	UDG_CLK0	0
#define	UDG_CLK9	9
#define	UDG_CLKCOLON	10
#define	UDG_UNDERSCORE	11
#define	ICON_MAIN	12
#define	ICON_PROG	13
#define	ICON_FILES	14
#define	ICON_UTILS	15
#define	ICON_ALARM	16
#define	ICON_CALC	17
#define	ICON_AM		18
#define	ICON_PM		19
#define	UDG_LDOT	20
#define	UDG_HDOT	21
#define	UDG_DI_TARROW	22
#define	UDG_DI_BARROW	23
#define	UDG_DI_BELL	24
#define	UDG_DI_WKBOX0	25
#define	UDG_DI_WKBOX1	26
#define	UDG_DI_WKBOX2	27
#define	UDG_DI_WKBOX3	28
#define	ICON_NOTES	29
#define	UDG_DI_LCHEVRON	30
#define	UDG_DI_RCHEVRON	31



/* zero page ports */
/*******************/
#define	POB_DDR2	<^x01>
#define POB_PORT2	<^x03>		
#define POB_TCSR1	<^x08>		/* timer control status register 1 */
#define POW_FRC		<^x09>		/* free running counter		*/
#define POW_OCR1	<^x0B>		/* ouput compare register 1	*/
#define POB_TCSR2	<^x0F>		/* Timer 2 control/status register */
#define POB_RMCR	<^x10>		/* rate, mode control register	*/
#define POB_TRCSR	<^x11>		/* Tx/Rx control status register */
#define POB_RDR		<^x12>		/* Recieve data register */
#define POB_TDR		<^x13>		/* Transmit data register */
#define POB_RCR		<^x14>		/* ram/port 5 control register	*/
#define POB_PORT5	<^x15>
#define POB_DDR6	<^x16>
#define POB_PORT6	<^x17>
#define POB_TCSR3	<^x1B>		/* Timer 3 control/status register */
#define POB_TCONR	<^x1C>		/* Timer constant register */


/* semi-custom chip addresses */
/******************************/
#define SCA_LCDCONTROL	<^x0180>	/* lcd registers		*/
#define SCA_LCDDATA	<^x0181>
#define SCA_SWITCHOFF	<^x01c0>	/* switch off			*/
#define SCA_PULSEENABLE	<^x0200>	/* pulse enable			*/
#define SCA_PULSEDISABLE <^x0240>	/* pulse disable		*/
#define SCA_ALARMHIGH	<^x0280>	/* buzzer			*/
#define SCA_ALARMLOW	<^x02c0>
#define SCA_COUNTERRESET <^x0300>	/* counter for kybd + clock	*/
#define SCA_COUNTERCLOCK <^x0340>
#define SCA_NMIMPU	<^x0380>	/* enable nmi to processor	*/
#define SCA_NMICOUNTER	<^x03c0>	/* enable nmi to counter	*/

#define	SCA_SETMODE1	<^x2a0>		/* select mode 1 bit		*/
#define	SCA_SETMODE2	<^x2e0>		/* select mode 2 bit		*/
#define	SCA_MODERESET	<^x320>		/* clear mode bits		*/
#define	SCA_BANKRESET	<^x360>		/* reset bank counters		*/
#define	SCA_NEXTRAM	<^x3a0>		/* select next RAM bank		*/
#define	SCA_NEXTROM	<^x3e0>		/* select next ROM bank		*/


/* port 5 bits	*/
/****************/
#define	ONCLR	<^x80>
#define	ACOUT	<^x02>
#define	LOWBATTERY	<^x01>

/* port 6 bits	*/
/****************/
#define PACON		<^x80>
#define CS3		<^x40>
#define CS2		<^x20>
#define CS1		<^x10>
#define OE		<^x08>
#define PGM		<^x04>
#define MR		<^x02>
#define CLK		<^x01>

/* tcsr1 bits	*/
/****************/
#define	EOCI1		<^x08>

/* kbb_stat bits  */
/******************/
#define	KY_SHFT		<^x80>		/* shift			*/
#define	KY_NUMB		<^x40>		/* numeric lock			*/
#define	KY_CPNM		<^x02>		/* CAPS / NUMB flag		*/
#define	KY_CAPS		<^x01>		/* caps lock			*/

#define	KY_MLKY		<^x04>		/* multi-lingual key flag	*/

/* pack control delays	*/
/************************/

#define	PACONDEL	11520		/* for 50ms delay		*/
;FIX	1112	- change from 2304 to 1613
#define	VPPONDEL	1613		/* for 7ms delay		*/
;ENDFIX	1112
#define	VPPOFFDEL	46080		/* for 200ms delay		*/
#define PK_OVERBLOW	5		/* 5*X overblow */

/* miscellaneous constants ! */
/*****************************/

#define RAMBASE		<^x2000>	/* machine ram base		*/
#define	RAMFREE		btt_ramf	/* end of osvars (first free byte) */
#define MACHINE_STACK	<^x0100>	/* size of machine stack	*/
#define	MINEVL_STACK	<^x0100>	/* min. size of evaluator stack	*/

#define	ALLCELLS	32		/* number of allocator cells	*/
#define	PERMCELL	0		/* permanent cell		*/
#define	MENUCELL	1		/* top level menu cell		*/
#define	DIRYCELL	2		/* diary cell			*/
#define	TEXTCELL	3		/* language text cell		*/
#define	SYMBCELL	4		/* symbol table cell		*/
#define	GLOBCELL	5		/* global record cell		*/
#define	OCODCELL	6		/* QCODE ouput cell		*/
#define	FSY1CELL	7		/* field name symbol table 1	*/
#define	FSY2CELL	8		/* field name symbol table 2	*/
#define	FSY3CELL	9		/* field name symbol table 3	*/
#define	FSY4CELL	10		/* field name symbol table 4	*/
#define	FBF1CELL	11		/* field buffer cell 1		*/
#define	FBF2CELL	12		/* field buffer cell 2		*/
#define	FBF3CELL	13		/* field buffer cell 3		*/
#define	FBF4CELL	14		/* field buffer cell 4		*/
#define	DATACELL	15		/* database cell		*/
#define	NOTECELL	16		/* Notepad cell			*/
#define DUMYCELL	17		/* Dummy cell for spreadsheet	*/
#define	PREALLOC	18		/* number of cells to preallocate */


#define	SWIDTH		<^x10>		/* screen width 		*/
#define	CURS_ON		<^x80>		/* cursor on flag		*/
#define	CURS_OFF	<^x00>		/* cursor off			*/
#define	CURSOR_BLOCK	<^x00>		/* cursor in block form		*/
#define	CURSOR_LINE	<^x01>		/* cursor in line form		*/

#define	CY_SWIDTH	20		/* LZ screen width		*/
#define CY_NLINES	4		/* 4 lines on LZ screen		*/

#define	TIMEOUT		300		/* automatic timeout in 5 mins	*/

#define	BSIZE		<256+64>	/* general purpose buffer size	*/
#define	FSIZE		32		/* find buffer size		*/
#define	DELIM		9		/* buffer delimiter		*/

#define	KEY_TIME	<^xb39F>	/* gives 50.000ms key polling	*/
    					/* See OSKB.SRC for more info	*/
#define	KEY_DELAY	14		/* delay before key repeat	*/
#define	KEY_REPEAT	0		/* rate of key repeat 0=fastest	*/
#define	KEY_CLICK	1		/* length of key click		*/
#define	TYPEAHEAD	16		/* 16 character type ahead	*/
#define	HDELAY		4		/* horizontal scrolling delay	*/
#define	VDELAY		10		/* vertical scrolling delay	*/

#define	REGSIZE		32		/* number of table registers	*/
#define	REGBASE		<256-REGSIZE>	/* first register number	*/
#define	STACKSIZE	32		/* table stack size		*/

#define	K_AC		1		/* all/clear key		*/
#define	K_MODE		2		/* mode key			*/
#define	K_UP		3		/* up arrow			*/
#define	K_DOWN		4		/* down arrow			*/
#define	K_LEFT		5		/* left arrow			*/
#define	K_RGHT		6		/* right arrow			*/
#define	K_DELR		7		/* delete right key		*/
#define	K_DEL		8		/* delete key			*/
#define	K_EXE		13		/* execute key			*/
#define	K_SHFTEXE	14		/* Shift EXE			*/
#define	K_SHFTSPACE	15		/* Shift SPACE			*/

#ifdef	KYBD_POS200
#define	K_F1		3		/* function keys on POS200	*/
#define	K_F2		4
#define	K_F3		5
#endif

/* ctrl chars for dp_emit */
/**************************/
#define	D_BS		8		/* back space			*/
#define	D_HT		9		/* nearest position modulo 8	*/
#define	D_LF		10		/* line feed			*/
#define	D_HM		11		/* position cursor top left	*/
#define	D_FF		12		/* clear entire display		*/
#define	D_CR		13		/* goto start of line		*/
#define	D_CT		14		/* clear top line		*/
#define	D_CB		15		/* clear bottom line		*/
#define	D_BL		16		/* bell !			*/
#define	D_RE		17		/* refresh both lines		*/
#define	D_TR		18		/* refresh top line		*/
#define	D_BR		19		/* refresh bottom line		*/
#define	D_3R		20		/* refresh 3rd line		*/
#define	D_4R		21		/* refresh 4th line		*/
#define	D_C3		22		/* clear 3rd line		*/
#define	D_C4		23		/* clear 4th line		*/
#define	D_HD		24		/* print high dotted line	*/
#define	D_LD		25		/* print low dotted line	*/
#define	D_CE		26		/* clear to the end of line	*/

/* ctrl chars for ut_disp */
/**************************/
#define	DSP_CN		31		/* for centring text in ut$disp	*/

#define PAKA 		0		/* Ram data pack 		*/
#define PAKB 		1		/* First pack slot 		*/
#define PAKC 		2		/* Second pack slot 		*/
#define	PAKD		3		/* Top slot			*/
#define EPROM		<^x02>		/* set if eprom pak (not ram pak) */
#define PGCPK		<^x04>		/* set if pak with page counter */
#define RDWRT		<^x08>		/* clear if pak write protected	*/
#define NOBOOT		<^x10>		/* clear if pak bootable ??? 	*/
#define COPYPK		<^x20>		/* set if pak copyable 		*/
#define NYIMPL  	<^x40>		/* set for future expansion 	*/
#define MK1PAK  	<^x80>		/* set if MARK 1 pak 		*/

#define GENERAL 	<^x90>		/* general record type		*/
#define MAXFILE 	4		/* Maximum number of open files */

#define	BBODTYP		<^x80>		/* block body records		*/
#define NAMETYP		<^x81>		/* record type for file names 	*/
#define	BDIATYP		<^x82>		/* block name record type for diary */
#define	BLANTYP		<^x83>		/* block name record type for language*/

#define	BNOTTYP		<^x87>		/* block name record type for notepad */

#define FRECTYP		<^x91>		/* lowest rec. type for named files */
#define NAMELEN		8		/* max len of a file name	*/
#define	TLRECT 		<FRECTYP-1>	/* record type for find/save	*/

#define AMSIZE 6	/* size of an alarm entry */
#define AMNUM  8	/* number of alarm entries */

#define EDITMODE 	3
#define LISTMODE 	4
#define RUNMODE 	7
#define	ERAMODE		8

#define	SIZEOF_PAKDEF	10		/* paktype, paksize, 8 byte id	*/
#define	PTYP		0		/* pak type			*/
#define	PSIZ		1		/* pak size			*/
#define	PIDS		2		/* unique ID string		*/

/* Maths constants */

#define	PRECISION	12		/* working precision for maths. */
#define	MANSIZE		6		/* size of BCD mantissa         */
#define MANBYTES	7		/* size of register mantissa    */
#define SZREG		9		/* size of BCD register		*/
#define SZBCD		8		/* size of BCD number		*/
/* offsets from byte 0 (sman[0]) of a BCD number */
#define SMSB		5		/* most significant byte	*/
#define	SEXP		6		/* exponent 			*/
#define SSGN		7		/* sign				*/
/* offsets from byte 0 (aman[0]) of a BCD register */
#define AMSB		6		/* most significant byte	*/
#define	AEXP		7		/* exponent 			*/
#define ASGN		8		/* sign				*/

#define MAXEXP		99		/* maximum exponent size	*/
#define MINEXP		-99		/* max. negative exponent size	*/
#define MAXDLEN		32		/* max. no. of dec. places      */
#define AMNUM 8

#define	MAXDLEN		32		/* max. dec. places + exponent	*/

/*	LANGUAGE CONTROL	*/
#define	LANG_ENG	0
#define LANG_FRN	1
#define LANG_GRM	2
#define MLT_PROTECT	129
#define MLT_PASSWORD	72
    			/* Text,passwords,paste buffer */
#define MLT_LENGTH	<MLT_PROTECT+MLT_PASSWORD+65>

/*	WORLD BASE CITY/COUNTRY	*/
#define WL_BASE_CITY	100
#define WL_BASE_COUNTRY	120

/* PASSWORD LENGTH */
#define MAXPASSLEN 8
