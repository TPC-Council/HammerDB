#!/usr/bin/tclsh
#
#   breeze:
#     - Notebook background is not graphical as it was in the original.
#     - Disabled checkbutton/radiobutton look match the enabled look.
#     - readonly combobox is not identical.
#     - toolbutton and menubutton press states are set the same as
#       the button press.
#     - treeview arrow selected color is changed.
#     - sizegrip design is different.
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

namespace eval ::ttk::theme::awbreeze {

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

    set colors(active.color) $colors(graphics.color.alternate)
    set colors(arrow.color) $colors(bg.darkest)
    set colors(border.button.active) $colors(graphics.color)
    set colors(border.checkbutton) $colors(graphics.color)
    set colors(button.active.focus) $colors(graphics.color.alternate)
    set colors(button.anchor) {}
    set colors(button.image.padding) {6 4}
    set colors(button.padding) {8 3}
    set colors(button.pressed) $colors(graphics.color)
    set colors(checkbutton.focusthickness) 1
    set colors(checkbutton.padding) {4 3 0 3}
    set colors(combobox.entry.image.padding) {6 7}
    set colors(entrybg.bg) #fcfcfc
    set colors(entrybg.checkbutton) $colors(bg.bg)
    set colors(entry.image.padding) {5 8}
    set colors(entry.padding) {2 0}
    set colors(menubutton.padding) {10 2}
    set colors(menubutton.use.button.image) true
    set colors(notebook.tab.focusthickness) 4
    set colors(parent.theme) default
    set colors(scale.trough)  $colors(graphics.color)
    set colors(scrollbar.has.arrows) false
    set colors(select.bg) $colors(graphics.color)
    set colors(spinbox.color.arrow) $colors(bg.darkest)
    set colors(spinbox.image.padding) {4 4}
    set colors(toolbutton.image.padding) {10 7}
    set colors(toolbutton.use.button.image) true
    set colors(tree.arrow.selected) #ffffff
    set colors(trough.color) $colors(bg.darker)
  }

  proc init { } {
    set theme awbreeze
    set version 1.9.1
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
