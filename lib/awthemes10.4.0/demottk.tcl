#!/usr/bin/tclsh

package require Tk

set iscript [info script]
if { [file type $iscript] eq "link" } { set iscript [file link $iscript] }
set ap [file dirname $iscript]
if { $ap ni $::auto_path } {
  lappend ::auto_path $ap
}
unset ap
unset iscript

proc setbg { args } {
  variable vars

  if { [regexp {^#[0-9a-f]{6,6}$} $::vars(bgentry)] } {
    set theme [::ttk::style theme use]
    if { [info commands ::ttk::theme::${vars(theme)}::setBackground] ne {} } {
      ::ttk::theme::${vars(theme)}::setBackground $vars(bgentry)
    }
  }
}

proc confMenu { w } {
  variable vars

  if { [info commands ::ttk::theme::${vars(theme)}::setMenuColors] ne {} } {
    if { ($vars(haveflex) || $::tcl_platform(platform) ne "windows") &&
         ! $vars(optiondb) && ! $vars(optionnone) } {
      ::ttk::theme::${vars(theme)}::setMenuColors $w
    }
  } elseif { ! [regexp {^aqua(light|dark)?$} $vars(theme)] } {
    set c [::ttk::style lookup $vars(mainW) -background]
    if { $c ne {} } {
      $w configure -background $c
    }
    set c [::ttk::style lookup $vars(mainW) -foreground]
    if { $c ne {} } {
      $w configure -foreground $c
    }
    set c [::ttk::style lookup TEntry -selectforeground focus]
    if { $c ne {} } {
      $w configure -activeforeground $c
    }
    set c [::ttk::style lookup TEntry -selectbackground focus]
    if { $c ne {} } {
      $w configure -activebackground $c
    }
    set c [::ttk::style lookup TEntry -foreground disabled]
    if { $c ne {} } {
      $w configure -disabledforeground $c
    }
  }
  if { $w ne "$vars(mainW).mb" } {
    $w configure -borderwidth 1
  } else {
    $w configure -borderwidth 0
  }
  $w configure -activeborderwidth 0
}

proc twrap { } {
  variable vars

  foreach {nm} [list textdisabled textenabled] {
    set c [$vars(mainW).two.${nm} cget -wrap]
    if { $c eq "none" } {
      set c word
    } else {
      set c none
    }
    $vars(mainW).two.${nm} configure -wrap $c
  }
}

proc configureFonts { } {
  variable vars

  if { $::tcl_platform(os) eq "Darwin" } {
    set vars(fontsize) [expr {round($vars(fontsize) * 1.3)}]
  }
  font configure TkDefaultFont -size ${vars(fontsize)}
  set origfontsz [font metrics TkDefaultFont -ascent]
  font configure TkDefaultFont -size \
      [expr {round(double(${vars(fontsize)})*$vars(fontscale))}]
  # MacOS aqua will use the TkSmallCaptionFont for labelframe fonts
  # (currently in the mac_styles branch, eventually in 8.7)
  font configure TkSmallCaptionFont -size \
      [expr {round(double(${vars(fontsize)}-1)*$vars(fontscale))}]
  if { "TextFont" ni [font names] } {
    font create TextFont
  }
  # these calculations only work with point sizes, not pixel sizes.
  font configure TextFont -size \
      [expr {round((double(${vars(fontsize)})-1.0)*$vars(fontscale))}]
  if { "MenuFont" ni [font names] } {
    font create MenuFont
  }
  font configure MenuFont -size \
      [expr {round((double(${vars(fontsize)})-2.0)*$vars(fontscale))}]

  return $origfontsz
}

proc main { } {
  variable vars

  wm withdraw .
  update idletasks
  set vars(mainW) .demottk
  toplevel $vars(mainW) -class demottk.tcl
  wm title $vars(mainW) demottk.tcl

  if { [llength $::argv] < 1 } {
    puts "Usage: demottk.tcl "
    puts "    \[-autopath <path>] "
    puts "    \[-ttkscale <scale-factor>] "
    puts "    \[-fontsize <points>] \[-fontscale <scale-factor>] "
    puts "    \[-background <color>] \[-focuscolor <color>] "
    puts "    \[-foreground <color>] \[-accentcolor <color>] "
    puts "    \[-notksvg] \[-noflex] \[-nocbt] \[-notable]"
    puts "    \[-sizegrip] \[-styledemo] \[-optiondb]"
    puts "    \[-optionnone]"
    puts "    <theme> "
    exit 1
  }

  set ::notksvg false
  set vars(noflex) false
  set vars(nocbt) false
  set vars(sizegrip) false
  set vars(fontsize) 11
  set vars(fontscale) 1.0 ; # default
  set vars(sf) 1.0
  set vars(gc) {}
  set vars(accent) {}
  set vars(nbg) {}
  set vars(nfg) {}
  set vars(styledemo) false
  set vars(theme) {}
  set vars(tkscaling) {}
  set vars(macstyles) false
  set vars(notable) false
  set vars(cleanpath) false
  set vars(optiondb) false
  set vars(optionnone) false
  set vars(optiondflt) false
  set vars(testharald) false
  for {set idx 0} {$idx < [llength $::argv]} {incr idx} {
    set a [lindex $::argv $idx]
    switch -exact -- $a {
      -accentcolor {
        incr idx
        set vars(accent) [lindex $::argv $idx]
      }
      -autopath {
        incr idx
        lappend ::auto_path [split [lindex $::argv $idx] {:;}]
      }
      -background {
        incr idx
        set vars(nbg) [lindex $::argv $idx]
      }
      -cleanpath {
        # use for testing...
        set vars(cleanpath) true
      }
      -focuscolor {
        incr idx
        set vars(gc) [lindex $::argv $idx]
      }
      -fontscale {
        incr idx
        set vars(fontscale) [lindex $::argv $idx]
      }
      -fontsize {
        incr idx
        set vars(fontsize) [lindex $::argv $idx]
      }
      -foreground {
        incr idx
        set vars(nfg) [lindex $::argv $idx]
      }
      -macstyles {
        set vars(macstyles) true
      }
      -nocbt {
        set vars(nocbt) true
      }
      -noflex {
        set vars(noflex) true
      }
      -notable {
        set vars(notable) true
      }
      -notksvg {
        set ::notksvg true
      }
      -optiondb {
        set vars(optiondb) true
      }
      -optionnone {
        set vars(optionnone) true
      }
      -optiondflt {
        set vars(optiondflt) true
      }
      -sizegrip {
        set vars(sizegrip) true
      }
      -styledemo {
        set vars(styledemo) true
      }
      -testharald {
        set vars(testharald) true
      }
      -ttkscale {
        incr idx
        set vars(tkscaling) [lindex $::argv $idx]
      }
      default {
        if { ! [string match -* $a] } {
          set vars(theme) $a
          if { $vars(optiondflt) } {
            option add *TkTheme [lindex $::argv $idx]
          }
        }
      }
    }
  }

  if { [regexp {^aqua(light|dark)?$} $vars(theme)] } {
    set vars(sizegrip) true
  }

  if { $vars(theme) eq {} } {
    puts stderr "no theme specified"
    exit 1
  }

  # now do the require so that -notksvg has an effect.
  catch { package require awthemes }
  set vars(havethemeutils) false
  if { ! [catch {package present awthemes}] } {
    set vars(havethemeutils) true
  }

  if { ! $::notksvg &&
      [package vcompare 8.6.99 $::tk_version] > 0 } {
    catch { package require tksvg }
  }

  set vars(havetksvg) false
  try {
    set ti [image create photo -data {<svg></svg>} -format svg]
    image delete $ti
    set vars(havetksvg) true
  } on error {err res} {
    lassign [dict get $res -errorcode] a b c d
    if { $c ne "PHOTO_FORMAT" } {
      set vars(havetksvg) true
    }
  }
  if { $::notksvg } {
    set vars(havetksvg) false
  }

  if { $vars(tkscaling) ne {} && $vars(tkscaling) ne "default" } {
    tk scaling -displayof $vars(mainW) $vars(tkscaling)
  }
  set calcdpi [expr {round([tk scaling]*72.0)}]
  set vars(scalefactor) [expr {$calcdpi/100.0}]

  set vars(haveflex) false
  set vars(menucmd) menu
  set vars(topmenuargs) {}
  set vars(menuargs) {}
  if { ! $vars(noflex) } {
    catch { package require flexmenu }
    if { ! [catch {package present flexmenu}] } {
      puts "using flexmenu"
      set vars(haveflex) true
      set vars(menucmd) ::flexmenu
      set vars(topmenuargs) [list -type menubar]
      set vars(menuargs) [list -mode frame]
    }
  }

  if { $vars(testharald) } {
    ::themeutils::setThemeColors awdark \
        style.progressbar rounded-line \
        style.scale circle-rev \
        style.scrollbar-grip none \
        scrollbar.has.arrows false
  }
  if { $vars(havethemeutils) && $vars(gc) ne {} } {
    ::themeutils::setHighlightColor $vars(theme) $vars(gc)
  }
  if { $vars(havethemeutils) && $vars(accent) ne {} } {
    ::themeutils::setThemeColors $vars(theme) accent.color $vars(accent)
  }
  if { $vars(havethemeutils) && $vars(nbg) ne {} } {
    ::themeutils::setBackgroundColor $vars(theme) $vars(nbg)
  }
  if { $vars(havethemeutils) && $vars(nfg) ne {} } {
    ::themeutils::setThemeColors $vars(theme) fg.fg $vars(nfg)
  }
  if { $vars(havethemeutils) && $vars(styledemo) } {
    ::themeutils::setThemeColors $vars(theme) \
        style.progressbar rounded-line \
        style.scale circle-rev \
        style.scrollbar-grip none \
        scrollbar.has.arrows false
  }

  # Tk defaults to pixels.  Sigh.
  # Use points so that the fonts scale.
  set origfontsz [configureFonts]

  set newfontsz [font metrics TkDefaultFont -ascent]
  if { $origfontsz != $newfontsz } {
    set appscale [expr {double($newfontsz)/double($origfontsz)}]
    ::themeutils::setThemeColors $vars(theme) \
        scale.factor $appscale
    set vars(scalefactor) [expr {$vars(scalefactor) * $appscale}]
  }

  set loaded false
  if { ! $loaded } {
    if { $vars(theme) in [::ttk::style theme names] } {
      # built-in themes
      puts "built-in theme or theme specified by option db"
      set loaded true
    }
  }
  if { ! $loaded } {
    # try a package require to grab older themes using
    # the ::ttk::theme namespace.
    # many themes use this namespace in the 'package require'.
    try {
      package require ttk::theme::$vars(theme)
      puts "loaded via: package require ttk::theme::$vars(theme)"
      set loaded true
    } on error { err res } {
      # do not need this error
    }
  }
  if { ! $loaded } {
    # try a package require to grab by theme name w/o leading namespace
    try {
      package require $vars(theme)
      puts "loaded via: package require $vars(theme)"
      set loaded true
    } on error {err res} {
      puts $err
    }
  }
  if { ! $loaded } {
    foreach p [list . {*}$::auto_path] {
      set ttheme $vars(theme)
      if { ! $::notksvg && $vars(havetksvg) &&
          [file exists [file join $p aw${ttheme}.tcl]] } {
        set ttheme aw${vars(theme)}
      }
      set fn [file join [file join $p $ttheme.tcl]]
      if { [file exists $fn] } {
        source $fn
        puts "loaded via: source $fn"
        set loaded true
        break
      }
    }
  }

  if { ! $vars(optiondflt) } {
    try {
      ::ttk::style theme use $vars(theme)
    } on error {err res} {
      puts $res
      puts "themes: [::ttk::style theme names]"
    }
  }

  set vars(havecbt) false
  if { ! $vars(nocbt) } {
    catch { package require checkButtonToggle }
    if { ! [catch {package present checkButtonToggle}] } {
      set vars(havecbt) true
    }
  }

  # tablelist must be loaded after the theme is set.
  set vars(havetablelist) false

  if { ! $vars(notable) } {
    set origscale [tk scaling]

    catch { package require tablelist_tile 6.11- }
    if { ! [catch {package present tablelist_tile 6.11-}] } {
      if { [info exists ::tablelist::library] } {
        set vars(tablelistdemofn) \
            [file join $::tablelist::library demos tileWidgets.tcl]
        if { [file exists $vars(tablelistdemofn)] } {
          set vars(havetablelist) true
        }
      }
    }

    # Tablelist resets the tk scaling based on its own calculations.
    # Change it back to the original.
    tk scaling $origscale
    # Tablelist may change the font sizes. Reset the font sizes to match
    # the original tk scaling setting.
    configureFonts
  }

  if { $vars(optiondb) && ! $vars(optionnone) &&
      [info commands ::ttk::theme::${vars(theme)}::setMenuColors] ne {} } {
    ::ttk::theme::${vars(theme)}::setMenuColors -optiondb
    ::ttk::theme::${vars(theme)}::setListboxColors -optiondb
    ::ttk::theme::${vars(theme)}::setTextColors -optiondb -entry
  }

  set vars(val) 55
  set vars(valb) $vars(theme)
  set vars(bgentry) [::ttk::style lookup TFrame -background]
  set ::off 0
  set ::on 1

  $vars(mainW) configure -background [::ttk::style lookup TFrame -background]

  $vars(menucmd) $vars(mainW).mb -font MenuFont \
      {*}$vars(topmenuargs) {*}$vars(menuargs)
  if { $vars(haveflex) } {
    pack $vars(mainW).mb -in $vars(mainW) -side top -fill x -anchor nw -pady 0 -padx 0 -expand false
  } else {
    $vars(mainW) configure -menu $vars(mainW).mb
  }

  $vars(menucmd) $vars(mainW).mb_cascade -tearoff 0 \
      -font MenuFont {*}$vars(menuargs)
  $vars(mainW).mb_cascade add command -label Menu-3
  $vars(mainW).mb_cascade add command -label Menu-4

  $vars(menucmd) $vars(mainW).mb_example -tearoff 0 \
      -font MenuFont {*}$vars(menuargs)
  $vars(mainW).mb_example add command -label Menu-1
  $vars(mainW).mb_example add command -label Menu-2
  $vars(mainW).mb_example add cascade -label Cascade \
      -menu $vars(mainW).mb_cascade
  $vars(mainW).mb_example add command -label Exit -command exit
  $vars(mainW).mb add cascade -label Example -menu $vars(mainW).mb_example

  $vars(menucmd) $vars(mainW).mb_b -tearoff 0 -font MenuFont {*}$vars(menuargs)
  $vars(mainW).mb add cascade -label {not in use} -menu $vars(mainW).mb_b -state disabled

  $vars(menucmd) $vars(mainW).mb_widgets -tearoff 0 -font MenuFont {*}$vars(menuargs)
  $vars(mainW).mb_widgets add checkbutton -label checkA -variable ::on
  $vars(mainW).mb_widgets add checkbutton -label checkB -variable ::off
  $vars(mainW).mb_widgets add radiobutton -label radioA -value 0 -variable ::on
  $vars(mainW).mb_widgets add radiobutton -label radioB -value 1 -variable ::on
  $vars(mainW).mb add cascade -label widgets -menu $vars(mainW).mb_widgets

  foreach {w} [list $vars(mainW).mb $vars(mainW).mb_example \
      $vars(mainW).mb_widgets $vars(mainW).mb_cascade] {
    confMenu $w
  }

  ::ttk::style configure TFrame -borderwidth 0

  ::ttk::notebook $vars(mainW).nb
  pack $vars(mainW).nb -side left -fill both -expand true
  ::ttk::frame $vars(mainW).one
  $vars(mainW).nb add $vars(mainW).one -text $vars(theme)
  ::ttk::frame $vars(mainW).two
  $vars(mainW).nb add $vars(mainW).two -text {Text w/scroll}
  ::ttk::frame $vars(mainW).three
  $vars(mainW).nb add $vars(mainW).three -text {Paned Window}
  ::ttk::frame $vars(mainW).four
  $vars(mainW).nb add $vars(mainW).four -text {Treeview}
  ::ttk::frame $vars(mainW).five
  $vars(mainW).nb add $vars(mainW).five -text {Buttons/Other}
  ::ttk::frame $vars(mainW).six
  $vars(mainW).nb add $vars(mainW).six -text {Listbox}
  if { ! $vars(notable) && $vars(havetablelist) } {
    ::ttk::frame $vars(mainW).seven
    $vars(mainW).nb add $vars(mainW).seven -text {Table List}
    set ::argv $vars(mainW).seven
    try {
      source $vars(tablelistdemofn)
    } on error {err res} {
      $vars(mainW).nb forget $vars(mainW).seven
      set vars(havetablelist) false
    }
    set ::argv {}
  }

  ::ttk::frame $vars(mainW).nine
  $vars(mainW).nb add $vars(mainW).nine -text {Inactive} -state disabled

  # configure the labelframe font to match what MacOS does.
  ::ttk::style configure TLabelframe.Label -font TkSmallCaptionFont

  ::ttk::labelframe $vars(mainW).lfn \
      -text " Normal "
  ::ttk::labelframe $vars(mainW).lfd \
      -text " Disabled "
  $vars(mainW).lfd state disabled
  foreach {k} {n d} {
    set s !disabled
    if { $k eq "d" } {
      set s disabled
    }
    set row 0
    ::ttk::label $vars(mainW).lb$k -text $vars(theme) -state $s
    ::ttk::button $vars(mainW).b$k -text $vars(theme) -state $s
    grid $vars(mainW).lb$k $vars(mainW).b$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p -columnspan 2
    incr row

    ::ttk::combobox $vars(mainW).combo$k \
        -values \
        [list $vars(theme) aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp] \
        -textvariable vars(valb) \
        -width 15 \
        -state $s \
        -height 5 \
        -font TkDefaultFont

    ::ttk::combobox $vars(mainW).comboro$k -values \
        [list $vars(theme) aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp] \
        -textvariable vars(valb) \
        -width 15 \
        -height 5 \
        -font TkDefaultFont
    $vars(mainW).comboro$k state [list readonly $s]
    option add *TCombobox*Listbox.font TkDefaultFont
    grid $vars(mainW).combo$k $vars(mainW).comboro$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p
    grid configure $vars(mainW).combo$k -columnspan 2
    grid configure $vars(mainW).comboro$k -columnspan 2 -column 2

    ::ttk::checkbutton $vars(mainW).cboff$k -text off -variable ::off -state $s
    ::ttk::checkbutton $vars(mainW).cbon$k -text on -variable ::on -state $s
    grid $vars(mainW).cboff$k $vars(mainW).cbon$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p
    incr row
    if { $vars(havecbt) } {
      ::ttk::checkbutton $vars(mainW).cbtoff$k -variable ::off -state $s \
          -style Toggle.TCheckbutton
      ::ttk::checkbutton $vars(mainW).cbton$k -variable ::on -state $s \
          -style Toggle.TCheckbutton
      grid $vars(mainW).cbtoff$k $vars(mainW).cbton$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p
      incr row
    }

    ::ttk::separator $vars(mainW).sep$k
    grid $vars(mainW).sep$k -in $vars(mainW).lf$k -sticky ew -padx 3p -pady 3p -columnspan 4
    incr row

    ::ttk::radiobutton $vars(mainW).rboff$k -text off -variable ::on -value 0 -state $s
    ::ttk::radiobutton $vars(mainW).rbon$k -text on -variable ::on -value 1 -state $s
    grid $vars(mainW).rboff$k $vars(mainW).rbon$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p
    incr row

    grid columnconfigure $vars(mainW).lf$k 4 -weight 1

    ::ttk::scale $vars(mainW).sc$k \
        -from 0 \
        -to 100 \
        -variable vars(val) \
        -orient horizontal \
        -length [expr {round(100*$vars(scalefactor))}]
    $vars(mainW).sc$k state $s
    grid $vars(mainW).sc$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p -columnspan 2
    incr row

    if { $s ne "disabled" } {
      ::ttk::progressbar $vars(mainW).pb$k \
          -orient horizontal \
          -mode determinate \
          -variable vars(val) \
          -length [expr {round(100*$vars(scalefactor))}]
      $vars(mainW).pb$k state $s
    }
    ::ttk::scale $vars(mainW).scv$k \
        -orient vertical \
        -from 100 \
        -to 0 \
        -variable vars(val) \
        -length [expr {round(100*$vars(scalefactor))}]
    $vars(mainW).scv$k state $s
    if { $s ne "disabled" } {
      ::ttk::progressbar $vars(mainW).pbv$k \
          -orient vertical \
          -mode determinate \
          -variable vars(val) \
          -length [expr {round(100*$vars(scalefactor))}]
      $vars(mainW).pbv$k state $s
    }
    if { $s ne "disabled" } {
      grid $vars(mainW).pb$k $vars(mainW).scv$k $vars(mainW).pbv$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p
      grid configure $vars(mainW).pb$k -columnspan 2
      grid configure $vars(mainW).pbv$k -rowspan 3 -column 3
    } else {
      grid $vars(mainW).scv$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p
    }
    incr row
    grid configure $vars(mainW).scv$k -rowspan 3 -column 2

    ::ttk::entry $vars(mainW).ent$k -textvariable ::vars(bgentry) \
        -width 15 \
        -state $k \
        -font TkDefaultFont
    trace add variable ::vars(bgentry) write setbg
    incr row
    grid $vars(mainW).ent$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p -columnspan 2 -row $row

    ::ttk::spinbox $vars(mainW).sbox$k -textvariable vars(val) \
        -width 5 \
        -from 1 -to 100 -increment 0.1 \
        -state $k \
        -font TkDefaultFont
    grid $vars(mainW).sbox$k -in $vars(mainW).lf$k -sticky w -padx 3p -pady 3p -columnspan 2
    incr row
  }
  set tag {(with tksvg)}
  if { $::notksvg || ! $vars(havetksvg) } {
    set tag {(without tksvg)}
  }
  $vars(mainW).lbn configure -text "$vars(theme) $tag"

  pack $vars(mainW).lfn $vars(mainW).lfd -in $vars(mainW).one -side left -padx 3p -pady 3p -expand 1 -fill both

  if { $vars(havetksvg) && ! $::notksvg && $vars(sizegrip) } {
    set sgdata {
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <!-- Created with Inkscape (http://www.inkscape.org/) -->

    <svg
       xmlns:dc="http://purl.org/dc/elements/1.1/"
       xmlns:cc="http://creativecommons.org/ns#"
       xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
       xmlns:svg="http://www.w3.org/2000/svg"
       xmlns="http://www.w3.org/2000/svg"
       xmlns:xlink="http://www.w3.org/1999/xlink"
       xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
       xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
       width="18"
       height="18"
       viewBox="0 0 18 18"
       version="1.1"
       id="svg8"
       inkscape:version="0.92.4 (5da689c313, 2019-01-14)"
       sodipodi:docname="sizegrip-base.svg">
      <defs
         id="defs2">
        <linearGradient
           inkscape:collect="always"
           id="linearGradient838">
          <stop
             style="stop-color:#ffffff;stop-opacity:1"
             offset="0"
             id="stop834" />
          <stop
             style="stop-color:#0000ff;stop-opacity:1"
             offset="1"
             id="stop836" />
        </linearGradient>
        <linearGradient
           inkscape:collect="always"
           xlink:href="#linearGradient838"
           id="linearGradient840"
           x1="3.7895701"
           y1="295.77591"
           x2="4.0541534"
           y2="296.04047"
           gradientUnits="userSpaceOnUse"
           gradientTransform="translate(-2.8763581e-8,5.0434905e-6)" />
        <linearGradient
           inkscape:collect="always"
           xlink:href="#linearGradient838"
           id="linearGradient848"
           x1="3.1750002"
           y1="295.0546"
           x2="3.4395835"
           y2="295.31915"
           gradientUnits="userSpaceOnUse"
           gradientTransform="translate(0.61456997,0.72132033)" />
      </defs>
      <sodipodi:namedview
         id="base"
         pagecolor="#ffffff"
         bordercolor="#666666"
         borderopacity="1.0"
         inkscape:pageopacity="0.0"
         inkscape:pageshadow="2"
         inkscape:zoom="19.833333"
         inkscape:cx="9.0000002"
         inkscape:cy="9.0000002"
         inkscape:document-units="px"
         inkscape:current-layer="layer1"
         showgrid="true"
         inkscape:window-width="1214"
         inkscape:window-height="532"
         inkscape:window-x="86"
         inkscape:window-y="25"
         inkscape:window-maximized="0"
         scale-x="1.1"
         units="px"
         inkscape:pagecheckerboard="true"
         fit-margin-top="0"
         fit-margin-left="-0.1"
         fit-margin-right="0"
         fit-margin-bottom="0"
         inkscape:snap-nodes="false"
         showguides="false">
        <inkscape:grid
           type="xygrid"
           id="grid843"
           originx="-1.6121707"
           originy="0.26814652" />
      </sodipodi:namedview>
      <metadata
         id="metadata5">
        <rdf:RDF>
          <cc:Work
             rdf:about="">
            <dc:format>image/svg+xml</dc:format>
            <dc:type
               rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
            <dc:title></dc:title>
          </cc:Work>
        </rdf:RDF>
      </metadata>
      <g
         inkscape:label="Layer 1"
         inkscape:groupmode="layer"
         id="layer1"
         transform="translate(-1.6121707,-293.47064)">
        <circle
           style="opacity:1;fill:_SZGRIP_;fill-opacity:1;stroke:_SZGRIP_;stroke-width:0;stroke-linecap:square;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0;paint-order:normal"
           id="path827"
           cx="17.398338"
           cy="309.25586"
           r="1.9999994" />
        <circle
           style="opacity:1;fill:_SZGRIP_;fill-opacity:1;stroke:_SZGRIP_;stroke-width:0;stroke-linecap:square;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0;paint-order:normal"
           id="path827-3"
           cx="-12.711312"
           cy="309.25586"
           transform="scale(-1,1)"
           r="1.9999994" />
        <circle
           style="opacity:1;fill:_SZGRIP_;fill-opacity:1;stroke:_SZGRIP_;stroke-width:0;stroke-linecap:square;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0;paint-order:normal"
           id="path827-6"
           cx="17.398474"
           cy="304.56882"
           r="1.9999994" />
        <circle
           style="opacity:1;fill:_SZGRIP_;fill-opacity:1;stroke:_SZGRIP_;stroke-width:0;stroke-linecap:square;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0;paint-order:normal"
           id="path827-3-7"
           cx="8.0244226"
           cy="309.25574"
           r="1.9999994" />
        <circle
           style="opacity:1;fill:_SZGRIP_;fill-opacity:1;stroke:_SZGRIP_;stroke-width:0;stroke-linecap:square;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0;paint-order:normal"
           id="path827-3-5"
           cx="12.711312"
           cy="304.56894"
           r="1.9999994" />
        <circle
           style="opacity:1;fill:_SZGRIP_;fill-opacity:1;stroke:_SZGRIP_;stroke-width:0;stroke-linecap:square;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0;paint-order:normal"
           id="path827-3-3"
           cx="17.398474"
           cy="299.88174"
           r="1.9999994" />
      </g>
    </svg>
    }

    set elsizegrip false
    set sgimg {}
    if { [regexp {^aqua(light|dark)?$} $vars(theme)] &&
        $vars(havetksvg) } {
      catch { package require colorutils }
    }

    if { [regexp {^aqua(light|dark)?$} $vars(theme)] &&
        ! $elsizegrip &&
        ! [catch {package present colorutils}] } {
      # aqua doesn't have a good sizegrip
      regsub -all _SZGRIP_ $sgdata \
          [::colorutils::rgbToHexStr \
          [winfo rgb $vars(mainW) systemControlAccentColor] 2] \
          sgdata
      set sgimg [image create photo -data $sgdata -format svg]
      ::ttk::style element create new.sizegrip image $sgimg
      set elsizegrip true
    }
    if { ! $elsizegrip &&
        ([info commands ::ttk::theme::${vars(theme)}::hasImage] eq {} ||
        ! [::ttk::theme::${vars(theme)}::hasImage sizegrip]) } {
      set tcol #000000
      # for dark themes, set tcol to a bright yellow
      regsub -all _SZGRIP_ $sgdata $tcol sgdata
      set sgimg [image create photo -data $sgdata -format svg]
      ::ttk::style element create new.sizegrip image $sgimg
      set elsizegrip true
    }
    if { $elsizegrip } {
      set sglayout [::ttk::style layout TSizegrip]
      regsub {Sizegrip\.sizegrip} $sglayout new.sizegrip sglayout
      ::ttk::style layout TSizegrip $sglayout
    }
  }

  ::ttk::sizegrip  $vars(mainW).sg
  pack $vars(mainW).sg -in $vars(mainW).one -side right -anchor se

  set w $vars(mainW).two
  ::ttk::button $w.wrap -text Wrap -command twrap
  pack $w.wrap -in $w -side bottom -anchor se
  # change borderwidth to 1 for color testing
  foreach {nm} [list textdisabled textenabled] {
    ::ttk::frame $w.${nm}frame
    pack $w.${nm}frame -expand 1 -fill both -side top
    if { [regexp {^aqua(light|dark)?$} $vars(theme)] } {
      ::ttk::scrollbar $w.${nm}sbv \
          -command [list $w.${nm} yview]
      ::ttk::scrollbar $w.${nm}sbh \
          -orient horizontal \
          -command [list $w.${nm} xview]
    } else {
      ::ttk::scrollbar $w.${nm}sbv \
          -command [list $w.${nm} yview] \
          -style Vertical.TScrollbar
      ::ttk::scrollbar $w.${nm}sbh \
          -orient horizontal \
          -command [list $w.${nm} xview] \
          -style Horizontal.TScrollbar
    }
    pack $w.${nm}sbv -in $w.${nm}frame \
        -side right -fill y -expand false
    pack $w.${nm}sbh -in $w.${nm}frame \
        -side bottom -fill x -expand false
    text $w.$nm \
        -xscrollcommand [list $w.${nm}sbh set] \
        -yscrollcommand [list $w.${nm}sbv set] \
        -wrap none \
        -height 5 \
        -relief flat \
        -width 50 \
        -highlightthickness 1 \
        -font TextFont
    $w.${nm} insert end {
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis non velit aliquam, malesuada nisi blandit, pellentesque ligula. Pellentesque convallis pulvinar justo ac blandit. Praesent scelerisque, risus vitae rhoncus feugiat, metus ante feugiat leo, sit amet iaculis dui urna vitae purus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Mauris mollis libero at ipsum mollis, non aliquet nunc porta. Mauris auctor lobortis neque, at ullamcorper elit porttitor a. Aliquam eu porttitor ante. Sed arcu dolor, pretium non diam in, imperdiet pellentesque ipsum. Quisque sollicitudin nisl ex, sodales scelerisque nunc consequat volutpat. Vestibulum aliquet augue mauris, sit amet commodo urna consectetur interdum. Aenean dignissim tellus eu sollicitudin porta. Aliquam accumsan vel leo non iaculis. Sed pharetra, tortor non malesuada pellentesque, felis magna tempor turpis, nec tincidunt justo erat in justo. Aliquam congue, lectus nec pulvinar euismod, enim lorem venenatis tellus, vitae placerat magna ligula in leo. Praesent nisl lectus, ornare tristique consequat egestas, fermentum a urna. Morbi metus nulla, convallis ac orci a, imperdiet pretium purus.

Aenean tincidunt dui lacinia urna sagittis bibendum. Maecenas eu vestibulum tellus, viverra tincidunt mi. Sed sollicitudin mattis mi, quis pellentesque urna. Ut auctor ligula eu lectus imperdiet, sed tempus massa tristique. Curabitur ac eros euismod, pellentesque sapien eget, pretium justo. Aliquam quis turpis nec tellus vehicula maximus vel ac urna. Proin efficitur purus erat, sed tristique enim faucibus ac. Nullam hendrerit tempor tincidunt. Duis id dolor enim.

Quisque malesuada volutpat ex, id porta sem. Cras tristique tellus eget urna tincidunt ultrices. Nunc mollis consectetur odio a ultrices. Morbi sed imperdiet odio. In hac habitasse platea dictumst. Mauris tellus dui, pretium sed dolor sit amet, accumsan pretium est. Donec eu libero in felis suscipit ultrices et nec magna. Nunc accumsan quam sem, ut pharetra mauris dapibus id. Sed mi quam, consectetur eu iaculis luctus, viverra gravida neque. Proin vel maximus nunc.

Phasellus non ultricies mi. Aliquam erat volutpat. Ut sed mollis felis, nec imperdiet sapien. Etiam id lacus at augue tempus malesuada. Cras vel est ac metus tempus dictum. Aliquam metus tortor, rutrum nec blandit id, dapibus quis felis. Nulla viverra sit amet est ac gravida. Phasellus ac vestibulum turpis. Proin dictum viverra lobortis.

Pellentesque commodo tellus ut semper consectetur. Praesent lacus sem, porta sit amet ligula vel, varius mattis ipsum. Praesent erat nisl, vulputate ut ultricies quis, accumsan sit amet diam. Nulla tempor, nunc in malesuada venenatis, purus erat blandit lectus, sit amet pretium arcu arcu id erat. Donec ante eros, sagittis nec tellus eget, porta faucibus nisl. Integer a ex sed felis varius finibus. In hac habitasse platea dictumst. Proin et nisl orci. Fusce mauris nulla, feugiat sit amet commodo viverra, posuere sit amet augue. Vestibulum congue ligula nec dolor dapibus scelerisque. Proin enim sem, congue et nibh nec, suscipit cursus ligula.
}
    if { $nm eq "textdisabled" } {
      $w.${nm} insert 0.0 "state disabled\n\n"
      $w.${nm} configure -state disabled
    } else {
      $w.${nm} insert 0.0 "state normal\n\n"
      $w.${nm} configure -state normal
    }
    if { ! $vars(optiondb) && ! $vars(optionnone) &&
        [info commands ::ttk::theme::${vars(theme)}::setTextColors] ne {} } {
      ::ttk::theme::${vars(theme)}::setTextColors $w.${nm}
    }
    bind $w.${nm} <MouseWheel> {%W yview scroll [expr {int(pow(-%D/240,3))}] units}
    pack $w.${nm} -in $w.${nm}frame -fill both -expand true
  }

  ::ttk::panedwindow $vars(mainW).pw -orient horizontal
  if { [info commands ::ttk::theme::${vars(theme)}::setBackground] eq {} } {
    ::ttk::style configure TPanedwindow -background \
        [::ttk::style lookup TNotebook.Tab -background]
  }
  pack $vars(mainW).pw -in $vars(mainW).three -fill both -expand true
  set ftype ::ttk::frame
  if { [regexp {^aqua(light|dark)?$} $vars(theme)] } {
    set ftype ::ttk::labelframe
  }
  $ftype $vars(mainW).p1
  $ftype $vars(mainW).p2
  $vars(mainW).pw add $vars(mainW).p1
  $vars(mainW).pw add $vars(mainW).p2
  ::ttk::label $vars(mainW).pl1 -text {Pane 1}
  ::ttk::label $vars(mainW).pl2 -text {Pane 2}
  pack $vars(mainW).pl1 -in $vars(mainW).p1 -anchor nw
  pack $vars(mainW).pl2 -in $vars(mainW).p2 -anchor ne

  ::ttk::style configure Treeview \
      -rowheight [expr {[font metrics TkDefaultFont -linespace] + 2}] \
      -fieldbackground [::ttk::style lookup Treeview -background] \
      -borderwidth 0 \
      -relief flat
  ::ttk::style configure Heading -relief raised
  # do not want the focus ring.
  # removing it entirely fixes it on both linux and windows.
  set l [::ttk::style layout Item]
  if { [regsub "Treeitem.focus.*?-children \{" $l {} l] } {
    regsub "\}$" $l {} l
  }
  ::ttk::style layout Item $l
  ::ttk::treeview $vars(mainW).tv -columns {a b c}
  pack $vars(mainW).tv -in $vars(mainW).four -fill both -expand true
  $vars(mainW).tv heading #0 -text #0
  $vars(mainW).tv heading a -text AAA
  $vars(mainW).tv heading b -text BBB
  $vars(mainW).tv heading c -text CCC
  set id [$vars(mainW).tv insert {} 0 -text {item 0} -values {a b c}]
  $vars(mainW).tv insert $id 0 -text {subitem 0-1} -values {aa bb cc}
  $vars(mainW).tv insert $id 1 -text {subitem 0-2} -values {dd ee ff}
  $vars(mainW).tv insert $id 2 -text {subitem 0-3} -values {gg hh ii}
  set id [$vars(mainW).tv insert {} 1 -text {item 1} -values {j k l}]
  $vars(mainW).tv insert $id 0 -text {subitem 1-1} -values {mm nn oo}
  $vars(mainW).tv insert $id 1 -text {subitem 1-2} -values {pp qq rr}
  $vars(mainW).tv insert $id 2 -text {subitem 1-3} -values {ss tt uu}
  set id [$vars(mainW).tv insert {} 2 -text {item 2} -values {v w x}]
  $vars(mainW).tv insert $id 0 -text {subitem 2-1} -values {y y y}
  $vars(mainW).tv insert $id 1 -text {subitem 2-2} -values {z z z}
  $vars(mainW).tv insert $id 2 -text {subitem 2-3} -values {& & &}

  ::ttk::labelframe $vars(mainW).five.menubar -text { Menu Buttons }
  grid $vars(mainW).five.menubar -sticky nw -pady 2p -padx 3p

  ::ttk::menubutton $vars(mainW).five.menubar.file -text File \
      -underline 0 -menu $vars(mainW).menubar_file_m
  ::ttk::menubutton $vars(mainW).five.menubar.edit -text Edit \
      -underline 0 -menu $vars(mainW).menubar_edit_m
  ::ttk::menubutton $vars(mainW).five.menubar.dis -text Disabled \
      -underline 0 -menu $vars(mainW).menubar_dis_m -state disabled

  $vars(menucmd) $vars(mainW).menubar_file_m -tearoff 0  -font MenuFont {*}$vars(menuargs)
  $vars(mainW).menubar_file_m add command -label "Exit" \
      -underline 1 -command exit
  confMenu $vars(mainW).menubar_file_m

  $vars(menucmd) $vars(mainW).menubar_edit_m -tearoff 0  -font MenuFont {*}$vars(menuargs)
  $vars(mainW).menubar_edit_m add command -label "Cut" \
      -underline 2 \
      -command {puts cut}
  $vars(mainW).menubar_edit_m add command -label "Copy" \
      -underline 0 \
      -command {puts copy}
  $vars(mainW).menubar_edit_m add command -label "Paste" \
      -command {puts paste}
  confMenu $vars(mainW).menubar_edit_m

  $vars(menucmd) $vars(mainW).menubar_dis_m -tearoff 0 -font MenuFont {*}$vars(menuargs)
  confMenu $vars(mainW).menubar_dis_m

  ::ttk::labelframe $vars(mainW).five.tb -text { Toolbuttons }
  ::ttk::button $vars(mainW).five.tb.tba -text {Toolbutton A} -style Toolbutton
  ::ttk::button $vars(mainW).five.tb.tbb -text {TB-B} -style Toolbutton
  ::ttk::button $vars(mainW).five.tb.tbc -text {Toolbutton C} -style Toolbutton -state disabled

  grid $vars(mainW).five.menubar.file \
      $vars(mainW).five.menubar.edit \
      $vars(mainW).five.menubar.dis \
      -sticky w -padx 1p -pady 1p

  grid $vars(mainW).five.tb -sticky nw -pady 2p -padx 3p
  grid $vars(mainW).five.tb.tba \
      $vars(mainW).five.tb.tbb \
      $vars(mainW).five.tb.tbc \
      -sticky w  -padx 1p -pady 1p

  ::ttk::labelframe $vars(mainW).five.cbf -text { Checkbutton with Toolbutton Style }
  grid $vars(mainW).five.cbf -sticky nw -pady 2p -padx 3p
  ::ttk::checkbutton $vars(mainW).five.cbf.cbtb -text { Checkbutton as Toolbutton } -style Toolbutton
  grid $vars(mainW).five.cbf.cbtb -sticky w  -padx 1p -pady 1p

  ::ttk::labelframe $vars(mainW).five.cbbig -text { Combobox With Big Font }
  grid $vars(mainW).five.cbbig -sticky nw -pady 2p -padx 3p
  font create BigFont
  font configure BigFont -size [expr {${vars(fontsize)}*2}]
  ::ttk::combobox $vars(mainW).comboBig \
      -values \
      [list $vars(theme) aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp] \
      -textvariable vars(valb) \
      -width 15 \
      -height 5 \
      -font BigFont
  pack $vars(mainW).comboBig -in $vars(mainW).five.cbbig -padx 3p -pady 3p -side left

  ::ttk::scrollbar $vars(mainW).sblbox1 -command [list $vars(mainW).lbox1 yview]
  ::ttk::scrollbar $vars(mainW).sblbox2 -command [list $vars(mainW).lbox2 yview]
  set ::lbox [list $vars(theme) aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt uuu vvv www xxx yyy zzz]
  # change borderwidth to 1 for color testing
  listbox $vars(mainW).lbox1 \
      -listvariable ::lbox \
      -yscrollcommand [list $vars(mainW).sblbox1 set] \
      -borderwidth 0 \
      -highlightthickness 1p \
      -font TextFont \
      -relief sunken
  listbox $vars(mainW).lbox2 \
      -listvariable ::lbox \
      -yscrollcommand [list $vars(mainW).sblbox2 set] \
      -borderwidth 1p \
      -highlightthickness 1p \
      -font TextFont \
      -relief sunken
  $vars(mainW).lbox2 configure -state disabled

  if { ! $vars(optiondb) && ! $vars(optionnone) &&
      [info commands ::ttk::theme::${vars(theme)}::setListboxColors] ne {} } {
    ::ttk::theme::${vars(theme)}::setListboxColors $vars(mainW).lbox1
    ::ttk::theme::${vars(theme)}::setListboxColors $vars(mainW).lbox2
  }
  pack $vars(mainW).lbox1 -in $vars(mainW).six -padx 3p -pady 3p -expand true -fill both -side left
  pack $vars(mainW).sblbox1 -in $vars(mainW).six -padx 0 -pady 3p -fill y -side left
  pack $vars(mainW).lbox2 -in $vars(mainW).six -padx 3p -pady 3p -expand true -fill both -side left
  pack $vars(mainW).sblbox2 -in $vars(mainW).six -padx 0 -pady 3p -fill y -side left

  wm protocol $vars(mainW) WM_DELETE_WINDOW [list ::exit]

  # various widgets from the mac_styles branch for Mac OS
  if { $vars(macstyles) && $::tcl_platform(os) eq "Darwin" } {
    # unmute
    set imgdata {
       iVBORw0KGgoAAAANSUhEUgAAABwAAAAZCAYAAAAiwE4nAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
       AAAbrwAAG68BXhqRHAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAMoSURB
       VEiJtZVPbFRVFIe/c+97pWClxT8Y40DBaKILQWwloQzNuCBsmpBIajTERKkzICZUmILRjeNGpUxH
       MYHEmaaEEBaGEEQNITGSQt8ILlgZggY2agUTiFCpte28uccFxbCgM9Ox81ve8zvnu+e+c98V/ocS
       Lal5Ou/vLKodBnn582DPyXI5plrYG7FdEZ07OoTqRqDRoWsryfOqgXW171hhQndcYdG94lvaehYW
       Letv/tlw8MiF1OTdsRl3GF+d3Gic+X46GICzEkHJLFgwen5TdPvj1QIlEe1JIXIIqJ/O9Hr7jkXg
       FtvQe0bRMYsNutqSzTMCbo1tbYhHe44qvA9IKa8t8piqZIteMet7Zj1wxYocS8VSHoCXaEn47r75
       EeeK9yzkiddUCPUAsKySzfXnM+e6Vm1/ylj7VSFkQA2dOH78PRzdBmQkHk3+ALKykmJllAnF/9jT
       wiVR3ecX6jKTdeEFRN/GydOIxuvvn1hqZgkGwIGhj64J2qEiWybrCu2gn6jjTau6D3h4/C9/XdX3
       cDplg75ARHYD3b4nB0VYNWmKDYqcRkzHrAMBBPcN0Gbnjt8A+cmoeVbgLNBSE6CO3boEmPFbfjPo
       ZWPME6LusgrNNQFmz2cLgEN9H7iuqg84IzdFaawJ8LVYqh7w1BbHgIdQuS6OOcBETYB1buRJoDDy
       yC+/gjwquGsIEYSrtfmGznsJ+G7+cKQRtNVZOQMsV+XirAMTq3e9ANptkM+sZ14EuXi7U9ainDII
       J2YL9tbKdx9UcV8L8mFBJa8qKeDTxitL1gELi9YdLfkjhtsPrYTuS6CljDWTC9JJgM7OTtt0dckh
       0MW5IN0ejybPCjKcDdIbyh5p/2DvsO+NxYBjZVucUtMfzScQfT407pXEmmQ3yPJQzXtQ4fO0f3D/
       aC5IbxD4ANByfnUyIHNsq+dMq6rsBn1nIN/7c8XAO3WyQTqF6qvAeCljf37PF0y4zcARhL25oG/v
       ndiMpzSX7zvsjGsT+K3k7mCZKptzQ+mdd6+XHZrpNDVMx4Hnppb+G5pSqvoe9g/2Dss/DWsQOQyM
       GOTbSvL+BWexMdZ81ssiAAAAAElFTkSuQmCC
    }
    set img [image create photo -data $imgdata -format png]

    foreach {k} {n d} {
      set s !disabled
      if { $k eq "d" } {
        set s disabled
      }
      ::ttk::frame $vars(mainW).dbf$k

      ::ttk::style configure InlineButton -font MenuFont
      ::ttk::button $vars(mainW).dbib$k -text $vars(theme) \
          -state $s -style InlineButton

      ::ttk::style configure ImageButton -font MenuFont
      ::ttk::button $vars(mainW).dbimg$k \
          -text unmute -image $img -state $s -style ImageButton

      ::ttk::style configure RecessedButton -font MenuFont
      ::ttk::button $vars(mainW).dbrb$k \
          -text $vars(theme) -state $s -style RecessedButton

      ::ttk::style configure RoundedRectButton -font MenuFont
      ::ttk::button $vars(mainW).dbrr$k -text $vars(theme) \
          -state $s -style RoundedRectButton

      ::ttk::style configure DisclosureButton -font MenuFont
      ::ttk::button $vars(mainW).dbdisc$k \
          -state $s -style DisclosureButton

      ::ttk::style configure GradientButton -font MenuFont
      ::ttk::button $vars(mainW).dbg$k -text $vars(theme) \
          -state $s -style GradientButton

      ::ttk::button $vars(mainW).dbhelp$k \
          -state $s -style HelpButton

      grid $vars(mainW).dbib$k $vars(mainW).dbimg$k $vars(mainW).dbrb$k \
          -in $vars(mainW).five -sticky w -padx 3p -pady 3p
      grid $vars(mainW).dbrr$k $vars(mainW).dbdisc$k $vars(mainW).dbg$k \
          $vars(mainW).dbhelp$k \
          -in $vars(mainW).five -sticky w -padx 3p -pady 3p
    }
  }
}

::main
