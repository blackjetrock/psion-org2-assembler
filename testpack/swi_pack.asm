 
                    TTL     EXSWI
           ;
           ; DEVICE EXTENSION TO INTERFACE SWI
           ; CALLS TO THE OPL LANGUAGE
           ;
     D_ADDR           EQU     ^XE0
     X_ADDR           EQU     ^XE2
     RTA_SP    EQU    ^XA5
     RTA_FP    EQU    ^XA7
     RTB_BL    EQU    ^X2187
     UTW_S0    EQU    ^X41
     ER_RT_UE  EQU    204
     ER_RT_NP  EQU    205
     ER_EX_TV  EQU    224
     ER_FN_BA  EQU    247
         ;
          ORG         ^X241b-25
     XX:
         .BYTE        ^X6A            ; DATAPACK BOOTABLE
         .BYTE        ^X02            ; 16K DATAPACK
         .BYTE        0               ; NO HARDWARE
         .BYTE        2               ; DEVICE NUMBER
         .BYTE        ^X10            ; VERSION NUMBER (1.0)
         .BYTE        2               ; PRIORITY
         .WORD        %ROOT-2         ; ROOT OVERLAY ADDRESS
         .BYTE        ^XFF
         .BYTE        ^XFF
         .BYTE        ^X09
         .BYTE        ^X81
         .ASCII       "MAIN    "



         .BYTE        ^X90
         .BYTE        ^X02
         .BYTE        ^X80
         .WORD        %PRGEND-%ROOT+2 ; SIZE OF CODE
     ;
     ; START ROOT OVERLAY
     ; ==================
     ;
         .OVER        ROOT
     CODELEN:
         .WORD        0000            ; SET BY DV$BOOT
     BDEVICE:
         .BYTE        00              ; SET BY DV$BOOT
     DEVNUM:
         .BYTE        2               ; DEVICE NUMBER
     VERNUM:
         .BYTE        ^X10            ; VERSION 1.0
     MAXVEC:
         .BYTE        <ENDVEC-VECTABLE>/2 ; NUMBER OF VECTORS
     VECTABLE:
         .WORD        INSTALL         ; INSTALL VECTOR
         .WORD        REMOVE          ; REMOVE VECTOR
         .WORD        LANG            ; LANGUAGE VECTOR
         .WORD        DO_SWI          ; HANDLE SWI%: VECTOR
     ENDVEC:
     ;
     ; INSTALL VECTOR - DOES NOTHING
     ; ==============
     ;
     INSTALL:
         CLC                  ; SIGNAL SUCCESS
         RTS
     ;
     ; REMOVE VECTOR - DOES NOTHING
     ; =============
     ;
     REMOVE:
         CLC                  ; SIGNAL SUCCESS
         RTS
     ;
     ; LANGUAGE VECTOR - RECOGNIZES 'SWI%:'
     ; ===============
     ;
     LANG:
         LDD  0,X
         SUBD #<4*256>+^A'S'
         BNE  NOT_SWI
         LDD  2,X
         SUBD #<^A'W'*256>+^A'I'
         BNE  NOT_SWI
         LDA  A,4,X
         CMP  A,#^A'%'
         BNE  NOT_SWI
         LDA  A,#2            ; DEVICE 2
         LDA  B,#3            ; DO_SWI VECTOR SERVICE NUMBER
         CLC                  ; SIGNAL SUCCESS
         RTS
     NOT_SWI:
         SEC                  ; SIGNAL NOT PREPARED TO HANDLE
         RTS                  ; REQUEST
     ;
     ; DO_SWI VECTOR - ACTUALLY DOES THE SWI%:
     ; =============
     ;
     DO_SWI:
         LDX  RTA_SP:         ; GET LANGUAGE STACK
         LDA  A,0,X           ; GET NUMBER OF ARGUMENTS
         DEC  A               ; CHECK IF 1
         BEQ  ARG_OK          ; YES - SO CORRECT ARG COUNT
         LDA  B,#ER_RT_NP     ; SIGNAL WRONG NUMBER OF ARGUMENTS
     BAD_EXIT:
         SEC                  ; SIGNAL BAD CALL
         RTS
     ARG_OK:
         LDA  A,1,X           ; GET ARGUMENT TYPE
         BEQ  ARG_INT         ; ZERO - SO ARG IS INTEGER
         LDA  B,#ER_EX_TV     ; SIGNAL TYPE VIOLATION
         BRA  BAD_EXIT
     ARG_INT:
         LDD  2,X             ; GET SWI FUNCTION TO DO
         SUBD #^X80           ; MAXIMUM FUNCTION + 1
         BCS  FUNCTION_OK     ; GOOD FUNCTION RANGE 0-127
         LDA  B,#ER_FN_BA     ; SIGNAL BAD FUNCTION ARGUMENT
         BRA  BAD_EXIT
     FUNCTION_OK:
         ADD  B,#^X80         ; GET BACK THE FUNCTION NUMBER
         STA  B,SWI_FUNC      ; PATCH THE CODE TO DO SWI FUNCTION
     ;
     ; LOOKUP THE GLOBALS D% AND X% IN THE CALLING PROCEDURE
     ; EXTERNALS ARE STORE AS LENGTH OF NAME FOLLOWED BY NAME
     ; FOLLOWED BY TYPE FOLLOWED BY 2 BYTE ADDRESS
     ;
         LDD  #0
         STD  D_ADDR:         ; MARK D NOT FOUND
         STD  X_ADDR:         ; MARK X NOT FOUND
         LDX  RTA_FP:         ; GET THE FRAME POINTER
         DEX
         DEX
         STX  UTW_S0:         ; SAVE END OF GLOBALS TABLE
         LDX  0,X             ; ADDRESS OF BASE OF GLOBALS TABLE
     LOOP:
         CPX  UTW_S0:         ; SEARCHED WHOLE TABLE YET
         BEQ  TEST_OK         ; FINISHED
         LDD  0,X
         SUBD #<2*256>+^A'D'  ; CHECK IF D%
         BNE  CHECK_X         ; NO - SO CHECK X
         LDD  2,X
         SUBD #<^A'%'*256>    ; CHECK IF D%
         BNE  CHECK_X         ; NO - SO CHECK X
         LDD  4,X             ; ADDRESS OF D
         STD  D_ADDR:         ; SAVE IT AWAY
         BRA  NEXT_EXT        ; GO LOOK UP THE OTHERS
     CHECK_X:
         LDD  0,X
         SUBD #<2*256>+^A'X'  ; CHECK IF X%
         BNE  NEXT_EXT        ; NO - SO CHECK NEXT
         LDD  2,X
         SUBD #<^A'%'*256>    ; CHECK IF X%
         BNE  NEXT_EXT        ; NO - SO CHECK NEXT
         LDD  4,X             ; ADDRESS OF X%
         STD  X_ADDR:         ; SAVE IT AWAY
     NEXT_EXT:
         LDA  B,0,X           ; GET LENGTH OF NAME
         ADD  B,#4            ; SKIP TO NEXT NAME
         ABX
         BRA  LOOP
     TEST_OK:
         LDX  X_ADDR:         ; GET X'S ADDRESS
         BNE  X_FOUND
         LDA  B,#^A'X'        ; SIGNAL X% NOT DECLARED
     SET_MISS:
         LDA  A,#2
         STD  RTB_BL
         LDA  A,#^A'%'
         STA  A,RTB_BL+2      ; USED WHEN REPORTING MISSING EXTERNALS
         LDA  B,#ER_RT_UE     ; SIGNAL UNDEFINED EXTERNALS
         BRA  BAD_EXIT
     X_FOUND:
         LDX  D_ADDR:         ; GET D'S ADDRESS
         BNE  D_FOUND
         LDA  B,#^A'D'        ; SIGNAL D% NOT DECLARED
         BRA  SET_MISS
     D_FOUND:
         LDD  0,X             ; GET VALUE FOR D
         LDX  X_ADDR:
         LDX  0,X             ; GET VALUE FOR X
         SWI
     SWI_FUNC:
         .BYTE 0              ; PATCHED HIGHER UP
         BCC  NO_ERR          ; ALL OK
         CLR  A
         LDX  D_ADDR:         ; GET D'S ADDRESS
         STD  0,X             ; SAVE ERROR IN D
         LDD  #^XFFFF         ; SIGNAL FAILURE
         BRA  EXIT            ; RETURN SWI%:'S VALUE
     NO_ERR:
         PSHX                 ; SAVE X
         LDX  D_ADDR:         ; GET D'S ADDRESS
         STD  0,X             ; SAVE D'S VALUE
         LDX  X_ADDR:         ; GET X'S ADDRESS
         PUL  A               ; GET BACK X IN D
         PUL  B
         STD  0,X             ; SAVE X'S VALUE
         CLR  A
         CLR  B               ; SIGNAL SUCCESS
     EXIT:
         LDX  RTA_SP:         ; GET STACK ADDRESS
         DEX
         DEX                  ; LEAVE ROOM FOR INT RESULT
         STD  0,X
         STX  RTA_SP:         ; UPDATE STACK POINTER
         CLC                  ; SIGNAL SUCCESS
         RTS
         .EOVER
         .OVER        PRGEND  ; TO MARK END OF CODE
         .EOVER
         .END
	
