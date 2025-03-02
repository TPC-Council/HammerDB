# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

proc ticklecharts::bar3DSeries {index chart value} {
    # options : https://echarts.apache.org/en/option-gl.html#series-bar3D
    #
    # index - index series.
    # chart - self.
    # value - Options described in proc ticklecharts::bar3DSeries below.
    #
    # return dict bar3DSeries options

    setdef options -type                    -minversion 5       -validvalue {}                   -type str             -default "bar3D"
    setdef options -name                    -minversion 5       -validvalue {}                   -type str             -default "bar3DSeries_${index}"
    setdef options -coordinateSystem        -minversion 5       -validvalue formatCSYS           -type str             -default "cartesian3D"    
    setdef options -grid3DIndex             -minversion 5       -validvalue {}                   -type num|null        -default "nothing"
    setdef options -geo3DIndex              -minversion 5       -validvalue {}                   -type num|null        -default "nothing"
    setdef options -globeIndex              -minversion 5       -validvalue {}                   -type num|null        -default "nothing"
    setdef options -barSize                 -minversion 5       -validvalue {}                   -type num|null        -default "nothing"
    setdef options -bevelSize               -minversion 5       -validvalue formatBevelSize      -type num|null        -default "nothing"
    setdef options -bevelSmoothness         -minversion 5       -validvalue {}                   -type num|null        -default "nothing"
    setdef options -stack                   -minversion 5       -validvalue {}                   -type str|null        -default "nothing"
    setdef options -stackStrategy           -minversion "5.3.3" -validvalue formatStackStrategy  -type str|null        -default "nothing"
    setdef options -minHeight               -minversion 5       -validvalue {}                   -type num|null        -default "nothing"
    setdef options -itemStyle               -minversion 5       -validvalue {}                   -type dict|null       -default [ticklecharts::itemStyle3D $value]
    setdef options -label                   -minversion 5       -validvalue {}                   -type dict|null       -default [ticklecharts::label3D $value]
    setdef options -emphasis                -minversion 5       -validvalue {}                   -type dict|null       -default [ticklecharts::emphasis3D $value]
    setdef options -data                    -minversion 5       -validvalue {}                   -type list.n          -default {}
    setdef options -shading                 -minversion 5       -validvalue formatShading3D      -type str|null        -default "nothing"
    setdef options -realisticMaterial       -minversion 5       -validvalue {}                   -type dict|null       -default [ticklecharts::realisticMaterial3D $value]
    setdef options -lambertMaterial         -minversion 5       -validvalue {}                   -type dict|null       -default [ticklecharts::lambertMaterial3D $value]
    setdef options -colorMaterial           -minversion 5       -validvalue {}                   -type dict|null       -default [ticklecharts::colorMaterial3D $value]
    setdef options -zlevel                  -minversion 5       -validvalue {}                   -type num             -default -10
    setdef options -silent                  -minversion 5       -validvalue {}                   -type bool            -default "False"
    setdef options -animation               -minversion 5       -validvalue {}                   -type bool|null       -default "True"
    setdef options -animationDurationUpdate -minversion 5       -validvalue {}                   -type num|jsfunc|null -default 500
    setdef options -animationEasingUpdate   -minversion 5       -validvalue formatAEasing        -type str|null        -default "cubicOut"

    # check if chart includes a dataset class
    set dataset [$chart dataset]

    if {$dataset ne ""} {
        if {[dict exists $value -data] || [dict exists $value -dataBar3DItem]} {
            error "'chart' Class cannot contain '-data' or '-dataBar3DItem' when a class dataset is present"
        }

        set options [dict remove $options -data]
        # set dimensions in dataset class... if need
        # setdef options -dimensions    -minversion 5  -validvalue {}                 -type list.d|null      -default "nothing"
        setdef options  -dataGroupId    -minversion 5  -validvalue {}                 -type str|null         -default "nothing"
        setdef options  -seriesLayoutBy -minversion 5  -validvalue formatSeriesLayout -type str|null         -default "nothing"
        setdef options  -encode         -minversion 5  -validvalue {}                 -type dict|null        -default [ticklecharts::encode $chart $value]
        setdef options  -datasetIndex   -minversion 5  -validvalue {}                 -type num|null         -default "nothing"

    }
      
    if {[dict exists $value -dataBar3DItem]} {
        if {[dict exists $value -data]} {
            error "'chart' args cannot contain '-data' and '-dataBar3DItem'..."
        }
        setdef options -data -minversion 5  -validvalue {} -type list.o -default [ticklecharts::bar3DItem $value]
    }

    # remove key(s)...
    set value [dict remove $value -itemStyle -label -emphasis \
                                  -realisticMaterial -lambertMaterial \
                                  -lambertMaterial -dataBar3DItem -encode]
                                
    set options [merge $options $value]

    return $options
}

proc ticklecharts::line3DSeries {index chart value} {
    # options : https://echarts.apache.org/en/option-gl.html#series-line3D
    #
    # index - index series.
    # chart - self.
    # value - Options described in proc ticklecharts::line3DSeries below.
    #
    # return dict line3DSeries options

    setdef options -type                    -minversion 5  -validvalue {}             -type str             -default "line3D"
    setdef options -name                    -minversion 5  -validvalue {}             -type str             -default "line3Dseries_${index}"
    setdef options -coordinateSystem        -minversion 5  -validvalue formatCSYS     -type str             -default "cartesian3D"
    setdef options -grid3DIndex             -minversion 5  -validvalue {}             -type num|null        -default "nothing"
    setdef options -lineStyle               -minversion 5  -validvalue {}             -type dict|null       -default [ticklecharts::lineStyle3D $value]
    setdef options -data                    -minversion 5  -validvalue {}             -type list.n          -default {}
    setdef options -zlevel                  -minversion 5  -validvalue {}             -type num             -default -10
    setdef options -silent                  -minversion 5  -validvalue {}             -type bool            -default "False"
    setdef options -animation               -minversion 5  -validvalue {}             -type bool|null       -default "nothing"
    setdef options -animationDurationUpdate -minversion 5  -validvalue {}             -type num|jsfunc|null -default "nothing"
    setdef options -animationEasingUpdate   -minversion 5  -validvalue formatAEasing  -type str|null        -default "nothing"

    # check if chart includes a dataset class
    set dataset [$chart dataset]

    if {$dataset ne ""} {
        if {[dict exists $value -data] || [dict exists $value -dataLine3DItem]} {
            error "'chart' Class cannot contain '-data' or '-dataLine3DItem' when a class dataset is present"
        }

        set options [dict remove $options -data]
        # set dimensions in dataset class...
        # setdef options -dimensions     -minversion 5  -validvalue {}                 -type list.d|null      -default "nothing"
        setdef options   -dataGroupId    -minversion 5  -validvalue {}                 -type str|null         -default "nothing"
        setdef options   -seriesLayoutBy -minversion 5  -validvalue formatSeriesLayout -type str|null         -default "nothing"
        setdef options   -encode         -minversion 5  -validvalue {}                 -type dict|null        -default [ticklecharts::encode $chart $value]
        setdef options   -datasetIndex   -minversion 5  -validvalue {}                 -type num|null         -default "nothing"

    }
    
    if {[dict exists $value -dataLine3DItem]} {
        if {[dict exists $value -data]} {
            error "'chart' args cannot contain '-data' and '-dataLine3DItem'..."
        }
        setdef options -data -minversion 5  -validvalue {} -type list.o -default [ticklecharts::line3DItem $value]
    }

    # remove key(s)...
    set value [dict remove $value -lineStyle -encode -dataLine3DItem]
                                
    set options [merge $options $value]

    return $options
}

proc ticklecharts::surfaceSeries {index value} {
    # options : https://echarts.apache.org/en/option-gl.html#series-line3D
    #
    # index - index series.
    # value - Options described in proc ticklecharts::surfaceSeries below.
    #
    # return dict surfaceSeries options

    setdef options -type                    -minversion 5  -validvalue {}               -type str             -default "surface"
    setdef options -name                    -minversion 5  -validvalue {}               -type str             -default "surfaceseries_${index}"
    setdef options -coordinateSystem        -minversion 5  -validvalue formatCSYS       -type str             -default "cartesian3D"
    setdef options -grid3DIndex             -minversion 5  -validvalue {}               -type num|null        -default "nothing"
    setdef options -parametric              -minversion 5  -validvalue {}               -type bool|null       -default "nothing"
    setdef options -wireframe               -minversion 5  -validvalue {}               -type dict|null       -default [ticklecharts::wireframe3D $value]
    setdef options -equation                -minversion 5  -validvalue {}               -type dict|null       -default [ticklecharts::equation3D $value]
    setdef options -parametricEquation      -minversion 5  -validvalue {}               -type dict|null       -default [ticklecharts::parametricEquation3D $value]
    setdef options -itemStyle               -minversion 5  -validvalue {}               -type dict|null       -default [ticklecharts::itemStyle3D $value]
    setdef options -data                    -minversion 5  -validvalue {}               -type list.n|null     -default "nothing"
    setdef options -shading                 -minversion 5  -validvalue formatShading3D  -type str|null        -default "nothing"
    setdef options -realisticMaterial       -minversion 5  -validvalue {}               -type dict|null       -default [ticklecharts::realisticMaterial3D $value]
    setdef options -lambertMaterial         -minversion 5  -validvalue {}               -type dict|null       -default [ticklecharts::lambertMaterial3D $value]
    setdef options -colorMaterial           -minversion 5  -validvalue {}               -type dict|null       -default [ticklecharts::colorMaterial3D $value]    
    setdef options -zlevel                  -minversion 5  -validvalue {}               -type num             -default -10
    setdef options -silent                  -minversion 5  -validvalue {}               -type bool            -default "False"
    setdef options -animation               -minversion 5  -validvalue {}               -type bool|null       -default "nothing"
    setdef options -animationDurationUpdate -minversion 5  -validvalue {}               -type num|jsfunc|null -default "nothing"
    setdef options -animationEasingUpdate   -minversion 5  -validvalue formatAEasing    -type str|null        -default "nothing"


    if {[dict exists $value -dataSurfaceItem]} {
        foreach k {-data -equation -parametricEquation} {
            if {[dict exists $value $k]} {
                error "'chart' args cannot contain '$k' and '-dataSurfaceItem'..."
            }
        }
        setdef options -data -minversion 5  -validvalue {} -type list.o -default [ticklecharts::surfaceItem $value]
    }

    if {[dict exists $value -equation]} {
        foreach k {-data -dataSurfaceItem -parametricEquation} {
            if {[dict exists $value $k]} {
                error "'chart' args cannot contain '$k' and '-equation'..."
            }
        }
    }

    if {[dict exists $value -parametricEquation]} {
        foreach k {-data -dataSurfaceItem -equation} {
            if {[dict exists $value $k]} {
                error "'chart' args cannot contain '$k' and '-parametricEquation'..."
            }
        }
    }

    # remove key(s)...
    set value [dict remove $value -wireframe -equation -parametricEquation -itemStyle \
                                  -realisticMaterial -lambertMaterial -colorMaterial -dataSurfaceItem]
                                
    set options [merge $options $value]

    return $options
}