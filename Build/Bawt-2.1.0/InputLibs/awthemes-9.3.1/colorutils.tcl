#!/usr/bin/tclsh
#
# Copyright 2012-2018 Brad Lanam Walnut Creek CA USA
# Copyright 2020 Brad Lanam Pleasant Hill CA
#
# Algorithms from:
# http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
# http://www.easyrgb.com/index.php?X=MATH&H=02#text2
# http://www.brucelindbloom.com/
# http://en.wikipedia.org/wiki/CIELUV
# https://stackoverflow.com/questions/726549/algorithm-for-additive-color-mixing-for-rgb-values#727339

# don't force Tk to be required
#package require Tk

package provide colorutils 4.8

namespace eval ::colorutils {
  variable vars

  set vars(onethird) [expr {1.0/3.0}]
  set vars(twothirds) [expr {2.0/3.0}]

  # this routine assumes the colors in the range 0-255
  proc perceivedLuminosity { clist } {
    if { [regexp {^#} $clist] } {
      lassign [hexStrToRgb $clist] r g b sz
      set div 65535.0
      if { $sz != 4 } {
        set div [expr {65536.0/(16.0**$sz)-1.0}]
      }
    } else {
      lassign $clist r g b
      set div 255.0
    }
    set r [expr {double($r)/$div}]
    set g [expr {double($g)/$div}]
    set b [expr {double($b)/$div}]
    # http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
    set l [expr {0.299*$r+0.587*$g+0.114*$b}]
    return $l
  }

  # this routine assumes the colors in the range 0-255
  proc luminosity { clist } {
    if { [regexp {^#} $clist] } {
      lassign [hexStrToRgb $clist] r g b sz
      set div 65535.0
      if { $sz != 4 } {
        set div [expr {65536.0/(16.0**$sz)-1.0}]
      }
    } else {
      lassign $clist r g b
      set div 255.0
    }
    set r [expr {double($r)/$div}]
    set g [expr {double($g)/$div}]
    set b [expr {double($b)/$div}]
    # http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
    set l [expr {0.2126*$r+0.7152*$g+0.0722*$b}]
    return $l
  }

  # adjust the color 'col'
  # based on the difference between 'oldcol' and 'newcol'
  proc adjustColor { col oldcol newcol {sz 4} } {
    lassign [winfo rgb . $col] rc gc bc
    lassign [winfo rgb . $oldcol] ro go bo
    lassign [winfo rgb . $newcol] rn gn bn

    # handle white and black.
    if { ($rc == 0 && $gc == 0 && $bc == 0) ||
        ($rc == 65535 && $gc == 65535 && $bc == 65535) } {
      return [rgbToHexStr [list $rc $gc $bc] $sz]
    }

    # 0.3 * 65535 = 19661
    # 0.2 * 65535 = 13107
    # 0.1 * 65535 = 6553
    set fga 19661
    set bga [expr {65535-$fga}]

    # assuming an 70% foreground, 30% background blend, do
    # a reverse transform to get a color based on the old background.
    set rorig [expr {abs(((65535 * $rc) - $ro * $bga) / $fga)}]
    set gorig [expr {abs(((65535 * $gc) - $go * $bga) / $fga)}]
    set borig [expr {abs(((65535 * $bc) - $bo * $bga) / $fga)}]

    # and then blend it back together with the new background.
    set rnew [expr {($rn * $bga + $rorig * $fga) / 65535}]
    set gnew [expr {($gn * $bga + $gorig * $fga) / 65535}]
    set bnew [expr {($bn * $bga + $borig * $fga) / 65535}]
    return [rgbToHexStr [list $rnew $gnew $bnew] $sz]
  }

  proc opaqueblend { fg bg fga {sz 4} } {
    variable vars

    # caching winfo rgb does not help
    lassign [winfo rgb . $fg] rf gf bf
    lassign [winfo rgb . $bg] rb gb bb

    set bga [expr {65535-$fga}]
    set rn [expr {($rb * $bga + $rf * $fga) / 65535}]
    set gn [expr {($gb * $bga + $gf * $fga) / 65535}]
    set bn [expr {($bb * $bga + $bf * $fga) / 65535}]
    return [rgbToHexStr [list $rn $gn $bn] $sz]
  }

  proc opaqueBlendPerc { fg bg perc {sz 4} } {
    set fga [expr {round(65535.0*$perc)}]
    return [opaqueblend $fg $bg $fga $sz]
  }

  proc lightenColor { col {sz 4} } {
    # 0.8 * 65535 = 52428
    return [opaqueblend $col #ffffff 52428 $sz]
  }

  proc darkenColor { col {sz 4} } {
    # 0.9 * 65535 = 58982
    return [opaqueblend $col #000000 58982 $sz]
  }

  # blend with the background
  proc disabledColor { col bg {perc 0.6} {sz 4} } {
    set val [expr {round(65535.0*$perc)}]
    return [opaqueblend $col $bg $val $sz]
  }

  proc getLightDarkColors { c } {
    set dcolor [::colorutils::darkenColor $c]
    set ddcolor [::colorutils::darkenColor $dcolor]
    set dddcolor [::colorutils::darkenColor $ddcolor]
    set lcolor [::colorutils::lightenColor $c]
    set llcolor [::colorutils::lightenColor $lcolor]
    if { $llcolor eq "#ffffffffffff" } {
      set llcolor [::colorutils::darkenColor #ffffffffffff]
      set lcolor [::colorutils::darkenColor $lcolor]
      set llcolor [::colorutils::darkenColor $llcolor]
    }
    return [list $dcolor $dddcolor $lcolor $llcolor]
  }


  proc rgbToHexStr { rgblist {sz 4} } {
    set nrgblist [list]
    foreach {i} {0 1 2} {
      set v [lindex $rgblist $i]
      if { ! [regexp {^\d{1,5}$} $v] || $v < 0 || $v > 65535} {
        return ""
      }
      if { $sz != 4 } {
        set div [expr {65536.0/(16.0**$sz)}]
        set v [expr {int(double($v)/$div)}]
      }
      lappend nrgblist $v
    }
    set fmt #%04x%04x%04x
    switch -exact -- $sz {
      4 { set fmt #%04x%04x%04x }
      3 { set fmt #%03x%03x%03x }
      2 { set fmt #%02x%02x%02x }
    }
    set t [format $fmt {*}$nrgblist]
    return $t
  }

  # also returns the colorwidth (2,3,4)
  proc hexStrToRgb { rgbtext } {
    # rgbtext is format: #aabbcc or #aaabbbccc or #aaaabbbbcccc

    set len [string length $rgbtext]
    if { [regexp {^#[[:xdigit:]]{6,12}$} $rgbtext] &&
        ($len == 7 || $len == 10 || $len == 13) } {
      set sfmt #%4x%4x%4x
      set cwidth 4
      switch -exact -- $len {
        7 { set sfmt #%2x%2x%2x; set cwidth 2 }
        10 { set sfmt #%3x%3x%3x; set cwidth 3 }
        14 { set sfmt #%4x%4x%4x; set cwidth 4 }
      }
      scan $rgbtext $sfmt r g b
      return [list $r $g $b $cwidth]
    } else {
      return false
    }
  }

  proc colorToRgbText { col {sz 4} } {
    variable vars

    set clist [winfo rgb . $col]
    return [rgbToHexStr $clist $sz]
  }

  proc toRgbText { vlist {type HSV} {sz 4} } {
    variable vars

    set proc ${type}toRGB
    set rgblist [$proc $vlist]
    return [rgbToHexStr $rgblist $sz]
  }

  proc fromRgbText { rgbtext {type HSV} } {
    variable vars

    set proc RGBto${type}
    set rgblist [hexStrToRgb $rgbtext]
    if { $rgblist != false } {
      return [$proc $rgblist]
    }
    return false
  }

  proc RGBtoDouble { rgblist } {
    set csz [expr {double([lindex $rgblist 3])}]
    set div [expr {(16.0**$csz)-1.0}]
    set r [expr {double([lindex $rgblist 0])/$div}]
    set g [expr {double([lindex $rgblist 1])/$div}]
    set b [expr {double([lindex $rgblist 2])/$div}]
    return [list $r $g $b]
  }

  # RGB

  proc RGBtoRGB { rgblist } {
    return [lrange $rgblist 0 2]
  }

  # HSV

  proc RGBtoHSV { rgblist } {
    lassign [RGBtoDouble $rgblist] r g b
    set max [expr {max($r, $g, $b)}]
    set min [expr {min($r, $g, $b)}]
    set h $max
    set s $max
    set v $max
    set d [expr {$max - $min}]
    if {$max == 0} {
      set s 0
    } else {
      set s [expr {$d / $max}]
    }

    if {$max == $min} {
      set h 0
    } else {
      if { $max == $r } {
        set t 0.0
        if { $g < $b } {
          set t 6.0
        }
        set h [expr {($g - $b) / $d + $t}]
      }
      if { $max == $g } {
        set h [expr {($b - $r) / $d + 2.0}]
      }
      if { $max == $b } {
        set h [expr {($r - $g) / $d + 4.0}]
      }
      set h [expr {$h / 6.0}]
    }
    return [list $h $s $v]
  }

  proc HSVtoRGB { hsvlist } {
    lassign $hsvlist h s v

    set i [expr {int($h * 6.0)}]
    set f [expr {$h * 6.0 - $i}]
    set p [expr {$v * (1.0 - $s)}]
    set q [expr {$v * (1.0 - $f * $s)}]
    set t [expr {$v * (1.0 - (1.0 - $f) * $s)}]

    set im6 [expr {$i % 6}]
    if { $im6 == 0 } {
      set r $v; set g $t; set b $p
    }
    if { $im6 == 1 } {
      set r $q; set g $v; set b $p
    }
    if { $im6 == 2 } {
      set r $p; set g $v; set b $t
    }
    if { $im6 == 3 } {
      set r $p; set g $q; set b $v
    }
    if { $im6 == 4 } {
      set r $t; set g $p; set b $v
    }
    if { $im6 == 5 } {
      set r $v; set g $p; set b $q
    }
    return [list [expr {int(round($r * 65535.0))}] \
        [expr {int(round($g * 65535.0))}] \
        [expr {int(round($b * 65535.0))}]]
  }

  # HSL

  proc RGBtoHSL { rgblist } {
    lassign [RGBtoDouble $rgblist] r g b
    set max [expr {max($r, $g, $b)}]
    set min [expr {min($r, $g, $b)}]
    set l [expr {($max + $min) / 2.0}]

    if { $max == $min } {
      set h 0.0
      set s 0.0
    } else {
      set d [expr {$max - $min}]
      if { $l > 0.5 } {
        set s [expr {$d / (2.0 - $max - $min)}]
      } else {
        set s [expr {$d / ($max + $min)}]
      }
      if {$max == $r } {
        set g2 0.0
        if {$g < $b} { set g2 6.0 }
        set h [expr {($g - $b) / $d + $g2}]
      } elseif {$max == $g} {
        set h [expr {($b - $r) / $d + 2.0}]
      } elseif {$max == $b} {
        set h [expr {($r - $g) / $d + 4.0}]
      }
      set h [expr {$h / 6.0}]
    }

    return [list $h $s $l]
  }

  # used by HSLtoRGB()
  proc hue2rgb {p q t} {
    variable vars

    if {$t < 0.0} { set t [expr {$t + 1.0}] }
    if {$t > 1.0} { set t [expr {$t - 1.0}] }

    if {$t < [expr 1.0/6.0]} { return [expr {$p + ($q - $p) * 6.0 * $t}] }

    if {$t < 0.5} { return $q }

    if {$t < $vars(twothirds)} {
      return [expr {$p + ($q - $p) * ($vars(twothirds) - $t) * 6.0}]
    }
    return $p
  }

  proc HSLtoRGB { hsllist } {
    variable vars

    lassign $hsllist h s l

    if {$s == 0} {
      set r $l
      set g $l
      set b $l
    } else {
      if { $l < 0.5 } {
        set q [expr {$l * (1.0 + $s)}]
      } else {
        set q [expr {$l + $s - ($l * $s)}]
      }
      set p [expr {2.0 * $l - $q}]

      set r [hue2rgb $p $q [expr {$h + $vars(onethird)}]]
      set g [hue2rgb $p $q $h]
      set b [hue2rgb $p $q [expr {$h - $vars(onethird)}]]
    }

    return [list [expr {round($r * 65535.0)}] \
        [expr {round($g * 65535.0)}] \
        [expr {round($b * 65535.0)}]];
  }
}
