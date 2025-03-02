#!/usr/bin/tclsh

package require Tk

set iscript [info script]
if { [file type $iscript] eq "link" } { set iscript [file link $iscript] }
set ap [file normalize [file dirname $iscript]]
if { $ap ni $::auto_path } {
  lappend ::auto_path $ap
}
unset ap
unset iscript

proc main { } {
  variable vars

  wm withdraw .
  update idletasks
  set vars(mainW) .demoscaled
  toplevel $vars(mainW) -class demoscaledb.tcl
  wm title $vars(mainW) demoscaledb.tcl

  if { [llength $::argv] < 1 } {
    puts "Usage: demoscaledb.tcl <theme> \[-ttkscale <scale-factor>]"
    exit 1
  }

  set theme [lindex $::argv 0]

  set ::notksvg false
  set fontscale 1.0 ; # default
  set sf 1.0
  set gc {}
  set fontsize 11
  for {set idx 1} {$idx < [llength $::argv]} {incr idx} {
    if { [lindex $::argv $idx] eq "-ttkscale" } {
      incr idx
      tk scaling [lindex $::argv $idx]
    }
  }

  package require awthemes

  ::themeutils::setThemeColors $theme \
      scale.factor $sf

  if { ! $::notksvg &&
      [package vcompare 8.6.99 $::tk_version] > 0 } {
    catch { package require tksvg }
  }

  set calcdpi [expr {round([tk scaling]*72.0)}]
  set scalefactor [expr {$calcdpi/100.0}]

  # Tk defaults to pixels.  Sigh.
  # Use points so that the fonts scale.
  font configure TkDefaultFont -size $fontsize
  set origfontsz [font metrics TkDefaultFont -ascent]
  font configure TkDefaultFont -size \
      [expr {round(double($fontsize)*$fontscale)}]

  set newfontsz [font metrics TkDefaultFont -ascent]
  if { $origfontsz != $newfontsz } {
    set appscale [expr {double($newfontsz)/double($origfontsz)}]
    ::themeutils::setThemeColors $theme \
        scale.factor $appscale
  }

  set loaded false

  if { ! $loaded } {
    try {
      package require $theme
      puts "loaded via: package require $theme"
      set loaded true
    } on error {err res} {
      puts $err
    }
  }

  set havetksvg false
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

  if { ! $havetksvg } {
    error "tksvg is required"
  }

  ::ttk::style theme use $theme

  set val 55
  set valb $theme
  set off 0
  set on 1

  $vars(mainW) configure -background [::ttk::style lookup TFrame -background]

  if { [info commands ::ttk::theme::${theme}::scaledStyle] ne {} } {
    ::themeutils::setThemeColors $theme accent.color red
    ::ttk::theme::${theme}::scaledStyle Red TkDefaultFont TkDefaultFont
    ::themeutils::setThemeColors $theme accent.color green
    ::ttk::theme::${theme}::scaledStyle Green TkDefaultFont TkDefaultFont
    ::themeutils::setThemeColors $theme accent.color pink
    ::ttk::theme::${theme}::scaledStyle Pink TkDefaultFont TkDefaultFont
    ::themeutils::setThemeColors $theme accent.color cyan
    ::ttk::theme::${theme}::scaledStyle Cyan TkDefaultFont TkDefaultFont
    ::themeutils::setThemeColors $theme accent.color #00ff80
    ::ttk::theme::${theme}::scaledStyle Seagreen TkDefaultFont TkDefaultFont
    ::themeutils::setThemeColors $theme accent.color magenta
    ::ttk::theme::${theme}::scaledStyle Magenta TkDefaultFont TkDefaultFont
  }

  set ::ga 0
  ::ttk::label $vars(mainW).la -text {Group A}
  ::ttk::radiobutton $vars(mainW).ga0 -text Zero -variable ga -value 0
  ::ttk::radiobutton $vars(mainW).ga1 -text One -variable ga -value 1
  ::ttk::radiobutton $vars(mainW).ga2  -text Two -variable ga -value 2
  ::ttk::radiobutton $vars(mainW).ga3  -text Three -variable ga -value 3
  grid $vars(mainW).la $vars(mainW).ga0 -sticky w
  grid $vars(mainW).ga1 -sticky w -column 1
  grid $vars(mainW).ga2 -sticky w -column 1
  grid $vars(mainW).ga3 -sticky w -column 1

  set ::gb 0
  ::ttk::label $vars(mainW).lb -text {Group B}
  ::ttk::radiobutton $vars(mainW).gb0  -text Alpha -variable gb -value 0 \
      -style Green.TRadiobutton
  ::ttk::radiobutton $vars(mainW).gb1  -text Beta -variable gb -value 1 \
      -style Green.TRadiobutton
  ::ttk::radiobutton $vars(mainW).gb2  -text Gamma -variable gb -value 2 \
      -style Green.TRadiobutton
  ::ttk::radiobutton $vars(mainW).gb3  -text Delta -variable gb -value 3 \
      -style Green.TRadiobutton
  grid $vars(mainW).lb $vars(mainW).gb0 -sticky w
  grid $vars(mainW).gb1 -sticky w -column 1
  grid $vars(mainW).gb2 -sticky w -column 1
  grid $vars(mainW).gb3 -sticky w -column 1

  set ::gc 0
  ::ttk::label $vars(mainW).lc -text {Group C}
  ::ttk::radiobutton $vars(mainW).gc0  -text Pink -variable gc -value 0 \
      -style Pink.TRadiobutton
  ::ttk::radiobutton $vars(mainW).gc1  -text Cyan -variable gc -value 1 \
      -style Cyan.TRadiobutton
  ::ttk::radiobutton $vars(mainW).gc2  -text {Spring Green} -variable gc -value 2 \
      -style Seagreen.TRadiobutton
  ::ttk::radiobutton $vars(mainW).gc3  -text Magenta -variable gc -value 3 \
      -style Magenta.TRadiobutton
  grid $vars(mainW).lc $vars(mainW).gc0 -sticky w
  grid $vars(mainW).gc1 -sticky w -column 1
  grid $vars(mainW).gc2 -sticky w -column 1
  grid $vars(mainW).gc3 -sticky w -column 1
}

::main
