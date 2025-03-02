#!/usr/bin/tclsh
#
#

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

    set colors(arrow.color) #000000
    set colors(border.tab) $colors(bg.light)
    set colors(button) $colors(bg.dark)
    set colors(button.active) $colors(bg.light)
    set colors(button.anchor) {}
    set colors(button.padding) {5 3}
    set colors(entrybg.bg) $colors(bg.lightest)
    set colors(entry.padding) {5 1}
    set colors(notebook.tab.focusthickness) 5
    set colors(scrollbar.color.grip) #ffffff
    set colors(select.bg) $colors(graphics.color)
    set colors(spinbox.color.bg) $colors(bg.bg)
    set colors(tab.active) $colors(bg.dark)
    set colors(tab.disabled) $colors(bg.dark)
    set colors(tab.inactive) $colors(bg.dark)
    set colors(tab.selected) $colors(bg.dark)
    set colors(tab.use.topbar) true
    set colors(tree.arrow.selected) #ffffff
    set colors(trough.color) $colors(bg.lightest)
  }

  proc init { } {
    set theme awlight
    set version 7.10
    ::ttk::awthemes::init $theme
    package provide $theme $version
    package provide ttk::theme::${theme} $version
  }

  init
}
