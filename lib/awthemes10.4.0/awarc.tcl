#!/usr/bin/tclsh
#
#   arc:
#     - selection colors are all blue.
#     - button focus uses blue color rather than focus ring.
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

namespace eval ::ttk::theme::awarc {

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
    set colors(trough.color) #cfd6e6

    set colors(accent.color) #ffffff
    set colors(border) $colors(bg.darker)
    set colors(button) $colors(bg.light)
    set colors(button.active) $colors(trough.color)
    set colors(button.pressed) $colors(bg.darker)
    set colors(tab.disabled) $colors(bg.dark)
    set colors(tab.inactive) $colors(bg.dark)
    set colors(border.button.active) $colors(bg.darker)
    set colors(button.anchor) {}
    set colors(button.active) $colors(bg.lightest)
    set colors(notebook.tab.focusthickness) 3
    set colors(notebook.tab.padding) {3 0}
    set colors(button.image.padding) {6 3}
    set colors(button.padding) {8 4}
    set colors(checkbutton.scale) 0.95
    set colors(combobox.entry.image.padding) {6 5}
    set colors(combobox.padding) {0 0}
    set colors(entrybg.bg) $colors(bg.lightest)
    set colors(entry.image.padding) {6 5}
    set colors(entry.padding) {0 0}
    set colors(arrow.color) $colors(bg.darkest)
    set colors(graphics.color.light) $colors(bg.bg)
    set colors(spinbox.color.bg) $colors(bg.bg)
    set colors(menubutton.padding) {8 3}
    set colors(menubutton.use.button.image) true
    set colors(parent.theme) default
    set colors(scale.trough) $colors(graphics.color)
    set colors(scrollbar.color.active) #d3d4d8
    set colors(scrollbar.color) #b8babf
    set colors(scrollbar.has.arrows) false
    set colors(scrollbar.color.pressed) $colors(graphics.color)
    set colors(scrollbar.trough) $colors(bg.bg)
    set colors(select.bg) $colors(graphics.color)
    set colors(spinbox.image.padding) {4 0}
    set colors(spinbox.padding) {0 0}
    set colors(toolbutton.image.padding) {8 7}
    set colors(toolbutton.use.button.image) true
    set colors(tree.arrow.selected) $colors(bg.darkest)
  }

  proc init { } {
    set theme awarc
    set version 1.6.1
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
