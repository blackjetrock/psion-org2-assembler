; Comms Link Assembly Definitions

rsb_baud    .EQU  $2150  ; 0-9	50,75,110,150,300,600,1200,2400,4800,9600 Baud rate (transfer speed)
rsb_parity  .EQU  $2151  ; 0-4	NONE, ODD, EVEN,MARK, SPACE	Data, Parity, Stop Bit settings:transfer frame setup
rsb_bits    .EQU  $2152  ; 0-1	0 - 7 BIT DATA1 - 8 BIT DATA
rsb_stop    .EQU  $2153  ; 0-1	0 - 1 STOP BIT1 - 2 STOP BITS
rsb_hand    .EQU  $2154  ; 0-7	NONE,XON,RTS,XON+RTS,DTR,DTR+XON,DTR+RTS,ALL	Handshake mode
rsb_proto   .EQU  $2155  ; 0-2	NONE, XMODEM, PSION	File transfer protocol(off by default)
rsb_echo    .EQU  $2156  ; 0-1	LOCAL, HOSTEcho(Terminal emulation only)
rsb_width   .EQU  $2157  ; 0-250	NONE,1-250	buffer width(forced line length)
rsb_timout  .EQU  $2158  ; 0-255	NONE,1-255 seconds	LPRINT timeout

rst_reol    .EQU  $2159  ;	13,10 <CR><LF>	Receive End Of Line character(s)
rst_reof    .EQU  $215C  ;	26    <SUB>	Receive End Of File character(s)
rst_rtrn    .EQU  $215F  ;	empty	Receive Translate character(s): 1 - remove, 2 - replace first by second
rst_teol    .EQU  $2162  ;	13,10 <CR><LF>	Transmit End Of Line character(s)
rst_teof    .EQU  $2165  ;	26 <SUB>	Transmit End Of Files character(s)
rst_ttrn    .EQU  $2168  ;	empty	Transmit Translate characters: 1 - remove, 2 - replace first by second

rsb_off_del     .EQU  $216B        ;1-255 default=3	Time to off delay in characters
rsb_xoff_del    .EQU  $216C        ;1-255 default=7	Time to off delay with XON/XOFF
rsb_tcon_val    .EQU  $216D        ;0-255	Time constant value for timer 2 baud rate generation
rsb_off_ticks   .EQU  $216E        ;0-255	No. of ticks for baud rate dependent Tx off delay
rsw_off_tcon    .EQU  $216F        ;0-$FFFF	Time constant for single tick TX off delay (word)
rsb_sec_timer   .EQU  $2171        ;0-255	General purpose decrement to zero second timer (decremented once every second until zero)
                                   ;$2172	RESERVED WORD
rst_entry_point .EQU   $2174       ;	 	Entry point for assembler interface, contains a jump instruction to the driver (3 bytes).

    ;
    ; RS - Macro for assembler interface to COMMS LINK drivers
    ;

.macro    RS  function
          jsr rst_entry_point
.byte     function
.endm

rs_open  	.EQU            0    ;	Open the COMMS LINK channel
rs_close        .EQU     	1    ;	Close the COMMS LINK channel
rs_putchar      .EQU       	2    ;	Put a character to the RS232 port
rs_getchar      .EQU       	3    ;	Get a character from the RS232 port
rs_flush        .EQU     	4    ;	Flush the receive buffer
rs_setvars      .EQU       	5    ;	Set the COMMS LINK variables up after a change
rs_lprint       .EQU      	6    ;	Print a string
rs_linput       .EQU      	7    ;	Input a string
rs_licon        .EQU     	8    ;	Link layer connect call
rs_lidis        .EQU     	9    ;	Link layer disconnect call
rs_liput        .EQU     	10    ;	Link layer put a frame call
rs_liget        .EQU     	11    ;	Link layer get a frame call
