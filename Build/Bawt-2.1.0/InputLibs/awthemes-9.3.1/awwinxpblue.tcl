#!/usr/bin/tclsh
#
#

package provide winxpblue 7.6

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

namespace eval ::ttk::theme::winxpblue {

  proc setBaseColors { } {
    variable colors

      # #ccccc2 -> #bab5ab
      # #cdcac3 -> #bab5ab
      # #21a12a accent color
      # #e59700 highlight color
      # #003c74 blue color
      array set colors {
          style.arrow           chevron
          style.button          roundedrect-accent-gradient
          style.checkbutton     square-check-gradient
          style.combobox        -
          style.menubutton      -
          style.notebook        roundedtop-light-accent
          style.radiobutton     circle-circle-gradient
          style.treeview        -
          bg.bg                 #ece9d8
          fg.fg                 #000000
          graphics.color        #003c74
      }
  }

  proc setDerivedColors { } {
    variable colors

    set colors(bg.lighter) #f0f0ea
    set colors(bg.lightest) #fbfbf8

    set colors(accent.color) #21a12a
    set colors(bg.active) $colors(bg.dark)
    set colors(button.anchor) w
    set colors(button.border) #003c74
    set colors(button.padding) {3 3}
    set colors(checkbutton.border) #003c74
    set colors(checkbutton.padding) {8 0 0 2}
    set colors(checkbutton.scale) 0.75
    set colors(combobox.padding) {5 0}
    set colors(entrybg.bg) #ffffff
    set colors(entry.padding) {2 0}
    set colors(focus.color) #003c74
    set colors(graphics.color.grip) $colors(bg.darkest)
    set colors(graphics.color.pbar) #ece9d8
    set colors(graphics.color.spin.arrow) $colors(graphics.color)
    set colors(graphics.highlight) #e59700
    set colors(menubutton.padding) {3 1}
    set colors(menubutton.relief) none
    set colors(menubutton.width) {}
    set colors(notebook.tab.focusthickness) 1
    set colors(notebook.tab.padding) {4 2 4 2}
    set colors(progressbar.color) $colors(bg.bg)
    set colors(scale.color) $colors(bg.bg)
    set colors(scrollbar.color) $colors(bg.bg)
    set colors(selectbg.bg) $colors(bg.darkest)
    set colors(spinbox.padding) {1 3}
    set colors(trough.color) $colors(bg.lightest)
  }

  proc init { } {
    ::ttk::awthemes::init winxpblue
  }

  init
}
