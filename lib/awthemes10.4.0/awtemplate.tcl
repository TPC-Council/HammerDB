#!/usr/bin/tclsh
#
# 2020-4-23
# Template for creating a new theme using the awthemes package.
# This code is in the public domain.
#
# Search for 'CHANGE:' within this file to locate the three changes
# that must be made to set up a new theme.
#

# CHANGE: 'awtemplate' to the filename containing your theme.
# Within the pkgIndex.tcl file, use the following layout to load
# the new theme:
#    package ifneeded awtemplate 1.0 \
#        [list source [file join $dir awtemplate.tcl]]

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

# CHANGE: 'awtemplate' to the name of your theme.
namespace eval ::ttk::theme::awtemplate {

  # To set a widget style, in the 'setBaseColors' procedure, add
  #   style.<widget-image-type> <style>
  # to the 'array set colors' command.
  #   e.g.
  #      array set colors {
  #         style.progressbar rounded-line
  #         ...
  #      }
  # To turn off a widget style, set it to 'none'.
  # To change a widget style to use the default, set it to '-' or 'default'.
  #
  # To make a basic scalable theme, the checkbuttons, radiobuttons,
  # progressbar, arrows and scale should be set.
  #
  # As of 2020-10-16, the available styles are:
  #     arrow
  #         chevron (default)
  #         solid-bg
  #         solid
  #         open
  #     button
  #         (default: none)
  #         roundedrect-accent-gradient
  #         roundedrect-flat
  #         roundedrect-gradient
  #     checkbutton
  #         roundedrect-check (default)
  #         roundedrect-check-rev
  #         roundedrect-square
  #         square-check-gradient
  #         square-x
  #     combobox
  #         (defaults to arrow/chevron)
  #         rounded
  #         solid-bg
  #     empty
  #         empty (default)
  #     entry
  #         (default: none)
  #         roundedrect
  #     labelframe
  #         (default: none)
  #         square
  #     menubutton
  #         (defaults to arrow/chevron)
  #         chevron (larger than arrow/chevron)
  #         solid
  #     notebook
  #         (default: none)
  #         roundedtop-dark
  #         roundedtop-light
  #         roundedtop-light-accent
  #     progressbar (these are used for scales and scrollbars also)
  #         rect
  #         rect-bord (default)
  #         rect-diag
  #         rounded-line
  #     radiobutton
  #         circle-circle (default)
  #         circle-circle-gradient
  #         circle-circle-hlbg
  #         circle-circle-rev
  #         octagon-circle
  #     scale
  #         circle
  #         circle-rev
  #         rect-bord-grip (default)
  #         rect-narrow
  #     scrollbar-grip
  #         circle (default)
  #     sizegrip
  #         circle (default)
  #     treeview
  #         (defaults to arrow/chevron)
  #         chevron (larger than arrow/chevron)
  #         open
  #         plusminus-box
  #         solid
  #

  #
  # in 'setBaseColors', set the following colors:
  #     bg.bg           main background color
  #     fg.fg           main foreground color
  #     graphics.color  main color for graphical elements
  #     is.dark         true / false
  #                     set to true if using a dark theme.
  #                     affects some color adjustments.
  # also set any widget styles here.
  # e.g.
  #    array set colors {
  #      bg.bg               #f5f6f7
  #      fg.fg               #000000
  #      graphics.color      #c03c2a
  #    }
  #
  proc setBaseColors { } {
    variable colors

    # the dark/light switch here is just for showing examples,
    # rarely would a theme support both.
    set dark true
    if { $dark } {
      array set colors {
        bg.bg               #424242
        fg.fg               #ffffff
        is.dark             true
        graphics.color      #c03c2a
      }
    } else {
      array set colors {
        bg.bg               #f5f6f7
        fg.fg               #000000
        is.dark             false
        graphics.color      #c03c2a
      }
    }
  }

  # Set any other colors here.
  #
  # The list of colors here is not complete.
  #
  # Use the form:
  #     set colors(color-name) color
  # The main colors you may want to set:
  #     entrybg.bg            entry field background
  #     entryfg.fg            entry field foreground
  #     select.bg             selection background
  #     select.fg             selection foreground
  #     focus.color           if different from graphics.color
  #     accent.color          used for some widget styles (check/radio button)
  #                           an alternate graphics color
  #     scrollbar.has.arrows  true / false
  #     style.scrollbar-grip  none / rect-bord-circle
  #     parent.theme          default / alt / clam (default is clam)
  #                           'alt' has not been used yet in this package,
  #                           I don't know what issues it will have.
  #
  # For dark themes using progressbar/rect-bord, set:
  #     scale.border
  #
  # See the source to 'awthemes.tcl' to see the complete list of settings.
  # See the other aw*.tcl themes for examples on how to set up a theme.
  #
  # Colors available to use within 'setDerivedColors':
  #     $colors(bg.bg)
  #     $colors(fg.fg)
  #     $colors(graphics.color)
  #     $colors(graphics.color.light)
  #     $colors(graphics.color.dark)
  #     $colors(bg.light)
  #     $colors(bg.lighter)
  #     $colors(bg.lightest)
  #     $colors(bg.dark)
  #     $colors(bg.darker)
  #     $colors(bg.darkest)
  # These colors can also be reset to a different color.
  #
  proc setDerivedColors { } {
    variable colors

    set colors(arrow.color) #ffffff
  }

  # CHANGE: 'awtemplate' to the name of your theme.
  proc init { } {
    set theme awtemplate
    set version 1.5.1
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
