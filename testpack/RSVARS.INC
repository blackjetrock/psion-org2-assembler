/**************************************************************************/
/* RSVARS.M - Module containing all fixed address variables for the RS232 */
/* driver assembler interface.						  */
/*									  */
/* Written by.....Mark Gretton						  */
/* Started........9-2-87						  */
/* Version........1.0							  */
/**************************************************************************/

;
; Function number definitions
;
#define	rs$open		0	/* Open the RS232 channel */
#define	rs$close	1	/* Close the RS232 channel */
#define	rs$putchar	2	/* Put a character to the RS232 channel */
#define	rs$getchar	3	/* Get a character from the RS232 channel */
#define	rs$flush	4	/* Flush the Tx and Rx buffers */
#define rs$setvars	5	/* Set the RS232 variables up after a change */
#define rs$lprint	6	/* Print a string */
#define rs$linput	7	/* Input a string */
#define	rs$licon	8	/* Link layer connect call */
#define	rs$lidis	9	/* Link layer disconnect call */
#define	rs$liput	10	/* Link layer put a frame call */
#define	rs$liget	11	/* Link layer get a frame call */
;
; Start of fixed address variable
;
    rsa_org	equ	^x214f		; Start of reserved RAM pace

rsb_init	equ	rsa_org	; cold boot flag
    		rsa_org equ	rsa_org+1
rsb_baud	equ	rsa_org	; paramters used in setup
    		rsa_org equ	rsa_org+1
rsb_parity	equ	rsa_org
    		rsa_org equ	rsa_org+1
rsb_bits	equ	rsa_org
    		rsa_org equ	rsa_org+1
rsb_stop	equ	rsa_org
    		rsa_org equ	rsa_org+1
rsb_hand	equ	rsa_org
    		rsa_org equ	rsa_org+1
rsb_proto	equ	rsa_org	; New setup protocol parameter
    		rsa_org equ	rsa_org+1
rsb_echo	equ	rsa_org
    		rsa_org equ	rsa_org+1
rsb_width	equ	rsa_org
    		rsa_org equ	rsa_org+1
rsb_timout	equ	rsa_org	; New setup timout parameter
    		rsa_org equ	rsa_org+1

rst_reol	equ	rsa_org	; Receive end of line
    		rsa_org equ	rsa_org+3
rst_reof	equ	rsa_org	; Receive end of file
    		rsa_org equ	rsa_org+3
rst_rtrn	equ	rsa_org	; Receive translate
    		rsa_org equ	rsa_org+3
rst_teol	equ	rsa_org	; Transmit end of line
    		rsa_org equ	rsa_org+3
rst_teof	equ	rsa_org	; Transmit end of file
    		rsa_org equ	rsa_org+3
rst_ttrn	equ	rsa_org	; Transmit translate
    		rsa_org equ	rsa_org+3
setup_tab_end	equ	rsa_org
rsb_off_del	equ	rsa_org	; Time to off delay in characters (=3)
    		rsa_org equ	rsa_org+1
rsb_xoff_del	equ	rsa_org	; Time to off with XON/XOFF in chars (=7)
    		rsa_org equ	rsa_org+1
rsb_tcon_val	equ	rsa_org	; Time constant value for timer 2 baud rate gen
    		rsa_org equ	rsa_org+1
rsb_off_ticks	equ	rsa_org	; No. of ticks for baud rate dependent Tx off delay
    		rsa_org equ	rsa_org+1
rsw_off_tcon	equ	rsa_org	; Time constant for single tick Tx off delay
    		rsa_org equ	rsa_org+2
rsb_sec_timer	equ	rsa_org	; General purpose decrement to zero second timer
    		rsa_org equ	rsa_org+1
rsb_tag_no	equ	rsa_org	; Byte to save capture buffer tag number in
    		rsa_org equ	rsa_org+1
rsb_node_addr	equ	rsa_org	; Organiser multi-drop node addres
    		rsa_org equ	rsa_org+1

rst_entry_point	equ	rsa_org	; Entry point for assembler interface
    		rsa_org equ	rsa_org+3

;
; RS - Macro for assembler interface to RS232 driver code
;
.macro	rs	function
    	jsr	rst_entry_point
	.byte	function
.endm

