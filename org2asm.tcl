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

set ::PASS 0

set ::LIST_TEXT    ""
set ::LABELLIST    ""
set ::MACROLIST    ""
set ::INCLUDELINES ""

set ::DIRNAMES ".ORG .WORD .EQU .BYTE org equ"
set ::DIRPROCS "dir_org dir_word dir_equ dir_byte dir_org dir_equ"

#    {"REL" 2 "^%s\[ \t\]+(\[A-Z0-9a-z_$^\]+)"                                                                chk_nul  proc_rel }

set ::RE_EXPR "\[A-Z0-9a-z_$^\]+"
set ::IMM_RE "^%s\[ \t\]+#\[ \t\]*(\[A-Z0-9a-z_$^\]+)"
set ::ADDMODE {
    {"REL" 2 "^%s\[ \t\]+($::RE_EXPR)"                                                                chk_nul  proc_rel }
    {"IMM" 2 "^%s\[ \t\]+#\[ \t\]*($::RE_EXPR)"                                                       chk_nul  proc_imm }
    {"DIR" 2 "^%s\[ \t\]+($::RE_EXPR)"                                                                chk_dir  proc_dir }
    {"IDX" 2 "^%s\[ \t\]+($::RE_EXPR)\[ \t\]*,\[ \t\]*(\[XY\])"                                        chk_nul  proc_idx }
    {"EXT" 3 "^%s\[ \t\]+($::RE_EXPR)"                                                                chk_nul  proc_ext }
    {"IMP" 1 "^%s\[ \t\]*$"                                                                                 chk_nul  proc_imp }
    {"XIM" 3 "^%s\[ \t\]+#\[ \t\]*($::RE_EXPR)\[ \t\]*,\[ \t\]*($::RE_EXPR)"                    chk_nul  proc_xim }
    {"XXM" 3 "^%s\[ \t\]+#\[ \t\]*($::RE_EXPR)\[ \t\]*,\[ \t\]*($::RE_EXPR)\[ \t\]*,\[ \t\]*X"  chk_nul  proc_xxm }
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
    {BMI  28   ____ ____ ____ ____ ____ ____ ____}
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
    {COM  ____ 00   00   63   73   ____ ____ ____}
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
    {INC  ____ 00   00   6C   7C   ____ ____ ____}
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
    {MUL  ____ 00   00   00   00   3D   ____ ____}
    {NEG  ____ 00   00   60   70   ____ ____ ____}
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
    {ROR  ____ 00   00   66   76   ____ ____ ____}
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

set ::FIXUP_TEXT ""

proc add_fixup {a} {
    if { $::PASS == 2 } {
	set d_a [evaluate_expression $a]
#	set d_a [value_to_dec $a]
	set f_a [format "%04X" $d_a]
	append ::FIXUP_TEXT "$f_a\n"    
    }
}

################################################################################
#
# List file collection
#

proc addlst {txt} {
    append ::LIST_TEXT "$txt\n"
}

proc addlstline {addr type object line} {
    set f_line [format "%-5s %-4s %-12s %-40s\n" $addr $type $object  $line]
    append ::LIST_TEXT $f_line
}
    
proc error {line msg} {
    puts "**ERROR***"
    puts $line
    puts $msg

    addlst "**ERROR***"
    addlst $line
    addlst $msg
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
# primarily for direct and extended modes. Direct has to have addres sless than 256

proc chk_nul {p1 p2} {
    return 1
}

proc chk_dir {p1 p2} {
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
    set p1 [evaluate_expression $p1]

    set r [expr $p1 - $::ADDR]

    # Convert to byte
    set r [expr $r & 0xff]
    
    emit $r
}

proc proc_imm {len p1 p2} {
    set p1 [evaluate_expression $p1]
    
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
    set p1 [evaluate_expression $p1]
    emit $p1
}

proc proc_idx {len p1 p2} {
    set p1 [evaluate_expression $p1]
    emit $p1
}

# Extended addressing needs fixup for relocatable code
proc proc_ext {len p1 p2} {
    set p1 [evaluate_expression $p1]
    emitword $p1

    # Fixup address is address of instruction to be fixed
    add_fixup $::ADDR
}

proc proc_imp {len p1 p2} {
}

proc proc_xim {len p1 p2} {
    set p1 [evaluate_expression $p1]
    set p2 [evaluate_expression $p2]
    emit $p1
    emit $p2
}

proc proc_xxm {len p1 p2} {
    set p1 [evaluate_expression $p1]
    set p2 [evaluate_expression $p2]
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

# Text variable
set ::EMITTED ""
set ::HEX_EMITTED ""

proc emit {b} {
    #    set fb [format "%02X" [value_to_dec $b]]
    set fb [format "%02X" [evaluate_expression $b]]

    set ::EMITTED_ADDR $::ADDR
    append ::EMITTED     " $fb"
    append ::HEX_EMITTED "$fb"
}

proc emitword {w} {
    if { $::PASS == 1 } {
	append ::EMITTED " 00 00"
	append ::HEX_EMITTED "0000"
	return
    }
    
    set fb [format "%02X" [value_to_dec [expr $w / 256]]]
    append ::EMITTED " $fb"
    set fb [format "%02X" [value_to_dec [expr $w % 256]]]
    append ::EMITTED " $fb"
}


################################################################################
#
# Creates a new label
proc create_label {name value} {
    if { [lsearch -exact $::LABELLIST $name] == -1 } {
	# Add a new label
	#puts "Label $name"
	lappend ::LABELLIST $name
    }

    set ::LABEL($name) $value
}

################################################################################
#
# Directives
#
# Directives can have expressions as arguments
#

proc evaluate_expression {exp} {
    # if this is pass 1 then just return zero
    if { $::PASS == 1 } {
	return 0
    }

    # If the expression is blank then just return blank
    if { [string length $exp] == 0 } {
	return ""
    }
    
    # Turn the expression into Tcl and evaluate it
    #puts "EVALEXP:'$exp'"
    
    # Turn label names into references to the label variables
    foreach label $::LABELLIST {
	set exp [string map "$label [set ::LABEL($label)]" $exp]
    }
    #puts "EVALEXP:'$exp'"
    
    # Force hex values to correct format
    set exp [string map "\$ 0x ^x 0x" $exp]

    #puts "EVALEXP:'$exp'"
    #puts "EVALEXP ='[expr $exp]'"
    # Evaluate, trap errors
    set result 0

    if { [catch {   set result [expr $exp] } ] } {
	error $::CURRENT_LINE "Bad expression '$exp'"
    }
    
    return $result
}

proc dir_org {line original_line} {
    # We set up ::ADDR as specified
    if { [regexp -- "(.ORG|org)\[ \t\]+(\[A-Za-z0-9$+*/<>\-]+)" $line all dir addr] } {
	set ::ADDR [evaluate_expression $addr]

	set f_addr    [format "%04X" $::ADDR]
	set f_emitted [format "%-12s" ""]
	set line [string trim $original_line]
	addlstline $f_addr "(O)" $f_emitted  $original_line

	return 1
    } else {
	error $line "Bad .ORG"
	return 0
    }
}

proc dir_byte {line original_line} {
    # We create a byte
    #puts "dir_byte:'$line'"
    
    if { [regexp -- ".BYTE\[ \t\]+(.+)" $line all byte] } {
	set byte [evaluate_expression $byte]

	# Emit it
	set ::EMITTED ""
	emit $byte
	
	set f_addr    [format "%04X" $::ADDR]
	set f_emitted [format "%-12s" $::EMITTED]
	set line [string trim $original_line]
	addlstline $f_addr "(B)" $f_emitted  $original_line
	
	incr ::ADDR 2
	return 1
    } else {
	error $line "Bad .BYTE"
	return 0
    }
    return 0
}

proc dir_word {line original_line} {
    # We create a word
    #puts "dir_word:'$line'"
    
    if { [regexp -- ".WORD\[ \t\]+(.+)" $line all word] } {
	set word [evaluate_expression $word]

	# Emit it
	set ::EMITTED ""
	emitword $word
	
	set f_addr    [format "%04X" $::ADDR]
	set f_emitted [format "%-12s" $::EMITTED]
	set line [string trim $original_line]
	addlstline $f_addr "(W)" $f_emitted  $original_line
	
	incr ::ADDR 2
	return 1
    } else {
	error $line "Bad .WORD"
	return 0
    }
    return 0
}

# Set label value
proc dir_equ {line original_line} {
    if { [regexp -- "(\[A-Za-z0-9_\]+)\[ \t\]+(.EQU|equ)\[ \t\]+(\[A-Za-z0-9$\(\)_<>*/+-\]+)" $line all name dir value] } {
	set value [evaluate_expression $value]
	create_label $name $value
	
	set f_value [format "%04X        " [evaluate_expression $value]]
	set line [string trim $original_line]
	addlstline "" "(E)" $f_value  $original_line

	return 1
    } else {
	error $line "Bad .EQU"
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
	puts $::DBF "NL(M):'$result'"
	return $result
    }

    # The get lines from included files
    if { [llength $::INCLUDELINES] != 0 } {
	set result [lindex $::INCLUDELINES 0]
	set ::INCLUDELINES [lrange $::INCLUDELINES 1 end]
	puts $::DBF "NL(I):'$result'"
	return $result
    }

    # Get the next line from the file being assembled
    if { [llength $::FILETEXT] != 0 } {
	set result [lindex $::FILETEXT 0]
	set ::FILETEXT [lrange $::FILETEXT 1 end]
	puts $::DBF "NL(F):'$result'"
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

    puts ""
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

	dbg "line=$line"

	# Remove comments
	if { [regexp -- "(\[^;\]*);.*" $line all strippedline] } {
	    set line $strippedline
	}

	# Handle creating labels
	if { [regexp -- "(\[A-Za-z0-9_\]+):(.*)" $line all label line] } {
	    # We have a label
	    create_label $label $::ADDR

	    if { [string length [string trim $line]] == 0 } {
		addlstline $::ADDR "(L)" "" "$label:"
	    }
	}

	# Handle included files
	if { [string first .INCLUDE $line] != -1 } {
	    puts $::DBF "Include in '$line'"
	    
	    # Get the file name
	    if { [regexp -- ".INCLUDE\[ \t\]+(.+)" $line all filename] } {
		puts $::DBF "Include $filename"

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
		puts $::DBF "Found macro $macro"
		puts $::DBF "RE=$macro\[ \t\]+($::MACROPAREXP($macro))"
		
		# This could be a macro expansion
		if { [regexp -- "$macro\[ \t\]+($::MACROPAREXP($macro))" $line all parvals] } {
		    puts $::DBF "Match regexp"
		    
		    # We need to expand parameters in the macro bidy
		    set macrotext $::MACRO($macro)

		    puts $::DBF "Macro text='$macrotext'"
		    
		    # Replace every parameter with a value
		    foreach parname [split $::MACROPARS($macro) ","] parval [split $parvals " ,"] {
			puts $::DBF "Replace '$parname' with '$parval'"
			regsub -all $parname $macrotext $parval macrotext
		    }

		    puts $::DBF "Macro text after replace='$macrotext'"
		    
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
	if { [string first .MACRO $line] != -1 } {
	    puts $::DBF "Macro def started in '$line'"
	    
	    # Get the macro name and parameters
	    if { [regexp -- "(\[A-Za-z0-9_\]+)\[ \t\]+.MACRO\[ \t\]+(.+)" $line all macname macpars] } {
		puts $::DBF "Macro $macname"
		
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
	    if { [string first .ENDM $line] != -1 } {
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
	foreach dirname $::DIRNAMES dirproc $::DIRPROCS {
	    if { [string first $dirname $line] != -1 } {
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

	    # If the line doesn't have the mnemonic in it then we don't bother
	    # processing further for this instruction
	    if { [string first $mne $line] == -1 } {
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
		set def_regexp [format $addrmode_regexp $mne]
		puts $::DBF "DEF REGEXP:'$def_regexp'"
		
		# See if we have a match
		set p1 0
		set p2 0
		
		if { [regexp -- $def_regexp $line all p1 p2] } {
		    # No need to convert parameters to instruction as that is done by the
		    # addressing mode handlers
#		    set p1 [value_to_dec $p1]
#		    set p2 [value_to_dec $p2]
		    
		    # The regexp has matched, but does the addressing mode
		    # check procedure say this is valid?
		    if { [$addrmode_chk_proc $p1 $p2] } {
		    } else {
			# The check procedure doesn't like this, keep checking
			incr addrmode_index 1
			continue
		    }

		    # If opcode is invalid, keep looking
		    if { $opcode == "____" } {
			puts $::DBF "OPCODE=$opcode"
			puts $::DBF "addrmode_spec=$addrmode_spec"
			puts $::DBF "def_regexp=$def_regexp"
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
			
			emit "\$$f_opcode"
			
			if { $::PASS == 2 } {
			    # Convert parameters to values
			    $addrmode_proc_proc $inst_length $p1 $p2
			} else {
			    $addrmode_proc_proc $inst_length 0 0
			}
			
			set f_emitted [format "%-12s" $::EMITTED]
			
			addlstline $f_addr "($addrmode_i)" $f_emitted   $original_line
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
	if { $::PASS == 2 } {
	    if { !$found } {
		error $line "Instruction not found"
	    }
	}
    }
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

    puts $f $::HEX_EMITTED
    
    close $f
}

################################################################################

proc write_lst_file {filename} {

    set f [open $filename w]

    puts $f $::LIST_TEXT
    
    foreach label $::LABELLIST {
	set label_value [format "$%04X" $::LABEL($label)]
	set f_name [format "%20s" $label]
	puts $f "$f_name: $label_value"
    }

    # Fixup information
    puts $f "\nFixup Information\n"
    puts $f "$::FIXUP_TEXT\n"
    close $f
}


set asm_filename [lindex $argv 0]
set lst_filename [string map {.asm .lst} $asm_filename]
set hex_filename [string map {.asm .hex} $asm_filename]
set mac_filename [string map {.asm .mac} $asm_filename]

set ::DBG_FILENAME [string map {.asm .dbg} $asm_filename]

set ::DBF [open $::DBG_FILENAME w]

################################################################################
#
# two passes

set ::PASS 1

clear_macros
assemble_file $asm_filename

set ::PASS 2
set ::HEX_EMITTED ""

clear_macros
assemble_file $asm_filename

write_lst_file $lst_filename

write_hex_file $hex_filename

write_macro_file $mac_filename

close $::DBF
