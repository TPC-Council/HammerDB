#!/usr/bin/tclsh
#
#
#

package provide arc 1.2

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

namespace eval ::ttk::theme::arc {

  proc setBaseColors { } {
    variable colors

      array set colors {
          style.arrow           chevron
          style.button          roundedrect-flat
          style.checkbutton     roundedrect-check-rev
          style.combobox        -
          style.entry           roundedrect
          style.menubutton      -
          style.notebook        roundedtop-dark
          style.progressbar     rounded-line
          style.radiobutton     circle-circle-rev
          style.scale           circle-rev
          style.scrollbar-grip  none
          style.treeview        plusminus-box
          bg.bg                 #f5f6f7
          fg.fg                 #000000
          graphics.color        #5294e2
      }
  }

  proc setDerivedColors { } {
    variable colors

    set colors(bg.light) #fcfdfd
    set colors(bg.lightest) #ffffff
    set colors(bg.dark) #eaebed
    set colors(bg.darker) #d3d8e2
    set colors(bg.darkest) #5c616c

    set colors(bg.border) $colors(bg.darker)
    set colors(bg.button) $colors(bg.light)
    set colors(bg.tab.disabled) $colors(bg.dark)
    set colors(bg.tab.inactive) $colors(bg.dark)
    set colors(button.active) $colors(bg.lightest)
    set colors(button.active.border) $colors(bg.darker) ; # #cfd6e6
    set colors(button.anchor) {}
    set colors(notebook.tab.focusthickness) 3
    set colors(notebook.tab.padding) {3 3}
    set colors(button.image.padding) {6 3}
    set colors(button.padding) {8 4}
    set colors(button.pressed) $colors(bg.darker)
    set colors(checkbutton.scale) 0.95
    set colors(combobox.entry.image.padding) {6 5}
    set colors(combobox.padding) {0 0}
    set colors(entrybg.bg) $colors(bg.lightest)
    set colors(entry.image.padding) {6 5}
    set colors(entry.padding) {0 0}
    set colors(graphics.color.spin.arrow) $colors(bg.darkest)
    set colors(graphics.color.spin.bg) $colors(bg.bg)
    set colors(menubutton.padding) {8 3}
    set colors(menubutton.use.button.image) true
    set colors(parent.theme) default
    set colors(scale.trough) $colors(graphics.color)
    set colors(scrollbar.active) #d3d4d8
    set colors(scrollbar.color) #b8babf
    set colors(scrollbar.has.arrows) false
    set colors(scrollbar.pressed) $colors(graphics.color)
    set colors(scrollbar.trough) $colors(bg.bg)
    set colors(selectbg.bg) $colors(graphics.color)
    set colors(spinbox.image.padding) {4 0}
    set colors(spinbox.padding) {0 0}
    set colors(toolbutton.image.padding) {8 7}
    set colors(toolbutton.use.button.image) true
    set colors(toolbutton.use.button.image) true
    set colors(trough.color) #cfd6e6
  }

  proc init { } {
    ::ttk::awthemes::init arc
  }

  init
}
