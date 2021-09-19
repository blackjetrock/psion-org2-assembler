# psion-org2-assembler
Assembler for the 6303 in a Psion organiser

Runs on Linux

Can output the relocatable format needed when creating code designed to be loaded as a driver.


Run with:

org2asm.tcl xxx.asm

for example.

It uses the datasheet syntax, so for example:

ADDA  #$74

not ADD A #$74

Hexadecimal numbers are $XX

The .WORD directive can have full expressions, but not instruction operands, which can be numbers or labels.

.lst file has object code, label information and fixup data.
