#!/usr/bin/tclsh
#
# Psion Organiser II assembler
#

# Define the addressing modes using regular expressions
# First field is name
# Next field is default instrcution length (can be over-riddn)
# Next field is regular expression that parses the addressing mode
#        This has a '%s' that is filled in with instruction mnemonics
#        and various sub expressions that are the parameters for the
#        object code generation

set ::LABELLIST ""

set ::DIRNAMES ".ORG .WORD"
set ::DIRPROCS "dir_org dir_word"

set ::ADDMODE {
    {"REL" 2 "^%s\[ \]+(\[A-Z0-9a-z_\]+)"}
    {"IMM" 2 "^%s\[ \]+#\[ \]*(\[A-Za-z0-9_$\]+)"}
    {"DIR" 2 "^%s\[ \]+(\[A-Za-z0-9_$\]+)"}
    {"IDX" 2 "^%s\[ \]+(\[0-9A-Fa-f$\]+)\[ \]*,\[ \]*(\[XY\])"}
    {"EXT" 3 "^%s\[ \]+(\[A-Za-z0-9_$\]+)"}
    {"IMP" 1 "^%s"}
}

# Searh order for addressing modes to ensure more complicated formats first

set ::ADDRMODE_ORDER {3 0 1 2 4 5}

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
    {ABA  ____ ____ ____ ____ ____ 1B  }
    {ABX  ____ ____ ____ ____ ____ 3A  }
    {ADCA ____ 89   99   A9   B9   ____}
    {ADCB ____ C9   D9   E9   F9   ____}
    {ADDA ____ 8B   9B   AB   BB   ____}
    {ADDB ____ CB   DB   EB   FB   ____}
    {ADDD ____ C3.3 D3   E3   F3   ____}
    {AIM  ____ ____ 71   61   ____ ____}
    {ANDA ____ 84   94   A4   B4   ____}
    {ANDB ____ C4   D4   E4   F4   ____}
    {ASL  ____ ____ ____ 68   78   ____}
    {ASLA ____ ____ ____ ____ ____ 48  }
    {ASLB ____ ____ ____ ____ ____ 58  }
    {ASLD ____ ____ ____ ____ ____ 05  }
    {ASR  ____ ____ ____ 67   77   ____}
    {ASRA ____ ____ ____ ____ ____ 47  }
    {ASRB ____ ____ ____ ____ ____ 57  }
    {BCC  24   ____ ____ ____ ____ ____}
    {BCS  25   ____ ____ ____ ____ ____}
    {BEQ  27   ____ ____ ____ ____ ____}
    {BGE  2C   ____ ____ ____ ____ ____}
    {BGT  2E   ____ ____ ____ ____ ____}
    {BHI  22   ____ ____ ____ ____ ____}
    {BITA ____ 85   95   A5   B5   ____}
    {BITB ____ C5   D5   E5   F5   ____}
    {BLE  2F   ____ ____ ____ ____ ____}
    {BLS  23   ____ ____ ____ ____ ____}
    {BLT  2D   ____ ____ ____ ____ ____}
    {BMI  28   ____ ____ ____ ____ ____}
    {BNE  26   ____ ____ ____ ____ ____}
    {BPL  2A   ____ ____ ____ ____ ____}
    {BRA  20   ____ ____ ____ ____ ____}
    {BRN  21   ____ ____ ____ ____ ____}
    {BSR  8D   ____ ____ ____ ____ ____}
    {BVC  28   ____ ____ ____ ____ ____}
    {BVS  29   ____ ____ ____ ____ ____}
    {CBA  ____ ____ ____ ____ ____ 11  }
    {CLC  ____ ____ ____ ____ ____ 0C  }
    {CLI  ____ 00   00   00   00   0E  }
    {CLR  ____ ____ ____ 6F   7F   ____}
    {CLRA ____ ____ ____ ____ ____ 4F  }
    {CLRB ____ ____ ____ ____ ____ 5F  }
    {CLV  ____ 00   00   00   00   ____}
    {CMPA ____ 81   91   A1   B1   ____}
    {CMPB ____ C1   D1   E1   F1   ____}
    {COM  ____ 00   00   63   73   ____}
    {COMA ____ ____ ____ ____ ____ 43  }
    {COMB ____ ____ ____ ____ ____ 53  }
    {CPX  ____ 8C.3 9C   AC   BC   ____}
    {DAA  ____ ____ ____ ____ ____ 19  }
    {DEC  ____ 00   00   6A   7A   ____}
    {DECA ____ ____ ____ ____ ____ 4A  }
    {DECB ____ ____ ____ ____ ____ 5A  }
    {DES  ____ ____ ____ ____ ____ 34  }
    {DEX  ____ ____ ____ ____ ____ 09  }
    {EIM  ____ ____ 75   65   ____ ____}
    {EORA ____ 88   98   A8   B8   ____}
    {EORB ____ C8   D8   E8   F8   ____}
    {INC  ____ 00   00   6C   7C   ____}
    {INCA ____ ____ ____ ____ ____ 4C  }
    {INCB ____ ____ ____ ____ ____ 5C  }
    {INS  ____ ____ ____ ____ ____ 31  }
    {INX  ____ ____ ____ ____ ____ 08  }
    {JMP  ____ ____ ____ 6E   7E   ____}
    {JSR  ____ ____ 9D   AD   BD   ____}
    {LDAA ____ 86   96   A6   B6   ____}
    {LDAB ____ C6   D6   E6   F6   ____}
    {LDD  ____ 00   00   00   00   ____}
    {LDS  ____ 8E.3 9E   AE   BE   ____}
    {LDX  ____ CE.3 DE   EE   FE   ____}
    {LSR  ____ ____ ____ 64   74   ____}
    {LSRA ____ ____ ____ ____ ____ 44  }
    {LSRB ____ ____ ____ ____ ____ 54  }
    {LSRD ____ ____ ____ ____ ____ 04  }
    {MUL  ____ 00   00   00   00   3D  }
    {NEG  ____ 00   00   60   70   ____}
    {NEGA ____ ____ ____ ____ ____ 40  }
    {NEGB ____ ____ ____ ____ ____ 50  }
    {NOP  ____ ____ ____ ____ ____ 01  }
    {OIM  ____ ____ 72   62   ____ ____}
    {ORAA ____ 8A   9A   AA   BA   ____}
    {ORAB ____ CA   DA   EA   FA   ____}
    {PSHA ____ ____ ____ ____ ____ 36  }
    {PSHB ____ ____ ____ ____ ____ 37  }
    {PSHX ____ ____ ____ ____ ____ 3C  }
    {PULA ____ ____ ____ ____ ____ 32  }
    {PULB ____ ____ ____ ____ ____ 33  }
    {PULX ____ ____ ____ ____ ____ 38  }
    {ROL  ____ ____ ____ 69   79   ____}
    {ROLA ____ ____ ____ ____ ____ 49  }
    {ROLB ____ ____ ____ ____ ____ 59  }
    {ROR  ____ 00   00   66   76   ____}
    {RORA ____ ____ ____ ____ ____ 46  }
    {RORB ____ ____ ____ ____ ____ 56  }
    {RTI  ____ 00   00   00   00   3B  }
    {RTS  ____ 00   00   00   00   39  }
    {SBA  ____ 00   00   00   00   ____}
    {SBCA ____ 00   00   00   00   ____}
    {SBCB ____ 00   00   00   00   ____}
    {SEC  ____ 00   00   00   00   0D  }
    {SEI  ____ 00   00   00   00   0F  }
    {SEV  ____ 00   00   00   00   0B  }
    {SLP  ____ ____ ____ ____ ____ 1A  }
    {STAA ____ ____ 97   A7   B7   ____}
    {STAB ____ ____ D7   E7   F7   ____}
    {STD  ____ ____ DD   ED   FD   ____}
    {STS  ____ ____ 9F   AF   BF   ____}
    {STX  ____ ____ DF   EF   FF   ____}
    {SUBA ____ 80   90   A0   B0   ____}
    {SUBB ____ C0   D0   E0   F0   ____}
    {SUBD ____ 83   93   A3   B3   ____}
    {SWI  ____ 00   00   00   00   3F  }
    {TAB  ____ ____ ____ ____ ____ 16  }
    {TAP  ____ ____ ____ ____ ____ 06  }
    {TBA  ____ ____ ____ ____ ____ 17  }
    {TIM  ____ ____ 7B   6B   ____ ____}
    {TPA  ____ ____ ____ ____ ____ 07  }
    {TRAP ____ ____ ____ ____ ____ 00  }
    {TST  ____ ____ ____ 6D   7D   ____}
    {TSTA ____ ____ ____ ____ ____ 4D  }
    {TSTB ____ ____ ____ ____ ____ 5D  }
    {TSX  ____ ____ ____ ____ ____ 30  }
    {TXS  ____ ____ ____ ____ ____ 35  }
    {WAI  ____ ____ ____ ____ ____ 3E  }
    {XGDX ____ ____ ____ ____ ____ 18  }
}

proc error {line msg} {
    puts "**ERROR***"
    puts $line
    puts $msg
}

################################################################################
#

proc value_to_dec {str} {

    puts "str='$str'"
    if { [string first "$" $str] != -1 } {
	set hex [string trim $str "$"]
	set res [expr 0x$hex]
    } else {
	set res [expr $str]
    }
    return $res
}

################################################################################
#
# Directives
#

proc dir_org {line} {
    # We set up ::ADDR as specified
    if { [regexp -- ".ORG\[ \]+(\[A-Fa-f0-9$\]+)" $line all addr] } {
	set ::ADDR [value_to_dec $addr]
    } else {
	error $line "Bad .ORG"
    }
}

proc dir_word {line} {
}

# takes an assembly file and assembles it to object code and any other
# information needed, such as a symbol table or fixup list

proc assemble_file {filename} {

    # Read file contents
    set f [open $filename]

    set ftext [read $f]
    close $f

    # Clear object code
    set obj ""

    # Address pointer
    set ::ADDR 0
    
    # Take each line and assemble it
    foreach line [split $ftext "\n"] {
	set found 0
	
	# Remove comments
	if { [regexp -- "(\[^;\]*);.*" $line all strippedline] } {
	    set line $strippedline
	}
	
	# Handle labels
	if { [regexp -- "(\[A-Za-z0-9_\]+):(.*)" $line all label line] } {
	    # We have a label
	    if { [lsearch -exact $::LABELLIST $label] == -1 } {
		# Add a new label
		#puts "Label $label"
		lappend ::LABELLIST $label
		set ::LABEL($label) $::ADDR
	    } else {
		# Already defined
		error $line "Label $label already defined" 
	    }
	}

	
	# handle directives
	foreach dirname $::DIRNAMES dirproc $::DIRPROCS {
	    if { [string first $dirname $line] != -1 } {
		# Process directive line
		$dirproc $line
	    }
	}
	
	# Run through every instruction trying each valid addressing
	# mode to see if we get a match

	# Remove leading spaces
	set line [string trim $line]
	
	foreach inst_rec $::INST {
	    set mne      [lindex $inst_rec 0]

	    # Run through all the addressing modes
	    set addrmode_index 0
	    set addrmode_i [lindex $::ADDRMODE_ORDER $addrmode_index]
	    
	    foreach addrmode_spec [lrange $inst_rec 1 end] {
		# We have the information for each addressing mode
		# Get the regexp for that mode
		set addrmode_spec   [lindex $::ADDMODE  $addrmode_i]
		set addrmode_regexp [lindex $addrmode_spec 2]
		set inst_length     [lindex $addrmode_spec 1]
		set opcode          [lindex $inst_rec [expr $addrmode_i+1]]

		# Modify non standard instruction lengths
		if { [regexp -- "(\[A-Fa-f0-9\]+).(\[0-9\]+)" $opcode all opcode inst_length] } {
		}
		
		# Put the mnemonic in the regexp
		set def_regexp [format $addrmode_regexp $mne]
		#puts "DEF REGEXP:'$def_regexp'"
		
		# See if we have a match
		if { [regexp -- $def_regexp $line all p1 p2] } {
		    if { 1 } {
			# We can assemble the instruction
			set f_addr    [format "%04X" $::ADDR]
			set f_opcode  [format "%s" $opcode]
			
			puts "$f_addr ($addrmode_i)  $f_opcode    $line"
			incr ::ADDR  $inst_length

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
    }
}

################################################################################

proc write_lst_file {filename} {

    set f [open $filename w]

    foreach label $::LABELLIST {
	set label_value [format "%04X" $::LABEL($label)]
	set f_name [format "%20s" $label]
	puts  "$f_name: $label_value"
    }
    
    close $f
}


assemble_file test.asm

puts ""
puts ""

write_lst_file test.lst
