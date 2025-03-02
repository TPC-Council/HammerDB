# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

proc ticklecharts::radiusAxis {value} {

    setdef options -id             -minversion 5  -validvalue {}                  -type str|null            -default "nothing"
    setdef options -polarIndex     -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -type           -minversion 5  -validvalue formatType          -type str|null            -default "nothing"
    setdef options -name           -minversion 5  -validvalue {}                  -type str|null            -default "nothing"
    setdef options -nameLocation   -minversion 5  -validvalue formatNameLocation  -type str|null            -default "nothing"
    setdef options -nameTextStyle  -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::nameTextStyle $value]
    setdef options -nameGap        -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -nameRotate     -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -nameTruncate   -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::nameTruncate $value]
    setdef options -inverse        -minversion 5  -validvalue {}                  -type bool|null           -default "nothing"
    setdef options -boundaryGap    -minversion 5  -validvalue {}                  -type bool|list.d|null    -default "nothing"
    setdef options -min            -minversion 5  -validvalue {}                  -type num|str|jsfunc|null -default "nothing"
    setdef options -max            -minversion 5  -validvalue {}                  -type num|str|jsfunc|null -default "nothing"
    setdef options -scale          -minversion 5  -validvalue {}                  -type bool|null           -default "nothing"
    setdef options -splitNumber    -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -minInterval    -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -maxInterval    -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -interval       -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -logBase        -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -silent         -minversion 5  -validvalue {}                  -type bool|null           -default "nothing"
    setdef options -triggerEvent   -minversion 5  -validvalue {}                  -type bool|null           -default "nothing"
    setdef options -axisLine       -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::axisLine $value]
    setdef options -axisTick       -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::axisTick $value]
    setdef options -minorTick      -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::minorTick $value]
    setdef options -axisLabel      -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::axisLabel $value]
    setdef options -splitLine      -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::splitLine $value]
    setdef options -minorSplitLine -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::minorSplitLine $value]
    setdef options -splitArea      -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::splitArea $value]
    setdef options -data           -minversion 5  -validvalue {}                  -type list.d|null         -default "nothing"
    setdef options -axisPointer    -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::axisPointer $value]
    setdef options -zlevel         -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    setdef options -z              -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
    #...

    # remove key(s)...
    set value [dict remove $value -axisLine -axisTick -minorSplitLine \
                                  -axisLabel -splitLine -axisPointer \
                                  -splitArea -nameTextStyle -minorTick -nameTruncate]

    set options [merge $options $value]
    
    return $options
}

proc ticklecharts::radarCoordinate {value} {

    setdef options -id           -minversion 5  -validvalue {}               -type str|null       -default "nothing"
    setdef options -zlevel       -minversion 5  -validvalue {}               -type num|null       -default "nothing"
    setdef options -z            -minversion 5  -validvalue {}               -type num|null       -default "nothing"
    setdef options -center       -minversion 5  -validvalue {}               -type list.d         -default [list {"50%" "50%"}]
    setdef options -radius       -minversion 5  -validvalue {}               -type list.d|num|str -default "75%"
    setdef options -startAngle   -minversion 5  -validvalue formatStartangle -type num            -default 90
    setdef options -axisName     -minversion 5  -validvalue {}               -type dict|null      -default [ticklecharts::axisName $value]
    setdef options -nameGap      -minversion 5  -validvalue {}               -type num|null       -default 15
    setdef options -splitNumber  -minversion 5  -validvalue {}               -type num|null       -default 5
    setdef options -shape        -minversion 5  -validvalue formatShape      -type str            -default "polygon"
    setdef options -scale        -minversion 5  -validvalue {}               -type bool|null      -default "nothing"
    setdef options -triggerEvent -minversion 5  -validvalue {}               -type bool|null      -default "nothing"
    setdef options -axisLine     -minversion 5  -validvalue {}               -type dict|null      -default [ticklecharts::axisLine $value]
    setdef options -axisTick     -minversion 5  -validvalue {}               -type dict|null      -default [ticklecharts::axisTick $value]
    setdef options -axisLabel    -minversion 5  -validvalue {}               -type dict|null      -default [ticklecharts::axisLabel $value]
    setdef options -splitLine    -minversion 5  -validvalue {}               -type dict|null      -default [ticklecharts::splitLine $value]
    setdef options -splitArea    -minversion 5  -validvalue {}               -type dict|null      -default [ticklecharts::splitArea $value]
    setdef options -indicator    -minversion 5  -validvalue {}               -type list.o         -default [ticklecharts::indicatorItem $value]
    #...

    # remove key(s)...
    set value [dict remove $value -axisLine -axisTick \
                                  -axisName -axisLabel -splitLine \
                                  -splitArea -indicatoritem]

    set options [merge $options $value]
    
    return $options
}

proc ticklecharts::angleAxis {value} {

    setdef options -id             -minversion 5  -validvalue {}               -type str|null            -default "nothing"
    setdef options -polarIndex     -minversion 5  -validvalue {}               -type num|null            -default "nothing"
    setdef options -startAngle     -minversion 5  -validvalue formatStartangle -type num                 -default 90
    setdef options -clockwise      -minversion 5  -validvalue {}               -type bool                -default "True"
    setdef options -type           -minversion 5  -validvalue formatType       -type str|null            -default "nothing"
    setdef options -boundaryGap    -minversion 5  -validvalue {}               -type bool|list.d|null    -default "nothing"
    setdef options -min            -minversion 5  -validvalue {}               -type num|str|jsfunc|null -default "nothing"
    setdef options -max            -minversion 5  -validvalue {}               -type num|str|jsfunc|null -default "nothing"
    setdef options -scale          -minversion 5  -validvalue {}               -type bool|null           -default "nothing"
    setdef options -splitNumber    -minversion 5  -validvalue {}               -type num|null            -default "nothing"
    setdef options -minInterval    -minversion 5  -validvalue {}               -type num|null            -default "nothing"
    setdef options -maxInterval    -minversion 5  -validvalue {}               -type num|null            -default "nothing"
    setdef options -interval       -minversion 5  -validvalue {}               -type num|null            -default "nothing"
    setdef options -logBase        -minversion 5  -validvalue {}               -type num|null            -default "nothing"
    setdef options -silent         -minversion 5  -validvalue {}               -type bool|null           -default "nothing"
    setdef options -triggerEvent   -minversion 5  -validvalue {}               -type bool|null           -default "nothing"
    setdef options -axisLine       -minversion 5  -validvalue {}               -type dict|null           -default [ticklecharts::axisLine $value]
    setdef options -axisTick       -minversion 5  -validvalue {}               -type dict|null           -default [ticklecharts::axisTick $value]
    setdef options -minorTick      -minversion 5  -validvalue {}               -type dict|null           -default [ticklecharts::minorTick $value]
    setdef options -axisLabel      -minversion 5  -validvalue {}               -type dict|null           -default [ticklecharts::axisLabel $value]
    setdef options -splitLine      -minversion 5  -validvalue {}               -type dict|null           -default [ticklecharts::splitLine $value]
    setdef options -minorSplitLine -minversion 5  -validvalue {}               -type dict|null           -default [ticklecharts::minorSplitLine $value]
    setdef options -splitArea      -minversion 5  -validvalue {}               -type dict|null           -default [ticklecharts::splitArea $value]
    setdef options -data           -minversion 5  -validvalue {}               -type list.d|null         -default "nothing"
    setdef options -axisPointer    -minversion 5  -validvalue {}               -type dict|null           -default [ticklecharts::axisPointer $value]
    setdef options -zlevel         -minversion 5  -validvalue {}               -type num|null            -default "nothing"
    setdef options -z              -minversion 5  -validvalue {}               -type num|null            -default "nothing"
    #...

    # remove key(s)...
    set value [dict remove $value -axisLine -axisTick \
                                  -minorTick -axisLabel -splitLine \
                                  -minorSplitLine -splitArea -axisPointer]

    set options [merge $options $value]
    
    return $options
}

proc ticklecharts::xAxis {chart value} {
    
    setdef options -id             -minversion 5       -validvalue {}                  -type str|null            -default "nothing"
    setdef options -show           -minversion 5       -validvalue {}                  -type bool                -default "True"
    setdef options -type           -minversion 5       -validvalue formatType          -type str|null            -default "category"
    setdef options -data           -minversion 5       -validvalue {}                  -type list.d|null         -default "nothing"
    setdef options -gridIndex      -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -alignTicks     -minversion "5.3.0" -validvalue {}                  -type bool|null           -default "nothing"
    setdef options -position       -minversion 5       -validvalue formatXAxisPosition -type str                 -default "bottom"
    setdef options -offset         -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -name           -minversion 5       -validvalue {}                  -type str|null            -default "nothing"
    setdef options -nameLocation   -minversion 5       -validvalue formatNameLocation  -type str                 -default "end"
    setdef options -nameTextStyle  -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::nameTextStyle $value]
    setdef options -nameGap        -minversion 5       -validvalue {}                  -type num                 -default 15
    setdef options -nameRotate     -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -nameTruncate   -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::nameTruncate $value]
    setdef options -inverse        -minversion 5       -validvalue {}                  -type bool                -default "False"
    setdef options -boundaryGap    -minversion 5       -validvalue {}                  -type bool|list.d         -default "True"
    setdef options -min            -minversion 5       -validvalue {}                  -type num|str|jsfunc|null -default "nothing"
    setdef options -max            -minversion 5       -validvalue {}                  -type num|str|jsfunc|null -default "nothing"
    setdef options -scale          -minversion 5       -validvalue {}                  -type bool                -default "False"
    setdef options -splitNumber    -minversion 5       -validvalue {}                  -type num                 -default 5
    setdef options -minInterval    -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -maxInterval    -minversion 5       -validvalue {}                  -type num|null            -default "nothing"
    setdef options -interval       -minversion 5       -validvalue {}                  -type num|null            -default "nothing"
    setdef options -logBase        -minversion 5       -validvalue {}                  -type num|null            -default "nothing"
    setdef options -silent         -minversion 5       -validvalue {}                  -type bool                -default "False"
    setdef options -triggerEvent   -minversion 5       -validvalue {}                  -type bool                -default "False"
    setdef options -axisLine       -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::axisLine $value]
    setdef options -axisTick       -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::axisTick $value]
    setdef options -minorTick      -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::minorTick $value]
    setdef options -axisLabel      -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::axisLabel $value]
    setdef options -splitLine      -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::splitLine $value]
    setdef options -minorSplitLine -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::minorSplitLine $value]
    setdef options -splitArea      -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::splitArea $value]
    setdef options -axisPointer    -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::axisPointer $value]
    setdef options -zlevel         -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -z              -minversion 5       -validvalue {}                  -type num                 -default 0

    # check if chart includes a dataset class
    set dataset [$chart dataset]

    if {$dataset ne ""} {
        if {[dict exists $value -data]} {
            error "'chart' Class cannot contain Xaxis 'data' when a class dataset is present"
        }
    }

    # remove key(s)...
    set value [dict remove $value -nameTextStyle -axisLine -axisTick \
                                  -minorTick -axisLabel -splitLine \
                                  -minorSplitLine -splitArea -axisPointer -nameTruncate]
    
    set options [merge $options $value]

    return $options
}

proc ticklecharts::yAxis {chart value} {

    setdef options -id              -minversion 5       -validvalue {}                  -type str|null            -default "nothing"
    setdef options -show            -minversion 5       -validvalue {}                  -type bool                -default "True"
    setdef options -gridIndex       -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -alignTicks      -minversion "5.3.0" -validvalue {}                  -type bool|null           -default "nothing"
    setdef options -position        -minversion 5       -validvalue formatYAxisPosition -type str                 -default "left"
    setdef options -offset          -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -realtimeSort    -minversion 5       -validvalue {}                  -type bool                -default "True"
    setdef options -sortSeriesIndex -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -type            -minversion 5       -validvalue formatType          -type str|null            -default "value"
    setdef options -data            -minversion 5       -validvalue {}                  -type list.d|null         -default "nothing"
    setdef options -name            -minversion 5       -validvalue {}                  -type str|null            -default "nothing"
    setdef options -nameLocation    -minversion 5       -validvalue formatNameLocation  -type str                 -default "end"
    setdef options -nameTextStyle   -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::nameTextStyle $value]
    setdef options -nameGap         -minversion 5       -validvalue {}                  -type num                 -default 15
    setdef options -nameRotate      -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -nameTruncate    -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::nameTruncate $value]
    setdef options -inverse         -minversion 5       -validvalue {}                  -type bool                -default "False"
    setdef options -boundaryGap     -minversion 5       -validvalue {}                  -type bool|list.s         -default "False"
    setdef options -min             -minversion 5       -validvalue {}                  -type num|str|jsfunc|null -default "nothing"
    setdef options -max             -minversion 5       -validvalue {}                  -type num|str|jsfunc|null -default "nothing"
    setdef options -scale           -minversion 5       -validvalue {}                  -type bool                -default "False"
    setdef options -splitNumber     -minversion 5       -validvalue {}                  -type num                 -default 5
    setdef options -minInterval     -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -maxInterval     -minversion 5       -validvalue {}                  -type num|null            -default "nothing"
    setdef options -interval        -minversion 5       -validvalue {}                  -type num|null            -default "nothing"
    setdef options -logBase         -minversion 5       -validvalue {}                  -type num|null            -default "nothing"
    setdef options -silent          -minversion 5       -validvalue {}                  -type bool                -default "False"
    setdef options -triggerEvent    -minversion 5       -validvalue {}                  -type bool                -default "False"
    setdef options -axisLine        -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::axisLine $value]
    setdef options -axisTick        -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::axisTick $value]
    setdef options -minorTick       -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::minorTick $value]
    setdef options -axisLabel       -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::axisLabel $value]
    setdef options -splitLine       -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::splitLine $value]
    setdef options -minorSplitLine  -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::minorSplitLine $value]
    setdef options -splitArea       -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::splitArea $value]
    setdef options -axisPointer     -minversion 5       -validvalue {}                  -type dict|null           -default [ticklecharts::axisPointer $value]
    setdef options -zlevel          -minversion 5       -validvalue {}                  -type num                 -default 0
    setdef options -z               -minversion 5       -validvalue {}                  -type num                 -default 0

    # check if chart includes a dataset class
    set dataset [$chart dataset]

    if {$dataset ne ""} {
        if {[dict exists $value -data]} {
            error "'chart' Class cannot contain YAxis 'data' when a class dataset is present"
        }
    }

    # remove key(s)...
    set value [dict remove $value -nameTextStyle -axisLine -axisTick \
                                  -minorTick -axisLabel -splitLine \
                                  -minorSplitLine -splitArea -axisPointer -nameTruncate]
    
    set options [merge $options $value]

    return $options
}

proc ticklecharts::singleAxis {value} {
    
    setdef options -id             -minversion 5  -validvalue {}                 -type str|null            -default "nothing"
    setdef options -zlevel         -minversion 5  -validvalue {}                 -type num                 -default 0
    setdef options -z              -minversion 5  -validvalue {}                 -type num                 -default 2
    setdef options -left           -minversion 5  -validvalue formatLeft         -type num|str             -default "5%"
    setdef options -top            -minversion 5  -validvalue formatTop          -type num|str             -default "5%"
    setdef options -right          -minversion 5  -validvalue formatRight        -type num|str             -default "5%"
    setdef options -bottom         -minversion 5  -validvalue formatBottom       -type num|str             -default "5%"
    setdef options -width          -minversion 5  -validvalue {}                 -type num|str             -default "auto"
    setdef options -height         -minversion 5  -validvalue {}                 -type num|str             -default "auto"
    setdef options -orient         -minversion 5  -validvalue formatOrient       -type str                 -default "horizontal"
    setdef options -type           -minversion 5  -validvalue formatType         -type str|null            -default "value"
    setdef options -name           -minversion 5  -validvalue {}                 -type str|null            -default "nothing"
    setdef options -nameLocation   -minversion 5  -validvalue formatNameLocation -type str                 -default "end"
    setdef options -nameTextStyle  -minversion 5  -validvalue {}                 -type dict|null           -default [ticklecharts::nameTextStyle $value]
    setdef options -nameGap        -minversion 5  -validvalue {}                 -type num                 -default 15
    setdef options -nameRotate     -minversion 5  -validvalue {}                 -type num                 -default 0
    setdef options -nameTruncate   -minversion 5  -validvalue {}                 -type dict|null           -default [ticklecharts::nameTruncate $value]
    setdef options -inverse        -minversion 5  -validvalue {}                 -type bool                -default "False"
    setdef options -boundaryGap    -minversion 5  -validvalue {}                 -type bool|list.d         -default "True"
    setdef options -min            -minversion 5  -validvalue {}                 -type num|str|jsfunc|null -default "nothing"
    setdef options -max            -minversion 5  -validvalue {}                 -type num|str|jsfunc|null -default "nothing"
    setdef options -scale          -minversion 5  -validvalue {}                 -type bool|null           -default "nothing"
    setdef options -splitNumber    -minversion 5  -validvalue {}                 -type num                 -default 5
    setdef options -minInterval    -minversion 5  -validvalue {}                 -type num                 -default 0
    setdef options -maxInterval    -minversion 5  -validvalue {}                 -type num|null            -default "nothing"
    setdef options -interval       -minversion 5  -validvalue {}                 -type num|null            -default "nothing"
    setdef options -logBase        -minversion 5  -validvalue {}                 -type num|null            -default "nothing"
    setdef options -silent         -minversion 5  -validvalue {}                 -type bool                -default "False"
    setdef options -triggerEvent   -minversion 5  -validvalue {}                 -type bool                -default "False"
    setdef options -axisPointer    -minversion 5  -validvalue {}                 -type dict|null           -default [ticklecharts::axisPointer $value]
    setdef options -axisTick       -minversion 5  -validvalue {}                 -type dict|null           -default [ticklecharts::axisTick $value]
    setdef options -axisLabel      -minversion 5  -validvalue {}                 -type dict|null           -default [ticklecharts::axisLabel $value]
    # ...

    # remove key(s)...
    set value [dict remove $value -nameTextStyle -axisTick -axisLabel -axisPointer -nameTruncate]

    set options [merge $options $value]

    return $options
}

proc ticklecharts::parallelAxis {value} {

    foreach item {*}$value {

        if {[llength $item] % 2} {
            error "item list for '[lindex [info level 0] 0]' must have an even number of elements..."
        }

        setdef options -id              -minversion 5  -validvalue {}                  -type str|null            -default "nothing"
        setdef options -dim             -minversion 5  -validvalue {}                  -type num                 -default 0
        setdef options -parallelIndex   -minversion 5  -validvalue {}                  -type num                 -default 0
        setdef options -realtime        -minversion 5  -validvalue {}                  -type bool                -default "True"
        setdef options -areaSelectStyle -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::areaSelectStyle $item]
        setdef options -type            -minversion 5  -validvalue formatType          -type str|null            -default "value"
        setdef options -name            -minversion 5  -validvalue {}                  -type str|null            -default "nothing"
        setdef options -nameLocation    -minversion 5  -validvalue formatNameLocation  -type str|null            -default "end"
        setdef options -nameTextStyle   -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::nameTextStyle $item]
        setdef options -nameGap         -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
        setdef options -nameRotate      -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
        setdef options -nameTruncate    -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::nameTruncate $value]
        setdef options -inverse         -minversion 5  -validvalue {}                  -type bool|null           -default "nothing"
        setdef options -boundaryGap     -minversion 5  -validvalue {}                  -type bool|list.d|null    -default "nothing"
        setdef options -min             -minversion 5  -validvalue {}                  -type num|str|jsfunc|null -default "nothing"
        setdef options -max             -minversion 5  -validvalue {}                  -type num|str|jsfunc|null -default "nothing"
        setdef options -scale           -minversion 5  -validvalue {}                  -type bool|null           -default "nothing"
        setdef options -splitNumber     -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
        setdef options -minInterval     -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
        setdef options -maxInterval     -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
        setdef options -interval        -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
        setdef options -logBase         -minversion 5  -validvalue {}                  -type num|null            -default "nothing"
        setdef options -silent          -minversion 5  -validvalue {}                  -type bool|null           -default "nothing"
        setdef options -triggerEvent    -minversion 5  -validvalue {}                  -type bool|null           -default "nothing"
        setdef options -axisLine        -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::axisLine $item]
        setdef options -axisTick        -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::axisTick $item]
        setdef options -minorTick       -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::minorTick $item]
        setdef options -axisLabel       -minversion 5  -validvalue {}                  -type dict|null           -default [ticklecharts::axisLabel $item]
        setdef options -data            -minversion 5  -validvalue {}                  -type list.d|null         -default "nothing"
        #...

        # remove key(s)...
        set item [dict remove $item -areaSelectStyle -nameTextStyle -axisLine -axisTick -minorTick -axisLabel -nameTruncate]

        lappend opts [merge $options $item]
        set options {}

    }

    return $opts
}