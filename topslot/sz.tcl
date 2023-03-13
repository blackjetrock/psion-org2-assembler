#!/usr/bin/tclsh

lappend a char
lappend a xxx
lappend a xxxxxxxxx
lappend a vchar


proc sz {a b} {
    return [expr [string length $a] > [string length $b]]
}

puts [lsort -command sz $a]



