# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {
    namespace ensemble create -command ::new
    namespace export elist edict
}

oo::class create ticklecharts::eList {
    variable _elist

    constructor {args} {
        # Initializes a new eList Class.
        #
        set _elist $args
    }
}

oo::define ticklecharts::eList {
    method get {} {
        # Returns list
        return $_elist
    }
    
    method getType {} {
        # Returns type
        return "eList"
    }
}

proc ticklecharts::elist {args} {
    # This procedure substitutes a pure Tcl list...
    # It can replace list types : 
    #   - list.s (list string)
    #   - list.n (list integer)
    #   - list.d (list integer || string or both)
    # 
    # args - list tcl
    #
    # example :
    # new elist {1 2 3 4 5}
    # new elist {1 "a" 2 "b"}
    # new elist {"a" "b" "c"}
    # new elist {"a" "b"} {1 2}
    #
    # Returns a eList object
    return [ticklecharts::eList new $args]
}

proc ticklecharts::iseListClass {value} {
    # Check if value is eList class
    #
    # value - obj or string
    #
    # Returns true if 'value' is a eList class, false otherwise.
    return [expr {
            [string match {::oo::Obj[0-9]*} $value] && 
            [string match "*::eList" [ticklecharts::typeOfClass $value]]
        }
    ]
}

oo::class create ticklecharts::eDict {
    variable _edict

    constructor {d} {
        # Initializes a new eList Class.
        #
        set _edict $d
    }
}

oo::define ticklecharts::eDict {
    method get {} {
        # Returns dict
        return $_edict
    }
    
    method getType {} {
        # Returns type
        return "eDict"
    }
}

proc ticklecharts::edict {value} {
    # This procedure substitutes a pure Tcl dict...
    # It can replace dict types : 
    #   - dict   (pure dict)
    #   - dict.o (pure dict)
    # 
    # value - dict tcl
    #
    # example :
    # new edict {key value key1 value1 ...}
    #
    # Returns a eDict object

    if {![ticklecharts::isDict $value]} {
        error "should be a dict representation..."
    }

    return [ticklecharts::eDict new $value]
}

proc ticklecharts::iseDictClass {value} {
    # Check if value is eDict class
    #
    # value - obj or string
    #
    # Returns true if 'value' is a eDict class, false otherwise.
    return [expr {
            [string match {::oo::Obj[0-9]*} $value] && 
            [string match "*::eDict" [ticklecharts::typeOfClass $value]]
        }
    ]
}

