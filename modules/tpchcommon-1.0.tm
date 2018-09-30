package provide tpchcommon 1.0
namespace eval tpchcommon {
namespace export chk_thread start_end findvuhposition RandomNumber set_dists get_dists set_dist_list LEAP LEAP_ADJ julian mk_time mk_sparse PART_SUPP_BRIDGE rpb_routine gen_phone MakeAlphaString calc_weight pick_str_1 pick_str_2 txt_vp_1 txt_vp_2 txt_np_1 txt_np_2 txt_sentence_1 txt_sentence_2 dbg_text_1 dbg_text_2 V_STR TEXT_1 TEXT_2 ordered_set gmean printlist
#TPCH BUILD PROCEDURES
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
#FIND BUILD START AND END
proc start_end { sup_rows myposition my_mult num_vu } {
set sf_chunk [ expr $sup_rows / $num_vu ]
set sf_rem [ expr $sup_rows % $num_vu ]
set chunk [ expr {$sf_chunk * $my_mult} ]
set rem [ expr {$sf_rem * $my_mult} ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_vu + 1 } { set myend [ expr {$sup_rows * $my_mult} ] }
return $mystart:$myend
}
#FIND VIRTUAL USER POSITION
proc findvuhposition {}  {
set mythread [thread::id]
set allthreads [split [thread::names]]
if {![catch {set masterthread [ tsv::get application themaster ]}]} {
set idx [lsearch -exact $allthreads $masterthread]
if { $idx != -1 } {
set allthreads [ lreplace $allthreads $idx $idx ]
        }
}
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
if {![catch {set countthread [ tsv::get application thecount ]}]} {
set idx [lsearch -exact $allthreads $countthread]
if { $idx != -1 } {
set allthreads [ lreplace $allthreads $idx $idx ]
             }
          }
       }
    }
if {![catch {set monitorthread [ tsv::get application themonitor ]}]} {
set idx [lsearch -exact $allthreads $monitorthread]
if { $idx != -1 } {
set allthreads [ lreplace $allthreads $idx $idx ]
        }
}
set totalvirtualusers  [llength $allthreads]
set myposition [ expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
return [ list $myposition $totalvirtualusers ]
}
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#SET DISTS
proc set_dists {} { 
global dists
set dists(category) {{FURNITURE 1} {{STORAGE EQUIP} 1} {TOOLS 1} {{MACHINE TOOLS} 1} {OTHER 1}}
set dists(p_cntr) {{{SM CASE} 1} {{SM BOX} 1} {{SM BAG} 1} {{SM JAR} 1} {{SM PACK} 1} {{SM PKG} 1} {{SM CAN} 1} {{SM DRUM} 1} {{LG CASE} 1} {{LG BOX} 1} {{LG BAG} 1} {{LG JAR} 1} {{LG PACK} 1} {{LG PKG} 1} {{LG CAN} 1} {{LG DRUM} 1} {{MED CASE} 1} {{MED BOX} 1} {{MED BAG} 1} {{MED JAR} 1} {{MED PACK} 1} {{MED PKG} 1} {{MED CAN} 1} {{MED DRUM} 1} {{JUMBO CASE} 1} {{JUMBO BOX} 1} {{JUMBO BAG} 1} {{JUMBO JAR} 1} {{JUMBO PACK} 1} {{JUMBO PKG} 1} {{JUMBO CAN} 1} {{JUMBO DRUM} 1} {{WRAP CASE} 1} {{WRAP BOX} 1} {{WRAP BAG} 1} {{WRAP JAR} 1} {{WRAP PACK} 1} {{WRAP PKG} 1} {{WRAP CAN} 1} {{WRAP DRUM} 1}}
set dists(instruct) {{{DELIVER IN PERSON} 1} {{COLLECT COD} 1} {{TAKE BACK RETURN} 1} {NONE 1}}
set dists(msegmnt) {{AUTOMOBILE 1} {BUILDING 1} {FURNITURE 1} {HOUSEHOLD 1} {MACHINERY 1}}
set dists(p_names) {{CLEANER 1} {SOAP 1} {DETERGENT 1} {EXTRA 1}}
set dists(nations) {{ALGERIA 0} {ARGENTINA 1} {BRAZIL 0} {CANADA 0} {EGYPT 3} {ETHIOPIA -4} {FRANCE 3} {GERMANY 0} {INDIA -1} {INDONESIA 0} {IRAN 2} {IRAQ 0} {JAPAN -2} {JORDAN 2} {KENYA -4} {MOROCCO 0} {MOZAMBIQUE 0} {PERU 1} {CHINA 1} {ROMANIA 1} {{SAUDI ARABIA} 1} {VIETNAM -2} {RUSSIA 1} {{UNITED KINGDOM} 0} {{UNITED STATES} -2}}
set dists(nations2) {{ALGERIA 1} {ARGENTINA 1} {BRAZIL 1} {CANADA 1} {EGYPT 1} {ETHIOPIA 1} {FRANCE 1} {GERMANY 1} {INDIA 1} {INDONESIA 1} {IRAN 1} {IRAQ 1} {JAPAN 1} {JORDAN 1} {KENYA 1} {MOROCCO 1} {MOZAMBIQUE 1} {PERU 1} {CHINA 1} {ROMANIA 1} {{SAUDI ARABIA} 1} {VIETNAM 1} {RUSSIA 1} {{UNITED KINGDOM} 1} {{UNITED STATES} 1}}
set dists(regions) {{AFRICA 1} {AMERICA 1} {ASIA 1} {EUROPE 1} {{MIDDLE EAST} 1}}
set dists(o_oprio) {{1-URGENT 1} {2-HIGH 1} {3-MEDIUM 1} {{4-NOT SPECIFIED} 1} {5-LOW 1}}
set dists(rflag) {{R 1} {A 1}}
set dists(smode) {{{REG AIR} 1} {AIR 1} {RAIL 1} {TRUCK 1} {MAIL 1} {FOB 1} {SHIP 1}}
set dists(p_types) {{{STANDARD ANODIZED TIN} 1} {{STANDARD ANODIZED NICKEL} 1} {{STANDARD ANODIZED BRASS} 1} {{STANDARD ANODIZED STEEL} 1} {{STANDARD ANODIZED COPPER} 1} {{STANDARD BURNISHED TIN} 1} {{STANDARD BURNISHED NICKEL} 1} {{STANDARD BURNISHED BRASS} 1} {{STANDARD BURNISHED STEEL} 1} {{STANDARD BURNISHED COPPER} 1} {{STANDARD PLATED TIN} 1} {{STANDARD PLATED NICKEL} 1} {{STANDARD PLATED BRASS} 1} {{STANDARD PLATED STEEL} 1} {{STANDARD PLATED COPPER} 1} {{STANDARD POLISHED TIN} 1} {{STANDARD POLISHED NICKEL} 1} {{STANDARD POLISHED BRASS} 1} {{STANDARD POLISHED STEEL} 1} {{STANDARD POLISHED COPPER} 1} {{STANDARD BRUSHED TIN} 1} {{STANDARD BRUSHED NICKEL} 1} {{STANDARD BRUSHED BRASS} 1} {{STANDARD BRUSHED STEEL} 1} {{STANDARD BRUSHED COPPER} 1} {{SMALL ANODIZED TIN} 1} {{SMALL ANODIZED NICKEL} 1} {{SMALL ANODIZED BRASS} 1} {{SMALL ANODIZED STEEL} 1} {{SMALL ANODIZED COPPER} 1} {{SMALL BURNISHED TIN} 1} {{SMALL BURNISHED NICKEL} 1} {{SMALL BURNISHED BRASS} 1} {{SMALL BURNISHED STEEL} 1} {{SMALL BURNISHED COPPER} 1} {{SMALL PLATED TIN} 1} {{SMALL PLATED NICKEL} 1} {{SMALL PLATED BRASS} 1} {{SMALL PLATED STEEL} 1} {{SMALL PLATED COPPER} 1} {{SMALL POLISHED TIN} 1} {{SMALL POLISHED NICKEL} 1} {{SMALL POLISHED BRASS} 1} {{SMALL POLISHED STEEL} 1} {{SMALL POLISHED COPPER} 1} {{SMALL BRUSHED TIN} 1} {{SMALL BRUSHED NICKEL} 1} {{SMALL BRUSHED BRASS} 1} {{SMALL BRUSHED STEEL} 1} {{SMALL BRUSHED COPPER} 1} {{MEDIUM ANODIZED TIN} 1} {{MEDIUM ANODIZED NICKEL} 1} {{MEDIUM ANODIZED BRASS} 1} {{MEDIUM ANODIZED STEEL} 1} {{MEDIUM ANODIZED COPPER} 1} {{MEDIUM BURNISHED TIN} 1} {{MEDIUM BURNISHED NICKEL} 1} {{MEDIUM BURNISHED BRASS} 1} {{MEDIUM BURNISHED STEEL} 1} {{MEDIUM BURNISHED COPPER} 1} {{MEDIUM PLATED TIN} 1} {{MEDIUM PLATED NICKEL} 1} {{MEDIUM PLATED BRASS} 1} {{MEDIUM PLATED STEEL} 1} {{MEDIUM PLATED COPPER} 1} {{MEDIUM POLISHED TIN} 1} {{MEDIUM POLISHED NICKEL} 1} {{MEDIUM POLISHED BRASS} 1} {{MEDIUM POLISHED STEEL} 1} {{MEDIUM POLISHED COPPER} 1} {{MEDIUM BRUSHED TIN} 1} {{MEDIUM BRUSHED NICKEL} 1} {{MEDIUM BRUSHED BRASS} 1} {{MEDIUM BRUSHED STEEL} 1} {{MEDIUM BRUSHED COPPER} 1} {{LARGE ANODIZED TIN} 1} {{LARGE ANODIZED NICKEL} 1} {{LARGE ANODIZED BRASS} 1} {{LARGE ANODIZED STEEL} 1} {{LARGE ANODIZED COPPER} 1} {{LARGE BURNISHED TIN} 1} {{LARGE BURNISHED NICKEL} 1} {{LARGE BURNISHED BRASS} 1} {{LARGE BURNISHED STEEL} 1} {{LARGE BURNISHED COPPER} 1} {{LARGE PLATED TIN} 1} {{LARGE PLATED NICKEL} 1} {{LARGE PLATED BRASS} 1} {{LARGE PLATED STEEL} 1} {{LARGE PLATED COPPER} 1} {{LARGE POLISHED TIN} 1} {{LARGE POLISHED NICKEL} 1} {{LARGE POLISHED BRASS} 1} {{LARGE POLISHED STEEL} 1} {{LARGE POLISHED COPPER} 1} {{LARGE BRUSHED TIN} 1} {{LARGE BRUSHED NICKEL} 1} {{LARGE BRUSHED BRASS} 1} {{LARGE BRUSHED STEEL} 1} {{LARGE BRUSHED COPPER} 1} {{ECONOMY ANODIZED TIN} 1} {{ECONOMY ANODIZED NICKEL} 1} {{ECONOMY ANODIZED BRASS} 1} {{ECONOMY ANODIZED STEEL} 1} {{ECONOMY ANODIZED COPPER} 1} {{ECONOMY BURNISHED TIN} 1} {{ECONOMY BURNISHED NICKEL} 1} {{ECONOMY BURNISHED BRASS} 1} {{ECONOMY BURNISHED STEEL} 1} {{ECONOMY BURNISHED COPPER} 1} {{ECONOMY PLATED TIN} 1} {{ECONOMY PLATED NICKEL} 1} {{ECONOMY PLATED BRASS} 1} {{ECONOMY PLATED STEEL} 1} {{ECONOMY PLATED COPPER} 1} {{ECONOMY POLISHED TIN} 1} {{ECONOMY POLISHED NICKEL} 1} {{ECONOMY POLISHED BRASS} 1} {{ECONOMY POLISHED STEEL} 1} {{ECONOMY POLISHED COPPER} 1} {{ECONOMY BRUSHED TIN} 1} {{ECONOMY BRUSHED NICKEL} 1} {{ECONOMY BRUSHED BRASS} 1} {{ECONOMY BRUSHED STEEL} 1} {{ECONOMY BRUSHED COPPER} 1} {{PROMO ANODIZED TIN} 1} {{PROMO ANODIZED NICKEL} 1} {{PROMO ANODIZED BRASS} 1} {{PROMO ANODIZED STEEL} 1} {{PROMO ANODIZED COPPER} 1} {{PROMO BURNISHED TIN} 1} {{PROMO BURNISHED NICKEL} 1} {{PROMO BURNISHED BRASS} 1} {{PROMO BURNISHED STEEL} 1} {{PROMO BURNISHED COPPER} 1} {{PROMO PLATED TIN} 1} {{PROMO PLATED NICKEL} 1} {{PROMO PLATED BRASS} 1} {{PROMO PLATED STEEL} 1} {{PROMO PLATED COPPER} 1} {{PROMO POLISHED TIN} 1} {{PROMO POLISHED NICKEL} 1} {{PROMO POLISHED BRASS} 1} {{PROMO POLISHED STEEL} 1} {{PROMO POLISHED COPPER} 1} {{PROMO BRUSHED TIN} 1} {{PROMO BRUSHED NICKEL} 1} {{PROMO BRUSHED BRASS} 1} {{PROMO BRUSHED STEEL} 1} {{PROMO BRUSHED COPPER} 1}}
set dists(colors) {{almond 1} {antique 1} {aquamarine 1} {azure 1} {beige 1} {bisque 1} {black 1} {blanched 1} {blue 1} {blush 1} {brown 1} {burlywood 1} {burnished 1} {chartreuse 1} {chiffon 1} {chocolate 1} {coral 1} {cornflower 1} {cornsilk 1} {cream 1} {cyan 1} {dark 1} {deep 1} {dim 1} {dodger 1} {drab 1} {firebrick 1} {floral 1} {forest 1} {frosted 1} {gainsboro 1} {ghost 1} {goldenrod 1} {green 1} {grey 1} {honeydew 1} {hot 1} {indian 1} {ivory 1} {khaki 1} {lace 1} {lavender 1} {lawn 1} {lemon 1} {light 1} {lime 1} {linen 1} {magenta 1} {maroon 1} {medium 1} {metallic 1} {midnight 1} {mint 1} {misty 1} {moccasin 1} {navajo 1} {navy 1} {olive 1} {orange 1} {orchid 1} {pale 1} {papaya 1} {peach 1} {peru 1} {pink 1} {plum 1} {powder 1} {puff 1} {purple 1} {red 1} {rose 1} {rosy 1} {royal 1} {saddle 1} {salmon 1} {sandy 1} {seashell 1} {sienna 1} {sky 1} {slate 1} {smoke 1} {snow 1} {spring 1} {steel 1} {tan 1} {thistle 1} {tomato 1} {turquoise 1} {violet 1} {wheat 1} {white 1} {yellow 1}}
set dists(nouns) {{packages 40} {requests 40} {accounts 40} {deposits 40} {foxes 20} {ideas 20} {theodolites 20} {{pinto beans} 20} {instructions 20} {dependencies 10} {excuses 10} {platelets 10} {asymptotes 10} {courts 5} {dolphins 5} {multipliers 1} {sauternes 1} {warthogs 1} {frets 1} {dinos 1} {attainments 1} {somas 1} {Tiresias 1} {patterns 1} {forges 1} {braids 1} {frays 1} {warhorses 1} {dugouts 1} {notornis 1} {epitaphs 1} {pearls 1} {tithes 1} {waters 1} {orbits 1} {gifts 1} {sheaves 1} {depths 1} {sentiments 1} {decoys 1} {realms 1} {pains 1} {grouches 1} {escapades 1} {{hockey players} 1}}
set dists(verbs) {{sleep 20} {wake 20} {are 20} {cajole 20} {haggle 20} {nag 10} {use 10} {boost 10} {affix 5} {detect 5} {integrate 5} {maintain 1} {nod 1} {was 1} {lose 1} {sublate 1} {solve 1} {thrash 1} {promise 1} {engage 1} {hinder 1} {print 1} {x-ray 1} {breach 1} {eat 1} {grow 1} {impress 1} {mold 1} {poach 1} {serve 1} {run 1} {dazzle 1} {snooze 1} {doze 1} {unwind 1} {kindle 1} {play 1} {hang 1} {believe 1} {doubt 1}}
set dists(adverbs) {{sometimes 1} {always 1} {never 1} {furiously 50} {slyly 50} {carefully 50} {blithely 40} {quickly 30} {fluffily 20} {slowly 1} {quietly 1} {ruthlessly 1} {thinly 1} {closely 1} {doggedly 1} {daringly 1} {bravely 1} {stealthily 1} {permanently 1} {enticingly 1} {idly 1} {busily 1} {regularly 1} {finally 1} {ironically 1} {evenly 1} {boldly 1} {silently 1}}
set dists(articles) {{the 50} {a 20} {an 5}}
set dists(prepositions) {{about 50} {above 50} {{according to} 50} {across 50} {after 50} {against 40} {along 40} {{alongside of} 30} {among 30} {around 20} {at 10} {atop 1} {before 1} {behind 1} {beneath 1} {beside 1} {besides 1} {between 1} {beyond 1} {by 1} {despite 1} {during 1} {except 1} {for 1} {from 1} {{in place of} 1} {inside 1} {{instead of} 1} {into 1} {near 1} {of 1} {on 1} {outside 1} {over {1 }} {past 1} {since 1} {through 1} {throughout 1} {to 1} {toward 1} {under 1} {until 1} {up {1 }} {upon 1} {whithout 1} {with 1} {within 1}}
set dists(auxillaries) {{do 1} {may 1} {might 1} {shall 1} {will 1} {would 1} {can 1} {could 1} {should 1} {{ought to} 1} {must 1} {{will have to} 1} {{shall have to} 1} {{could have to} 1} {{should have to} 1} {{must have to} 1} {{need to} 1} {{try to} 1}}
set dists(terminators) {{. 50} {{;} 1} {: 1} {? 1} {! 1} {-- 1}}
set dists(adjectives) {{special 20} {pending 20} {unusual 20} {express 20} {furious 1} {sly 1} {careful 1} {blithe 1} {quick 1} {fluffy 1} {slow 1} {quiet 1} {ruthless 1} {thin 1} {close 1} {dogged 1} {daring 1} {brave 1} {stealthy 1} {permanent 1} {enticing 1} {idle 1} {busy 1} {regular 50} {final 40} {ironic 40} {even 30} {bold 20} {silent 10}}
set dists(grammar) {{{N V T} 3} {{N V P T} 3} {{N V N T} 3} {{N P V N T} 1} {{N P V P T} 1}}
set dists(np) {{N 10} {{J N} 20} {{J J N} 10} {{D J N} 50}}
set dists(vp) {{V 30} {{X V} 1} {{V D} 40} {{X V D} 1}}
set dists(Q13a) {{special 20} {pending 20} {unusual 20} {express 20}}
set dists(Q13b) {{packages 40} {requests 40} {accounts 40} {deposits 40}}
}
#GET DISTS
proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}
#DIST LIST
proc set_dist_list {dist_type} {
global dists weights dist_names dist_weights
set name $dist_type
set dist_list $dists($dist_type)
set dist_list_length [ llength $dist_list ]
if { [ array get weights $name ] != "" } { set max_weight $weights($name) } else {
set max_weight [ calc_weight $dist_list $name ]
	}
set i 0
while {$i < $dist_list_length} {
set dist_name [ lindex [lindex $dist_list $i ] 0 ]
set dist_value [ lindex [ join [lindex $dist_list $i ] ] end ]
lappend dist_names($dist_type) $dist_name
lappend dist_weights($dist_type) $dist_value 
incr i
	}
}
#LEAP
proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}
#LEAP_ADJ
proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}
#JULIAN
proc julian { date } {
set offset [ expr {$date - 92001} ]
set result 92001
while { 1 eq 1 } {
set yr [ expr {$result / 1000} ]
set yend [ expr {$yr * 1000 + 365 + [ LEAP $yr ]} ]
if { [ expr {$result + $offset > $yend} ] } {
set offset [ expr {$offset - ($yend - $result + 1)} ]
set result [ expr {$result + 1000} ]
continue
	} else { break }
}
return [ expr {$result + $offset} ]
}
#MK_TIME
proc mk_time { index } {
set list {JAN 31 31 FEB 28 59 MAR 31 90 APR 30 120 MAY 31 151 JUN 30 181 JUL 31 212 AUG 31 243 SEP 30 273 OCT 31 304 NOV 30 334 DEC 31 365}
set timekey [ expr {$index + 8035} ]
set jyd [ julian [ expr {($index + 92001 - 1)} ] ] 
set y [ expr {$jyd / 1000} ]
set d [ expr {$jyd % 1000} ]
set year [ expr {1900 + $y} ]
set m 2
set n [ llength $list ]
set month [ lindex $list [ expr {$m - 2} ] ]
set day $d
while { ($d > [ expr {[ lindex $list $m ] + [ LEAP_ADJ $y [ expr {($m + 1) / 3} ]]}]) } {
set month [ lindex $list [ expr $m + 1 ] ]
set day [ expr {$d - [ lindex $list $m ] - [ LEAP_ADJ $y [ expr ($m + 1) / 3 ] ]} ]
incr m +3
}
set day [ format %02d $day ]
return [ concat $year-$month-$day ]
}
#MK_SPARSE
proc mk_sparse { i seq } {
set ok $i
set low_bits [ expr {$i & ((1 << 3) - 1)} ]
set ok [ expr {$ok >> 3} ]
set ok [ expr {$ok << 2} ]
set ok [ expr {$ok + $seq} ]
set ok [ expr {$ok << 3} ]
set ok [ expr {$ok + $low_bits} ]
return $ok
}
#PART_SUPP_BRIDGE
proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}
#RPB_ROUTINE
proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}
#PHONE
proc gen_phone {} {
set acode [ RandomNumber 100 999 ]
set exchg [ RandomNumber 100 999 ]
set number [ RandomNumber 1000 9999 ]
return [ concat $acode-$exchg-$number ]
}
#ALPHA STRING
proc MakeAlphaString { min max chArray chalen } {
set len [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}
#WEIGHT
proc calc_weight { list name } {
global weights
set total 0
set n [ expr {[llength $list] - 1} ]
while {$n >= 0} {
set interim [ lindex [ join [lindex $list $n] ] end ]
set total [ expr {$total + $interim} ]
incr n -1
	}
set weights($name) $total
return $total
}
#PICK STR BUILD
proc pick_str_1 { name } {
global weights dist_names dist_weights
set total 0
set i 0
set ran_weight [ RandomNumber 1  $weights($name) ]
while {$total < $ran_weight} {
set total [ expr {$total + [lindex $dist_weights($name) $i ]} ]
incr i
}
return  [lindex $dist_names($name) [ expr {$i - 1} ]]
}
#TXT VP BUILD
proc txt_vp_1 {} {
set verb_list [ split [ pick_str_1 vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str_1 $src ] " "
incr c
}
return $verb_p
}
#TXT NP BUILD
proc txt_np_1 {} {
set noun_list [ split [ pick_str_1 np ] ]
set c 0
set n [ expr {[llength $noun_list] - 1} ]
while {$c <= $n } {
set interim [lindex $noun_list $c]
switch $interim {
A { set src articles }
J { set src adjectives }
D { set src adverbs }
N { set src nouns }
}
append verb_p [ pick_str_1 $src ] " "
incr c
}
return $verb_p
}
#TXT SENTENCE BUILD
proc txt_sentence_1 {} {
set sen_list [ split [ pick_str_1 grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp_1 ] }
N { append txt [ txt_np_1 ] }
P { append txt [ pick_str_1 prepositions ] " the "
append txt [ txt_np_1 ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str_1 terminators ] }
}
incr c
}
return $txt
}
#DBG TEXT BUILD
proc dbg_text_1 {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence_1 ] 
set s_len [ string length $part_sen ]
set needed [ expr {$length - $wordlen} ]
if { $needed >= [ expr {$s_len + 1} ] } {
append sentence "$part_sen "
set wordlen [ expr {$wordlen + $s_len + 1}]
	} else {
append sentence [ string range $part_sen 0 $needed ] 
set wordlen [ expr {$wordlen + $needed} ]
	}
}
return $sentence
}
#V STR
proc V_STR { avg } {
set globArray [ list , \  0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
return [ MakeAlphaString [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] $globArray $chalen ] 
}
#TEXT BUILD
proc TEXT_1 { avg } {
return [ dbg_text_1 [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}
#TPCH DRIVER PROCEDURES
#PICK STR DRIVER
proc pick_str_2 { dists name } {
global weights
set total 0
set i 0
if { [ array get weights $name ] != "" } { set max_weight $weights($name) } else {
set max_weight [ calc_weight $dists $name ]
        }
set ran_weight [ RandomNumber 1 $max_weight ]
while {$total < $ran_weight} {
set interim [ lindex [ join [lindex $dists $i ] ] end ]
set total [ expr {$total + $interim} ]
incr i
}
set pkstr [ lindex [lindex $dists [ expr {$i - 1} ] ] 0 ]
return $pkstr
}
#TXT_VP DRIVER
proc txt_vp_2 {} {
set verb_list [ split [ pick_str_2 [ get_dists vp ] vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str_2 [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}
#TXT_NP DRIVER
proc txt_np_2 {} {
set noun_list [ split [ pick_str_2 [ get_dists np ] np ] ]
set c 0
set n [ expr {[llength $noun_list] - 1} ]
while {$c <= $n } {
set interim [lindex $noun_list $c]
switch $interim {
A { set src articles }
J { set src adjectives }
D { set src adverbs }
N { set src nouns }
}
append verb_p [ pick_str_2 [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}
#TXT_SENTENCE DRIVER
proc txt_sentence_2 {} {
set sen_list [ split [ pick_str_2 [ get_dists grammar ] grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp_2 ] }
N { append txt [ txt_np_2 ] }
P { append txt [ pick_str_2 [ get_dists prepositions ] prepositions ] " the "
append txt [ txt_np_2 ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str_2 [ get_dists terminators ] terminators ] }
}
incr c
}
return $txt
}
#DBG TEXT BUILD
proc dbg_text_2 {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence_2 ] 
set s_len [ string length $part_sen ]
set needed [ expr {$length - $wordlen} ]
if { $needed >= [ expr {$s_len + 1} ] } {
append sentence "$part_sen "
set wordlen [ expr {$wordlen + $s_len + 1}]
	} else {
append sentence [ string range $part_sen 0 $needed ] 
set wordlen [ expr {$wordlen + $needed} ]
	}
}
return $sentence
}
#TEXT BUILD
proc TEXT_2 { avg } {
return [ dbg_text_2 [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}
#ORDERED SET
proc ordered_set { myposition } {
if { $myposition > 40 } { set myposition [ expr $myposition % 40 ] }
        set o_s(0)  { 14 2 9 20 6 17 18 8 21 13 3 22 16 4 11 15 1 10 19 5 7 12 }
        set o_s(1)  { 21 3 18 5 11 7 6 20 17 12 16 15 13 10 2 8 14 19 9 22 1 4 }
        set o_s(2)  { 6 17 14 16 19 10 9 2 15 8 5 22 12 7 13 18 1 4 20 3 11 21 }
        set o_s(3)  { 8 5 4 6 17 7 1 18 22 14 9 10 15 11 20 2 21 19 13 16 12 3 }
        set o_s(4)  { 5 21 14 19 15 17 12 6 4 9 8 16 11 2 10 18 1 13 7 22 3 20 }
        set o_s(5)  { 21 15 4 6 7 16 19 18 14 22 11 13 3 1 2 5 8 20 12 17 10 9 }
        set o_s(6)  { 10 3 15 13 6 8 9 7 4 11 22 18 12 1 5 16 2 14 19 20 17 21 }
        set o_s(7)  { 18 8 20 21 2 4 22 17 1 11 9 19 3 13 5 7 10 16 6 14 15 12 }
        set o_s(8)  { 19 1 15 17 5 8 9 12 14 7 4 3 20 16 6 22 10 13 2 21 18 11 }
        set o_s(9)  { 8 13 2 20 17 3 6 21 18 11 19 10 15 4 22 1 7 12 9 14 5 16 }
        set o_s(10) { 6 15 18 17 12 1 7 2 22 13 21 10 14 9 3 16 20 19 11 4 8 5 }
        set o_s(11) { 15 14 18 17 10 20 16 11 1 8 4 22 5 12 3 9 21 2 13 6 19 7 }
        set o_s(12) { 1 7 16 17 18 22 12 6 8 9 11 4 2 5 20 21 13 10 19 3 14 15 }
        set o_s(13) { 21 17 7 3 1 10 12 22 9 16 6 11 2 4 5 14 8 20 13 18 15 19 }
        set o_s(14) { 2 9 5 4 18 1 20 15 16 17 7 21 13 14 19 8 22 11 10 3 12 6 }
        set o_s(15) { 16 9 17 8 14 11 10 12 6 21 7 3 15 5 22 20 1 13 19 2 4 18 }
        set o_s(16) { 1 3 6 5 2 16 14 22 17 20 4 9 10 11 15 8 12 19 18 13 7 21 }
        set o_s(17) { 3 16 5 11 21 9 2 15 10 18 17 7 8 19 14 13 1 4 22 20 6 12 }
        set o_s(18) { 14 4 13 5 21 11 8 6 3 17 2 20 1 19 10 9 12 18 15 7 22 16 }
        set o_s(19) { 4 12 22 14 5 15 16 2 8 10 17 9 21 7 3 6 13 18 11 20 19 1 }
        set o_s(20) { 16 15 14 13 4 22 18 19 7 1 12 17 5 10 20 3 9 21 11 2 6 8 }
        set o_s(21) { 20 14 21 12 15 17 4 19 13 10 11 1 16 5 18 7 8 22 9 6 3 2 }
        set o_s(22) { 16 14 13 2 21 10 11 4 1 22 18 12 19 5 7 8 6 3 15 20 9 17 }
        set o_s(23) { 18 15 9 14 12 2 8 11 22 21 16 1 6 17 5 10 19 4 20 13 3 7 }
        set o_s(24) { 7 3 10 14 13 21 18 6 20 4 9 8 22 15 2 1 5 12 19 17 11 16 }
        set o_s(25) { 18 1 13 7 16 10 14 2 19 5 21 11 22 15 8 17 20 3 4 12 6 9 }
        set o_s(26) { 13 2 22 5 11 21 20 14 7 10 4 9 19 18 6 3 1 8 15 12 17 16 }
        set o_s(27) { 14 17 21 8 2 9 6 4 5 13 22 7 15 3 1 18 16 11 10 12 20 19 }
        set o_s(28) { 10 22 1 12 13 18 21 20 2 14 16 7 15 3 4 17 5 19 6 8 9 11 }
        set o_s(29) { 10 8 9 18 12 6 1 5 20 11 17 22 16 3 13 2 15 21 14 19 7 4 }
        set o_s(30) { 7 17 22 5 3 10 13 18 9 1 14 15 21 19 16 12 8 6 11 20 4 2 }
        set o_s(31) { 2 9 21 3 4 7 1 11 16 5 20 19 18 8 17 13 10 12 15 6 14 22 }
        set o_s(32) { 15 12 8 4 22 13 16 17 18 3 7 5 6 1 9 11 21 10 14 20 19 2 }
        set o_s(33) { 15 16 2 11 17 7 5 14 20 4 21 3 10 9 12 8 13 6 18 19 22 1 }
        set o_s(34) { 1 13 11 3 4 21 6 14 15 22 18 9 7 5 10 20 12 16 17 8 19 2 }
        set o_s(35) { 14 17 22 20 8 16 5 10 1 13 2 21 12 9 4 18 3 7 6 19 15 11 }
        set o_s(36) { 9 17 7 4 5 13 21 18 11 3 22 1 6 16 20 14 15 10 8 2 12 19 }
        set o_s(37) { 13 14 5 22 19 11 9 6 18 15 8 10 7 4 17 16 3 1 12 2 21 20 }
        set o_s(38) { 20 5 4 14 11 1 6 16 8 22 7 3 2 12 21 19 17 13 10 15 18 9 }
        set o_s(39) { 3 7 14 15 6 5 21 20 18 10 4 16 19 1 13 9 8 17 11 12 22 2 }
        set o_s(40) { 13 15 17 1 22 11 3 4 7 20 14 21 9 8 2 18 16 6 10 12 5 19 }
        return $o_s($myposition)
}
#GMEAN
proc gmean L {
    expr pow([join $L *],1./[llength $L])
}
#PRINTLIST
proc printlist { inlist } {
    foreach item $inlist {
    if { [llength $item] > 1 } {  printlist $item  } else { puts $item }
    }
  }
}
