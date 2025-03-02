# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

oo::class create ticklecharts::jsfunc {
    variable _jsfunc
    variable _position

    constructor {args} {
        # Initializes a new jsfunc Class.
        #
        # args - Options described below.
        #
        # function - pure javascript function, variable...
        # -start   - To place your script at the beginning of the file. 
        # -end     - To place your script at the end of the file. 
        # -header  - To place your script in the file header.

        set _position "null" ;  # default value

        if {[llength $args] == 1} {
            set jsf [string trim [join $args]]

        } elseif {[llength $args] == 2} {

            set jsf [string trim [lindex $args 0]]

            switch -exact -- [lindex $args 1] {
                -start  {set _position "start"}
                -end    {set _position "end"}
                -header {set _position "header"}
                default {error "flag should be '-start', '-end' or '-header'..."}
            }            
        } else {
            error "jsfunc args not supported..."
        }

        # delete comma at the end if exists...
        # since I added jsfunc as huddle type 
        if {[string range $jsf end end] eq ","} {
            set jsf [string range $jsf 0 end-1]
        }

        set _jsfunc [list $jsf]
    }
}

oo::define ticklecharts::jsfunc {
    method get {} {
        # Returns js list
        return $_jsfunc
    }
    
    method getType {} {
        # Returns type
        return "jsfunc"
    }

    method position {} {
        # Returns position where the function or script should be 
        # write in html template file.
        return $_position
    }

}