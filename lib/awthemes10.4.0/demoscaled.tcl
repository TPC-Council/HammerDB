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

proc setcboxfont { w } {
  set cb [winfo parent [winfo parent [winfo parent $w]]]
  set style [$cb cget -style]
  if { [regexp Small $style] } {
    $w configure -font SmallFont
  }
}

proc setcboxgeom { w } {
  set w [winfo parent $w]
  set w [winfo parent $w]
  set cb [winfo parent $w]
  ::ttk::combobox::PlacePopdown $cb $w
}

proc main { } {
  variable vars

  wm withdraw .
  update idletasks
  set vars(mainW) .demoscaled
  toplevel $vars(mainW) -class demoscaled.tcl
  wm title $vars(mainW) demoscaled.tcl


  if { [llength $::argv] < 1 } {
    puts "Usage: demoscaled.tcl <theme> \[-ttkscale <scale-factor>]"
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

  if { [package vcompare 8.6.99 $::tk_version] > 0 } {
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
    font create SmallFont
    font configure SmallFont -size [expr {round(8.0*$fontscale)}]

#    ::themeutils::setThemeColors $theme \
#        graphics.color #aa2233 \
#        pbar.color #aa2233 \
#        spinbox.color.bg #aa2233 \
#        scale.color #aa2233
    ::ttk::theme::${theme}::scaledStyle Small TkDefaultFont SmallFont
  }

  ::ttk::style configure TFrame -borderwidth 0

  bind ComboboxListbox <Map> +[list ::setcboxfont %W]
  bind ComboboxListbox <Visibility> +[list after 10 ::setcboxgeom %W]

  foreach {k} {{} Small} {
    set tfont TkDefaultFont
    set s {}
    if { $k ne {} } {
      set tfont SmallFont
      set s Small.
    }

    ::ttk::labelframe $vars(mainW).lf${k} \
        -text " Normal " \
        -style ${s}TLabelframe
    ::ttk::style configure ${s}TLabelframe.Label -font $tfont

    ::ttk::frame $vars(mainW).bf$k
    ::ttk::label $vars(mainW).lb$k -text $theme -style ${s}TLabel
    ::ttk::style configure ${s}TLabel -font $tfont
    ::ttk::button $vars(mainW).b$k -text $theme -style ${s}TButton
    ::ttk::style configure ${s}TButton -font $tfont
    pack $vars(mainW).lb$k $vars(mainW).b$k -in $vars(mainW).bf$k -side left -padx 3p

    ::ttk::combobox $vars(mainW).combo$k -values \
        [list aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp] \
        -textvariable valb \
        -width 15 \
        -height 5 \
        -font $tfont \
        -style ${s}TCombobox

    ::ttk::frame $vars(mainW).cbf$k
    ::ttk::checkbutton $vars(mainW).cboff$k -text off -variable off -style ${s}TCheckbutton
    ::ttk::checkbutton $vars(mainW).cbon$k -text on -variable on -style ${s}TCheckbutton
    pack $vars(mainW).cboff$k $vars(mainW).cbon$k -in $vars(mainW).cbf$k -side left -padx 3p

    ::ttk::separator $vars(mainW).sep$k -style ${s}TSeparator

    ::ttk::frame $vars(mainW).rbf$k
    ::ttk::radiobutton $vars(mainW).rboff$k -text off -variable on -value 0 -style ${s}TRadiobutton
    ::ttk::radiobutton $vars(mainW).rbon$k -text on -variable on -value 1 -style ${s}TRadiobutton
    pack $vars(mainW).rboff$k $vars(mainW).rbon$k -in $vars(mainW).rbf$k -side left -padx 3p

    pack $vars(mainW).bf$k $vars(mainW).combo$k $vars(mainW).cbf$k $vars(mainW).sep$k $vars(mainW).rbf$k \
        -in $vars(mainW).lf$k -side top -anchor w -padx 3p -pady 3p
    pack configure $vars(mainW).sep$k -fill x -expand true

    ::ttk::frame $vars(mainW).hf$k
    ::ttk::scale $vars(mainW).sc$k \
        -from 0 \
        -to 100 \
        -variable val \
        -length [expr {round(100*$scalefactor)}] \
        -style ${s}Horizontal.TScale
    ::ttk::progressbar $vars(mainW).pb$k \
        -mode determinate \
        -variable val \
        -length [expr {round(100*$scalefactor)}] \
        -style ${s}Horizontal.TProgressbar
    ::ttk::entry $vars(mainW).ent$k -textvariable valb \
        -width 15 \
        -font $tfont \
        -style ${s}TEntry
    ::ttk::spinbox $vars(mainW).sbox$k -textvariable val \
        -width 5 \
        -from 1 -to 100 -increment 0.1 \
        -font $tfont \
        -style ${s}TSpinbox
    pack $vars(mainW).sc$k $vars(mainW).pb$k $vars(mainW).ent$k $vars(mainW).sbox$k \
        -in $vars(mainW).hf$k -side top -anchor w -padx 3p -pady 3p

    ::ttk::frame $vars(mainW).vf$k
    ::ttk::scale $vars(mainW).scv$k \
        -orient vertical \
        -from 100 -to 0 \
        -variable val \
        -length [expr {round(100*$scalefactor)}] \
        -style ${s}Vertical.TScale
    ::ttk::progressbar $vars(mainW).pbv$k -orient vertical \
        -mode determinate \
        -variable val \
        -length [expr {round(100*$scalefactor)}] \
        -style ${s}Vertical.TProgressbar
    pack $vars(mainW).pbv$k $vars(mainW).scv$k -in $vars(mainW).vf$k -side right -padx 3p -pady 3p

    pack $vars(mainW).hf$k $vars(mainW).vf$k -in $vars(mainW).lf$k -side left -anchor e
  }
  $vars(mainW).lfSmall configure -text " Scaled "
  pack $vars(mainW).lf $vars(mainW).lfSmall -in $vars(mainW) -side left -padx 3p -pady 3p -expand 1 -fill both

}

::main
