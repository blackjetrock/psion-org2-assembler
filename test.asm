	.INCLUDE        MOSVARS.INC
	.INCLUDE        MOSHEAD.INC
	
		OS      .MACRO  VAL
	
		  	SWI
	  .BYTE VAL
	
		  		.ENDM


        .ORG    0
                .WORD   CEND-CBASE              ; SIZE OF CODE
                .ORG    $1000
                CBASE:
                        LDX     #rtt_bf         ; RUN TIME BUFFER
                        LDAA    #^x20          ; SPACE CHARACTER
                        LDAB    #10           ; DO 10 TIMES
                LOOP:
                        STAA    0,X           ; STORE SPACE IN BUFFER
                        INX                     ; GO ON TO NEXT BYTE
                        DECB                   ; DECREASE COUNT
                        BNE     LEND            ; FINISHED ?
                FIX1:   JMP     LOOP            ; NO - SO LOOP
                LEND:
                        RTS                     ; EXIT ROUTINE
                CEND:
                        .WORD   $4E9            ; CHECKSUM OF CODE BLOCK
                        .WORD   (FIXEN-FIXST)/2 ; NUMBER OF FIXUPS
                FIXST:
                        .WORD   FIX1+1          ; ADDRESS IN CODE BLOCK
                FIXEN:
                        .WORD   $E              ; CHECKSUM OF FIXUPS

	LDX     #CBASE          ; START ADDRESS
        CLRA
        CLRB
        STD     utw_s0         ; START CHECKSUM AS 0
LOOP2:
        CLRA
        LDAB    0,X           ; GET BYTE
        ADDD    utw_s0         ; ADD CHECKSUM
        STD     utw_s0         ; SAVE IT
        INX
        CPX     #CEND           ; ALL DONE
        BNE     LOOP2            ; NO - SO DO MORE
        ; UTW_S0 NOW HAS THE CHECKSUM




	
