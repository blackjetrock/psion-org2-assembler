#!/usr/bin/tclsh
#
# Psion Organiser II assembler
#
#
# Multi pass assembler:
#
# Pass 1: All labels zero as some labels may be forward references and not defined
# Pass 2: Values used for all labels, but zero page/direct addressing modes may
# be wrong due to zero being used
# Pass 3: Addressing modes should be correct as expressions now have final values
#         but code may move due to zero page/direct addressing changes
# Pass 4: Code fixed so final pass, no further passes will alter code from this pass
#
#
# Define the addressing modes using regular expressions
# First field is name
# Next field is default instrcution length (can be over-riddn)
# Next field is regular expression that parses the addressing mode
#        This has a '%s' that is filled in with instruction mnemonics
#        and various sub expressions that are the parameters for the
#        object code generation
#
# Fixups are created for absolute 16 bit values. How this is done was inferred
# from a list file for XDICT.SRC. Labels created with EQU are not fixed. labels
# created using a colon at the start of a line are fixed. Pack address versions
# of labels (%LABEL) are not fixed. This seems to match the Psion XA assembler.
#
#--------------------------------------------------------------------------------
# From technical manual:
#     As device code can be loaded anywhere  in  memory,  depending  on  the
# machine type (CM, XP or LA etc.), and on how many devices are loaded, it is
# mandatory that the code to  be  loaded  is  in  a  relocatable  form.   The
# operating system provides a service DV$LOAD which will load the relocatable
# code into the machine and apply the relocation fix-ups.
# 
#      The code pointed to by the DEVICE_CODE_ADDRESS_WORD must be in Psion's
# relocatable  object  code format.  The relocatable object code format is as
# follows:
# 
#      1.  A word containing the number of bytes of code to be loaded.
#      2.  The block of code to be loaded.
#      3.  A word containing the checksum of the preceding block of code.
#      4.  A word containing the number of fix-up addresses.
#      5.  One word for each fix-up address.
#      6.  A word containing the checksum of the preceding fix-up table.
#
#
#
# 1.8 Device code
#  Device code is a program that is run when a pack (or top slot device) is booted. They
# are booted either when ON/Clear is pressed in the main menu, or when the system
# service DV$BOOT (SWI $17) is called. See bootable packs. Device code is in
# a relocatable code format, and its code block has the following format:
# 
# Byte:	Meaning:
#  0/1	Contains 0000. When loaded into memory, the program length is stored here,
# allowing the organiser to skip through consecutively loaded device code blocks.
# 2	Contains 00. When loaded into memory, the program pack is stored here, which is 1, 2, or 3 for packs B:, C:, or D: (top slot).
# 3	Device identification number. Same as in the pack header.
# 4	Device Version number. Same as in the pack header.
# 5	Number of vectors. Device code consists of several smaller programs called vectors.
#          Generally, device code must have at least 3 special vectors, which are detailed below.
# 6/7+	List of addresses of the vectors. These addresses are normally fixed up addresses pointing to routines in this code block.
# ??+	This is followed by the device vector routines.
# Device code is generally stored on a pack in a headerless block.
#
#
# 1.9 Device vectors
# Device code consists of several smaller programs called vectors. By using the system service
# DV$VECT (SWI $1B) any vector on any booted device can be called (register A should contain
# the device number, B the vector number).
#
# Generally, a device must have at least 3 special vectors, which are detailed below.
#
# Vector:	Purpose:
#
#  0	Install vector. Performs device initialisation, for example inserts a menu item.
# If the carry flag is set on return, the device code will be rejected, i.e. not loaded.
#  1	Remove vector. Performs removal, for example deletes a menu item. (On return,
#  carry flag is ignored.) After running this vector, the device code could be safely deleted from memory.
#  2	Language vector. Is called by the organiser to see if the device is willing to
#  accept a particular procedure name as an external command. Peripherals like
#  the Comms link use this vector for all the extra commands. On entry, X points
#  to the string (with leading byte count) and on exit it should have the
#  device identification number in register A and the vector number of the vector
#  that performs the task in register B, ready for a DV$VECT call. Carry should be
#  clear. If the device will not handle that command name, carry should be set. On a
#  device which does not implement any extra commands, this vector generally reads SEC, RTS.
#  Pressing ON/Clear in the main menu (or using service DV$BOOT, SWI $17) will first
#   call the remove vector of all devices (using service DV$CLER, SWI $18) and remove
#  all device code from memory. Then all device code is loaded, calling the install
#  vector in the process.
#  
#  If a procedure call is encountered in a program or in the calculator, (the service
#  DV$LKUP, SWI $19, is called so that) the procedure name is passed to the language
#  vector of all devices in turn. If the carry flag is set, then none of the devices
#  accept it and the packs are searched for a normal OPL procedure of that name. If a
#  device returns with a clear carry flag, then the appropriate vector is immediately
#  called (registers A and B are already prepared for calling service DV$VECT, SWI $1B).

# Fixups are necessary for any refernces to labels created with a colon, any labels
# created with an EQU does not ned a fixup. Fixups are local to the current overlay
# as they are used when an overlay is loaded

set ::PASS 0
set ::NUMBER_OF_PASSES 4
set ::LAST_PASS         [expr $::NUMBER_OF_PASSES]

set ::EMBED_FLAG   0
set ::EMBED_COMMENT_START "// ASSEMBLER_EMBEDDED_CODE_START"
set ::EMBED_COMMENT_END   "// ASSEMBLER_EMBEDDED_CODE_END"


set ::LIST_TEXT    ""
set ::LABELLIST    ""
set ::MACROLIST    ""
set ::OVER_LIST    ""
set ::CURRENT_OVER ""
set ::OVER_ORG 0
set ::OVER_LEN 0

set ::INCLUDELINES ""
set ::INCLUDEDIR_LIST ""
set ::LAST_GLOBAL_LABEL "NONE"
set ::OVER_ORG_PACK 0

set ::LABEL_DELIM "\[^A-Za-z0-9_\]"

set ::DIRECTIVES ".ORG    dir_org    \
                  .WORD   dir_word   \
		  .EQU	  dir_equ    \	 
                  .BYTE   dir_byte   \
                   org    dir_org    \
                   EQU    dir_equ    \
                  .ASCIC  dir_ascic  \
                  .ASCIZ  dir_asciz  \
		  .ASCII  dir_ascii  \
		  .BLKB   dir_blkb   \	
		  .OVER   dir_over   \	
		  .EOVER  dir_eover  \	
"

#    {"REL" 2 "^%s\[ \t\]+(\[A-Z0-9a-z_$^\]+)"                                                                chk_nul  proc_rel }

set ::RE_EXPR "\[A-Z0-9a-z_$^\]+"
set ::RE_EXPR ".+"
set ::IMM_RE "^%s\[ \t\]+#\[ \t\]*(\[A-Z0-9a-z_$^\]+)"
set ::ADDMODE {
    {"REL" 2 "^%s\[ \t\]+($::RE_EXPR)"                                                                chk_nul  proc_rel }
    {"IMM" 2 "^%s\[ \t\]+#\[ \t\]*($::RE_EXPR)"                                                       chk_nul  proc_imm }
    {"DIR" 2 "^%s\[ \t\]+($::RE_EXPR)"                                                                chk_dir  proc_dir }
    {"IDX" 2 "^%s\[ \t\]+($::RE_EXPR)\[ \t\]*,\[ \t\]*(\[Xx\])"                                        chk_nul  proc_idx }
    {"EXT" 3 "^%s\[ \t\]+($::RE_EXPR)"                                                                chk_nul  proc_ext }
    {"IMP" 1 "^%s\[ \t\]*$"                                                                                 chk_nul  proc_imp }
    {"XIM" 3 "^%s\[ \t\]+#\[ \t\]*($::RE_EXPR)\[ \t\]*,\[ \t\]*($::RE_EXPR)"                    chk_nul  proc_xim }
    {"XXM" 3 "^%s\[ \t\]+#\[ \t\]*($::RE_EXPR)\[ \t\]*,\[ \t\]*($::RE_EXPR)\[ \t\]*,\[ \t\]*\[Xx\]"  chk_nul  proc_xxm }
}

# Search order for addressing modes to ensure more complicated formats first

set ::ADDRMODE_ORDER {3 0 1 2 4 5 6 7}

# Define the instructions
#
# First field is mnemonic for instruction
# next fields are the opcodes for each addressong mode in the order
# given above
# Each instruction is of the default length for the addressong mode
# unless an override length is given (of the for .n when n is the
# instruction length)
#
# (I wanted to copy and paste this from the datasheet, but couldn't find one
# that wasn't a bitmap).

set ::INST {
    {ABA  ____ ____ ____ ____ ____ 1B   ____ ____}
    {ABX  ____ ____ ____ ____ ____ 3A   ____ ____}
    {ADCA ____ 89   99   A9   B9   ____ ____ ____}
    {ADCB ____ C9   D9   E9   F9   ____ ____ ____}
    {ADDA ____ 8B   9B   AB   BB   ____ ____ ____}
    {ADDB ____ CB   DB   EB   FB   ____ ____ ____}
    {ADDD ____ C3.3 D3   E3   F3   ____ ____ ____}
    {AIM  ____ ____ ____ ____ ____ ____ 71   61  }
    {ANDA ____ 84   94   A4   B4   ____ ____ ____}
    {ANDB ____ C4   D4   E4   F4   ____ ____ ____}
    {ASL  ____ ____ ____ 68   78   ____ ____ ____}
    {ASLA ____ ____ ____ ____ ____ 48   ____ ____}
    {ASLB ____ ____ ____ ____ ____ 58   ____ ____}
    {ASLD ____ ____ ____ ____ ____ 05   ____ ____}
    {ASR  ____ ____ ____ 67   77   ____ ____ ____}
    {ASRA ____ ____ ____ ____ ____ 47   ____ ____}
    {ASRB ____ ____ ____ ____ ____ 57   ____ ____}
    {BCC  24   ____ ____ ____ ____ ____ ____ ____}
    {BCS  25   ____ ____ ____ ____ ____ ____ ____}
    {BEQ  27   ____ ____ ____ ____ ____ ____ ____}
    {BGE  2C   ____ ____ ____ ____ ____ ____ ____}
    {BGT  2E   ____ ____ ____ ____ ____ ____ ____}
    {BHI  22   ____ ____ ____ ____ ____ ____ ____}
    {BITA ____ 85   95   A5   B5   ____ ____ ____}
    {BITB ____ C5   D5   E5   F5   ____ ____ ____}
    {BLE  2F   ____ ____ ____ ____ ____ ____ ____}
    {BLS  23   ____ ____ ____ ____ ____ ____ ____}
    {BLT  2D   ____ ____ ____ ____ ____ ____ ____}
    {BMI  2B   ____ ____ ____ ____ ____ ____ ____}
    {BNE  26   ____ ____ ____ ____ ____ ____ ____}
    {BPL  2A   ____ ____ ____ ____ ____ ____ ____}
    {BRA  20   ____ ____ ____ ____ ____ ____ ____}
    {BRN  21   ____ ____ ____ ____ ____ ____ ____}
    {BSR  8D   ____ ____ ____ ____ ____ ____ ____}
    {BVC  28   ____ ____ ____ ____ ____ ____ ____}
    {BVS  29   ____ ____ ____ ____ ____ ____ ____}
    {CBA  ____ ____ ____ ____ ____ 11   ____ ____}
    {CLC  ____ ____ ____ ____ ____ 0C   ____ ____}
    {CLI  ____ ____ ____ ____ ____ 0E   ____ ____}
    {CLR  ____ ____ ____ 6F   7F   ____ ____ ____}
    {CLRA ____ ____ ____ ____ ____ 4F   ____ ____}
    {CLRB ____ ____ ____ ____ ____ 5F   ____ ____}
    {CLV  ____ ____ ____ ____ ____ 0A   ____ ____}
    {CMPA ____ 81   91   A1   B1   ____ ____ ____}
    {CMPB ____ C1   D1   E1   F1   ____ ____ ____}
    {COM  ____ ____ ____ 63   73   ____ ____ ____}
    {COMA ____ ____ ____ ____ ____ 43   ____ ____}
    {COMB ____ ____ ____ ____ ____ 53   ____ ____}
    {CPX  ____ 8C.3 9C   AC   BC   ____ ____ ____}
    {DAA  ____ ____ ____ ____ ____ 19   ____ ____}
    {DEC  ____ ____ ____ 6A   7A   ____ ____ ____}
    {DECA ____ ____ ____ ____ ____ 4A   ____ ____}
    {DECB ____ ____ ____ ____ ____ 5A   ____ ____}
    {DES  ____ ____ ____ ____ ____ 34   ____ ____}
    {DEX  ____ ____ ____ ____ ____ 09   ____ ____}
    {EIM  ____ ____ ____ ____ ____ ____ 75   65  }
    {EORA ____ 88   98   A8   B8   ____ ____ ____}
    {EORB ____ C8   D8   E8   F8   ____ ____ ____}
    {INC  ____ ____ ____ 6C   7C   ____ ____ ____}
    {INCA ____ ____ ____ ____ ____ 4C   ____ ____}
    {INCB ____ ____ ____ ____ ____ 5C   ____ ____}
    {INS  ____ ____ ____ ____ ____ 31   ____ ____}
    {INX  ____ ____ ____ ____ ____ 08   ____ ____}
    {JMP  ____ ____ ____ 6E   7E   ____ ____ ____}
    {JSR  ____ ____ 9D   AD   BD   ____ ____ ____}
    {LDAA ____ 86   96   A6   B6   ____ ____ ____}
    {LDAB ____ C6   D6   E6   F6   ____ ____ ____}
    {LDD  ____ CC.3 DC   EC   FC   ____ ____ ____}
    {LDS  ____ 8E.3 9E   AE   BE   ____ ____ ____}
    {LDX  ____ CE.3 DE   EE   FE   ____ ____ ____}
    {LSR  ____ ____ ____ 64   74   ____ ____ ____}
    {LSRA ____ ____ ____ ____ ____ 44   ____ ____}
    {LSRB ____ ____ ____ ____ ____ 54   ____ ____}
    {LSRD ____ ____ ____ ____ ____ 04   ____ ____}
    {MUL  ____ ____ ____ ____ ____ 3D   ____ ____}
    {NEG  ____ ____ ____ 60   70   ____ ____ ____}
    {NEGA ____ ____ ____ ____ ____ 40   ____ ____}
    {NEGB ____ ____ ____ ____ ____ 50   ____ ____}
    {NOP  ____ ____ ____ ____ ____ 01   ____ ____}
    {OIM  ____ ____ ____ ____ ____ ____ 72   62  }
    {ORAA ____ 8A   9A   AA   BA   ____ ____ ____}
    {ORAB ____ CA   DA   EA   FA   ____ ____ ____}
    {PSHA ____ ____ ____ ____ ____ 36   ____ ____}
    {PSHB ____ ____ ____ ____ ____ 37   ____ ____}
    {PSHX ____ ____ ____ ____ ____ 3C   ____ ____}
    {PULA ____ ____ ____ ____ ____ 32   ____ ____}
    {PULB ____ ____ ____ ____ ____ 33   ____ ____}
    {PULX ____ ____ ____ ____ ____ 38   ____ ____}
    {ROL  ____ ____ ____ 69   79   ____ ____ ____}
    {ROLA ____ ____ ____ ____ ____ 49   ____ ____}
    {ROLB ____ ____ ____ ____ ____ 59   ____ ____}
    {ROR  ____ ____ ____ 66   76   ____ ____ ____}
    {RORA ____ ____ ____ ____ ____ 46   ____ ____}
    {RORB ____ ____ ____ ____ ____ 56   ____ ____}
    {RTI  ____ ____ ____ ____ ____ 3B   ____ ____}
    {RTS  ____ ____ ____ ____ ____ 39   ____ ____}
    {SBA  ____ ____ ____ ____ ____ 10   ____ ____}
    {SBCA ____ 82   92   A2   B2   ____ ____ ____}
    {SBCB ____ C2   D2   E2   F2   ____ ____ ____}
    {SEC  ____ ____ ____ ____ ____ 0D   ____ ____}
    {SEI  ____ ____ ____ ____ ____ 0F   ____ ____}
    {SEV  ____ ____ ____ ____ ____ 0B   ____ ____}
    {SLP  ____ ____ ____ ____ ____ 1A   ____ ____}
    {STQA ____ ____ ____ ____ B7   ____ ____ ____}
    {STAA ____ ____ 97   A7   B7   ____ ____ ____}
    {STAB ____ ____ D7   E7   F7   ____ ____ ____}
    {STD  ____ ____ DD   ED   FD   ____ ____ ____}
    {STS  ____ ____ 9F   AF   BF   ____ ____ ____}
    {STX  ____ ____ DF   EF   FF   ____ ____ ____}
    {SUBA ____ 80   90   A0   B0   ____ ____ ____}
    {SUBB ____ C0   D0   E0   F0   ____ ____ ____}
    {SUBD ____ 83.3 93   A3   B3   ____ ____ ____}
    {SWI  ____ ____ ____ ____ ____ 3F   ____ ____}
    {TAB  ____ ____ ____ ____ ____ 16   ____ ____}
    {TAP  ____ ____ ____ ____ ____ 06   ____ ____}
    {TBA  ____ ____ ____ ____ ____ 17   ____ ____}
    {TIM  ____ ____ ____ ____ ____ ____ 7B   6B  }
    {TPA  ____ ____ ____ ____ ____ 07   ____ ____}
    {TRAP ____ ____ ____ ____ ____ 00   ____ ____}
    {TST  ____ ____ ____ 6D   7D   ____ ____ ____}
    {TSTA ____ ____ ____ ____ ____ 4D   ____ ____}
    {TSTB ____ ____ ____ ____ ____ 5D   ____ ____}
    {TSX  ____ ____ ____ ____ ____ 30   ____ ____}
    {TXS  ____ ____ ____ ____ ____ 35   ____ ____}
    {WAI  ____ ____ ____ ____ ____ 3E   ____ ____}
    {XGDX ____ ____ ____ ____ ____ 18   ____ ____}
}

################################################################################
#
# Fixup collection
#
# This proc is passed the address (of a 16 bit quantity) that needs a fixup
# record.
# The address is changed to an overlay offset
#
# Fixups are local, so each overlay has a fixup list
#


proc add_fixup {a} {
#    if { $::PASS == $::LAST_PASS || 1 } {
	set d_a [lindex [evaluate_expression $a] 0]
	set d_a [expr $d_a]
	#	set d_a [value_to_dec $a]
	set f_a [format "%04X" $d_a]
	append ::FIXUP_TEXT($::CURRENT_OVER) "$d_a\n"    
#    }
}

################################################################################
#
# List file collection
#

proc addlst {txt} {
    append ::LIST_TEXT "$txt\n"
}

# packaddr is either an integer or an empty string
proc addlstline {packaddr addr type object line} {
    if { [string length $packaddr] != 0 } {
	set packaddr [format "%04X" $packaddr]
    } else {
	set packaddr 0
    }
    if { [string length $addr] == 0 } {
	set xaddr "0"
    } else {
	set xaddr [expr 0x$addr-$::OVER_ORG]
    }
    
    set f_line [format "%04X %-5s %-5s %04X %04X %-4s %-12s %-40s\n" [expr 0x$packaddr - $::OVER_ORG_PACK] $packaddr $addr $xaddr $::OVER_ORG $type $object  $line]
    append ::LIST_TEXT $f_line
}

proc error {line msg} {
    
    dbg "**ERROR***"
    dbg $line
    dbg $msg

    puts "**ERROR***"
    puts $line
    puts $msg

    addlst "**ERROR***"
    addlst $line
    addlst $msg
}

# Formats a decimal word value for th elst file
proc formatword {w} {
    return [format "\$%04X" $w]
}

################################################################################
#
# debug

proc dbg {str} {
    puts $::DBF $str
}

################################################################################
#
# Procs to check each addressing mode is valid
# primarily for direct and extended modes. Direct has to have address less than 256

proc chk_nul {p1 p2} {
    return 1
}

proc chk_dir {p1 p2} {
    set p1 [lindex [evaluate_expression $p1] 0]
    dbg "chk_dir '$p1'"
    if { $p1 < 256 } {
	return 1
    }
    
    return 0
}

################################################################################
#
# Processes each addressing mode to add the bytes following the opcode

# Indexed
# One argument byte
proc proc_rel {len p1 p2} {
    set p1 [lindex [evaluate_expression $p1] 0]

    # Note the 1 is actually the instruction length minus 1, but as all instructions
    # using REL addr mode are branches that is always 2
    set r [expr ($p1 - $::ADDR - 1)]

    # Convert to byte
    set r [expr $r & 0xff]
    
    emit $r
}

proc proc_imm {len p1 p2} {
    dbg "Proc_imm: '$p1'"
    #    set value [evaluate_expression $p1]
    
    #    set p1   [lindex $value 0]
    #    set type [lindex $value 1]
    
    switch $len {
	2 {
	    emit $p1
	}
	3 {
	    emitword $p1
	}
    }
}

proc proc_dir {len p1 p2} {
    #set p1 [lindex [evaluate_expression $p1] 0]
    emit $p1
}

proc proc_idx {len p1 p2} {
    #set p1 [lindex [evaluate_expression $p1] 0]
    emit $p1
}

# Extended addressing needs fixup for relocatable code
proc proc_ext {len p1 p2} {
    dbg "proc_ext '$p1'"
    #    set p1 [lindex [evaluate_expression $p1] 0]
    emitword $p1
}

proc proc_imp {len p1 p2} {
}

proc proc_xim {len p1 p2} {
    #set p1 [lindex [evaluate_expression $p1] 0]
    #set p2 [lindex [evaluate_expression $p2] 0]
    emit $p1
    emit $p2
}

proc proc_xxm {len p1 p2} {
    #set p1 [lindex [evaluate_expression $p1] 0]
    #set p2 [lindex [evaluate_expression $p2] 0]
    emit $p1
    emit $p2
}


################################################################################
#

proc value_to_dec {str} {

    #    puts "str='$str'"
    if { [string first "$" $str] != -1 } {
	set hex [string trim $str "$"]
	set res [expr 0x$hex]
    } else {
	set res  $str
    }
    return $res
}

################################################################################
#
# Emits a byte of object code
#
# Keeps track of pack address as these bytes go to pack image
# Also checksums overlay code as it is emitted

# Text variable
set ::EMITTED ""
set ::HEX_EMITTED ""

proc emit {b} {
    set ::FIXED " "

    set evb [expr [lindex [evaluate_expression $b] 0] & 0xFF]
    set fb [format "%02X" $evb]

    # Add to overlay checksum
    if { [string length $::CURRENT_OVER] > 0 } {
	incr ::OVER_CSUM($::CURRENT_OVER) $evb
    }

    # Add to object code
    set ::EMITTED_ADDR $::ADDR
    append ::EMITTED     " $fb"
    append ::HEX_EMITTED "$fb"

    # next pack address
    incr ::PACK_ADDR 1
}

# We emit a word
# The address is needed for the fixup records

proc emitword {w} {
    if { $::PASS == 1 } {
	append ::EMITTED " 00 00"
	append ::HEX_EMITTED "0000"

	# Next pack address
	incr ::PACK_ADDR 2

	return
    }

    dbg "Emitword:'$w'"
    set ev    [evaluate_expression $w]
    dbg "    after eval:'$ev'"
    set w     [lindex $ev 0]
    set type  [lindex $ev 1]
    dbg "    type:$type"
    
    # Create fixup record, as an address into the code block. This is the same as the current overlay
    # address minus the start of the current overlay
    set ::FIXED " "
    switch $type {
	COLON {
	    #	    add_fixup $::PACK_ADDR
	    add_fixup [expr $::ADDR-$::OVER_ORG]

	    # Adjust word so it is fixed up corectly
	    set w [expr $w - $::OVER_START($::CURRENT_OVER)]
	    
	    set ::FIXED "*"
	}
    }
    
    set fb [format "%02X" [expr $w / 256]]

    # Add to overlay checksum
    if { [string length $::CURRENT_OVER] > 0 } {
	incr ::OVER_CSUM($::CURRENT_OVER) [expr $w / 256]
    }

    append ::EMITTED " $fb"
    append ::HEX_EMITTED "$fb"
    set fb [format "%02X" [expr $w % 256]]

        # Add to overlay checksum
    if { [string length $::CURRENT_OVER] > 0 } {
	incr ::OVER_CSUM($::CURRENT_OVER) [expr $w % 256]
    }

    append ::EMITTED " $fb"
    append ::HEX_EMITTED "$fb"

    # Next pack address
    incr ::PACK_ADDR 2

}


################################################################################
#
# Creates a new label
# The type is either COLON EQU depending on how it was created

proc create_label {name value type packaddr} {
    dbg "create_label:$name $value $type"
    
    if { [lsearch -exact $::LABELLIST $name] == -1 } {
	# Add a new label
	#puts "Label $name"
	lappend ::LABELLIST $name

	# Sort into length order, for substitution
	set ::LABELLIST [lsort -command sz $::LABELLIST]
    }

    set ::LABEL($name) $value
    set ::LABEL_TYPE($name) $type
    set ::LABEL_PACK_ADDR($name) $packaddr
    dbg "create_label:$name $value $type $packaddr"
}

################################################################################
#
# Sort a list into size order.
# We use this when replacing label text so we get the largest match
# possible first

proc sz {a b} {
    return [expr [string length $a] < [string length $b]]
}

################################################################################
#
# Directives
#
# Directives can have expressions as arguments
#
# ^xnn     converted to 0xnn
# ^Cx      converted to ~x
# ^Adxd    converted to ASCII code of 'x'
# ^Adxyd   converted to ASCIi code of x and y as two bytes
#
# The type of the expression is COLON if any label used is
# COLON, otherwise EQU
# The type is used to work out if a fixup is needed.
#
# Return value is a list:
# {value type}
#

proc evaluate_expression_core {exp} {
    # if this is pass 1 then just return zero
    # Pass 1 is the pass that may not have labels defined due to forward references.
    # So we use zero
    
    if { $::PASS == 1 } {
	return {0 EQU}
    }

    # If the expression is blank then just return blank
    if { [string length $exp] == 0 } {
	return {"" EQU}
    }
    
    # Turn the expression into Tcl and evaluate it
    dbg "EVALEXP:exp = '$exp'"

    # Default to EQU type (so no fixup generated from immediate constants for example
    set type EQU
    
    # Force complement to tilde as it stops label substitution
    set exp [string map "^C ~" $exp]
    
    dbg "After map = '$exp'"
    
    # Turn label names into references to the label variables
    foreach label $::LABELLIST {
	set is_local 0
	
	# If it is a local label then we check it's valid and then convert it
	# to its original form
	set labellookup $label
	if { [regexp -- "LOCAL:(\[A-Za-z0-9_\]+):(\[0-9\]+)" $label all last_global number] } {
	    if { [string compare $last_global $::LAST_GLOBAL_LABEL] == 0 } {
		# Valid local variable, create local label name
		dbg "Is valid:($label), last global ($::LAST_GLOBAL_LABEL)"

		#Save the original name for looking things up
		set labellookup $label
		set label "$number\$"
		dbg "Becomes '$label'"
		set is_local 1
		
	    } else {
		# Not valid, skip it
		# dbg "Not valid ($label), last global ($::LAST_GLOBAL_LABEL)"
		continue
	    }
	}

	# Labels are replaced but only if they are correctly delimited, i.e. they
	# don't have characters next to them. They have to be delimited by something
	# other than just characters that can be in label names

	# We attempt two substitutions, one for labels with a % infront of them
	# which is replaced with the pack address of the label, and a second
	# which is a delimited name only, this is replaced with the ORG address
	# of the label.

	# First the label with % prefix as it's larger
	
	#	dbg "Subst for %$label with [set ::LABEL($labellookup)]"

	if { [string first "%$label" $exp] != -1 } {
	    dbg "Found1 %$label"

	    # A label that uses pack addresses is never fixed up
	    # Name changed for local labels, only check if still EQU
	    set type EQU

	    dbg "  label type:$type"
	    
	    # Delimit expression so we can delimit labels correctly 
	    set exp "=$exp="
	    dbg "'$exp'"

	    # If label has '$' in it then we have to escape it
	    set label [string map {"$" "SSS"} $label]
	    dbg "Label escaped:'$label'"
	    set labellookup "$labellookup"
	    
	    dbg "Label lookup='$labellookup'"
	    
	    regsub -all "($::LABEL_DELIM)%$label\($::LABEL_DELIM)" [string map {"$" "SSS"} $exp] "\\1[set ::LABEL_PACK_ADDR($labellookup)]\\2" exp
	    dbg "'$exp'"
	    set exp [string trim $exp "="]
	}
	#set exp [string map "$label [set ::LABEL($labellookup)]" $exp]
	
	
	#	dbg "Subst for $label with [set ::LABEL($labellookup)]"
	
	if { [string first $label $exp] != -1 } {
	    dbg "Found2 $label, type currently=$type"

	    if { $is_local } {
		set type $::LABEL_TYPE($labellookup)
	    } else {
		set type $::LABEL_TYPE($label)
	    }
	    
	    dbg "  label type:$type"
	    
	    # Delimit expression so we can delimit labels correctly 
	    set exp "=$exp="
	    dbg "'$exp'"
	    
	    # If label has '$' in it then we have to escape it
	    set label [string map {"$" "SSS"} $label]
	    dbg "Label escaped:'$label'"
	    dbg "Label lookup='$labellookup'"
	    
	    regsub -all "($::LABEL_DELIM)$label\($::LABEL_DELIM)" [string map {"$" "SSS"} $exp] "\\1[set ::LABEL($labellookup)]\\2" exp
	    dbg "'$exp'"
	    set exp [string trim $exp "="]
	}
	#set exp [string map "$label [set ::LABEL($labellookup)]" $exp]
    }
    
    dbg "EVALEXP:after labels = '$exp'"
    
    # Now handle the ASCII character expressions
    if { [regexp -- "\\^(a|A)(.)(.+)(.)" $exp all code delim1 ascii delim2] } {
	dbg "code='$code' del1='$delim1' del2='$delim2' ascii='$ascii'"
	# We have an ascii expression
	# Get indices of expression
	if { [regexp -indices -- "\\^(a|A)(.)(.+)(.)" $exp i_all i_code i_delim1 i_ascii i_delim2] } {
	    # Some checks
	    dbg "i_all    $i_all"
	    dbg "i_code   $i_code"
	    dbg "i_delim1 $i_delim1"
	    dbg "i_ascii  $i_ascii"
	    dbg "i_delim2 $i_delim2"
	    
	    
	    if { $delim1 != $delim2 } {
		error $original_line "Different delimiters in $code"
	    }
	    
	    if { [string length $ascii] > 2 } {
		error $original_line "Too many characters in $code"
	    }

	    # Convert characters and replace original expression with ASCII codes
	    set value "0x"
	    foreach ch [split $ascii ""] {
		binary scan $ch H2 hex_ch
		append value $hex_ch
	    }

	    dbg "ASCII conv: $ascii => $value"

	    dbg "insert $i_all"
	    # insert into expression
	    set exp [string replace $exp [lindex $i_all 0] [lindex $i_all 1] $value]
	    dbg "EXP after ^A: '$exp'"
	}
    }


    # Force hex values to correct format
    set exp [string map "\$ 0x ^x 0x ^X 0x" $exp]

    dbg "EVALEXP:after hex conv='$exp'"
    dbg "EVALEXP ='[expr $exp]'"

    # Evaluate, trap errors
    set result 0

    if { [catch {   set result [expr $exp] } ] } {
	error $::CURRENT_LINE "Bad expression '$exp'"
    }

    dbg "EVALEXP:$result $type"
    return [list $result $type]
}

proc evaluate_expression {exp} {

    return [evaluate_expression_core $exp]
}


################################################################################
#
# Directives
#


# Overlay start
#
# Set up the current overlay
# Store the overlay start
#
# We need to insert the overlay length into the object code, but the addresses don't increment for
# it as it is just for loading the code.

proc dir_over {line original_line} {
    # We set up ::OVERLAY_ORG to the current address
    # Also set ::OVERLAY_NAME
    # We also create a label with the name of the overlay

    dbg ".OVER"
    
    if { [regexp -- "(.OVER|over)\[ \t\]+(\[A-Za-z0-9$+*/<>\^-]+)" $line all dir overname] } {
	# Set up current overlay
	set ::CURRENT_OVER   $overname

	set ::OVER_ORG       [expr $::ADDR]

	# Pack address is always incremented and so we add two here to get
	# the pack address of the first code byte.
	set ::OVER_ORG_PACK  [expr $::PACK_ADDR]
	
	set f_addr    [format "%04X" $::OVER_ORG]
	set f_emitted [format "%-12s" ""]
	set line [string trim $original_line]
	addlstline $::PACK_ADDR $f_addr "(OVER)" $f_emitted  $original_line

	# The label created by the .over directive is the address of the first code byte of the
	# overlay
	create_label $overname $::ADDR COLON [expr $::OVER_ORG_PACK]

	# Add overlay to list and set up default values if it doesn't
	# already exist

	if { [lsearch -exact $::OVER_LIST $overname] == -1 } {
	    # New overlay
	    lappend ::OVER_LIST $overname
	    
	    # Set up start and end, in ORG address and pack address
	    set ::OVER_START($overname) $::OVER_ORG
	    set ::OVER_START_PACK($overname) $::OVER_ORG_PACK 
	    set ::OVER_END($overname) $::OVER_ORG
	    set ::OVER_END_PACK($overname) $::OVER_ORG_PACK
	    set ::FIXUP_TEXT($overname) ""
	    dbg "OVER:new $overname $::OVER_ORG  $::OVER_ORG_PACK"

	} else {
	    # Store latest start addresses
	    set ::OVER_START($overname) $::OVER_ORG
	    set ::OVER_START_PACK($overname) $::OVER_ORG_PACK
	    set ::FIXUP_TEXT($overname) ""
	    dbg "OVER:upd $overname $::OVER_ORG  $::OVER_ORG_PACK"
	}

	# Insert overlay code length
	set overlen [expr $::OVER_END_PACK($overname) - $::OVER_START_PACK($overname) + 1]
#	set overlen $::OVER_LEN
	set overlen [expr $::OVER_END($overname)-$::OVER_START($overname)+1]
	
	# If overlay is of zero length then we don't put anything in the object code

	if { $overlen > 0 } {
	    # Save pack address
	    set paddr $::PACK_ADDR
	    
	    # Emit it
	    set ::EMITTED ""
	    emitword $overlen
	    
	    set f_addr    [format "%04X" $::ADDR]
	    set f_emitted [format "%-12s" $::EMITTED]
	    set line [string trim $original_line]
	    addlstline $paddr $f_addr "(OL)" "$f_emitted$::FIXED"  $original_line
	    
	    # Do not increment the address, this is hidden data for loading only
	    #incr ::ADDR 2
	}
	
	# The checksum should only sum data, not the length word
	set ::OVER_CSUM($overname) 0
	
	return 1
    } else {
	error $line "Bad .OVER"
	return 0
    }
}

proc emit_and_list_word {w tag original_line} {
    
    # Save pack address
    set paddr $::PACK_ADDR
    
    # Emit it
    set ::EMITTED ""
    emitword $w
    
    set f_addr    [format "%04X" $::ADDR]
    set f_emitted [format "%-12s" $::EMITTED]
    set line [string trim $original_line]
    addlstline $paddr $f_addr "$tag" "$f_emitted$::FIXED"  $original_line
    
    incr ::ADDR 2
}

# End of overlay
#
# Closes an overlay
#
# Adds to object data:
#
#  Checksum of overlay
#  Number of fixups in overlay
#  Fixup list
#  Checksum of fixups

proc dir_eover {line original_line} {

    dbg ".EOVER"
    
    if { [regexp -- "(.EOVER|eover)" $line all dir] } {
	set f_addr    [format "%04X" $::ADDR]
	set f_emitted [format "%-12s" ""]
	set line [string trim $original_line]
	addlstline $::PACK_ADDR $f_addr "(OE)" $f_emitted  $original_line

	# Set up the end of the overlay, the last byte is the last byte of the code
	set ::OVER_END($::CURRENT_OVER)      [expr $::ADDR - 1]
	set ::OVER_END_PACK($::CURRENT_OVER) [expr $::PACK_ADDR - 1]

	set ov $::CURRENT_OVER
	
	set overlen [expr $::OVER_END_PACK($ov) - $::OVER_START_PACK($ov) + 1]
	set overlen [expr $::ADDR - $::OVER_ORG]
	#set ::OVER_LEN $overlen
	
	# Only put data in object stream if overlay is not of zero length
	if { $overlen > 0 } {
	    # Insert overlay data checksum
	    set overcsum [expr $::OVER_CSUM($ov) & 0xFFFF]
	    emit_and_list_word  $overcsum "(OSUM)" ""
	    
	    # Now number of fixups
	    set nfix   [llength $::FIXUP_TEXT($ov)]
	    emit_and_list_word $nfix "(NFX)" ""
	    
	    set fixcsum 0
	    foreach rec $::FIXUP_TEXT($ov) {
		incr fixcsum $rec
		emit_and_list_word $rec "(FX)" ""
	    }
	    
	    # And the fixup list csum
	    emit_and_list_word $fixcsum "(FCSUM)" ""
	}
	
	return 1
    } else {
	error $line "Bad .EOVER"
	return 0
    }
}

#
# Sets the code origin.
#
# The origin determines the addresses the code is assembled for
# This is the ::ADDR variable. The code also lives at a certain address on the pck,
# this is the PACK_ADDR variable. These are updated during assembly.
# Overlays have their own ORG and PACK variables for keeping track of where code is assembled
# within overlays (ORG can be reset within and overlay)
#
#
proc dir_org {line original_line} {
    # We set up ::ADDR as specified
    if { [regexp -- "(.ORG|org)\[ \t\]+(\[A-Za-z0-9$+*/<>\^-]+)" $line all dir addr] } {
	set ::ADDR [lindex [evaluate_expression $addr] 0]

	set f_addr    [format "%04X" $::ADDR]
	set f_emitted [format "%-12s" ""]
	set line [string trim $original_line]
	addlstline $::PACK_ADDR $f_addr "(O)" $f_emitted  $original_line

	return 1
    } else {
	error $line "Bad .ORG"
	return 0
    }
}

# Byte list
proc dir_byte {line original_line} {
    # We create a byte
    dbg "dir_byte:'$line'"
    
    if { [regexp -- "(.BYTE|.byte)\[ \t\]+(.+)" $line all bytedir bytelist] } {
	set bytelist [string trim $bytelist]
	
	dbg "BYTE directive byte list = '$bytelist'"
	
	foreach byte [split $bytelist " \t,"] {
	    set bytelist [string map {" " ""} $bytelist]
	    set byte [lindex [evaluate_expression $byte] 0]

	    # Save pack address
	    set paddr $::PACK_ADDR
	    
	    # Emit it
	    set ::EMITTED ""
	    emit $byte
	    
	    set f_addr    [format "%04X" $::ADDR]
	    set f_emitted [format "%-12s" $::EMITTED]
	    set line [string trim $original_line]
	    addlstline $paddr $f_addr "(B)" $f_emitted  $original_line
	    
	    incr ::ADDR 1
	}
	return 1
    } else {
	error $line "Bad .BYTE"
	return 0
    }
    return 0
}

# Word list
proc dir_word {line original_line} {
    # We create a word
    dbg "dir_word:'$line'"
    dbg "   ::ADDR=$::ADDR"
    
    # Remove space from line

    if { [regexp -- "(.WORD|.word)\[ \t\]+(.+)" $line all worddir wordlist] } {
	set wordlist [string trim $wordlist]
	dbg "WORD directive word list = '$wordlist'"

	foreach word [split $wordlist " \t,"] {
	    
	    #set word [lindex [evaluate_expression $word] 0]

	    # Save pack address
	    set paddr $::PACK_ADDR
	    
	    # Emit it
	    set ::EMITTED ""
	    emitword $word
	    
	    set f_addr    [format "%04X" $::ADDR]
	    set f_emitted [format "%-12s" $::EMITTED]
	    set line [string trim $original_line]
	    addlstline $paddr $f_addr "(W)" "$f_emitted$::FIXED"  $original_line
	    
	    incr ::ADDR 2
	}
	return 1
    } else {
	error $line "Bad .WORD"
	return 0
    }
    return 0
}

# Set label value
proc dir_equ {line original_line} {
    if { [regexp -- "(\[A-Za-z0-9_$\]+)\[ \t\]+(.EQU|equ|EQU|.equ)\[ \t\]+(\[A-Za-z0-9$\(\)_<>*/+-\]+)" $line all name dir value] } {
	set value [lindex [evaluate_expression $value] 0]

	# Pack address doesn't make much sense for EQU labels
	create_label $name $value EQU $value
	
	set f_value [format "%04X        " [lindex [evaluate_expression $value] 0]]
	set line [string trim $original_line]
	addlstline "" "" "(E)" $f_value  $original_line

	return 1
    } else {
	error $line "Bad .EQU"
	return 0
    }
}

proc dir_blkb {line original_line} {
    if { [regexp -- "(.BLKB|blkb|BLKB|.blkb)\[ \t\]+(\[A-Za-z0-9$\(\)_<>*/+-\]+)" $line all dir value] } {
	set value [lindex [evaluate_expression $value] 0]

	# Make space

	for {set i 0} {$i < $value} {incr i 1} {
	    set EMITTED ""
	    emit 0
	}
	
	set f_addr    [format "%04X" $::ADDR]	
	set f_value [format "%04X        " [lindex [evaluate_expression $value] 0]]
	set line [string trim $original_line]
	addlstline $::PACK_ADDR "$f_addr" "(E)" $f_value  $original_line

	incr ::ADDR $value
#	incr ::PACK_ADDR $value
	return 1
    } else {
	error $line "Bad .BLKB"
	return 0
    }
}

proc dir_ascii {line original_line} {
    if { [regexp -- "(.ASCII|.ascii)\[ \t\]+\"(\[^\"\]+)\"" $line all dir str] } {
	dbg "ASCII: '$str'"
	# First, the string length byte
	set str_len [string length $str]
	dbg "ASCII:$str_len"
	if { $str_len > 255 } {
	    error $line "String in .ASCII ('$str') too long ($str_len bytes)"
	    return 0
	}
	
	foreach char [split $str ""] {
	    
	    binary scan $char H2 hex_char

	    set paddr $::PACK_ADDR
	    
	    set ::EMITTED ""
	    emit 0x$hex_char
	    
	    set f_addr    [format "%04X" $::ADDR]
	    set f_emitted [format "%-12s" $::EMITTED]
	    set line [string trim $original_line]
	    addlstline $paddr $f_addr "(A)" $f_emitted  $original_line
	    
	    incr ::ADDR 1
	}
	return 1
    } else {
	error $line "Bad .ASCII"
	return 0
    }
}

proc dir_ascic {line original_line} {
    if { [regexp -- "(.ASCIC|.ascic)\[ \t\]+\"(\[^\"\]+)\"" $line all dir str] } {
	dbg "ASCIC: '$str'"
	# First, the string length byte
	set str_len [string length $str]
	dbg "ASCIC:$str_len"
	if { $str_len > 255 } {
	    error $line "String in .ASCIC ('$str') too long ($str_len bytes)"
	    return 0
	}

	set paddr $::PACK_ADDR
	
	set ::EMITTED ""
	emit $str_len

	dbg "ASCIC: '$::EMITTED'"
	set f_addr    [format "%04X" $::ADDR]
	set f_emitted [format "%-12s" $::EMITTED]
	set line [string trim $original_line]
	addlstline $paddr $f_addr "(AL)" $f_emitted  $original_line

	incr ::ADDR 1
	
	foreach char [split $str ""] {
	    
	    binary scan $char H2 hex_char

	    set paddr $::PACK_ADDR
	    
	    set ::EMITTED ""
	    emit 0x$hex_char
	    
	    set f_addr    [format "%04X" $::ADDR]
	    set f_emitted [format "%-12s" $::EMITTED]
	    set line [string trim $original_line]
	    addlstline $paddr $f_addr "(A)" $f_emitted  $original_line
	    
	    incr ::ADDR 1
	}
	return 1
    } else {
	error $line "Bad .ASCIC"
	return 0
    }
}


proc dir_asciz {line original_line} {
    if { [regexp -- "(.ASCIZ|.asciz)\[ \t\]+\"(\[^\"\]+)\"" $line all dir str] } {
	dbg "ASCIZ: '$str'"
	# First, the string length byte
	set str_len [string length $str]
	dbg "ASCIZ:$str_len"
	if { $str_len > 255 } {
	    error $line "String in .ASCIZ ('$str') too long ($str_len bytes)"
	    return 0
	}
	
	
	foreach char [split $str ""] {
	    
	    binary scan $char H2 hex_char

	    set paddr $::PACK_ADDR
	    
	    set ::EMITTED ""
	    emit 0x$hex_char
	    
	    set f_addr    [format "%04X" $::ADDR]
	    set f_emitted [format "%-12s" $::EMITTED]
	    set line [string trim $original_line]
	    addlstline $paddr $f_addr "(A)" $f_emitted  $original_line
	    
	    incr ::ADDR 1
	}

	set paddr $::PACK_ADDR
	
	# Emit the nul terminator
	set ::EMITTED ""
	emit 0
	
	dbg "ASCIZ: '$::EMITTED'"
	set f_addr    [format "%04X" $::ADDR]
	set f_emitted [format "%-12s" $::EMITTED]
	set line [string trim $original_line]
	addlstline $paddr $f_addr "(AL)" $f_emitted  $original_line

	incr ::ADDR 1

	return 1
    } else {
	error $line "Bad .ASCIZ"
	return 0
    }
}

################################################################################
#
# Returns the next line to be processed
#


proc next_line {} {
    
    # We get lines from a macro first
    if { [llength $::MACROEXP] != 0 } {
	set result [lindex $::MACROEXP 0]
	set ::MACROEXP [lrange $::MACROEXP 1 end]
	dbg "NL(M):'$result'"
	return $result
    }

    # The get lines from included files
    if { [llength $::INCLUDELINES] != 0 } {
	set result [lindex $::INCLUDELINES 0]
	set ::INCLUDELINES [lrange $::INCLUDELINES 1 end]
	dbg "NL(I):'$result'"
	return $result
    }

    # Get the next line from the file being assembled
    if { [llength $::FILETEXT] != 0 } {
	set result [lindex $::FILETEXT 0]
	set ::FILETEXT [lrange $::FILETEXT 1 end]
	dbg "NL(F):'$result'"
	return $result
    } else {
	set ::DONE 1
    }
    
    return ""
}

################################################################################
#
# Takes an assembly file and assembles it to object code and any other
# information needed, such as a symbol table or fixup list

proc assemble_file {filename} {

    puts "Assembling $filename  Pass $::PASS"

    addlst "Assembling $filename  Pass $::PASS"
    
    # Read file contents
    set f [open $filename]

    set ::FILETEXT [read $f]
    close $f

    set ::FILETEXT [split $::FILETEXT "\n"]
    
    # Clear object code
    set obj ""

    # Address pointer
    set ::ADDR 0

    # Not collecting a macro
    set collect_macro 0
    set ::DONE 0
    
    # Take each line and assemble it
    while { !$::DONE } {
	set line [next_line]

	# Keep a record of the unaltered source line
	set original_line $line

	# Keep a global copy of line for errors
	set ::CURRENT_LINE $line
	
	set found 0
	dbg "----------"
	dbg "line=$line"
	dbg "ADDR=[formatword $::ADDR] PACK_ADDR=[formatword $::PACK_ADDR]"
	# Remove comments
	if { [regexp -- "(\[^;\]*);.*" $line all strippedline] } {
	    set line $strippedline
	}

	# Handle creating labels
	# We handle local labels by storing them in a different form.
	# If <LG> is the last global label seen
	# they are transformed from n$ into 'LOCAL_<LG>_n' 
	if { [regexp -- "^\[ \t\]*(\[A-Za-z0-9_$\]+):(.*)" $line all label line] } {
	    # We have a label it could be a local label
	    if { [regexp -- "(\[0-9\]+)\[$\]" $label all number] } {
		dbg "Local label creation: $label
"
		# Local label, make name globally unique
		set label "LOCAL:$::LAST_GLOBAL_LABEL\:$number"
		dbg "Renamed as '$label'"
	    } else {
		dbg "Global label now $label"
		set ::LAST_GLOBAL_LABEL $label
	    }

	    # Labels cannot be numbers
	    if { [regexp -- "^\[0-9\]+$" $label] } {
		error $line "Bad label ($label) cannot be number"
		
	    }
	    
	    create_label $label $::ADDR COLON $::PACK_ADDR
	    dbg "Created (L) '$label' = '$::ADDR'"
	    if { [string length [string trim $line]] == 0 } {
		set f_addr    [format "%04X" $::ADDR]

		addlstline $::PACK_ADDR $f_addr "(L)" "" "$label:"
		continue
	    }
	}

	# Are we done?
	if { [regexp -- ".END$" $line] } {
	    set ::DONE 1
	    continue
	}

	# Handle included files
	if { [string first .INCLUDE [string toupper $line]] != -1 } {
	    dbg "Include in '$line'"
	    
	    # Get the file name
	    if { [regexp -- "(.INCLUDE)\[ \t\]+(.+)" $line all dir filename] } {
		dbg "Include $filename"

		# Try to find include file in all directories inthe include dir list
		foreach directory $::INCLUDEDIR_LIST {
		    if { [file exists $directory/$filename] } {
			set filename $directory/$filename
			break;
		    }
		}

		dbg "INCLUDE:'$filename'"
		
		# Read file and add to a line stream
		set g [open $filename]
		set itxt [read $g]
		close $g

		# Split into lines
		set ilines [split $itxt "\n"]

		# Add to line stream
		foreach lline $ilines {
		    lappend ::INCLUDELINES $lline
		}
		
		# Do not process the include directive any more
		continue
	    }
	}
	
	# Expand macros
	set expanded 0
	
	foreach macro $::MACROLIST {
	    if { [string first $macro $line] != -1 } {
		dbg "Found macro $macro"
		dbg "RE=$macro\[ \t\]+($::MACROPAREXP($macro))"
		
		# This could be a macro expansion. Macro name has to be a word, i.e. spaces on either side.
		if { [regexp -- "\[ \t\]+$macro\[ \t\]+($::MACROPAREXP($macro))" $line all parvals] } {
		    dbg "Match regexp"
		    
		    # We need to expand parameters in the macro bidy
		    set macrotext $::MACRO($macro)

		    dbg "Macro text='$macrotext'"
		    
		    # Replace every parameter with a value
		    foreach parname [split $::MACROPARS($macro) ","] parval [split $parvals " ,"] {
			dbg "Replace '$parname' with '$parval'"
			regsub -all $parname $macrotext $parval macrotext
		    }

		    dbg "Macro text after replace='$macrotext'"
		    
		    # We now replace the input lines with the macro text
		    set ::MACROEXP [split $macrotext "\n"]
		    set expanded 1
		}
	    }
	}

	# Don't process expanded macros
	if { $expanded } {
	    continue
	}
	
	# Handle macros
	# We collect macro text here then insert macros into the line stream
	if { [string first .MACRO [string toupper $line]] != -1 } {
	    dbg "Macro def started in '$line'"
	    
	    # Get the macro name and parameters
	    if { [regexp -- "(\[A-Za-z0-9_\]+)\[ \t\]+(.MACRO|.macro)\[ \t\]+(.+)" $line all macname macdir macpars] } {
		dbg "Macro $macname"
		
		# Add to macro list
		if { [lsearch -exact $::MACROLIST $macname] != -1 } {
		    # This is a redefinition
		} else {
		    # Add to list
		    lappend ::MACROLIST $macname
		}

		# Process the parameters to remove spaces
		set macpars [string map {" " ""} $macpars]
		set ::MACROPARS($macname) $macpars

		# Create a regexp to match the parameters
		set regexp ""
		foreach par [split $macpars ","] {
		    lappend regexp "\[A-Za-z0-9_$\]+"
		}
		set regexp [join $regexp "\[ \\t\]*,\[ \\t\]*"]
		set ::MACROPAREXP($macname) $regexp
	    }
	    

	    # Now collect the macro body, it ends with a .ENDM
	    set collect_macro 1
	    set collect_macro_name $macname
	    continue
	}

	# Macro body collection
	if { $collect_macro } {
	    if { [string first .ENDM [string toupper $line]] != -1 } {
		# End of macro definition
		set collect_macro 0
		continue
	    }

	    # Add this line to the macro body
	    append ::MACRO($collect_macro_name) "$line\n"

	    # We are done with this line
	    continue
	}
	
	# handle directives
	set donedir 0
	foreach {dirname dirproc} $::DIRECTIVES {
	    if { [string first $dirname [string toupper $line]] != -1 } {
		# Process directive line
		if { [$dirproc $line $original_line] } {
		    set donedir 1
		    break
		}
	    }
	}

	# If we processed a directive then we are finished with this line
	if { $donedir } {
	    continue
	}
	
	# Run through every instruction trying each valid addressing
	# mode to see if we get a match

	# Remove leading spaces
	set line [string trim $line]

	# If there's no text left then we are done with this line
	if { [string length $line] == 0 } {
	    continue
	}
	
	foreach inst_rec $::INST {
	    dbg "  inst_rec = $inst_rec"
	    set mne      [lindex $inst_rec 0]
	    set low_mne [string tolower $mne]
	    set insensitive_mne "($mne|$low_mne)"

	    # If the line doesn't have the mnemonic in it then we don't bother
	    # processing further for this instruction
	    if { [string first $mne [string toupper $line]] == -1 } {
		continue
	    }
	    
	    # Run through all the addressing modes
	    set addrmode_index 0

	    foreach addrmode_spec [lrange $inst_rec 1 end] {

		set addrmode_i [lindex $::ADDRMODE_ORDER $addrmode_index]

		# We have the information for each addressing mode
		# Get the regexp for that mode
		set addrmode_spec      [lindex $::ADDMODE  $addrmode_i]
		set addrmode_regexp    [subst -nocommands [lindex $addrmode_spec 2]]
		set inst_length        [lindex $addrmode_spec 1]
		set addrmode_chk_proc  [lindex $addrmode_spec 3]
		set addrmode_proc_proc [lindex $addrmode_spec 4]
		set opcode             [lindex $inst_rec [expr $addrmode_i+1]]

		
		# Modify non standard instruction lengths
		if { [regexp -- "(\[A-Fa-f0-9\]+).(\[0-9\]+)" $opcode all opcode inst_length] } {
		}
		
		# Put the mnemonic in the regexp
		set def_regexp [format $addrmode_regexp $insensitive_mne]
		dbg "DEF REGEXP:'$def_regexp'"
		
		# See if we have a match
		set p1 0
		set p2 0
		
		if { [regexp -- $def_regexp $line all dummy p1 p2] } {
		    dbg "Line='$line'"
		    dbg "MATCH p1='$p1' p2='$p2'"
		    
		    # No need to convert parameters to instruction as that is done by the
		    # addressing mode handlers
		    #		    set p1 [value_to_dec $p1]
		    #		    set p2 [value_to_dec $p2]
		    
		    # The regexp has matched, but does the addressing mode
		    # check procedure say this is valid?
		    if { [$addrmode_chk_proc $p1 $p2] } {
			dbg "Check OK"
		    } else {
			# The check procedure doesn't like this, keep checking
			dbg "Check not OK"
			incr addrmode_index 1
			continue
		    }

		    # If opcode is invalid, keep looking
		    if { $opcode == "____" } {
			dbg "OPCODE=$opcode"
			dbg "addrmode_spec=$addrmode_spec"
			dbg "def_regexp=$def_regexp"
			incr addrmode_index 1
			continue
		    }
		    
		    if { 1 } {
			# We can assemble the instruction
			set f_addr    [format "%04X" $::ADDR]
			set f_opcode  [format "%s" $opcode]

			# Use the addr mode to process for the bytes following the
			# opcode
			set ::EMITTED ""
			set paddr $::PACK_ADDR
			
			emit [expr 0x$opcode]

			# Add one to the address here so we have ::ADDR set up correctly
			# for the operand (especially for fixups) when the emitword
			# is called in the proc_proc below
			incr ::ADDR 1
			
			if { $::PASS != 1 } {
			    # Convert parameters to values
			    $addrmode_proc_proc $inst_length $p1 $p2
			} else {
			    $addrmode_proc_proc $inst_length 0 0
			}
			
			set f_emitted [format "%-12s" $::EMITTED]
			
			addlstline $paddr $f_addr "($addrmode_i)" "$f_emitted$::FIXED"   $original_line

			# Increment past operand, we have already incremented past the opcode
			incr ::ADDR  [expr $inst_length-1]

		    } else {
			puts "$line  matches"
			puts "'$def_regexp'"
		    }
		    
		    set found 1

		    # Don't try any more matches
		    break
		}

		incr addrmode_index 1
	    }


	    if { $found } {
		break;
	    }
	}
	if { $::PASS == $::LAST_PASS } {
	    if { !$found } {
		error $line "Instruction not found"
	    }
	}
    }
    set label_sum [calc_label_sum]
    
    addlstline "" "" "(SUM)" "Label Sum: [format "$%04X" $label_sum]" ""
}

################################################################################
#

# Wipe out all of the macros

proc clear_macros {} {
    foreach macro $::MACROLIST {
	unset ::MACRO($macro)
	unset ::MACROPARS($macro)
    }

    set ::MACROLIST ""
    set ::MACROEXP ""
}

################################################################################
#
# Writes a file that has all of the macros

proc write_macro_file {filename} {

    set f [open $filename w]

    puts $f "Macro List"
    puts $f ""
    
    foreach macro $::MACROLIST {
	puts $f "$macro   .MACRO   $::MACROPARS($macro)"
	puts $f "$::MACROPAREXP($macro)"
	puts $f "$::MACRO($macro)"
	puts $f ".ENDM"
	
	puts $f "\n"
    }
    
    close $f
}


################################################################################
#
# Writes a hex file. This is just a file full of ASCII hex bytes
# Not Intel Hex

proc write_hex_file {filename} {

    set f [open $filename w]

    set i 0
    foreach {na nb}  [split $::HEX_EMITTED ""] {
	set hx [string tolower "$na$nb"]
	puts -nonewline $f $hx
	if { [expr ($i % 16) == 15] } {
	    puts $f ""
	}
	incr i 1
    }
    close $f
}

################################################################################
#
# Writes a bin file.


proc write_bin_file {filename} {

    set f [open $filename wb]

    # Convert to binary
    set bin [binary format H* $::HEX_EMITTED]
    puts -nonewline $f $bin
    
    close $f
}

################################################################################

proc calc_label_sum {} {

    set label_sum 0
    
    foreach label $::LABELLIST {
	set label_value [format "$%04X" $::LABEL($label)]
	incr label_sum [lindex [evaluate_expression $label_value] 0]
    }

    return $label_sum
}

proc write_lst_file {filename} {
    
    set f [open $filename w]
    
    puts $f $::LIST_TEXT
    
    foreach label $::LABELLIST {
	set label_value [formatword $::LABEL($label)]
	set label_pack_value [formatword $::LABEL_PACK_ADDR($label)]
	
	set f_name [format "%20s" $label]

	switch $::LABEL_TYPE($label) {
	    COLON {
		set ltype "FIX"
	    }
	    EQU {
		set ltype "   "
	    }
	}
	
	puts $f "$f_name: $ltype $label_value %$label_pack_value"
    }
    
    # Overlay list
    foreach ov $::OVER_LIST {
	set ovlen [expr $::OVER_END($ov)-$::OVER_START($ov)+1]
	puts $f "Overlay:$ov"
	puts $f "  Org        : [formatword $::OVER_ORG]"
	puts $f "  Org Pack   : [formatword $::OVER_ORG_PACK]"
	puts $f "  Start      : [formatword $::OVER_START($ov)]"
	puts $f "  End        : [formatword $::OVER_END($ov)]"
	puts $f "  Length     : [formatword $ovlen]"
	puts $f "  Pack Start : [formatword $::OVER_START_PACK($ov)]"
	puts $f "  Pack End   : [formatword $::OVER_END_PACK($ov)]"
	
	# Fixup information
	set nfix   [llength $::FIXUP_TEXT($ov)]
	set f_nfix [format "\$%04X" $nfix]
	
	puts $f "\nFixup Information\n"
	puts $f "\n$f_nfix records"
	puts $f ""
	set i 0
	
	foreach rec $::FIXUP_TEXT($ov) {
	    puts $f "[formatword $i]: [formatword $rec]"
	    incr i 1
	}
    }
    
    close $f
}

################################################################################
#
# Set up
#
################################################################################

# Sign on
puts ""
puts "Psion Organiser 6303 Assembler"
puts ""

# First place to look for include files is the location of the assembler
set asm_dir [file dirname $argv0]

lappend ::INCLUDEDIR_LIST "."
lappend ::INCLUDEDIR_LIST $asm_dir


set arg_i 0

while { $arg_i < [llength $argv]} {
    set thisarg [lindex $argv $arg_i]
    
    switch [lindex $argv $arg_i] {
	-f {
	    incr arg_i 1
	    set asm_filename [lindex $argv $arg_i]
	    
	    puts "File: $asm_filename"
	    set lst_filename [string map {.asm .lst} $asm_filename]
	    set hex_filename [string map {.asm .hex} $asm_filename]
	    set mac_filename [string map {.asm .mac} $asm_filename]
	    set bin_filename [string map {.asm .bin} $asm_filename]
	    
	    set ::DBG_FILENAME [string map {.asm .dbg} $asm_filename]
	}

	# If specified then the hex dta is embedded into a C file using
	# marker comments to specify where
	--embed {
	    set ::EMBED_FLAG 1
	    incr arg_i 1
	    set ::EMBED_FILENAME [lindex $argv $arg_i]
	    puts "Embed file:$::EMBED_FILENAME"
	}
    }
    
    incr arg_i 1
}


set ::DBF [open $::DBG_FILENAME w]



################################################################################
#
# two passes

set time_start [clock seconds]

puts ""

for { set ::PASS 1 } {$::PASS <= $::NUMBER_OF_PASSES} {incr ::PASS 1} {
    
    set ::HEX_EMITTED ""    
    set ::LAST_GLOBAL_LABEL "NONE"
    set ::PACK_ADDR 0
    set ::FIXED " "
    
    clear_macros
    assemble_file $asm_filename

    # Save the intermediate code for debug
    set f [open EMITTED_$::PASS.hex w]
    puts $f $::HEX_EMITTED
    close $f
}

write_lst_file $lst_filename

write_hex_file $hex_filename
write_bin_file $bin_filename
write_macro_file $mac_filename

# Embed data?
if { $::EMBED_FLAG } {
    # Open and read the file
    set f [open $::EMBED_FILENAME]
    set embed_text [read $f]
    close $f

    # Format the code as C array hex
    set f_hex ""
    set f_i 0
    foreach {c1 c2} [split $::HEX_EMITTED ""] {
	append f_hex "0x$c1$c2,"
	incr f_i 1
	if { ($f_i % 16) == 0 } {
	    append f_hex "\n"
	}
    }
    
    # Embed the code

    puts "Embedding object code in C file:$::EMBED_FILENAME"
    
    regsub "$::EMBED_COMMENT_START\(.*)$::EMBED_COMMENT_END" $embed_text "$::EMBED_COMMENT_START\n$f_hex\n$::EMBED_COMMENT_END" embed_text2

    set g [open $::EMBED_FILENAME w]
    puts -nonewline $g $embed_text2
    close $g
}

close $::DBF

set time_end [clock seconds]
set elapsed [expr $time_end - $time_start]
puts "Elapsed time: $elapsed\s"
