#!/usr/bin/tclsh
#
#   black:
#     - Added the labelframe box.
#     - Changed selection color to match the background color.
#     - Scale, progressbar, scrollbar, spinbox button design are different.
#     - sizegrip design is different.
#
# 7.8
#   - set menu.relief to solid.

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

namespace eval ::ttk::theme::awblack {

  proc setBaseColors { } {
    variable colors

    array set colors {
        style.arrow           solid-bg
        style.checkbutton     square-x
        style.combobox        solid-bg
        style.radiobutton     octagon-circle
        style.menubutton      solid
        style.treeview        solid
        bg.bg                 #424242
        fg.fg                 #ffffff
        graphics.color        #424242
        is.dark               true
    }
  }

  proc setDerivedColors { } {
    variable colors

    set colors(bg.darkest) #121212

    set colors(border) #000000
    set colors(button) $colors(bg.bg)
    set colors(border.button) $colors(bg.darkest)
    set colors(button.padding) {5 1}
    set colors(border.checkbutton) $colors(bg.darker)
    set colors(checkbutton.padding) {4 0 0 3}
    set colors(checkbutton.scale) 0.7
    set colors(combobox.padding) {2 0}
    set colors(entrybg.bg) #ffffff
    set colors(entryfg.fg) #000000
    set colors(entry.padding) {3 0}
    set colors(focus.color) #000000
    set colors(arrow.color) #000000
    set colors(scrollbar.color.grip) #000000
    set colors(scrollbar.color.arrow) #000000
    set colors(sizegrip.color) #000000
    set colors(menu.relief) solid
    set colors(menubutton.padding) {5 1}
    set colors(menubutton.relief) raised
    set colors(menubutton.width) -8
    set colors(notebook.tab.focusthickness) 1
    set colors(notebook.tab.padding) {4 2 4 2}
    set colors(border.scale) $colors(bg.darkest)
    set colors(select.bg) $colors(bg.darkest)
    set colors(tree.arrow.selected) $colors(fg.fg)
    set colors(trough.color) $colors(bg.darkest)
  }

  proc init { } {
    set theme awblack
    set version 7.8.1
    try {
      set ti [image create photo -data {<svg></svg>} -format svg]
      image delete $ti
      set havetksvg true
    } on error {err res} {
      lassign [dict get $res -errorcode] a b c d
      if { $c ne "PHOTO_FORMAT" } {
        set havetksvg true
      }
    }
    if { ([info exists ::notksvg] && $::notksvg) || ! $havetksvg } {
      namespace delete ::ttk::theme::${theme}
      error "no tksvg package present: cannot load scalable ${theme} theme"
    }
    package provide ${theme} $version
    package provide ttk::theme::${theme} $version
    ::ttk::awthemes::init ${theme}
  }

  init
}
