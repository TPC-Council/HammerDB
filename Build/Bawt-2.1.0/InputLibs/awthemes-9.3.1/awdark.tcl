#!/usr/bin/tclsh
#
#

package provide awdark 7.7

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

namespace eval ::ttk::theme::awdark {

  proc setBaseColors { } {
    variable colors

    array set colors {
        style.arrow           solid-bg
        style.checkbutton     roundedrect-check
        style.combobox        solid-bg
        style.menubutton      solid
        style.radiobutton     circle-circle-hlbg
        style.treeview        solid
        bg.bg                 #33393b
        fg.fg                 #ffffff
        graphics.color        #215d9c
        is.dark               true
    }
  }

  proc setDerivedColors { } {
    variable colors

    set colors(bg.border) #000000
    set colors(bg.button) $colors(bg.darker)
    set colors(bg.tab.active) $colors(bg.darker)
    set colors(bg.tab.border) $colors(bg.light)
    set colors(bg.tab.disabled) $colors(bg.darker)
    set colors(bg.tab.inactive) $colors(bg.darker)
    set colors(bg.tab.selected) $colors(bg.darker)
    set colors(button.anchor) {}
    set colors(button.padding) {5 3}
    set colors(entrybg.bg) $colors(bg.darkest)
    set colors(entry.padding) {5 1}
    set colors(graphics.color.grip) #000000
    set colors(graphics.color.spin.arrow) #ffffff
    set colors(graphics.color.spin.bg) $colors(graphics.color)
    set colors(graphics.color.tree.arrow) #ffffff
    set colors(menubutton.padding) {5 2}
    set colors(notebook.tab.focusthickness) 5
    set colors(scale.border) $colors(bg.darkest)
    set colors(selectbg.bg) $colors(graphics.color)
    set colors(tab.use.topbar) true
    set colors(trough.color) $colors(bg.darkest)
  }

  proc init { } {
    ::ttk::awthemes::init awdark
  }

  init
}
