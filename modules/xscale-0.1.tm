# -----------------------------------------------------------------------------
# xscale.tcl ---
# -----------------------------------------------------------------------------
# (c) 2017, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] gmail.com
#     www.johann-oberdorfer.eu
# -----------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# -----------------------------------------------------------------------------
# Purpose:
#  A TclOO class template to extend ttk::scale functionality.
#  Same behavior as tk::scale widget,
#  implements -resolution option.
# -----------------------------------------------------------------------------


# http://wiki.tcl.tk/40210
# derived from ttk::scale, implements -resolution found in older scale

package provide xscale 0.1

namespace eval xscale {
        
        variable cnt 0
        
        # this is a tk-like wrapper around my... class so that
        # object creation works like other tk widgets
        
        proc xscale {path args} {
                variable cnt
                incr cnt
                set obj [XScaleClass create tmp${cnt} $path {*}$args]
                
                # rename oldName newName
                rename $obj ::$path
                return $path
        }
        
        oo::class create XScaleClass {
                
                constructor { path args } {
                        my variable widgetOptions
                        my variable oldval
                        my variable label_txt
                        
                        set label_txt ""
                        
                        array set widgetOptions {
                                -resolution 1
                                -command ""
                                -showvalue 1
                                -compound "left"
                        }
                        
                        # incorporate arguments to local widget options
                        array set widgetOptions $args
                        
                        # we use a frame for this specific widget class
                        set f [ttk::frame $path -class xscale]
                        
                        # we must rename the widget command
                        # since it clashes with the object being created
                        set widget ${path}_
                        my Build $f
                        rename $path $widget
                        
                        my configure {*}$args
                }
                
                # add a destructor to clean up the widget
                destructor {
                        set w [namespace tail [self]]
                        catch {bind $w <Destroy> {}}
                        catch {destroy $w}
                }
                
                method cget { {opt "" }  } {
                        my variable scalewidget
                        my variable widgetOptions
                        
                        if { [string length $opt] == 0 } {
                                return [array get widgetOptions]
                        }
                        if { [info exists widgetOptions($opt) ] } {
                                return $widgetOptions($opt)
                        }
                        return [$scalewidget cget $opt]
                }
                
                method configure { args } {
                        my variable scalewidget
                        my variable widgetOptions
                        my variable label_txt

                        
                        if {[llength $args] == 0}  {
                                
                                # return all tablelist options
                                set opt_list [$scalewidget configure]
                                
                                # as well as all custom options
                                foreach xopt [array get widgetOptions] {
                                        lappend opt_list $xopt
                                }
                                return $opt_list
                                
                        } elseif {[llength $args] == 1}  {
                                
                                # return configuration value for this option
                                set opt $args
                                if { [info exists widgetOptions($opt) ] } {
                                        return $widgetOptions($opt)
                                }
                                return [$scalewidget cget $opt]
                        }
                        
                        # error checking
                        if {[expr {[llength $args]%2}] == 1}  {
                                return -code error "value for \"[lindex $args end]\" missing"
                        }
                        
                        # process the new configuration options...
                        array set opts $args
                        
                        foreach opt_name [array names opts] {
                                set opt_value $opts($opt_name)
                                
                                # overwrite with new value
                                if { [info exists widgetOptions($opt_name)] } {
                                        set widgetOptions($opt_name) $opt_value
                                }
                                
                                # some options need action from the widgets side
                                switch -- $opt_name {
                                        -resolution {
                                                set widgetOptions(-resolution) $opt_value
                                        }
                                        -variable {
                                                my SetVariable $opt_value
                                                my ShowValue
                                        }
                                        -command {
                                                # not allowed to overwrite our own command
                                                # procedure as it triggers the "hopping" behavior
                                                # use the variable to get the actual scale value
                                                set cmd $opt_value
                                                append cmd "; [namespace code {my ResolutionCmd}]"
                                                
                                                $scalewidget configure -command $cmd
                                        }
                                        -showvalue {
                                                # immediately show or hide the actual value...
                                                set widgetOptions(-showvalue) $opt_value
                                                my ShowValue
                                        }
                                        -value {
                                                # overwrite existing option!
                                                return -code error \
                                                        "option -value is not supported, use -variable instead!"
                                        }
                                        -compound {
                                                # static declaration for the moment
                                        }
                                        default {
                                                
                                                # -------------------------------------------------------
                                                # if the configure option wasn't one of our special one's,
                                                # pass control over to the original ttk::scale widget
                                                # -------------------------------------------------------
                                                # puts ">>> $opt_name : $opt_value"
                                                
                                                if {[catch {$scalewidget configure $opt_name $opt_value} result]} {
                                                        return -code error $result
                                                }
                                        }
                                }
                        }
                }
                                
                # --------------------------------------------------
                # if the command wasn't one of our special one's,
                # pass control over to the original tablelist widget
                # --------------------------------------------------
                method unknown {method args} {
                        my variable scalewidget
                        
                        if {[catch {$scalewidget $method {*}$args} result]} {
                                return -code error $result
                        }
                        return $result
                }

                method ShowValue { } {
                        my variable scalewidget
                        my variable widgetOptions
                        my variable label_txt

                        if {$widgetOptions(-showvalue) == 0} {
                                set label_txt ""
                        } else {
                                set label_txt [$scalewidget cget -value]
                        }
                }
                
                method SetVariable { varname } {
                        my variable scalewidget
                        my variable widgetOptions
                        
                        set widgetOptions(-variable) $varname
                        $scalewidget configure -variable $varname
                        
                        if { $varname ne {} } {
                                upvar #0 $varname tracevar
                                if { ![info exists tracevar] } {
                                        set tracevar [$scalewidget cget -from]
                                }
                               set oldval $tracevar
                        }
                }
                
                method ResolutionCmd { val } {
                        my variable widgetOptions
                        my variable oldval
                        my variable label_txt

                        
                        # round value to nearest multiple of resolution
                        set res $widgetOptions(-resolution)
                        set hopval [expr {$res * floor(double($val) / $res + 0.5)}]
                
                        if { $widgetOptions(-variable) ne {} } {
                                upvar #0 $widgetOptions(-variable) var
                                set var $hopval
                        }
                        
                        # run callback as in standard scale
                        # only for a different value == integer hop

                        if { $hopval != $oldval } {
                                set oldval $hopval
                                if { $widgetOptions(-command) ne {} } {
                                        set command_with_value [linsert $widgetOptions(-command) end $hopval]
                                        uplevel #0 $command_with_value
                                }
                        }

                        # round the return value !
                        set hopval [expr {double(round(100*$hopval))/100}]
                         puts "hopval: $hopval"

                        if {$widgetOptions(-showvalue) == 1} {
                                set label_txt $hopval
                        }
                        
                        return $hopval                
                }                
        
                method Build {win} {
                        my variable scalewidget
                        my variable widgetOptions
                        my variable oldval
                        my variable label_txt

                        ttk::label $win.lbl \
                                -textvariable "[namespace current]::label_txt"
                                
                        ttk::scale $win.sc \
                                -command "[namespace code {my ResolutionCmd}]"

                        # compound left:
                        # pack $win.lbl -side left
                        # pack $win.sc -side right -fill x -expand true

                        # compound right (default)
                        pack $win.sc -side left -fill x -expand true
                        pack $win.lbl -side right
                        
                        set scalewidget $win.sc
                        
                        set oldval [$scalewidget cget -value]
                        
                        # need to overwrite the ttk binding:
                        # note:
                        #   the original bindings in the tcl distribution
                        #   uses "Press" instead of "Jump" which, when clicking
                        #   with the mouse, has no effect!
                        #
                        bind TScale <ButtonPress-1> { ttk::scale::Jump %W %x %y }
                }
                
        }
        
}
package require xscale 0.1
