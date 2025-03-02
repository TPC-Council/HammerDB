#!/usr/bin/tclsh
#
#   breeze-dark:
#     - Notebook background is not graphical as it was in the original.
#     - Improved tab hover color.
#     - Add button press color, remove button focus color (not focus ring).
#     - toolbutton and menubutton press states are set the same as
#       the button press.
#     - sizegrip design is different.
#     - entry and button backgrounds are lighter.
#     - cleaned up some background color issues.
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

namespace eval ::ttk::theme::awbreezedark {

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
          bg.bg                 #2f3336
          fg.fg                 #ffffff
          graphics.color        #3984ac
          is.dark               true
      }
  }

  proc setDerivedColors { } {
    variable colors

    # entry-active: 56707c
    # entry-focus: 3986af
    # cb-active: 556d7a
    # border: 53575a
    set colors(active.color) #56707c
    set colors(arrow.color) $colors(bg.lightest)
    set colors(border) #53575a
    set colors(border.checkbutton) $colors(graphics.color)
    set colors(button) $colors(bg.light)
    set colors(button.anchor) {}
    set colors(button.image.padding) {6 4}
    set colors(button.padding) {8 4}
    set colors(button.pressed) $colors(graphics.color)
    set colors(checkbutton.focusthickness) 1
    set colors(checkbutton.padding) {4 3 0 3}
    set colors(combobox.entry.image.padding) {6 8}
    set colors(entrybg.bg) $colors(bg.light) ; # #31363b
    set colors(entry.image.padding) {5 8}
    set colors(entry.padding) {2 0}
    set colors(focus.color) #3986af
    set colors(graphics.color.light) $colors(graphics.color)
    set colors(menubutton.padding) {10 2}
    set colors(menubutton.use.button.image) true
    set colors(notebook.tab.focusthickness) 4
    set colors(parent.theme) default
    set colors(scale.trough)  $colors(graphics.color)
    set colors(scrollbar.has.arrows) false
    set colors(select.bg) $colors(graphics.color)
    set colors(spinbox.color.arrow) $colors(bg.lightest)
    set colors(spinbox.image.padding) {4 4}
    set colors(toolbutton.image.padding) {10 7}
    set colors(toolbutton.use.button.image) true
    set colors(tree.arrow.selected) #ffffff
    set colors(trough.color) $colors(bg.bg)
  }

  proc init { } {
    set theme awbreezedark
    set version 1.0.1
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
