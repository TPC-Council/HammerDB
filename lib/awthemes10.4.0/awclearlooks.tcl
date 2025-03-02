#!/usr/bin/tclsh
#
#   clearlooks:
#     - changed blue focus, selection and progressbar colors to a color
#       matching the overall theme
#     -
#
# 1.3
#   - fix toolbutton height.
#   - fix select foreground color.
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

namespace eval ::ttk::theme::awclearlooks {

  proc setBaseColors { } {
    variable colors

      array set colors {
          style.arrow           solid-bg
          style.button          roundedrect-gradient
          style.checkbutton     square-check-gradient
          style.combobox        rounded
          style.entry           roundedrect
          style.menubutton      solid
          style.notebook        -
          style.progressbar     rect-diag
          style.radiobutton     circle-circle
          style.scale           rect-narrow
          style.scrollbar       rect-bord
          style.scrollbar-grip  none
          style.treeview        open
          bg.bg                 #efebe7
          fg.fg                 #000000
          graphics.color        #c9ac9a
      }
  }

  proc setDerivedColors { } {
    variable colors

    set colors(bg.light) #f5f3f0
    set colors(bg.lightest) #ffffff
    set colors(bg.dark) #e7ddd8
    set colors(bg.darker) #c9c1bc
    set colors(bg.darkest) #9c9284

    set colors(accent.color) #000000
    set colors(border) $colors(bg.darkest)
    set colors(button) $colors(bg.dark)
    set colors(button.active) $colors(bg.bg)
    set colors(button.pressed) $colors(bg.darker)
    set colors(tab.active) $colors(bg.darker)
    set colors(tab.inactive) $colors(bg.darker)
    set colors(button.anchor) {}
    set colors(button.padding) {8 2}
    set colors(checkbutton.scale) 0.8
    set colors(combobox.entry.image.border) {4 4}
    set colors(combobox.entry.image.padding) {3 1}
    set colors(entry.active) $colors(bg.darkest)
    set colors(entrybg.bg) $colors(bg.lightest)
    set colors(entry.image.padding) {3 1}
    set colors(entry.padding) {0 1}
    set colors(focus.color) #c9ac9a
    set colors(arrow.color) #000000
    set colors(pbar.color) $colors(focus.color)
    set colors(pbar.color.border) $colors(border)
    set colors(scrollbar.color.arrow) #000000
    set colors(sizegrip.color) $colors(bg.darkest)
    set colors(spinbox.color.bg) $colors(bg.dark)
    set colors(menubutton.padding) {0 2}
    set colors(menubutton.use.button.image) true
    set colors(notebook.tab.focusthickness) 2
    set colors(notebook.tab.padding) {3 2}
    set colors(parent.theme) clam
    set colors(scrollbar.color.active) $colors(bg.light)
    set colors(scrollbar.color) $colors(spinbox.color.bg)
    set colors(scrollbar.has.arrows) true
    set colors(select.bg) $colors(focus.color)
    set colors(select.fg) #000000
    set colors(trough.color) #d7cbbe
    set colors(toolbutton.image.padding) {4 4}
    set colors(toolbutton.use.button.image) true
  }

  proc init { } {
    set theme awclearlooks
    set version 1.3.1
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
