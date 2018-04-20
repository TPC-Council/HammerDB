proc LCD_Pixels { canv_x canv_y onrim onfill offrim offfill } {
global varStdFont_8 varStdFont_16
foreach var {varColours varLCDSize varPixelSize varPixelSpace varFonts} { upvar #0 $var $var }
 set varPixelSize [list 5 6 5 0 0 0 0 6]
 #The space between pixels
 set varPixelSpace 2
 #The number of pixels in Row, Column
 #set varLCDSize [list 32 122]
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
global bm
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
return
 }

proc transcount { } {
global tcl_platform masterthread tc_threadID bm rdbms afval
upvar #0 icons icons
foreach var {varColours varLCDSize varPixelSize varPixelSpace varFonts} { upvar #0 $var $var }
upvar #0 genericdict genericdict
tsv::set application tc_errmsg ""
if {[dict exists $genericdict settings refresh_rate]} {
set interval [ dict get $genericdict settings refresh_rate ]
        } else { set interval 10 }

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
#canvas for black on white numbers
pack [ canvas .ed_mainFrame.tc.c -width 525 -height 60 -background white -highlightthickness 0 ] -fill both -expand 1 -side top
#Emu graph canvas
pack [ canvas .ed_mainFrame.tc.g -width 525 -height 250 -background white -highlightthickness 0 ] -fill both -expand 1 -side left
set graph [image create photo -data [ dict get $icons graph ] -gamma 1 -palette 5/5/4]
.ed_mainFrame.tc.g create image 300 100 -image $graph
set tcdata {}
set timedata {}
#Set Up LCD Pixels for Canvas size X pixels by Y Pixels Pixel On Rim Colour, Pixel On Fill Colour, Pixel Off Rim Colour, Pixel Off Fill Colour
#Black & White
LCD_Pixels 7 87 #626262 black white white
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
showLCD 0

emu_graph::emu_graph tce -canvas .ed_mainFrame.tc.g -width 525 -height 150 \
-axistextoffset 10 -autorange 1 -ticklen 5 -xref 75

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

proc post_kill_transcount_cleanup {} {
global tc_threadID
unset -nocomplain tc_threadID
tsv::set application timeout 2
tsv::unset application thecount
 }

proc show_tc_errmsg {} {
upvar #0 icons icons
set ban [image create photo -data [ dict get $icons ban ] -gamma 1 -palette 5/5/4]
set tc_errmsg [ tsv::get application tc_errmsg ]
if { $tc_errmsg != "" } {
puts "Transaction Counter Error:$tc_errmsg"
	}
LCD_Display "               " 0 0 0
LCD_Display "   TX ERROR   " 0 0 0
#attempt to delete canvas
catch { .ed_mainFrame.tc.g delete "all" }
.ed_mainFrame.tc.g create image 300 100 -image $ban
#error message is always followed by thread release before loop enter
#so remove tc_threadID to prevent false positive on startup
post_kill_transcount_cleanup
}

proc setlocaltcountvars { configdict allvars } {
#set variables to values in dict
if $allvars {
dict for {descriptor attributes} $configdict  {
if {$descriptor eq "connection" || $descriptor eq "tpcc" || $descriptor eq "tpch" } {
foreach { val } [ dict keys $attributes ] {
uplevel "variable $val"
upvar 1 $val $val
if {[dict exists $attributes $val]} {
set $val [ dict get $attributes $val ]
}}}}
} else {
dict for {descriptor attributes} $configdict  {
if {$descriptor eq "connection" } {
foreach { val } [ dict keys $attributes ] {
uplevel "variable $val"
upvar 1 $val $val
if {[dict exists $attributes $val]} {
set $val [ dict get $attributes $val ]
}}}}
}
}
