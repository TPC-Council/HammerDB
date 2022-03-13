#!/usr/bin/tclsh
#
#

package provide awlight 7.6

set ap [file normalize [file dirname [info script]]]
if { $ap ni $::auto_path } {
  lappend ::auto_path $ap
}
set ap [file normalize [file join [file dirname [info script]] .. code]]
if { $ap ni $::auto_path } {
  lappend ::auto_path $ap
}
unset ap
package require awthemes

namespace eval ::ttk::theme::awlight {

  proc setBaseColors { } {
    variable colors

    array set colors {
        style.arrow           solid-bg
        style.checkbutton     roundedrect-check
        style.combobox        solid-bg
        style.menubutton      solid
        style.radiobutton     circle-circle-hlbg
        style.treeview        solid
        bg.bg                 #e8e8e7
        fg.fg                 #000000
        graphics.color        #1a497c
    }
  }

  proc setDerivedColors { } {
    variable colors

    set colors(bg.button) $colors(bg.dark)
    set colors(bg.tab.active) $colors(bg.dark)
    set colors(bg.tab.border) $colors(bg.light)
    set colors(bg.tab.disabled) $colors(bg.dark)
    set colors(bg.tab.inactive) $colors(bg.dark)
    set colors(bg.tab.selected) $colors(bg.dark)
    set colors(button.anchor) {}
    set colors(button.padding) {5 3}
    set colors(entrybg.bg) $colors(bg.lightest)
    set colors(entry.padding) {5 1}
    set colors(graphics.color.spin.arrow) #000000
    set colors(graphics.color.spin.bg) $colors(bg.bg)
    set colors(graphics.color.tree.arrow) #000000
    set colors(graphics.color.grip) #ffffff
    set colors(notebook.tab.focusthickness) 5
    set colors(selectbg.bg) $colors(graphics.color)
    set colors(tab.use.topbar) true
    set colors(trough.color) $colors(bg.lightest)
  }

  proc init { } {
    ::ttk::awthemes::init awlight
  }

  init
}


