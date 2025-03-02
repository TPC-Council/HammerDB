# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

proc ticklecharts::bar3DItem {value} {

    foreach item [dict get $value -dataBar3DItem] {

        if {[llength $item] % 2} {
            error "item list for '[ticklecharts::getLevelProperties [info level]]' must have an even number of elements..."
        }

        if {![dict exists $item value]} {
            error "key 'value' must be present in item '[ticklecharts::getLevelProperties [info level]]'"
        }

        setdef options name       -minversion 5  -validvalue {}  -type str|null     -default "nothing"
        setdef options value      -minversion 5  -validvalue {}  -type list.n|null  -default "nothing"
        setdef options itemStyle  -minversion 5  -validvalue {}  -type dict|null    -default [ticklecharts::itemStyle3D $item]
        setdef options label      -minversion 5  -validvalue {}  -type dict|null    -default [ticklecharts::label3D $item]
        setdef options emphasis   -minversion 5  -validvalue {}  -type dict|null    -default [ticklecharts::emphasis3D $item]

        # remove key(s)...
        set item [dict remove $item itemStyle label emphasis]

        lappend opts [merge $options $item]
        set options {}

    }

    return [list {*}$opts]
}

proc ticklecharts::surfaceItem {value} {

    foreach item [dict get $value -dataSurfaceItem] {

        if {[llength $item] % 2} {
            error "item list for '[ticklecharts::getLevelProperties [info level]]' must have an even number of elements..."
        }

        if {![dict exists $item value]} {
            error "key 'value' must be present in item '[ticklecharts::getLevelProperties [info level]]'"
        }

        setdef options name       -minversion 5  -validvalue {}  -type str|null     -default "nothing"
        setdef options value      -minversion 5  -validvalue {}  -type list.n|null  -default "nothing"
        setdef options itemStyle  -minversion 5  -validvalue {}  -type dict|null    -default [ticklecharts::itemStyle3D $item]

        # remove key(s)...
        set item [dict remove $item itemStyle]

        lappend opts [merge $options $item]
        set options {}

    }

    return [list {*}$opts]
}

proc ticklecharts::line3DItem {value} {

    foreach item [dict get $value -dataLine3DItem] {

        if {[llength $item] % 2} {
            error "item list for '[ticklecharts::getLevelProperties [info level]]' must have an even number of elements..."
        }

        if {![dict exists $item value]} {
            error "key 'value' must be present in item '[ticklecharts::getLevelProperties [info level]]'"
        }

        setdef options name       -minversion 5  -validvalue {}  -type str|null     -default "nothing"
        setdef options value      -minversion 5  -validvalue {}  -type list.n|null  -default "nothing"
        setdef options lineStyle  -minversion 5  -validvalue {}  -type dict|null    -default [ticklecharts::lineStyle3D $item]

        # remove key(s)...
        set item [dict remove $item lineStyle]

        lappend opts [merge $options $item]
        set options {}

    }

    return [list {*}$opts]
}

proc ticklecharts::nameTextStyle3D {value} {

    if {![ticklecharts::keyDictExists "nameTextStyle" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]

    setdef options color        -minversion 5  -validvalue formatColor       -type str|null  -default "nothing"
    setdef options borderWidth  -minversion 5  -validvalue {}                -type num       -default 0
    setdef options borderColor  -minversion 5  -validvalue formatColor       -type str|null  -default "nothing"
    setdef options fontFamily   -minversion 5  -validvalue {}                -type str       -default "sans-serif"
    setdef options fontSize     -minversion 5  -validvalue {}                -type num       -default 12
    setdef options fontWeight   -minversion 5  -validvalue formatFontWeight  -type str|num   -default "normal"
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::axisLine3D {value} {
    variable theme
    variable minProperties

    set levelP [ticklecharts::getLevelProperties [info level]]
    set minP $minProperties

    if {![ticklecharts::keyDictExists "axisLine" $value key]} {
        if {$theme ne "custom" && ![string match "*Item.*" $levelP]} {
            set minProperties 1 ; set key "axisLine"
            dict set value $key {dummy null}
        } else {
            return "nothing"
        }
    }

    set property [string range $levelP 0 6]
        
    if {$property eq "xAxis3D" || $property eq "yAxis3D" || $property eq "zAxis3D"} {
        set levelP [string cat $property [string map {3D ""} [string range $levelP 7 end]]]
    } else {
        set levelP [string map {3D ""} $levelP]
    }

    set show [expr {[keysOptsThemeExists $levelP.show] ? [echartsOptsTheme $levelP.show] : "True"}]
    
    set d [dict get $value $key]

    setdef options show       -minversion 5  -validvalue {}  -type bool.t          -default $show
    setdef options interval   -minversion 5  -validvalue {}  -type num|jsfunc|null -default "nothing"
    setdef options lineStyle  -minversion 5  -validvalue {}  -type dict|null       -default [ticklecharts::lineStyle3D $d]

    # remove key(s)...
    set d [dict remove $d lineStyle]
    
    set options [merge $options $d]
    
    # reset minProperties...
    set minProperties $minP

    if {![dict size $options]} {
        return "nothing"
    } else {
        return [new edict $options]
    }
}

proc ticklecharts::lineStyle3D {value} {
    variable theme
    variable minProperties

    set levelP [ticklecharts::getLevelProperties [info level]]
    set minP $minProperties

    if {![ticklecharts::keyDictExists "lineStyle" $value key]} {
        if {$theme ne "custom" && ![string match "*Item.*" $levelP]} {
            set minProperties 1 ; set key "lineStyle"
            dict set value $key {dummy null}
        } else {
            return "nothing"
        }
    }

    set property [string range $levelP 0 6]
        
    if {$property eq "xAxis3D" || $property eq "yAxis3D" || $property eq "zAxis3D"} {
        set levelP [string cat $property [string map {3D ""} [string range $levelP 7 end]]]
    } else {
        set levelP [string map {3D ""} $levelP]
    }

    set color     [expr {[keysOptsThemeExists $levelP.color] ? [echartsOptsTheme $levelP.color] : "nothing"}]
    set linewidth [expr {[keysOptsThemeExists $levelP.width] ? [echartsOptsTheme $levelP.width] : "nothing"}]
    
    setdef options color    -minversion 5  -validvalue formatColor    -type str.t|list.nt|null  -default $color
    setdef options width    -minversion 5  -validvalue {}             -type num.t|null          -default $linewidth
    setdef options opacity  -minversion 5  -validvalue formatOpacity  -type num|null            -default 1
    #...
    
    set options [merge $options [dict get $value $key]]

    # reset minProperties...
    set minProperties $minP

    if {![dict size $options]} {
        return "nothing"
    } else {
        return [new edict $options]
    }
}

proc ticklecharts::axisLabel3D {value} {

    if {![ticklecharts::keyDictExists "axisLabel" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
        
    setdef options show       -minversion 5  -validvalue {}  -type bool             -default "True"
    setdef options margin     -minversion 5  -validvalue {}  -type num              -default 8
    setdef options interval   -minversion 5  -validvalue {}  -type num|jsfunc|null  -default "nothing"    
    setdef options formatter  -minversion 5  -validvalue {}  -type str|jsfunc|null  -default "nothing"
    setdef options textStyle  -minversion 5  -validvalue {}  -type dict|null        -default [ticklecharts::textStyle3D $d textStyle]
    #...

    # remove key(s)...
    set d [dict remove $d textStyle]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::textStyle3D {value key} {
    variable theme
    variable minProperties

    set levelP [string map [list 3D "" textStyle $key] [ticklecharts::getLevelProperties [info level]]]
    set minP $minProperties

    if {![dict exists $value $key]} {
        if {$theme ne "custom" && ![string match "*Item.*" $levelP]} {
            set minProperties 1
            dict set value $key {dummy null}
        } else {
            return "nothing"
        }
    }

    set color      [expr {[keysOptsThemeExists $levelP.color]      ? [echartsOptsTheme $levelP.color] : "nothing"}]
    set fontSize   [expr {[keysOptsThemeExists $levelP.fontSize]   ? [echartsOptsTheme $levelP.fontSize] : "nothing"}]
    set fontWeight [expr {[keysOptsThemeExists $levelP.fontWeight] ? [echartsOptsTheme $levelP.fontWeight] : "nothing"}]

    setdef options color        -minversion 5  -validvalue formatColor       -type str.t|jsfunc|null -default $color
    setdef options borderWidth  -minversion 5  -validvalue {}                -type num               -default 0
    setdef options borderColor  -minversion 5  -validvalue formatColor       -type str|null          -default "nothing"
    setdef options fontFamily   -minversion 5  -validvalue {}                -type str               -default "sans-serif"
    setdef options fontWeight   -minversion 5  -validvalue formatFontWeight  -type str.t|num.t|null  -default $fontWeight
    setdef options fontSize     -minversion 5  -validvalue {}                -type num.t|null        -default $fontSize

    #...

    set options [merge $options [dict get $value $key]]

    # reset minProperties...
    set minProperties $minP

    if {![dict size $options]} {
        return "nothing"
    } else {
        return [new edict $options]
    }
}

proc ticklecharts::axisTick3D {value} {
    variable theme
    variable minProperties

    set levelP [ticklecharts::getLevelProperties [info level]]
    set minP $minProperties

    if {![ticklecharts::keyDictExists "axisTick" $value key]} {
        if {$theme ne "custom" && ![string match "*Item.*" $levelP]} {
            set minProperties 1 ; set key "axisTick"
            dict set value $key {dummy null}
        } else {
            return "nothing"
        }
    }

    set property [string range $levelP 0 6]
    
    if {$property eq "xAxis3D" || $property eq "yAxis3D" || $property eq "zAxis3D"} {
        set levelP [string cat $property [string map {3D ""} [string range $levelP 7 end]]]
    } else {
        set levelP [string map {3D ""} $levelP]
    }

    set show [expr {[keysOptsThemeExists $levelP.show] ? [echartsOptsTheme $levelP.show] : "True"}]

    set d [dict get $value $key]

    setdef options show       -minversion 5  -validvalue {}  -type bool.t           -default $show
    setdef options interval   -minversion 5  -validvalue {}  -type num|jsfunc|null  -default "nothing"
    setdef options length     -minversion 5  -validvalue {}  -type num              -default 5
    setdef options lineStyle  -minversion 5  -validvalue {}  -type dict|null        -default [ticklecharts::lineStyle3D $d]

    # remove key(s)...
    set d [dict remove $d lineStyle]

    set options [merge $options $d]

    # reset minProperties...
    set minProperties $minP

    if {![dict size $options]} {
        return "nothing"
    } else {
        return [new edict $options]
    }
}

proc ticklecharts::splitLine3D {value} {
    variable theme
    variable minProperties

    set levelP [ticklecharts::getLevelProperties [info level]]
    set minP $minProperties

    if {![ticklecharts::keyDictExists "splitLine" $value key]} {
        if {$theme ne "custom" && ![string match "*Item.*" $levelP]} {
            set minProperties 1 ; set key "splitLine"
            dict set value $key {dummy null}
        } else {
            return "nothing"
        }
    }

    set property [string range $levelP 0 6]
    
    if {$property eq "xAxis3D" || $property eq "yAxis3D" || $property eq "zAxis3D"} {
        set levelP [string cat $property [string map {3D ""} [string range $levelP 7 end]]]
    } else {
        set levelP [string map {3D ""} $levelP]
    }

    set showgrid [expr {[keysOptsThemeExists $levelP.show] ? [echartsOptsTheme $levelP.show] : "True"}]

    set d [dict get $value $key]

    setdef options show       -minversion 5  -validvalue {}  -type bool.t           -default $showgrid
    setdef options interval   -minversion 5  -validvalue {}  -type num|jsfunc|null  -default "nothing"
    setdef options lineStyle  -minversion 5  -validvalue {}  -type dict|null        -default [ticklecharts::lineStyle3D $d]

    # remove key(s)...
    set d [dict remove $d lineStyle]

    set options [merge $options $d]

    # reset minProperties...
    set minProperties $minP

    if {![dict size $options]} {
        return "nothing"
    } else {
        return [new edict $options]
    }
}

proc ticklecharts::splitArea3D {value} {

    if {![dict exists $value -splitArea]} {
        return "nothing"
    }

    set d [dict get $value -splitArea]

    setdef options show       -minversion 5  -validvalue {}  -type bool             -default "False"
    setdef options interval   -minversion 5  -validvalue {}  -type num|jsfunc|null  -default "nothing"
    setdef options areaStyle  -minversion 5  -validvalue {}  -type dict|null        -default [ticklecharts::areaStyle3D $d]

    # remove key(s)...
    set d [dict remove $d areaStyle]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::itemStyle3D {value} {
    variable theme
    variable minProperties

    set levelP [string map {3D ""} [ticklecharts::getLevelProperties [info level]]]
    set minP $minProperties

    if {![ticklecharts::keyDictExists "itemStyle" $value key]} {
        if {$theme ne "custom" && ![string match "*Item.*" $levelP]} {
            set minProperties 1 ; set key "itemStyle"
            dict set value $key {dummy null}
        } else {
            return "nothing"
        }
    }

    set color [expr {[keysOptsThemeExists $levelP.color] ? [echartsOptsTheme $levelP.color] : "nothing"}]

    set d [dict get $value $key]

    setdef options color      -minversion 5  -validvalue {}  -type str.t|jsfunc|null  -default $color
    setdef options opacity    -minversion 5  -validvalue {}  -type num|null           -default 1

    set options [merge $options $d]

    # reset minProperties...
    set minProperties $minP

    if {![dict size $options]} {
        return "nothing"
    } else {
        return [new edict $options]
    }
}

proc ticklecharts::areaStyle3D {value} {

    if {![ticklecharts::keyDictExists "areaStyle" $value key]} {
        return "nothing"
    }

    set levelP [string map {3D ""} [ticklecharts::getLevelProperties [info level]]]

    if {[keysOptsThemeExists $levelP.color]} {
        set color [echartsOptsTheme $levelP.color]
    } else {
        set color [list {rgba(250,250,250,0.3) rgba(200,200,200,0.3)}]
    }

    setdef options color -minversion 5  -validvalue formatColor  -type list.st|null -default $color
    #...

    set options [merge $options [dict get $value $key]]

    return [new edict $options]
}

proc ticklecharts::axisPointer3D {value} {

    if {![ticklecharts::keyDictExists "axisPointer" $value key]} {
        return "nothing"
    }
    
    set d [dict get $value $key]

    setdef options show       -minversion 5  -validvalue {}  -type bool       -default "False"
    setdef options lineStyle  -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::lineStyle3D $d]
    setdef options label      -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::label3D $d]
    #...

    # remove key(s)...
    set d [dict remove $d label lineStyle]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::label3D {value} {

    if {![ticklecharts::keyDictExists "label" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options show       -minversion 5  -validvalue {}  -type bool             -default "True"
    setdef options formatter  -minversion 5  -validvalue {}  -type str|jsfunc|null  -default "nothing"
    setdef options margin     -minversion 5  -validvalue {}  -type num|null         -default "nothing"

    if {[infoNameProc 2 "bar3DSeries"] || [infoNameProc {2 3} "emphasis3D"]} {
        setdef options distance   -minversion 5  -validvalue {}  -type num|null  -default "nothing"
        setdef options textStyle  -minversion 5  -validvalue {}  -type dict|null -default [ticklecharts::textStyle3D $d textStyle]
    }
    #...

    # remove key(s)...
    set d [dict remove $d label textStyle]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::emphasis3D {value} {

    if {![ticklecharts::keyDictExists "emphasis" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options itemStyle  -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::itemStyle3D $d]
    setdef options label      -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::label3D $d]
    #...

    # remove key(s)...
    set d [dict remove $d label itemStyle label]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::light3D {value} {

    if {![ticklecharts::keyDictExists "light" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options main            -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::main3D $d]
    setdef options ambient         -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::ambient3D $d]
    setdef options ambientCubemap  -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::ambientCubemap3D $d]
    #...

    # remove key(s)...
    set d [dict remove $d main ambient ambientCubemap]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::main3D {value} {

    if {![ticklecharts::keyDictExists "main" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options color          -minversion 5  -validvalue formatColor          -type str|null   -default "#fff"
    setdef options intensity      -minversion 5  -validvalue {}                   -type num|null   -default 1
    setdef options shadow         -minversion 5  -validvalue {}                   -type bool|null  -default "False"
    setdef options shadowQuality  -minversion 5  -validvalue formatShadowQuality  -type str|null   -default "medium"
    setdef options alpha          -minversion 5  -validvalue {}                   -type num|null   -default 30
    setdef options beta           -minversion 5  -validvalue {}                   -type num|null   -default 30
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::ambient3D {value} {

    if {![ticklecharts::keyDictExists "ambient" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options color      -minversion 5  -validvalue formatColor -type str|null   -default "#fff"
    setdef options intensity  -minversion 5  -validvalue {}          -type num|null   -default 0.2
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::ambientCubemap3D {value} {

    if {![ticklecharts::keyDictExists "ambientCubemap" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options texture            -minversion 5  -validvalue {}  -type str|null   -default "nothing"
    setdef options exposure           -minversion 5  -validvalue {}  -type num|null   -default "nothing"
    setdef options diffuseIntensity   -minversion 5  -validvalue {}  -type num|null   -default 0.5
    setdef options specularIntensity  -minversion 5  -validvalue {}  -type num|null   -default 0.5
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::postEffect3D {value} {

    if {![ticklecharts::keyDictExists "postEffect" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options enable           -minversion 5  -validvalue {}  -type bool|null  -default "False"
    setdef options bloom            -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::bloom3D $d]
    setdef options depthOfField     -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::depthOfField3D $d]
    setdef options SSAO             -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::SSAO3D $d]
    setdef options colorCorrection  -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::colorCorrection3D $d]
    setdef options FXAA             -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::FXAA3D $d]
    # setdef options screenSpaceAmbientOcclusion   -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::screenSpaceAmbientOcclusion3D $d]
    #...

    # remove key(s)...
    set d [dict remove $d bloom depthOfField screenSpaceAmbientOcclusion SSAO colorCorrection FXAA]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::bloom3D {value} {

    if {![ticklecharts::keyDictExists "bloom" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options enable          -minversion 5  -validvalue {}  -type bool|null  -default "nothing"
    setdef options bloomIntensity  -minversion 5  -validvalue {}  -type num|null   -default 0.1
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::depthOfField3D {value} {

    if {![ticklecharts::keyDictExists "depthOfField" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options enable          -minversion 5  -validvalue {}  -type bool|null  -default "False"
    setdef options focalDistance   -minversion 5  -validvalue {}  -type num|null   -default 50
    setdef options focalRange      -minversion 5  -validvalue {}  -type num|null   -default 20
    setdef options fstop           -minversion 5  -validvalue {}  -type num|null   -default 2.8
    setdef options blurRadius      -minversion 5  -validvalue {}  -type num|null   -default 10
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::SSAO3D {value} {

    if {![ticklecharts::keyDictExists "SSAO" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options enable     -minversion 5  -validvalue {}                 -type bool|null  -default "False"
    setdef options quality    -minversion 5  -validvalue formatSSAOQuality  -type str|null   -default "medium"
    setdef options radius     -minversion 5  -validvalue {}                 -type num|null   -default 2
    setdef options intensity  -minversion 5  -validvalue {}                 -type num|null   -default 1
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::colorCorrection3D {value} {

    if {![ticklecharts::keyDictExists "colorCorrection" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options enable          -minversion 5  -validvalue {}  -type bool|null  -default "True"
    setdef options lookupTexture   -minversion 5  -validvalue {}  -type str|null   -default "nothing"
    setdef options exposure        -minversion 5  -validvalue {}  -type num|null   -default "nothing"
    setdef options brightness      -minversion 5  -validvalue {}  -type num|null   -default "nothing"
    setdef options contrast        -minversion 5  -validvalue {}  -type num|null   -default 1
    setdef options saturation      -minversion 5  -validvalue {}  -type num|null   -default 1
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::FXAA3D {value} {

    if {![ticklecharts::keyDictExists "FXAA" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options enable -minversion 5  -validvalue {}  -type bool|null  -default "False"
    #...

    set options [merge $options $d]

    return [new edict $options]
}


proc ticklecharts::temporalSuperSampling3D {value} {

    if {![ticklecharts::keyDictExists "temporalSuperSampling" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options enable -minversion 5  -validvalue {}  -type bool|null  -default "nothing"
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::viewControl3D {value} {

    if {![ticklecharts::keyDictExists "viewControl" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options projection               -minversion 5  -validvalue formatProjection3D  -type str|null          -default "perspective"
    setdef options autoRotate               -minversion 5  -validvalue {}                  -type bool|null         -default "nothing"
    setdef options autoRotateDirection      -minversion 5  -validvalue formatDirection3D   -type str|null          -default "cw"
    setdef options autoRotateSpeed          -minversion 5  -validvalue {}                  -type num|null          -default 10
    setdef options autoRotateAfterStill     -minversion 5  -validvalue {}                  -type num|null          -default 3
    setdef options damping                  -minversion 5  -validvalue {}                  -type num|null          -default 0.8
    setdef options rotateSensitivity        -minversion 5  -validvalue {}                  -type num|list.n|null   -default 1
    setdef options zoomSensitivity          -minversion 5  -validvalue {}                  -type num|null          -default 1
    setdef options panSensitivity           -minversion 5  -validvalue {}                  -type num|null          -default 1
    setdef options panMouseButton           -minversion 5  -validvalue formatMouseButton   -type str|null          -default "nothing"
    setdef options rotateMouseButton        -minversion 5  -validvalue formatMouseButton   -type str|null          -default "nothing"
    setdef options distance                 -minversion 5  -validvalue {}                  -type num|null          -default "nothing"
    setdef options minDistance              -minversion 5  -validvalue {}                  -type num|null          -default "nothing"
    setdef options maxDistance              -minversion 5  -validvalue {}                  -type num|null          -default "nothing"
    setdef options orthographicSize         -minversion 5  -validvalue {}                  -type num|null          -default "nothing"
    setdef options maxOrthographicSize      -minversion 5  -validvalue {}                  -type num|null          -default "nothing"
    setdef options minOrthographicSize      -minversion 5  -validvalue {}                  -type num|null          -default "nothing"
    setdef options alpha                    -minversion 5  -validvalue {}                  -type num|null          -default 20
    setdef options beta                     -minversion 5  -validvalue {}                  -type num|null          -default 40
    setdef options center                   -minversion 5  -validvalue {}                  -type list.n|null       -default [list {0 0 0}]
    setdef options minAlpha                 -minversion 5  -validvalue {}                  -type num|null          -default -90
    setdef options maxAlpha                 -minversion 5  -validvalue {}                  -type num|null          -default 90
    setdef options minBeta                  -minversion 5  -validvalue {}                  -type num|null          -default "nothing"
    setdef options maxBeta                  -minversion 5  -validvalue {}                  -type num|null          -default "nothing"
    setdef options animation                -minversion 5  -validvalue {}                  -type bool|null         -default "True"
    setdef options animationDurationUpdate  -minversion 5  -validvalue {}                  -type num|null          -default 1000
    setdef options animationEasingUpdate    -minversion 5  -validvalue {}                  -type str|null          -default "cubicInOut"
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::realisticMaterial3D {value} {

    if {![ticklecharts::keyDictExists "realisticMaterial" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options detailTexture    -minversion 5  -validvalue {}  -type str|null      -default "nothing"
    setdef options textureTiling    -minversion 5  -validvalue {}  -type num|null      -default "nothing"
    setdef options textureOffset    -minversion 5  -validvalue {}  -type num|null      -default "nothing"
    setdef options roughness        -minversion 5  -validvalue {}  -type num|str|null  -default "nothing"
    setdef options metalness        -minversion 5  -validvalue {}  -type num|str|null  -default "nothing"
    setdef options roughnessAdjust  -minversion 5  -validvalue {}  -type num|null      -default "nothing"
    setdef options metalnessAdjust  -minversion 5  -validvalue {}  -type num|null      -default "nothing"
    setdef options normalTexture    -minversion 5  -validvalue {}  -type str|null      -default "nothing"
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::lambertMaterial3D {value} {

    if {![ticklecharts::keyDictExists "lambertMaterial" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options detailTexture    -minversion 5  -validvalue {}  -type str|null  -default "nothing"
    setdef options textureTiling    -minversion 5  -validvalue {}  -type num|null  -default "nothing"
    setdef options textureOffset    -minversion 5  -validvalue {}  -type num|null  -default "nothing"
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::colorMaterial3D {value} {

    if {![ticklecharts::keyDictExists "colorMaterial" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options detailTexture    -minversion 5  -validvalue {}  -type str|null  -default "nothing"
    setdef options textureTiling    -minversion 5  -validvalue {}  -type num|null  -default "nothing"
    setdef options textureOffset    -minversion 5  -validvalue {}  -type num|null  -default "nothing"
    #...

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::wireframe3D {value} {

    if {![ticklecharts::keyDictExists "wireframe" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options show       -minversion 5  -validvalue {}  -type bool       -default "True"
    setdef options lineStyle  -minversion 5  -validvalue {}  -type dict|null  -default [ticklecharts::lineStyle3D $d]
    #...

    # remove key(s)...
    set d [dict remove $d lineStyle]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::equation3D {value} {

    if {![ticklecharts::keyDictExists "equation" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]

    setdef options x  -minversion 5  -validvalue {}  -type dict   -default [ticklecharts::coordinate3D $d "x"]
    setdef options y  -minversion 5  -validvalue {}  -type dict   -default [ticklecharts::coordinate3D $d "y"]
    setdef options z  -minversion 5  -validvalue {}  -type jsfunc -default {}
    #...

    # remove key(s)...
    set d [dict remove $d x y]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::parametricEquation3D {value} {

    if {![ticklecharts::keyDictExists "parametricEquation" $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]

    setdef options u  -minversion 5  -validvalue {}  -type dict   -default [ticklecharts::coordinate3D $d "u"]
    setdef options v  -minversion 5  -validvalue {}  -type dict   -default [ticklecharts::coordinate3D $d "v"]
    setdef options x  -minversion 5  -validvalue {}  -type jsfunc -default {}
    setdef options y  -minversion 5  -validvalue {}  -type jsfunc -default {}
    setdef options z  -minversion 5  -validvalue {}  -type jsfunc -default {}
    #...

    # remove key(s)...
    set d [dict remove $d u v]

    set options [merge $options $d]

    return [new edict $options]
}

proc ticklecharts::coordinate3D {value coordinate} {

    if {![ticklecharts::keyDictExists $coordinate $value key]} {
        return "nothing"
    }

    set d [dict get $value $key]
    
    setdef options step  -minversion 5  -validvalue {}  -type num|null  -default "nothing"
    setdef options min   -minversion 5  -validvalue {}  -type num|null  -default "nothing"
    setdef options max   -minversion 5  -validvalue {}  -type num|null  -default "nothing"
    #...

    set options [merge $options $d]

    return [new edict $options]
}