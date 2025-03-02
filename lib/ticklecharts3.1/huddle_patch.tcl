# bug fixed in version 0.4
if {[package present huddle] == 0.3} {
    proc ::huddle::jsondump {huddle_object {offset "  "} {newline "\n"} {begin ""}} {
        # patch huddle 0.3 = huddle::jsondump
        # typo $data should be $huddle_object
        # unwrap $huddle_object for avoid to have this error below :
        # 'can't read "types(callback:tag)": no such element in array'
        #
        variable types
        set nextoff "$begin$offset"
        set nlof "$newline$nextoff"
        set sp " "
        if {[string equal $offset ""]} {set sp ""}

        set type [huddle type $huddle_object]

        switch -- $type {
            boolean -
            number {
                return [huddle get_stripped $huddle_object]
            }
            null {
                return null
            }
            string {
                set data [huddle get_stripped $huddle_object]

                # JSON permits only oneline string
                set data [string map {
                        \n \\n
                        \t \\t
                        \r \\r
                        \b \\b
                        \f \\f
                        \\ \\\\
                        \" \\\"
                        / \\/
                    } $data
                ]
            return "\"$data\""
            }
            list {
                set inner {}
                set len [huddle llength $huddle_object]
                for {set i 0} {$i < $len} {incr i} {
                    set subobject [huddle get $huddle_object $i]
                    lappend inner [jsondump $subobject $offset $newline $nextoff]
                }
                if {[llength $inner] == 1} {
                    return "\[[lindex $inner 0]\]"
                }
                return "\[$nlof[join $inner ,$nlof]$newline$begin\]"
            }
            dict {
                set inner {}
                foreach {key} [huddle keys $huddle_object] {
                    lappend inner [subst {"$key":$sp[jsondump [huddle get $huddle_object $key] $offset $newline $nextoff]}]
                }
                if {[llength $inner] == 1} {
                    return $inner
                }
                return "\{$nlof[join $inner ,$nlof]$newline$begin\}"
            }
            default {
                # patch...
                lassign [huddle unwrap $huddle_object] tag _src
                return [$types(callback:$tag) jsondump $huddle_object $offset $newline $nextoff]
            }
        }
    }
}