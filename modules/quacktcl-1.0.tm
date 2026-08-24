#########################################################################
# HammerDB
# Copyright (C) HammerDB Ltd
# Hosted by the TPC-Council
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#########################################################################
#
# quacktcl - a dependency-light, pure-Tcl client for the sqlxtc "Quack"
# wire protocol (see libxtc examples/06_sqlxtc/PROTOCOL.md).
#
# Quack is newline-delimited JSON over a plain TCP socket:
#   server, on connect, sends {"hello":"sqlxtc",...}\n
#   client sends one JSON object per line:
#       {"q":"SQL"}                    simple statement
#       {"q":"SQL","params":[...]}     parameterised statement (?1..?N)
#       {"q":"SQL","limit":N}          row cap
#       {"ping":1}                     heartbeat
#       {"quit":1}                     graceful close
#   server replies with JSON lines:
#       {"cols":[...]}   {"row":[...]}  {"done":N}   {"err":"..."}   {"pong":1}
#
# This package deliberately implements only a tiny flat-JSON encoder and
# a streaming decoder sufficient for the Quack framing; it pulls in no
# external Tcl package so it runs under a bare tclsh as well as the
# bundled HammerDB runtime.  The command surface mirrors the small set
# of verbs the HammerDB driver files need (connect / exec / sel /
# commit / rollback / close), styled after the other DB access packages.
#
package provide quacktcl 1.0

namespace eval ::quack {
    variable handles
    array set handles {}
    variable seq 0
    namespace export quackconnect quackexec quacksel quackcommit \
        quackrollback quackclose quackping quackescape
}

# ----------------------------------------------------------------------
# Minimal JSON encoding of a single scalar value.
# Integers and reals are emitted bare; everything else is a quoted
# string with the JSON escapes the protocol needs.
# ----------------------------------------------------------------------
proc ::quack::json_escape_string { s } {
    set out ""
    foreach ch [split $s ""] {
        scan $ch %c code
        switch -- $ch {
            "\"" { append out "\\\"" }
            "\\" { append out "\\\\" }
            "\n" { append out "\\n" }
            "\r" { append out "\\r" }
            "\t" { append out "\\t" }
            default {
                if { $code < 0x20 } {
                    append out [format "\\u%04x" $code]
                } else {
                    append out $ch
                }
            }
        }
    }
    return "\"$out\""
}

# ----------------------------------------------------------------------
# Streaming JSON decoder for one line (a single flat object).  Returns a
# Tcl dict mapping the recognised top-level keys (cols, row, done, err,
# pong, hello) to their decoded Tcl values.  Arrays decode to Tcl lists,
# scalars to their Tcl representation, null to the empty string.
#
# The decoder is intentionally small: the Quack wire format is flat
# (objects contain scalars or one-level arrays of scalars), so a full
# recursive JSON parser is unnecessary.
# ----------------------------------------------------------------------
proc ::quack::json_decode { text } {
    upvar 0 ::quack::_p p
    set ::quack::_s $text
    set ::quack::_i 0
    set ::quack::_n [string length $text]
    return [::quack::_parse_value]
}

proc ::quack::_skip_ws {} {
    while { $::quack::_i < $::quack::_n } {
        set c [string index $::quack::_s $::quack::_i]
        if { $c eq " " || $c eq "\t" || $c eq "\n" || $c eq "\r" } {
            incr ::quack::_i
        } else { break }
    }
}

proc ::quack::_parse_value {} {
    ::quack::_skip_ws
    set c [string index $::quack::_s $::quack::_i]
    switch -- $c {
        "\{"    { return [::quack::_parse_object] }
        "\["    { return [::quack::_parse_array] }
        "\""    { return [::quack::_parse_string] }
        default { return [::quack::_parse_literal] }
    }
}

proc ::quack::_parse_object {} {
    incr ::quack::_i
    set d [dict create]
    ::quack::_skip_ws
    if { [string index $::quack::_s $::quack::_i] eq "\}" } {
        incr ::quack::_i
        return $d
    }
    while { $::quack::_i < $::quack::_n } {
        ::quack::_skip_ws
        set key [::quack::_parse_string]
        ::quack::_skip_ws
        incr ::quack::_i
        set val [::quack::_parse_value]
        dict set d $key $val
        ::quack::_skip_ws
        set c [string index $::quack::_s $::quack::_i]
        incr ::quack::_i
        if { $c eq "\}" } { break }
    }
    return $d
}

proc ::quack::_parse_array {} {
    incr ::quack::_i
    set l [list]
    ::quack::_skip_ws
    if { [string index $::quack::_s $::quack::_i] eq "\]" } {
        incr ::quack::_i
        return $l
    }
    while { $::quack::_i < $::quack::_n } {
        lappend l [::quack::_parse_value]
        ::quack::_skip_ws
        set c [string index $::quack::_s $::quack::_i]
        incr ::quack::_i
        if { $c eq "\]" } { break }
    }
    return $l
}

proc ::quack::_parse_string {} {
    incr ::quack::_i
    set out ""
    while { $::quack::_i < $::quack::_n } {
        set c [string index $::quack::_s $::quack::_i]
        incr ::quack::_i
        if { $c eq "\"" } { break }
        if { $c eq "\\" } {
            set e [string index $::quack::_s $::quack::_i]
            incr ::quack::_i
            switch -- $e {
                "n" { append out "\n" }
                "r" { append out "\r" }
                "t" { append out "\t" }
                "b" { append out "\b" }
                "f" { append out "\f" }
                "/" { append out "/" }
                "\"" { append out "\"" }
                "\\" { append out "\\" }
                "u" {
                    set hex [string range $::quack::_s $::quack::_i [expr {$::quack::_i + 3}]]
                    incr ::quack::_i 4
                    append out [format %c [scan $hex %x]]
                }
                default { append out $e }
            }
        } else {
            append out $c
        }
    }
    return $out
}

proc ::quack::_parse_literal {} {
    set start $::quack::_i
    while { $::quack::_i < $::quack::_n } {
        set c [string index $::quack::_s $::quack::_i]
        if { $c eq "," || $c eq "\}" || $c eq "\]" || $c eq " " || \
             $c eq "\t" || $c eq "\n" || $c eq "\r" } { break }
        incr ::quack::_i
    }
    set tok [string range $::quack::_s $start [expr {$::quack::_i - 1}]]
    if { $tok eq "null" } { return "" }
    if { $tok eq "true" } { return 1 }
    if { $tok eq "false" } { return 0 }
    return $tok
}

# ----------------------------------------------------------------------
# quackconnect host port  ->  handle
#
# Opens a TCP socket, consumes the server hello banner, and returns an
# opaque handle string used by the other commands.  Errors out (like the
# other DB packages) if the connection or banner fails.
# ----------------------------------------------------------------------
proc ::quack::quackconnect { host port } {
    variable handles
    variable seq
    if { [catch {set sock [socket $host $port]} msg] } {
        error "quack: connection to $host:$port failed: $msg"
    }
    fconfigure $sock -translation {lf lf} -buffering line -encoding utf-8 \
        -blocking 1
    # Read the hello banner.
    if { [catch {set banner [gets $sock]} msg] } {
        catch {close $sock}
        error "quack: reading hello banner failed: $msg"
    }
    set hd [::quack::json_decode $banner]
    if { ![dict exists $hd hello] } {
        catch {close $sock}
        error "quack: unexpected banner: $banner"
    }
    set h "quack[incr seq]"
    set handles($h) $sock
    return $h
}

proc ::quack::_sock { h } {
    variable handles
    if { ![info exists handles($h)] } { error "quack: invalid handle $h" }
    return $handles($h)
}

# ----------------------------------------------------------------------
# Send one query line and read the streamed reply.  Returns a dict:
#   status  ->  ok | error
#   error   ->  error text when status == error
#   cols    ->  list of column names (may be empty)
#   rows    ->  list of rows, each row a list of values
#   count   ->  the done N (rows returned, or affected rows for DML/DDL)
# ----------------------------------------------------------------------
proc ::quack::_send_query { h sql args } {
    set sock [::quack::_sock $h]
    set limit ""
    set params ""
    foreach {k v} $args {
        switch -- $k {
            -limit  { set limit $v }
            -params { set params $v }
        }
    }
    set line "\{\"q\":[::quack::json_escape_string $sql]"
    if { $limit ne "" } { append line ",\"limit\":$limit" }
    if { $params ne "" } {
        append line ",\"params\":\["
        set first 1
        foreach p $params {
            if { !$first } { append line "," }
            set first 0
            if { [string is entier -strict $p] } {
                append line $p
            } elseif { [string is double -strict $p] } {
                append line $p
            } else {
                append line [::quack::json_escape_string $p]
            }
        }
        append line "\]"
    }
    append line "\}"
    if { [catch {puts $sock $line} msg] } {
        error "quack: write failed: $msg"
    }
    set res [dict create status ok error {} cols {} rows {} count 0]
    while { 1 } {
        if { [catch {set replyln [gets $sock]} msg] } {
            dict set res status error
            dict set res error "read failed: $msg"
            return $res
        }
        if { $replyln eq "" && [eof $sock] } {
            dict set res status error
            dict set res error "connection closed by server"
            return $res
        }
        if { $replyln eq "" } { continue }
        set d [::quack::json_decode $replyln]
        if { [dict exists $d err] } {
            dict set res status error
            dict set res error [dict get $d err]
            return $res
        }
        if { [dict exists $d cols] } {
            dict set res cols [dict get $d cols]
            continue
        }
        if { [dict exists $d row] } {
            dict lappend res rows [dict get $d row]
            continue
        }
        if { [dict exists $d done] } {
            dict set res count [dict get $d done]
            return $res
        }
        if { [dict exists $d pong] } {
            dict set res count 1
            return $res
        }
    }
}

# ----------------------------------------------------------------------
# quackexec handle sql ?-params list?
#   Run a statement for its side effects (DDL/DML/txn control).  Returns
#   the affected-row count reported by the server.  Raises a Tcl error
#   on a server error so the caller's [catch] behaves like the other
#   drivers.
# ----------------------------------------------------------------------
proc ::quack::quackexec { h sql args } {
    set res [::quack::_send_query $h $sql {*}$args]
    if { [dict get $res status] eq "error" } {
        error [dict get $res error]
    }
    return [dict get $res count]
}

# ----------------------------------------------------------------------
# quacksel handle sql ?-flatlist|-list? ?-params list?
#   Run a query and return its rows.
#     -flatlist : one flat list of all values (row order) - the default,
#                 matching the mysqltcl "-flatlist" convention the driver
#                 code relies on.
#     -list     : a list of rows, each row a list of column values.
# ----------------------------------------------------------------------
proc ::quack::quacksel { h sql args } {
    set mode -flatlist
    set passthru [list]
    foreach a $args {
        switch -- $a {
            -flatlist { set mode -flatlist }
            -list     { set mode -list }
            default   { lappend passthru $a }
        }
    }
    set res [::quack::_send_query $h $sql {*}$passthru]
    if { [dict get $res status] eq "error" } {
        error [dict get $res error]
    }
    set rows [dict get $res rows]
    if { $mode eq "-list" } {
        return $rows
    }
    set flat [list]
    foreach r $rows { foreach v $r { lappend flat $v } }
    return $flat
}

proc ::quack::quackcommit { h }   { return [::quack::quackexec $h "COMMIT"] }
proc ::quack::quackrollback { h } { return [::quack::quackexec $h "ROLLBACK"] }

proc ::quack::quackping { h } {
    set sock [::quack::_sock $h]
    puts $sock "\{\"ping\":1\}"
    set reply [gets $sock]
    set d [::quack::json_decode $reply]
    return [dict exists $d pong]
}

proc ::quack::quackclose { h } {
    variable handles
    if { ![info exists handles($h)] } { return }
    set sock $handles($h)
    catch { puts $sock "\{\"quit\":1\}" }
    catch { close $sock }
    unset handles($h)
    return
}

# SQL string-literal escaping (double single quotes) for values the
# driver interpolates directly into statement text.
proc ::quack::quackescape { s } {
    return [string map {' ''} $s]
}

namespace eval :: {
    namespace import ::quack::quackconnect ::quack::quackexec \
        ::quack::quacksel ::quack::quackcommit ::quack::quackrollback \
        ::quack::quackclose ::quack::quackping ::quack::quackescape
}
