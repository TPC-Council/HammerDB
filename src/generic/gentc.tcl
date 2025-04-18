#Generic GUI Transaction Counter
proc LCD_Pixels { canv_x canv_y onrim onfill offrim offfill win_scale_fact } {
    global varStdFont_8 varStdFont_16
    foreach var {varColours varLCDSize varPixelSize varPixelSpace varFonts} { upvar #0 $var $var }
    set polydim1 [ expr {round((5 / 1.333333) * $win_scale_fact)} ]
    set polydim2 [ expr {round((6 / 1.333333) * $win_scale_fact)} ]
    set polyspace [ expr {round((2 / 1.333333) * $win_scale_fact)} ]
    set varPixelSize [list $polydim1 $polydim2 $polydim1 0 0 0 0 $polydim2]
    #The space between pixels
    set varPixelSpace $polyspace
    #The number of pixels in Row, Column
    set varLCDSize [list $canv_x $canv_y]
    #LCD colours
    set varColours [list $onrim $onfill $offrim $offfill ]
    #Standard Characters
    #Build by 7 x 5 pixels (Last 3 Rows and 1 Column should be blank)
    array set varStdFont_8 {
        0 { {0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 1 1 0} \
	 {1 0 1 0 1 0} \
	 {1 1 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        1 { {0 0 0 1 0 0} \
	 {0 0 1 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 1 1 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        2 { {0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 1 0} \
	 {0 0 0 1 0 0} \
	 {0 0 1 0 0 0} \
	 {0 1 0 0 0 0} \
	 {1 1 1 1 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        3 { {0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 1 0} \
	 {0 0   1 0 0} \
	 {0 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        4 { {0 0 0 1 0 0} \
	 {0 0 1 1 0 0} \
	 {0 1 0 1 0 0} \
	 {1 0 0 1 0 0} \
	 {1 1 1 1 1 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        5 { {1 1 1 1 1 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 1 1 1 0 0} \
	 {0 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        6 { {0 0 1 1 0 0} \
	 {0 1 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        7 { {1 1 1 1 1 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 1 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        8 { {0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        9 { {0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 1 0} \
	 {0 0 0 0 1 0} \
	 {0 0 0 1 0 0} \
	 {0 1 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        ? { {0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 1 0} \
	 {0 0 0 1 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        { } {{0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        A   {{0 0 1 0 0 0} \
	 {0 1 0 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 1 1 1 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        B   {{1 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        C   {{0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        D   {{1 1 1 0 0 0} \
	 {1 0 0 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 1 0 0} \
	 {1 1 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        E  {{1 1 1 1 1 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 1 1 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 1 1 1 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        F   {{1 1 1 1 1 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 1 1 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        G   {{0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 0 0} \
	 {1 0 1 1 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        H  {{1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 1 1 1 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        I   {{1 1 1 0} \
	 {0 1 0 0} \
	 {0 1 0 0} \
	 {0 1 0 0} \
	 {0 1 0 0} \
	 {0 1 0 0} \
	 {1 1 1 0} \
	 {0 0 0 0} \
	 {0 0 0 0} \
	 {0 0 0 0}}
        J   {{0 0 1 1 1 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {1 0 0 1 0 0} \
	 {0 1 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        K   {{1 0 0 0 1 0} \
	 {1 0 0 1 0 0} \
	 {1 0 1 0 0 0} \
	 {1 1 0 0 0 0} \
	 {1 0 1 0 0 0} \
	 {1 0 0 1 0 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        L  {{1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 1 1 1 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        M  {{1 0 0 0 1 0} \
	 {1 1 0 1 1 0} \
	 {1 0 1 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        N   {{1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 1 0 0 1 0} \
	 {1 0 1 0 1 0} \
	 {1 0 0 1 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        O   {{0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        P   {{1 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 1 1 1 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        Q  {{0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 1 0 1 0} \
	 {1 0 0 1 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        R   {{1 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 1 1 1 0 0} \
	 {1 0 1 0 0 0} \
	 {1 0 0 1 0 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        S   {{0 1 1 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 0 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        T  {{1 1 1 1 1 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        U  {{1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 1 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        V   {{1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 0 1 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        W  {{1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {1 0 1 0 1 0} \
	 {1 1 0 1 1 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        X   {{1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 0 1 0 0} \
	 {0 0 1 0 0 0} \
	 {0 1 0 1 0 0} \
	 {1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        Y  {{1 0 0 0 1 0} \
	 {1 0 0 0 1 0} \
	 {0 1 0 1 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        Z   {{1 1 1 1 1 0} \
	 {0 0 0 0 1 0} \
	 {0 0 0 1 0 0} \
	 {0 0 1 0 0 0} \
	 {0 1 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {1 1 1 1 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        {+} {{0 0 0 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {1 1 1 1 1 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        {-} {{0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {1 1 1 1 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        {/} {{0 0 0 0 1 0} \
	 {0 0 0 1 0 0} \
	 {0 0 0 1 0 0} \
	 {0 0 1 0 0 0} \
	 {0 1 0 0 0 0} \
	 {0 1 0 0 0 0} \
	 {1 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        <   {{0 0 1 0 0 0} \
	 {0 1 1 1 0 0} \
	 {1 0 1 0 1 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 1 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        : { {0 0} \
	 {0 0} \
	 {1 0} \
	 {0 0} \
	 {0 0} \
	 {1 0} \
	 {0 0} \
	 {0 0} \
	 {0 0} \
	 {0 0} }
        . { {0 0} \
	 {0 0} \
	 {0 0} \
	 {0 0} \
	 {0 0} \
	 {0 0} \
	 {1 0} \
	 {0 0} \
	 {0 0} \
	 {0 0} }
        h   {{1 0 0 0 0 0} \
	 {1 1 1 0 0 0} \
	 {1 0 0 1 0 0} \
	 {1 0 0 1 0 0} \
	 {1 0 0 1 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        p   {{0 0 0 0 0} \
	 {0 1 1 0 0} \
	 {1 0 0 1 0} \
	 {1 0 0 1 0} \
	 {1 1 1 0 0} \
	 {1 0 0 0 0} \
	 {1 0 0 0 0} \
	 {0 0 0 0 0} \
	 {0 0 0 0 0} \
	 {0 0 0 0 0}}
        q   {{0 0 0 0 0 0 0} \
	 {0 0 0 1 1 0 0} \
	 {0 0 1 0 0 1 0} \
	 {0 0 1 0 0 1 0} \
	 {0 0 0 1 1 1 0} \
	 {0 0 0 0 0 1 0} \
	 {0 0 0 0 0 1 0} \
	 {0 0 0 0 0 0 0} \
	 {0 0 0 0 0 0 0} \
	 {0 0 0 0 0 0 0}}
        m   {{0 0 0 0 0 0} \
	 {1 1 1 1 0 0} \
	 {1 0 1 0 1 0} \
	 {1 0 1 0 1 0} \
	 {1 0 1 0 1 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0} \
	 {0 0 0 0 0 0}}
        t   {{0 0 0 1 0 0 0} \
	 {0 0 1 1 1 1 0} \
	 {0 0 0 1 0 0 0} \
	 {0 0 0 1 0 0 0} \
	 {0 0 0 0 1 1 0} \
	 {0 0 0 0 0 0 0} \
	 {0 0 0 0 0 0 0} \
	 {0 0 0 0 0 0 0} \
	 {0 0 0 0 0 0 0} \
	 {0 0 0 0 0 0 0}}

    }

    #Build by 13 x 10 pixels (Last 3 Rows and 1 Column should be blank)
    array set varStdFont_16 {
        0   {{0 0 1 1 1 1 1 1 0 0 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {0 0 1 1 1 1 1 1 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        1   {{0 0 0 0 1 1 1 0 0 0 0} \
	  {0 0 0 1 1 1 1 0 0 0 0} \
	  {0 0 1 1 1 1 1 0 0 0 0} \
	  {0 1 1 1 0 1 1 0 0 0 0} \
	  {0 0 0 0 0 1 1 0 0 0 0} \
	  {0 0 0 0 0 1 1 0 0 0 0} \
	  {0 0 0 0 0 1 1 0 0 0 0} \
	  {0 0 0 0 0 1 1 0 0 0 0} \
	  {0 0 0 0 0 1 1 0 0 0 0} \
	  {0 0 0 0 0 1 1 0 0 0 0} \
	  {0 0 0 0 0 1 1 0 0 0 0} \
	  {0 0 0 1 1 1 1 1 1 0 0} \
	  {0 0 0 1 1 1 1 1 1 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        2   {{0 0 1 1 1 1 1 1 0 0 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 0 0 1 1 0} \
	  {0 0 0 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 1 1 1 0 0} \
	  {0 0 0 0 0 1 1 1 0 0 0} \
	  {0 0 0 0 1 1 1 0 0 0 0} \
	  {0 0 0 1 1 1 0 0 0 0 0} \
	  {0 0 1 1 1 0 0 0 0 0 0} \
	  {0 1 1 1 0 0 0 0 0 0 0} \
	  {1 1 1 1 1 1 1 1 1 1 0} \
	  {1 1 1 1 1 1 1 1 1 1 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        3   {{0 0 1 1 1 1 1 1 0 0 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 1 1 1 0 0} \
	  {0 0 0 0 0 1 1 1 0 0 0} \
	  {0 0 0 0 0 0 1 1 1 0 0} \
	  {0 0 0 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {0 0 1 1 1 1 1 1 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        4   {{0 0 0 0 0 1 1 1 0 0 0} \
	  {0 0 0 0 1 1 1 1 0 0 0} \
	  {0 0 0 1 1 1 1 1 0 0 0} \
	  {0 0 0 1 1 0 1 1 0 0 0} \
	  {0 0 1 1 1 0 1 1 0 0 0} \
	  {0 0 1 1 0 0 1 1 0 0 0} \
	  {0 1 1 1 0 0 1 1 0 0 0} \
	  {0 1 1 0 0 0 1 1 0 0 0} \
	  {1 1 1 0 0 0 1 1 0 0 0} \
	  {1 1 1 1 1 1 1 1 1 1 0} \
	  {1 1 1 1 1 1 1 1 1 1 0} \
	  {0 0 0 0 0 0 1 1 0 0 0} \
	  {0 0 0 0 0 0 1 1 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        5   {{1 1 1 1 1 1 1 1 1 1 0} \
	  {1 1 1 1 1 1 1 1 1 1 0} \
	  {1 1 0 0 0 0 0 0 0 0 0} \
	  {1 1 0 0 0 0 0 0 0 0 0} \
	  {1 1 1 1 1 1 1 1 0 0 0} \
	  {1 1 1 1 1 1 1 1 1 0 0} \
	  {0 0 0 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 0 0 1 1 0} \
	  {0 0 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {0 0 1 1 1 1 1 1 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        6   {{0 0 0 0 1 1 1 1 1 0 0} \
	  {0 0 0 1 1 1 1 1 1 0 0} \
	  {0 0 1 1 1 0 0 0 0 0 0} \
	  {0 1 1 1 0 0 0 0 0 0 0} \
	  {0 1 1 1 0 0 0 0 0 0 0} \
	  {1 1 1 1 1 1 1 1 0 0 0} \
	  {1 1 1 1 1 1 1 1 1 0 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {0 0 1 1 1 1 1 1 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        7   {{1 1 1 1 1 1 1 1 1 1 0} \
	  {1 1 1 1 1 1 1 1 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {0 0 0 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 0 1 1 0 0} \
	  {0 0 0 0 0 0 1 1 1 0 0} \
	  {0 0 0 0 0 0 1 1 0 0 0} \
	  {0 0 0 0 0 1 1 1 0 0 0} \
	  {0 0 0 0 0 1 1 0 0 0 0} \
	  {0 0 0 0 1 1 1 0 0 0 0} \
	  {0 0 0 0 1 1 0 0 0 0 0} \
	  {0 0 0 0 1 1 0 0 0 0 0} \
	  {0 0 0 0 1 1 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        8   {{0 0 1 1 1 1 1 1 0 0 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {0 0 1 1 1 1 1 1 0 0 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {0 0 1 1 1 1 1 1 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        9   {{0 0 1 1 1 1 1 1 0 0 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {0 1 1 1 1 1 1 1 1 1 0} \
	  {0 0 1 1 1 1 1 1 1 1 0} \
	  {0 0 0 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 1 1 1 0 0} \
	  {0 0 0 0 0 1 1 1 0 0 0} \
	  {0 0 0 0 1 1 1 0 0 0 0} \
	  {0 1 1 1 1 1 0 0 0 0 0} \
	  {0 1 1 1 1 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        ?   {{0 0 1 1 1 1 1 1 0 0 0} \
	  {0 1 1 1 1 1 1 1 1 0 0} \
	  {1 1 1 0 0 0 0 1 1 1 0} \
	  {1 1 0 0 0 0 0 0 1 1 0} \
	  {1 1 0 0 0 0 0 1 1 1 0} \
	  {0 0 0 0 0 0 1 1 1 0 0} \
	  {0 0 0 0 0 1 1 1 0 0 0} \
	  {0 0 0 0 1 1 1 0 0 0 0} \
	  {0 0 0 0 1 1 0 0 0 0 0} \
	  {0 0 0 0 1 1 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 1 1 0 0 0 0 0} \
	  {0 0 0 0 1 1 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        { } {{0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0} \
	  {0 0 0 0 0 0 0 0 0 0 0}}
        :  {{0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {1 1 0} \
	  {1 1 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {1 1 0} \
	  {1 1 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0}}
        .   {{0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {1 1 0} \
	  {1 1 0} \
	  {0 0 0} \
	  {0 0 0} \
	  {0 0 0}}
    }
    set varFonts [list varStdFont_8 varStdFont_16]
}

proc LCD_Display {varMessage {varFont {0}} {varStartRow {0}} {varStartCol {0}}}  {
    global varStdFont_8 varStdFont_16
    upvar #0 varFonts varFonts
    set varRow $varStartRow
    set varCol $varStartCol
    for {set I 0} {$I < [string length $varMessage]} {incr I}  {
        set varChar [string index $varMessage $I]
        switch -regexp -- $varChar {
            [0-9]|[:\.+-/<]|[\ ]|[A-Z]|[hmpqt] {
                upvar #0 [lindex $varFonts $varFont] varLCDFont
                if {[info exist varLCDFont($varChar)]}  {
                    foreach "varRow varCol" [SetPixels $varRow $varCol $varLCDFont($varChar)] {}
                } else {
                    foreach "varRow varCol" [SetPixels $varRow $varCol $varLCDFont(?)] {}
                }
            }

            default {
                foreach "varRow varCol" [SetPixels $varRow $varCol $varLCDFont(?)] {}
            }
        }
    }
}

proc SetPixels {varRow varCol varChar}  {
    global varColours varLCDSize

    #Set the colours
    foreach {varOnRim varOnFill varOffRim varOffFill} $varColours  {}

    set varStartCol $varCol
    set varStartRow $varRow
    foreach varPixelRow $varChar {
        set varCol $varStartCol
        set varPixelCol [split $varPixelRow]
        foreach varPixel $varPixelCol {
            if {$varPixel == 0}  {
                .ed_mainFrame.tc.c itemconfigure "Pixel_$varRow,$varCol" -outline $varOffRim
                .ed_mainFrame.tc.c itemconfigure "Pixel_$varRow,$varCol" -fill $varOffFill
            } else {
                .ed_mainFrame.tc.c itemconfigure "Pixel_$varRow,$varCol" -outline $varOnRim
                .ed_mainFrame.tc.c itemconfigure "Pixel_$varRow,$varCol" -fill $varOnFill
            }
            incr varCol
        }
        incr varRow
    }
    #Try to implement autowrap, but is is to late because the character
    #may already fallen off the LCD
    if {$varCol > [lindex $varLCDSize 1]}  {
        set varStartRow $varRow
        set varCol 0
    }
    return [list $varStartRow $varCol]
}

proc showLCD {number} {
    global bm rdbms jobid
    if { $bm eq "TPC-C" } { set metric "tpm" } else { set metric "qph" }
    #blank display before displaying number
    LCD_Display "               " 0 0 0
    set LCDlen [ string length $number ]
    if { $LCDlen eq 1 } { set startcol 63 } else {
        set startcol [ expr {76-($LCDlen*7)} ]
    }
    if { $LCDlen <= 9 } {
        LCD_Display "$number$metric" 0 0 [ expr {$startcol-7} ]
    } else {
        LCD_Display "ERR:OVERFLOW" 0 0 0
    }
    write_to_transcount_log $number $rdbms $metric
    if { [ info exists jobid ] && $jobid != "" } {
        hdbjobs eval {INSERT INTO JOBTCOUNT(jobid,counter,metric) VALUES($jobid,$number,$metric)}
    }
    return
}

proc transcount { } {
    global tcl_platform masterthread tc_threadID bm rdbms afval tc_flog
    upvar #0 icons icons
    foreach var {varColours varLCDSize varPixelSize varPixelSpace varFonts} { upvar #0 $var $var }
    upvar #0 genericdict genericdict
    tsv::set application tc_errmsg ""
    #If log to temp is set open transaction counter logfile
    dict with genericdict { dict with transaction_counter {
            set interval $tc_refresh_rate
            set tclog $tc_log_to_temp
            set uniquelog $tc_unique_log_name
    }}
    if { $tclog } {
        set tc_logfile [ open_transcount_log gui $uniquelog ]
        if { $tc_logfile != "notclog" } {
            set tc_flog $tc_logfile
        } else {
            set tc_flog "notclog"
        }
    }
    set tclist [ thread::names ]
    if { [ info exists tc_threadID ] } {
        set idx [ lsearch $tclist $tc_threadID ]
        if { $idx != -1 } {
            tk_messageBox -icon warning -message "Transaction Counter Stopping"
            return 1
        }
        unset -nocomplain tc_threadID
    }
    tsv::set application timeout 0
    if {  ![ info exists bm ] } { set bm "TPC-C" }
    if {  ![ info exists rdbms ] } { set rdbms "Oracle" }
    if { [ info exists afval ] } {
        after cancel $afval
        unset afval
    }

    ed_stop_transcount
    .ed_mainFrame.notebook tab .ed_mainFrame.tc  -state normal
    .ed_mainFrame.notebook select .ed_mainFrame.tc 
    set old 0
    global win_scale_fact
    global tc_scale
    unset -nocomplain tc_scale
    set scale_width [ expr {(535 / 1.333333) * $win_scale_fact} ]
set tcc_height [ expr {(60 / 1.333333) * $win_scale_fact} ]
set tcg_height [ expr {(250 / 1.333333) * $win_scale_fact} ]
set emug_height [ expr {(150 / 1.333333) * $win_scale_fact} ]
set axistextoffset [ expr {(20 / 1.333333) * $win_scale_fact * 0.50} ]
set ticklen [ expr {(10 / 1.333333) * $win_scale_fact * 0.60} ]
set xref [ expr {(75 / 1.333333) * $win_scale_fact * 0.90} ]
if { [ string match "*dark*" $ttk::currentTheme ] } {
set tcbackground black
  } else {
set tcbackground white
}
#canvas for black on white numbers
.ed_mainFrame.tc configure -background $tcbackground
pack [ tkp::canvas .ed_mainFrame.tc.c -width $scale_width -height $tcc_height -background $tcbackground -highlightthickness 0 ] -side top -anchor ne -padx [ list 0 [ expr {$scale_width * 0.05} ] ] -ipadx [ expr {$scale_width * 0.05} ]
#Adjust width and height in case frame has already been expanded
set orig_width_percent [ expr {(floor([ expr {( [ winfo width .ed_mainFrame.tc ] - $scale_width) / $scale_width * 100}]) / 100)+1}]
set orig_height_percent [ expr {(floor([ expr {( [ winfo height .ed_mainFrame.tc ] - $tcg_height) / $tcg_height * 100}]) / 100)+1}]
set scale_width [ expr {$scale_width * $orig_width_percent * 0.80 } ]
set tcg_height [ expr {$tcg_height * $orig_height_percent} ]
set emug_height [ expr {$emug_height * $orig_height_percent} ]
    #Emu graph canas
   pack [ tkp::canvas .ed_mainFrame.tc.g -width $scale_width -height $tcg_height -background $tcbackground -highlightthickness 0 ] -fill both -expand 1 -side left  -padx [ list 0 [ expr {$scale_width * 0.05} ] ] -ipadx [ expr {$scale_width * 0.05} ]
    unset -nocomplain tc_scale
    foreach param {scale_width tcc_height tcg_height emug_height axistextoffset ticklen xref} { dict set tc_scale $param [ set $param ] }
    dict set tc_scale width [ winfo width .ed_mainFrame.tc.g ]
    dict set tc_scale height [ winfo height .ed_mainFrame.tc.g ]
    dict set tc_scale last_resize_width [ dict get $tc_scale width ]
    dict set tc_scale last_resize_height [ dict get $tc_scale height ] 
    dict set tc_scale emu_width $scale_width
    dict set tc_scale emu_height $emug_height
    dict set tc_scale resize_count 0
    dict set tc_scale last_resize 0
    bind .ed_mainFrame.tc.g <Configure> {
    #Configure is triggered dynamically whenever we resize the canvas
	    global tc_scale
	    dict set tc_scale resize_count [ expr {[ dict get $tc_scale resize_count ] + 1}]
	    if  { ([ dict get $tc_scale last_resize ] eq 0) } {
	    dict set tc_scale old_width [ dict get $tc_scale width ]
	    dict set tc_scale old_height [ dict get $tc_scale height ]
	    } else {
	    dict set tc_scale old_width [ dict get $tc_scale last_resize_width ]
	    dict set tc_scale old_height [ dict get $tc_scale last_resize_height ]
    	    }
	    dict set tc_scale width %w.0
	    dict set tc_scale height %h.0
	    #We capture canvas % scale this is passed to redraw and use to scale the emu graph
	    dict set tc_scale width_percent [ expr {(([ dict get $tc_scale width ] - [ dict get $tc_scale old_width ]) / [ dict get $tc_scale old_width ]) * 100}]
	    dict set tc_scale height_percent [ expr {(([ dict get $tc_scale height ] - [ dict get $tc_scale old_height ]) / [ dict get $tc_scale old_height ]) * 100}]
	    if  { ![ dict exists $tc_scale graph ] } { 
		dict set tc_scale graph tce
		dict set tc_scale timelist {}
		dict set tc_scale timelength {}
	    }
    #Keep the LCD Number to 5% of the top right corner
                pack .ed_mainFrame.tc.c -padx [ list 0 [ expr {[ dict get $tc_scale width ] * 0.05} ] ] 
    #Redraw the graph to same percent as the canvas has been resized
		emu_graph::redraw [ dict get $tc_scale graph ] [ dict get $tc_scale timelist ] [ dict get $tc_scale timelength ] 
    }
    set graph [ create_image graph icons ]
    .ed_mainFrame.tc.g create image [ expr {[winfo reqwidth .ed_mainFrame.tc.g ]/1.6} ] [ expr {[ winfo reqheight .ed_mainFrame.tc.g ]/3} ] -image $graph -anchor center 
    set tcdata {}
    set timedata {}
    #Set Up LCD Pixels for Canvas size X pixels by Y Pixels Pixel On Rim Colour, Pixel On Fill Colour, Pixel Off Rim Colour, Pixel Off Fill Colour
    #Black & White
    #7 x 87 is the number of pixels we create 7 in height and 87 in length. This remains fixed as we scale up pixel size.
if { [ string match "*dark*" $ttk::currentTheme ] } {
    set onrim white
    set onfill white
    set offrim black
    set offfill black
    } else {
    set onrim #626262 
    set onfill #626262 
    set offrim white
    set offfill white
    }
    LCD_Pixels 7 87 $onrim $onfill $offrim $offfill $win_scale_fact
    #Add same padding
    set varLCDx 3
    set varLCDy 3

    #Set the colours
    foreach {varOnRim varOnFill varOffRim varOffFill} $varColours  {}

    for {set varRow 0} {$varRow < [lindex $varLCDSize 0]} {incr varRow}  {
        #Reset Column position
        set varLCDx 5
        for {set varCol 0} {$varCol < [lindex $varLCDSize 1]} {incr varCol}  {
            #Create the pixel
            set varPixel [.ed_mainFrame.tc.c create polygon $varPixelSize -tags "Pixel_$varRow,$varCol" \
		 -outline $varOffRim -fill $varOffFill]
            #Put it in its place
            .ed_mainFrame.tc.c move $varPixel $varLCDx $varLCDy
            #Next column position
            incr varLCDx [lindex $varPixelSize 0]
            incr varLCDx $varPixelSpace
        }
        #Next row position
        incr varLCDy [lindex $varPixelSize 1]
        incr varLCDy $varPixelSpace
    }
    #Add same padding
    incr varLCDy 3
    incr varLCDx 3
    #showLCD 0

    emu_graph::emu_graph tce -canvas .ed_mainFrame.tc.g -width $scale_width -height $emug_height \
-axistextoffset $axistextoffset -autorange 1 -ticklen $ticklen -xref $xref

    #Call Database specific transaction counter
    upvar #0 dbdict dbdict
    foreach { key } [ dict keys $dbdict ] {
        if { [ dict get $dbdict $key name ] eq $rdbms } { 
            set prefix [ dict get $dbdict $key prefix ]
            set command [ concat [subst {tcount_$prefix $bm $interval $masterthread}]]
            eval $command 
            break
        }
    }
    if { [ info exists tc_threadID ] } {
        tsv::set application thecount $tc_threadID
    }
}

proc ed_kill_transcount {args} {
    global _ED
    tsv::set application timeout 1
    ed_status_message -show "... Stopping Transaction Counter ..."
    close_transcount_log gui
    update
    ed_transcount_button
    update
    if {[winfo exists .ed_mainFrame.tc]} {
        destroy .ed_mainFrame.tc.c ;
        destroy .ed_mainFrame.tc.g ;
    }
    .ed_mainFrame.notebook select .ed_mainFrame.mainwin
    if ![ string match "*.ed_mainFrame.tc*" [ .ed_mainFrame.notebook tabs ]] {
        #transaction counter has been detached so reattach before disabling
        Attach .ed_mainFrame.notebook .ed_mainFrame.tc 2
    }
    .ed_mainFrame.notebook tab .ed_mainFrame.tc -state disabled
    ed_status_message -finish "Transaction Counter Stopped"
}

proc show_tc_errmsg {} {
    global jobid
    upvar #0 icons icons
    set ban [ create_image ban icons ]
    set tc_errmsg [ tsv::get application tc_errmsg ]
    if { $tc_errmsg != "" } {
        if [catch {set joinedmsg [ join $tc_errmsg ]} message ] {
            #error in join show unjoined message
	    puts "Transaction Counter Error: $tc_errmsg"
            hdbjobs eval {INSERT INTO JOBTCOUNT(jobid,counter,metric) VALUES($jobid,0,$tc_errmsg)}
        } else {
            #show joined message
	    puts "Transaction Counter Error: $joinedmsg"
            hdbjobs eval {INSERT INTO JOBTCOUNT(jobid,counter,metric) VALUES($jobid,0,$joinedmsg)}
        }
    } else {
        putscli "Transaction Counter Error"
    }
    LCD_Display "               " 0 0 0
    LCD_Display "   TX ERROR   " 0 0 0
    #attempt to delete canvas
    catch { .ed_mainFrame.tc.g delete "all" }
    .ed_mainFrame.tc.g create image [ expr {[winfo reqwidth .ed_mainFrame.tc.g ]/1.6} ] [ expr {[ winfo reqheight .ed_mainFrame.tc.g ]/3} ] -image $ban -anchor center
    #error message is always followed by thread release before loop enter
    #so remove tc_threadID to prevent false positive on startup
    post_kill_transcount_cleanup
}
