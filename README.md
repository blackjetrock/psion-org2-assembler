# psion-org2-assembler
Assembler for the 6303 in a Psion organiser

Runs on Linux

Can output the relocatable format needed when creating code designed to be loaded as a driver.


Run with:

org2asm.tcl -f xxx.asm

for example.

It uses the datasheet syntax, so for example:

ADDA  #$74

not ADD A #$74

Hexadecimal numbers are $XX

Expressions can be used anywhere.

.lst file has object code, label information and fixup data.
