;;****************************************************************************
;;									      
;;	written on........28/OCT/85					      
;;	written by........BILL						      
;;	version no........1.0	(FROM V3.7 ORG II O.S.)			      
;;									      
;;	Contains constants and macros for the LZ operating system.            
;;									      
;;****************************************************************************

MLANG             .EQU 0
BUILDLA           .EQU 0
BUILDXP           .EQU 0
LADDR             .EQU 1
RAMPAK            .EQU 1
REMOVE_INFO       .EQU 0
REMOVE_MK1        .EQU 0

; UDGS and ICONS 
;****************

UDG_CLK0	.EQU    0
UDG_CLK9	.EQU    9
UDG_CLKCOLON	.EQU    10
UDG_UNDERSCORE	.EQU    11
ICON_MAIN	.EQU    12
ICON_PROG	.EQU    13
ICON_FILES	.EQU    14
ICON_UTILS	.EQU    15
ICON_ALARM	.EQU    16
ICON_CALC	.EQU    17
ICON_AM	.EQU    	18
ICON_PM	.EQU    	19
UDG_LDOT	.EQU    20
UDG_HDOT	.EQU    21
UDG_DI_TARROW	.EQU    22
UDG_DI_BARROW	.EQU    23
UDG_DI_BELL	.EQU    24
UDG_DI_WKBOX0	.EQU    25
UDG_DI_WKBOX1	.EQU    26
UDG_DI_WKBOX2	.EQU    27
UDG_DI_WKBOX3	.EQU    28
ICON_NOTES	.EQU    29
UDG_DI_LCHEVRON	.EQU    30
UDG_DI_RCHEVRON	.EQU    31



; zero page ports 
;*****************
POB_DDR2	.EQU    $01
POB_PORT2	.EQU    $03		
POB_TCSR1	.EQU    $08		; timer control status register 1 
POW_FRC		.EQU    $09		; free running counter		
POW_OCR1	.EQU    $0B		; ouput compare register 1	
POB_TCSR2	.EQU    $0F		; Timer 2 control/status register 
POB_RMCR	.EQU    $10		; rate, mode control register	
POB_TRCSR	.EQU    $11		; Tx/Rx control status register 
POB_RDR		.EQU    $12		; Recieve data register 
POB_TDR		.EQU    $13		; Transmit data register 
POB_RCR		.EQU    $14		; ram/port 5 control register	
POB_PORT5	.EQU    $15
POB_DDR6	.EQU    $16
POB_PORT6	.EQU    $17
POB_TCSR3	.EQU    $1B		; Timer 3 control/status register 
POB_TCONR	.EQU    $1C		; Timer constant register 


; semi-custom chip addresses 
;****************************
SCA_LCDCONTROL	.EQU    $0180	; lcd registers		
SCA_LCDDATA	.EQU    $0181
SCA_SWITCHOFF	.EQU    $01c0	; switch off			
SCA_PULSEENABLE	.EQU    $0200	; pulse enable			
SCA_PULSEDISABLE .EQU    $0240	; pulse disable		
SCA_ALARMHIGH	.EQU    $0280	; buzzer			
SCA_ALARMLOW	.EQU    $02c0
SCA_COUNTERRESET .EQU    $0300	; counter for kybd + clock	
SCA_COUNTERCLOCK .EQU    $0340
SCA_NMIMPU	.EQU    $0380	; enable nmi to processor	
SCA_NMICOUNTER	.EQU    $03c0	; enable nmi to counter	

SCA_SETMODE1	.EQU    $2a0		; select mode 1 bit		
SCA_SETMODE2	.EQU    $2e0		; select mode 2 bit		
SCA_MODERESET	.EQU    $320		; clear mode bits		
SCA_BANKRESET	.EQU    $360		; reset bank counters		
SCA_NEXTRAM	.EQU    $3a0		; select next RAM bank		
SCA_NEXTROM	.EQU    $3e0		; select next ROM bank		


; port 5 bits	
;**************
ONCLR	.EQU    $80
ACOUT	.EQU    $02
LOWBATTERY	.EQU    $01

; port 6 bits	
;**************
PACON		.EQU    $80
CS3		.EQU    $40
CS2		.EQU    $20
CS1		.EQU    $10
OE		.EQU    $08
PGM		.EQU    $04
MR		.EQU    $02
CLK		.EQU    $01

; tcsr1 bits	
;**************
EOCI1		.EQU    $08

; kbb_stat bits  
;****************
KY_SHFT		.EQU    $80		; shift			
KY_NUMB		.EQU    $40		; numeric lock			
KY_CPNM		.EQU    $02		; CAPS / NUMB flag		
KY_CAPS		.EQU    $01		; caps lock			

KY_MLKY		.EQU    $04		; multi-lingual key flag	

; pack control delays	
;**********************

PACONDEL	.EQU    11520		; for 50ms delay		
;FIX	1112	- change from 2304 to 1613
VPPONDEL	.EQU    1613		; for 7ms delay		
;ENDFIX	1112
VPPOFFDEL       .EQU    	46080		; for 200ms delay		
PK_OVERBLOW	.EQU    5		; 5*X overblow 

; miscellaneous constants ! 
;***************************

RAMBASE		.EQU    $2000	; machine ram base		
RAMFREE		.EQU    btt_ramf	; end of osvars (first free byte) 
MACHINE_STACK	.EQU    $0100	; size of machine stack	
MINEVL_STACK	.EQU    $0100	; min. size of evaluator stack	

ALLCELLS	.EQU    32      	; number of allocator cells	
PERMCELL	.EQU    0		; permanent cell		
MENUCELL	.EQU    1		; top level menu cell		
DIRYCELL	.EQU    2		; diary cell			
TEXTCELL	.EQU    3		; language text cell		
SYMBCELL	.EQU    4		; symbol table cell		
GLOBCELL	.EQU    5		; global record cell		
OCODCELL	.EQU    6		; QCODE ouput cell		
FSY1CELL	.EQU    7		; field name symbol table 1	
FSY2CELL	.EQU    8		; field name symbol table 2	
FSY3CELL	.EQU    9		; field name symbol table 3	
FSY4CELL	.EQU    10		; field name symbol table 4	
FBF1CELL	.EQU    11		; field buffer cell 1		
FBF2CELL	.EQU    12		; field buffer cell 2		
FBF3CELL	.EQU    13		; field buffer cell 3		
FBF4CELL	.EQU    14		; field buffer cell 4		
DATACELL	.EQU    15		; database cell		
NOTECELL	.EQU    16		; Notepad cell			
DUMYCELL	.EQU    17		; Dummy cell for spreadsheet	
PREALLOC	.EQU    18		; number of cells to preallocate 


SWIDTH		.EQU    $10		; screen width 		
CURS_ON		.EQU    $80		; cursor on flag		
CURS_OFF	.EQU    $00		; cursor off			
CURSOR_BLOCK	.EQU    $00		; cursor in block form		
CURSOR_LINE	.EQU    $01		; cursor in line form		

CY_SWIDTH     .EQU    	20		; LZ screen width		
CY_NLINES     .EQU    	4		; 4 lines on LZ screen		

TIMEOUT		.EQU    300		; automatic timeout in 5 mins	

BSIZE		.EQU    256+64	; general purpose buffer size	
FSIZE		.EQU    32		; find buffer size		
DELIM		.EQU    9		; buffer delimiter		

KEY_TIME	.EQU    $b39F	; gives 50.000ms key polling	
    					; See OSKB.SRC for more info	
KEY_DELAY	.EQU    14		; delay before key repeat	
KEY_REPEAT      .EQU    	0		; rate of key repeat 0=fastest	
KEY_CLICK	.EQU    1		; length of key click		
TYPEAHEAD	.EQU    16		; 16 character type ahead	
HDELAY		.EQU    4    	; horizontal scrolling delay	
VDELAY		.EQU    10		; vertical scrolling delay	

REGSIZE		.EQU    32		; number of table registers	
REGBASE		.EQU    256-REGSIZE	; first register number	
STACKSIZE	.EQU    32		; table stack size		

K_AC		.EQU    1		; all/clear key		
K_MODE		.EQU    2		; mode key			
K_UP		.EQU    3		; up arrow			
K_DOWN		.EQU    4		; down arrow			
K_LEFT		.EQU    5		; left arrow			
K_RGHT		.EQU    6		; right arrow			
K_DELR		.EQU    7		; delete right key		
K_DEL		.EQU    8		; delete key			
K_EXE		.EQU    13		; execute key			
K_SHFTEXE	.EQU    14		; Shift EXE			
K_SHFTSPACE	.EQU    15		; Shift SPACE			


K_F1		.EQU    3		; function keys on POS200	
K_F2		.EQU    4
K_F3		.EQU    5


; ctrl chars for dp_emit 
;************************
D_BS		.EQU    8		; back space			
D_HT		.EQU    9		; nearest position modulo 8	
D_LF		.EQU    10		; line feed			
D_HM		.EQU    11		; position cursor top left	
D_FF		.EQU    12		; clear entire display		
D_CR		.EQU    13		; goto start of line		
D_CT		.EQU    14		; clear top line		
D_CB		.EQU    15		; clear bottom line		
D_BL		.EQU    16		; bell !			
D_RE		.EQU    17		; refresh both lines		
D_TR		.EQU    18		; refresh top line		
D_BR		.EQU    19		; refresh bottom line		
D_3R		.EQU    20		; refresh 3rd line		
D_4R		.EQU    21		; refresh 4th line		
D_C3		.EQU    22		; clear 3rd line		
D_C4		.EQU    23		; clear 4th line		
D_HD		.EQU    24		; print high dotted line	
D_LD		.EQU    25		; print low dotted line	
D_CE		.EQU    26		; clear to the end of line	

; ctrl chars for ut_disp 
;************************
DSP_CN		.EQU    31		; for centring text in ut$disp	

PAKA 		.EQU    0		; Ram data pack 		
PAKB 		.EQU    1		; First pack slot 		
PAKC 		.EQU    2		; Second pack slot 		
PAKD		.EQU    3		; Top slot			
EPROM		.EQU    $02		; set if eprom pak (not ram pak) 
PGCPK		.EQU    $04		; set if pak with page counter 
RDWRT		.EQU    $08		; clear if pak write protected	
NOBOOT		.EQU    $10		; clear if pak bootable ??? 	
COPYPK		.EQU    $20		; set if pak copyable 		
NYIMPL  	.EQU    $40		; set for future expansion 	
MK1PAK  	.EQU    $80		; set if MARK 1 pak 		

GENERAL 	.EQU    $90		; general record type		
MAXFILE 	.EQU    4		; Maximum number of open files 

BBODTYP		.EQU    $80		; block body records		
NAMETYP		.EQU    $81		; record type for file names 	
BDIATYP		.EQU    $82		; block name record type for diary 
BLANTYP		.EQU    $83		; block name record type for language

BNOTTYP		.EQU    $87		; block name record type for notepad 

FRECTYP		.EQU    $91		; lowest rec. type for named files 
NAMELEN		.EQU    8		; max len of a file name	
TLRECT 		.EQU    FRECTYP-1	; record type for find/save	

AMSIZE .EQU    6	; size of an alarm entry 
AMNUM  .EQU    8	; number of alarm entries 

EDITMODE 	.EQU         3
LISTMODE 	.EQU         4
RUNMODE 	.EQU         7
ERAMODE		.EQU         8

SIZEOF_PAKDEF	.EQU    10		; paktype, paksize, 8 byte id	
PTYP		.EQU    0		; pak type			
PSIZ		.EQU    1		; pak size			
PIDS		.EQU    2		; unique ID string		

; Maths constants 

PRECISION	.EQU    12		; working precision for maths. 
MANSIZE		.EQU    6		; size of BCD mantissa         
MANBYTES	.EQU    7		; size of register mantissa    
SZREG		.EQU    9		; size of BCD register		
SZBCD		.EQU    8		; size of BCD number		
; offsets from byte 0 (sman[0]) of a BCD number 
SMSB		.EQU    5		; most significant byte	
SEXP		.EQU    6		; exponent 			
SSGN		.EQU    7		; sign				
; offsets from byte 0 (aman[0]) of a BCD register 
AMSB		.EQU    6		; most significant byte	
AEXP		.EQU    7		; exponent 			
ASGN		.EQU    8		; sign				

MAXEXP		.EQU    99		; maximum exponent size	
MINEXP		.EQU    -99		; max. negative exponent size	
MAXDLEN		.EQU    32		; max. no. of dec. places      
AMNUM .EQU         8

MAXDLEN		.EQU    32		; max. dec. places + exponent	

;	LANGUAGE CONTROL	
LANG_ENG	.EQU         0
LANG_FRN	.EQU         1
LANG_GRM	.EQU         2
MLT_PROTECT	.EQU         129
MLT_PASSWORD	.EQU         72
    			; Text,passwords,paste buffer 
MLT_LENGTH	.EQU    MLT_PROTECT+MLT_PASSWORD+65

;	WORLD BASE CITY/COUNTRY	
WL_BASE_CITY	.EQU         100
WL_BASE_COUNTRY	.EQU         120

; PASSWORD LENGTH 
MAXPASSLEN .EQU         8
