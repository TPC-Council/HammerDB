# json.tcl --
#
#	JSON parser for Tcl. Management code, Tcl/C detection and selection.
#
# Copyright (c) 2013 by Andreas Kupries

# @mdgen EXCLUDE: jsonc.tcl

package require Tcl 8.4
namespace eval ::json {}

# ### ### ### ######### ######### #########
## Management of json implementations.

# ::json::LoadAccelerator --
#
#	Loads a named implementation, if possible.
#
# Arguments:
#	key	Name of the implementation to load.
#
# Results:
#	A boolean flag. True if the implementation
#	was successfully loaded; and False otherwise.

proc ::json::LoadAccelerator {key} {
    variable accel
    set r 0
    switch -exact -- $key {
	critcl {
	    # Critcl implementation of json requires Tcl 8.4.
	    if {![package vsatisfies [package provide Tcl] 8.4]} {return 0}
	    if {[catch {package require tcllibc}]} {return 0}
	    # Check for the jsonc 1.1.1 API we are fixing later.
	    set r [llength [info commands ::json::many_json2dict_critcl]]
	}
	tcl {
	    variable selfdir
#
#   JSON parser for Tcl.
#
#   See http://www.json.org/ && http://www.ietf.org/rfc/rfc4627.txt
#
#   Total rework of the code published with version number 1.0 by
#   Thomas Maeder, Glue Software Engineering AG
#
#   $Id: json.tcl,v 1.7 2011/11/10 21:05:58 andreas_kupries Exp $
#

if {![package vsatisfies [package provide Tcl] 8.5]} {
    package require dict
}

# Parse JSON text into a dict
# @param jsonText JSON text
# @return dict (or list) containing the object represented by $jsonText
proc ::json::json2dict_tcl {jsonText} {
    variable tokenRE

    set tokens [regexp -all -inline -- $tokenRE $jsonText]
    set nrTokens [llength $tokens]
    set tokenCursor 0

    #puts I:($jsonText)
    #puts T:\t[join $tokens \nT:\t]
    return [parseValue $tokens $nrTokens tokenCursor]
}

# Parse multiple JSON entities in a string into a list of dictionaries
# @param jsonText JSON text to parse
# @param max      Max number of entities to extract.
# @return list of (dict (or list) containing the objects) represented by $jsonText
proc ::json::many-json2dict_tcl {jsonText {max -1}} {
    variable tokenRE

    if {$max == 0} {
	return -code error -errorCode {JSON BAD-LIMIT ZERO} \
	    "Bad limit 0 of json entities to extract."
    }

    set tokens [regexp -all -inline -- $tokenRE $jsonText]
    set nrTokens [llength $tokens]
    set tokenCursor 0

    set result {}
    set found 0
    set n $max
    while {$n != 0} {
	if {$tokenCursor >= $nrTokens} break
	lappend result [parseValue $tokens $nrTokens tokenCursor]
	incr found
	if {$n > 0} {incr n -1}
    }

    if {$n > 0} {
	return -code error -errorCode {JSON BAD-LIMIT TOO LARGE} \
	    "Bad limit $max of json entities to extract, found only $found."
    }

    return $result
}

# Throw an exception signaling an unexpected token
proc ::json::unexpected {tokenCursor token expected} {
    return -code error -errorcode [list JSON UNEXPECTED $tokenCursor $expected] \
	"unexpected token \"$token\" at position $tokenCursor; expecting $expected"
}

# Get rid of the quotes surrounding a string token and substitute the
# real characters for escape sequences within it
# @param token
# @return unquoted unescaped value of the string contained in $token
proc ::json::unquoteUnescapeString {tokenCursor token} {
    variable stringREv
    set unquoted [string range $token 1 end-1]

    if {![regexp $stringREv $token]} {
	unexpected $tokenCursor $token STRING
    }

    set res [subst -nocommands -novariables $unquoted]
    return $res
}

# Parse an object member
# @param tokens list of tokens
# @param nrTokens length of $tokens
# @param tokenCursorName name (in caller's context) of variable
#                        holding current position in $tokens
# @param objectDictName name (in caller's context) of dict
#                       representing the JSON object of which to
#                       parse the next member
proc ::json::parseObjectMember {tokens nrTokens tokenCursorName objectDictName} {
    upvar $tokenCursorName tokenCursor
    upvar $objectDictName objectDict

    set token [lindex $tokens $tokenCursor]
    set tc $tokenCursor
    incr tokenCursor

    set leadingChar [string index $token 0]
    if {$leadingChar eq "\""} {
        set memberName [unquoteUnescapeString $tc $token]

        if {$tokenCursor == $nrTokens} {
            unexpected $tokenCursor "END" "\":\""
        } else {
            set token [lindex $tokens $tokenCursor]
            incr tokenCursor

            if {$token eq ":"} {
                set memberValue [parseValue $tokens $nrTokens tokenCursor]
                dict set objectDict $memberName $memberValue
            } else {
                unexpected $tokenCursor $token "\":\""
            }
        }
    } else {
        unexpected $tokenCursor $token "STRING"
    }
}

# Parse the members of an object
# @param tokens list of tokens
# @param nrTokens length of $tokens
# @param tokenCursorName name (in caller's context) of variable
#                        holding current position in $tokens
# @param objectDictName name (in caller's context) of dict
#                       representing the JSON object of which to
#                       parse the next member
proc ::json::parseObjectMembers {tokens nrTokens tokenCursorName objectDictName} {
    upvar $tokenCursorName tokenCursor
    upvar $objectDictName objectDict

    while true {
        parseObjectMember $tokens $nrTokens tokenCursor objectDict

        set token [lindex $tokens $tokenCursor]
        incr tokenCursor

        switch -exact $token {
            "," {
                # continue
            }
            "\}" {
                break
            }
            default {
                unexpected $tokenCursor $token "\",\"|\"\}\""
            }
        }
    }
}

# Parse an object
# @param tokens list of tokens
# @param nrTokens length of $tokens
# @param tokenCursorName name (in caller's context) of variable
#                        holding current position in $tokens
# @return parsed object (Tcl dict)
proc ::json::parseObject {tokens nrTokens tokenCursorName} {
    upvar $tokenCursorName tokenCursor

    if {$tokenCursor == $nrTokens} {
        unexpected $tokenCursor "END" "OBJECT"
    } else {
        set result [dict create]

        set token [lindex $tokens $tokenCursor]

        if {$token eq "\}"} {
            # empty object
            incr tokenCursor
        } else {
            parseObjectMembers $tokens $nrTokens tokenCursor result
        }

        return $result
    }
}

# Parse the elements of an array
# @param tokens list of tokens
# @param nrTokens length of $tokens
# @param tokenCursorName name (in caller's context) of variable
#                        holding current position in $tokens
# @param resultName name (in caller's context) of the list
#                   representing the JSON array
proc ::json::parseArrayElements {tokens nrTokens tokenCursorName resultName} {
    upvar $tokenCursorName tokenCursor
    upvar $resultName result

    while true {
        lappend result [parseValue $tokens $nrTokens tokenCursor]

        if {$tokenCursor == $nrTokens} {
            unexpected $tokenCursor "END" "\",\"|\"\]\""
        } else {
            set token [lindex $tokens $tokenCursor]
            incr tokenCursor

            switch -exact $token {
                "," {
                    # continue
                }
                "\]" {
                    break
                }
                default {
                    unexpected $tokenCursor $token "\",\"|\"\]\""
                }
            }
        }
    }
}

# Parse an array
# @param tokens list of tokens
# @param nrTokens length of $tokens
# @param tokenCursorName name (in caller's context) of variable
#                        holding current position in $tokens
# @return parsed array (Tcl list)
proc ::json::parseArray {tokens nrTokens tokenCursorName} {
    upvar $tokenCursorName tokenCursor

    if {$tokenCursor == $nrTokens} {
        unexpected $tokenCursor "END" "ARRAY"
    } else {
        set result {}

        set token [lindex $tokens $tokenCursor]

        set leadingChar [string index $token 0]
        if {$leadingChar eq "\]"} {
            # empty array
            incr tokenCursor
        } else {
            parseArrayElements $tokens $nrTokens tokenCursor result
        }

        return $result
    }
}

# Parse a value
# @param tokens list of tokens
# @param nrTokens length of $tokens
# @param tokenCursorName name (in caller's context) of variable
#                        holding current position in $tokens
# @return parsed value (dict, list, string, number)
proc ::json::parseValue {tokens nrTokens tokenCursorName} {
    upvar $tokenCursorName tokenCursor

    if {$tokenCursor == $nrTokens} {
        unexpected $tokenCursor "END" "VALUE"
    } else {
        set token [lindex $tokens $tokenCursor]
	set tc $tokenCursor
        incr tokenCursor

        set leadingChar [string index $token 0]
        switch -exact -- $leadingChar {
            "\{" {
                return [parseObject $tokens $nrTokens tokenCursor]
            }
            "\[" {
                return [parseArray $tokens $nrTokens tokenCursor]
            }
            "\"" {
                # quoted string
                return [unquoteUnescapeString $tc $token]
            }
            "t" -
            "f" -
            "n" {
                # bare word: true, false, null (return as is)
                return $token
            }
            default {
                # number?
                if {[string is double -strict $token]} {
                    return $token
                } else {
                    unexpected $tokenCursor $token "VALUE"
                }
            }
        }
    }
}
	    set r 1
	}
        default {
            return -code error "invalid accelerator/impl. package $key:\
                must be one of [join [KnownImplementations] {, }]"
        }
    }
    set accel($key) $r
    return $r
}

# ::json::SwitchTo --
#
#	Activates a loaded named implementation.
#
# Arguments:
#	key	Name of the implementation to activate.
#
# Results:
#	None.

proc ::json::SwitchTo {key} {
    variable accel
    variable loaded
    variable apicmds

    if {[string equal $key $loaded]} {
	# No change, nothing to do.
	return
    } elseif {![string equal $key ""]} {
	# Validate the target implementation of the switch.

	if {![info exists accel($key)]} {
	    return -code error "Unable to activate unknown implementation \"$key\""
	} elseif {![info exists accel($key)] || !$accel($key)} {
	    return -code error "Unable to activate missing implementation \"$key\""
	}
    }

    # Deactivate the previous implementation, if there was any.

    if {![string equal $loaded ""]} {
	foreach c $apicmds {
	    rename ::json::${c} ::json::${c}_$loaded
	}
    }

    # Activate the new implementation, if there is any.

    if {![string equal $key ""]} {
	foreach c $apicmds {
	    rename ::json::${c}_$key ::json::${c}
	}
    }

    # Remember the active implementation, for deactivation by future
    # switches.

    set loaded $key
    return
}

# ::json::Implementations --
#
#	Determines which implementations are
#	present, i.e. loaded.
#
# Arguments:
#	None.
#
# Results:
#	A list of implementation keys.

proc ::json::Implementations {} {
    variable accel
    set res {}
    foreach n [array names accel] {
	if {!$accel($n)} continue
	lappend res $n
    }
    return $res
}

# ::json::KnownImplementations --
#
#	Determines which implementations are known
#	as possible implementations.
#
# Arguments:
#	None.
#
# Results:
#	A list of implementation keys. In the order
#	of preference, most prefered first.

proc ::json::KnownImplementations {} {
    return {critcl tcl}
}

proc ::json::Names {} {
    return {
	critcl {tcllibc based}
	tcl    {pure Tcl}
    }
}

# ### ### ### ######### ######### #########
## Initialization: Data structures.

namespace eval ::json {
    variable  selfdir [file dirname [info script]]
    variable  accel
    array set accel   {tcl 0 critcl 0}
    variable  loaded  {}

    variable apicmds {
	json2dict
	many-json2dict
    }
}

# ### ### ### ######### ######### #########
## Wrapper fix for the jsonc package to match APIs.

proc ::json::many-json2dict_critcl {args} {
    eval [linsert $args 0 ::json::many_json2dict_critcl]
}

# ### ### ### ######### ######### #########
## Initialization: Choose an implementation,
## most prefered first. Loads only one of the
## possible implementations. And activates it.

namespace eval ::json {
    variable e
    foreach e [KnownImplementations] {
	if {[LoadAccelerator $e]} {
	    SwitchTo $e
	    break
	}
    }
    unset e
}

# ### ### ### ######### ######### #########
## Tcl implementation of validation, shared for Tcl and C implementation.
##
## The regexp based validation is consistently faster than json-c.
## Suspected reasons: Tcl REs are mainly in C as well, and json-c has
## overhead in constructing its own data structures. While irrelevant
## to validation json-c still builds them, it has no mode doing pure
## syntax checking.

namespace eval ::json {
    # Regular expression for tokenizing a JSON text (cf. http://json.org/)

    # tokens consisting of a single character
    variable singleCharTokens { "{" "}" ":" "\\[" "\\]" "," }
    variable singleCharTokenRE "\[[join $singleCharTokens {}]\]"

    # quoted string tokens
    variable escapableREs { "[\\\"\\\\/bfnrt]" "u[[:xdigit:]]{4}" "." }
    variable escapedCharRE "\\\\(?:[join $escapableREs |])"
    variable unescapedCharRE {[^\\\"]}
    variable stringRE "\"(?:$escapedCharRE|$unescapedCharRE)*\""

    # as above, for validation
    variable escapableREsv { "[\\\"\\\\/bfnrt]" "u[[:xdigit:]]{4}" }
    variable escapedCharREv "\\\\(?:[join $escapableREsv |])"
    variable stringREv "\"(?:$escapedCharREv|$unescapedCharRE)*\""

    # (unquoted) words
    variable wordTokens { "true" "false" "null" }
    variable wordTokenRE [join $wordTokens "|"]

    # number tokens
    # negative lookahead (?!0)[[:digit:]]+ might be more elegant, but
    # would slow down tokenizing by a factor of up to 3!
    variable positiveRE {[1-9][[:digit:]]*}
    variable cardinalRE "-?(?:$positiveRE|0)"
    variable fractionRE {[.][[:digit:]]+}
    variable exponentialRE {[eE][+-]?[[:digit:]]+}
    variable numberREa "${cardinalRE}(?:$fractionRE)?(?:$exponentialRE)?"
    variable numberREb "${fractionRE}(?:$exponentialRE)?"
    variable numberREc "${cardinalRE}\[.\](?:$exponentialRE)?"
    variable numberRE  "$numberREa|$numberREb|$numberREc"
    variable numberRE  "$numberREa|$numberREb|$numberREc"

    # JSON token, and validation
    variable tokenRE "$singleCharTokenRE|$stringRE|$wordTokenRE|$numberRE"
    variable tokenREv "$singleCharTokenRE|$stringREv|$wordTokenRE|$numberRE"

    # 0..n white space characters
    set whiteSpaceRE {[[:space:]]*}

    # Regular expression for validating a JSON text
    variable validJsonRE "^(?:${whiteSpaceRE}(?:$tokenREv))*${whiteSpaceRE}$"
}


# Validate JSON text
# @param jsonText JSON text
# @return 1 iff $jsonText conforms to the JSON grammar
#           (@see http://json.org/)
proc ::json::validate {jsonText} {
    variable validJsonRE

    return [regexp -- $validJsonRE $jsonText]
}

# ### ### ### ######### ######### #########
## These three procedures shared between Tcl and Critcl implementations.
## See also package "json::write".

proc ::json::dict2json {dictVal} {
    # XXX: Currently this API isn't symmetrical, as to create proper
    # XXX: JSON text requires type knowledge of the input data
    set json ""
    set prefix ""

    foreach {key val} $dictVal {
	# key must always be a string, val may be a number, string or
	# bare word (true|false|null)
	if {0 && ![string is double -strict $val]
	    && ![regexp {^(?:true|false|null)$} $val]} {
	    set val "\"$val\""
	}
    	append json "$prefix\"$key\": $val" \n
	set prefix ,
    }

    return "\{${json}\}"
}

proc ::json::list2json {listVal} {
    return "\[[join $listVal ,]\]"
}

proc ::json::string2json {str} {
    return "\"$str\""
}

# ### ### ### ######### ######### #########
## Ready

package provide json 1.3.4
