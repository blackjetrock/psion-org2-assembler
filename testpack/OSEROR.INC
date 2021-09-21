/*      HEADER - OS_EROR
;
;    written on :- 22/10/85
;    written by :- Colly et al
;    version no :- 1.0
;
;    Contains all the operating system errors.
;
;	version	2.7
;	===========
;	FIX 1111 - BILL - 3/NOV/1986
;		 - remove PACK BATTERY LOW error message.
;
*/

/*      ALLOCATOR ERRORS        */

#define ER_AL_NC 255            /* NO MORE ALLOCATOR CELLS */
#define ER_AL_NR 254            /* NO MORE ROOM */

/*      CALCULATOR ERRORS       */

#define ER_MT_EX 253            /* EXPONENT OVERFLOW (OR UNDERFLOW) */
#define ER_MT_IS 252            /* CONVERSION FROM STRING TO NUMERIC FAILED */
#define ER_MT_DI 251            /* DIVIDE BY ZERO */
#define ER_MT_FL 250            /* CONVERSION FROM NUMERIC TO STRING FAILED */
#define ER_IM_OV 249            /* BCD STACK OVERFLOW */
#define ER_IM_UN 248            /* BCD STACK UNDERFLOW */
#define ER_FN_BA 247            /* BAD ARGUMENT IN FUNCTION CALL */

/*      DATAPAK ERRORS          */

#define ER_PK_NP 246            /* NO PAK IN SLOT */
#define ER_PK_DE 245            /* DATAPAK ERROR (WRITE ERROR) */
#define ER_PK_RO 244            /* ATTEMPTED WRITE TO READ ONLY PAK */
#define ER_PK_DV 243            /* BAD DEVICE NAME */
#define ER_PK_CH 242            /* PAK CHANGED */
#define ER_PK_NB 241            /* PAK NOT BLANK */
#define ER_PK_IV 240		/* UNKNOWN PACK TYPE */

/*      File system errors      */

#define ER_FL_PF 239            /* PAK FULL */
#define ER_FL_EF 238            /* END OF FILE */
#define ER_FL_BR 237            /* BAD RECORD TYPE */
#define ER_FL_BN 236            /* BAD FILE NAME */
#define ER_FL_EX 235            /* FILE ALREADY EXISTS */
#define ER_FL_NX 234            /* FILE DOES NOT EXITS */
#define ER_FL_DF 233            /* DIRECTORY FULL */
#define ER_FL_CY 232		/* PAK NOT COPYABLE */

/*	Device system errors	*/

#define ER_DV_CA 231		/* INVALID DEVICE CALL */
#define ER_DV_NP 230		/* DEVICE NOT PRESENT */
#define ER_DV_CS 229		/* CHECKSUM ERROR */

/*	Transalator errors	*/

#define ER_EX_SY 228		/* Syntax error */
#define ER_EX_MM 227		/* Mismatched brackets */
#define ER_EX_FA 226		/* Wrong number of function args */
#define ER_EX_AR 225		/* Subsrcipt or dimension error */
#define ER_EX_TV 224		/* Type violation */
#define ER_LX_ID 223		/* identifier too long */
#define ER_LX_FV 222		/* bad field variable name */
#define ER_LX_MQ 221		/* unmatched quotes in string */
#define ER_LX_ST 220		/* string too long */
#define ER_LX_US 219		/* unrecognised symbol */
#define ER_LX_NM 218		/* Non-valid numeric format */
#define ER_TR_PC 217		/* Missing procedure declaration */
#define ER_TR_DC 216		/* Illegal declaration */
#define ER_TR_IN 215		/* Non-integer dimension */
#define ER_TR_DD 214		/* Name already declared */
#define ER_TR_ST 213		/* Structure error */
#define ER_TR_ND 212		/* Nesting too deep */
#define ER_TR_NL 211		/* Label required */
#define ER_TR_CM 210		/* Missing comma */
#define ER_TR_BL 209		/* Bad Logical file name */
#define ER_TR_PA 208		/* ARGUMENTS MAY NOT BE TARGET OF ASSIGN */
#define ER_TR_FL 207		/* Too many fields */

/*	runtime errors	    */

#define ER_RT_BK 206	/* Break Key */
#define ER_RT_NP 205	/* Wrong number of parameters */
#define ER_RT_UE 204	/* Undefined external */
#define ER_RT_PN 203	/* Procedure not found */
#define ER_RT_ME 202	/* Menu error */
#define ER_RT_NF 201	/* Field not found */
#define ER_PK_BR 200	/* Pack bad read error */
#define ER_RT_FO 199	/* File already open (open/delete) */
#define ER_RT_RB 198	/* Record too big */
#define ER_LG_BN 197	/* Bad procedure name */
#define ER_RT_FC 196	/* File not open (close) */
#define ER_RT_IO 195	/* Integer overflow */

/*	general errors */

#define ER_GN_BL 194    /* Battery too low */
#define ER_GN_RF 193    /* Device read fail */
#define ER_GN_WF 192    /* Device write fail */

#define	ER_LAST	 191	/* For er$lkup	*/


/*	printer errors */

#define	ER_PR_BK 182	/* printer excape */

