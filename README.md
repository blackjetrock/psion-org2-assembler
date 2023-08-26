Assembler for the 6303 in a Psion organiser
===========================================

This is an assembler that was primarily designed for the Psion Organiser II platform. I wanted an assembler that I could run natively on Linux instead of having to fire up DOSBox and run the original psion macro assembler.

Features:

* Runs on Linux
* Can output the Psion relocatable format needed when creating code designed to be loaded as a driver.
* Assembles 6303 code for other platforms
* Uses Tcl so source code is always available (and changeable or fixable)
* Uses Tcl expressions so you can use sin(), log() etc in the assembler.
* Expressions can be used anywhere.
* Macros are supported.


Assembling a file
=================

Run with:

org2asm.tcl -f xxx.asm

for example.

Assembler Syntax
================

It uses the 6303 datasheet syntax, so for example:

ADDA  #$74

not 

ADD A #$74

Hexadecimal numbers are $XX, 0xXX, or ^xXX

Expressions can be used anywhere.
Macros are supported.

Output Files
============

xxxxx.lst 

    Has object code, label information, overlay information  and fixup data.

xxxxx.lst.short

    The same output as the .lst file but without the overlay information and label definitions.

xxxxx.opl_n
    OPL files that have the object code embedded in them in various ways.
    
Embedding Object Code
=====================

The object code can be embedded in a C file as array data using comments to place the data.

Examples
========

syntax_test.asm
Examples of the syntax of the assembler.

topslot/break3.asm
This is the code that I used to drive the top slot adapter PCB I made. Being able to assemble this code is the reason I wrote this assembler. This file uses the overlay mechanism that the organiser uses to effectively have position independent code. There's not a lot of information about the overly format so I had to reverse engineer some of it. The .lst file has a lot of information about overlays and the fixup records.

Test Code
=========

This version can assemble the XDICT example code in the Psion files. That was my test file and I haven't assembled much else with it. This assembler generated slightly smaller object code than the Psion assembler as the Psion assembler used a 3 byte extended addressing mode for one instruction where it could have used the 2 byte zero page form.


