00001
 ************************************************
00002
 00003
 '"
 NAME : MOVING MEMORY BLOCKS (MOVE)
 '"
00004
 '"
 '"
00005
 ' *******************~****************************d
 "
 '"
,.
00006
 00007
 '"
 ENTRY
 IX
 (SOURCE ADDR)
OOOOB
 '"
 DEA (DESTINATION ADDR)
 '"
00009
 '"
 ACCB (TRANSFER COUNTER)
 '"
00010
 '" RETURNS : NOTHING
 '"
00011
 '"
 ,. '"
00012
 '"
 ************************************************
00013
 00014A
 OOBO
 '"
 ORG
 $80
00015
 ,.
00016A
 0080
 0002
 A DEA
 RMB
 2
 Destination ADDR
00017
 00018A
 FOOO
 '"
 ORG
 $FOOO
00019
 00020
 FOOO
 A MOVE
 '"
 EQU
 Entry point
00021A
 FOOO
 A6
 00
 A
 LDAA
 ' O.X
 "
 Load transfer data
00022A
 F002
 08
 INX
 Increment source ADDR
00023A
 F003
 3C
 PSHX
 Push source ADDR
00024A
 F004
 DE
 80
 A
 LDX
 DEA
 Load destination ADDR
0002SA
 F006
 A7
 00
 A
 STAA
 O.X
 Store transfer data
00026A
 F008
 08
 INX
 Increment destination ADDR
00027A
 F009
 OF
 60
 A
 STX
 DEA
 Store destination ADDR
00028A
 FOOB
 38
 PULX
 Pull sorce ADDR
00029A
 FOOC
 SA
 DECB
 Decrement transfer counter
00030A
 FOOD
 26
 Fl FOOO
 BNE
 MOVE
 Loop until transfer counter
 0
00031A
 FOOF
 39
 RTS
