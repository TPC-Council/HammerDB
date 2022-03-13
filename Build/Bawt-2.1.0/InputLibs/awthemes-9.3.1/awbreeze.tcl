#!/usr/bin/tclsh
#
#

package provide breeze 1.5

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

namespace eval ::ttk::theme::breeze {

  proc setBaseColors { } {
    variable colors

      # original breeze base foreground is #31363b
      # I personally want as high of a contrast as is possible.
      # the combobox style must be set to -, otherwise the awthemes
      # default (solid-bg) is used.

      array set colors {
          style.arrow           chevron
          style.button          roundedrect-flat
          style.checkbutton     roundedrect-square
          style.combobox        -
          style.entry           roundedrect
          style.labelframe      square
          style.menubutton      chevron
          style.notebook        roundedtop-dark
          style.progressbar     rounded-line
          style.radiobutton     circle-circle
          style.scale           circle
          style.scrollbar-grip  none
          style.treeview        chevron
          bg.bg                 #eff0f1
          fg.fg                 #000000
          graphics.color        #3daee9
      }
  }

  proc setDerivedColors { } {
    variable colors

    # the alternate color would be defined, but we need a copy now
    # for button-af
    set colors(graphics.color.alternate) \
        [::colorutils::opaqueBlendPerc $colors(graphics.color) #ffffff 0.7 2]

    set colors(bg.checkbutton) $colors(bg.bg)
    set colors(button.active.border) $colors(graphics.color)
    set colors(button.activefocus) $colors(graphics.color.alternate)
    set colors(button.anchor) {}
    set colors(button.image.padding) {6 4}
    set colors(button.padding) {8 3}
    set colors(button.pressed) $colors(graphics.color)
    set colors(button.pressed) $colors(graphics.color)
    set colors(checkbutton.border) $colors(graphics.color)
    set colors(checkbutton.focusthickness) 1
    set colors(checkbutton.padding) {4 0 0 2}
    set colors(combobox.entry.image.padding) {6 8}
    set colors(entrybg.bg) #fcfcfc
    set colors(entry.image.padding) {5 8}
    set colors(entry.padding) {2 0}
    set colors(graphics.color.spin.arrow) $colors(bg.darkest)
    set colors(graphics.color.tree.arrow) $colors(bg.darkest)
    set colors(menubutton.padding) {10 2}
    set colors(menubutton.use.button.image) true
    set colors(parent.theme) default
    set colors(scale.trough)  $colors(graphics.color)
    set colors(scrollbar.has.arrows) false
    set colors(selectbg.bg) $colors(graphics.color)
    set colors(spinbox.image.padding) {4 4}
    set colors(toolbutton.image.padding) {10 7}
    set colors(toolbutton.use.button.image) true
    set colors(trough.color) $colors(bg.darker)
  }

  proc init { } {
    ::ttk::awthemes::init breeze
  }

  init
}
