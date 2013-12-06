proc check_oratpch {} {
global instance system_password tpch_user tpch_pass tpch_def_tab tpch_def_temp scale_fact num_tpch_threads tpch_tt_compat maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists system_password ] } { set system_password "manager" }
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists scale_fact ] } { set scale_fact "1" }
if {  ![ info exists num_tpch_threads ] } { set num_tpch_threads "1" }
if {  ![ info exists tpch_user ] } { set tpch_user "tpch" }
if {  ![ info exists tpch_pass ] } { set tpch_pass "tpch" }
if {  ![ info exists tpch_def_tab ] } { set tpch_def_tab "tpchtab" }
if {  ![ info exists tpch_def_temp ] } { set tpch_def_temp "temp" }
if {  ![ info exists tpch_tt_compat ] } { set tpch_tt_compat "false" }
if { $tpch_tt_compat eq "true" } {
set install_message "Ready to create a Scale Factor $scale_fact TimesTen TPC-H schema\nin the existing database [string toupper $instance]\n under existing user [ string toupper $tpch_user ]?"
	} else {
set install_message "Ready to create a Scale Factor $scale_fact TPC-H schema in database [string toupper $instance]\n under user [ string toupper $tpch_user ] in tablespace [ string toupper $tpch_def_tab]?"
	}
if {[ tk_messageBox -title "Create Schema" -icon question -message $install_message -type yesno
 ] == yes} {
if { $num_tpch_threads eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $num_tpch_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "Oracle TPC-H creation"
if { [catch {load_virtual} message]} {
puts "Failed to create threads for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require Oratcl} ] { error "Failed to load Oratcl - Oracle OCI Library Error" }
proc GatherStatistics { lda tpch_user timesten } {
puts "GATHERING SCHEMA STATISTICS"
set curn1 [ oraopen $lda ]
if { $timesten } {
set sql(1) "call ttOptUpdateStats('ORDERS',1)"
set sql(2) "call ttOptUpdateStats('PARTSUPP',1)"
set sql(3) "call ttOptUpdateStats('CUSTOMER',1)"
set sql(4) "call ttOptUpdateStats('PART',1)"
set sql(5) "call ttOptUpdateStats('SUPPLIER',1)"
set sql(6) "call ttOptUpdateStats('NATION',1)"
set sql(7) "call ttOptUpdateStats('REGION',1)"
set sql(8) "call ttOptUpdateStats('LINEITEM',1)"
for { set i 1 } { $i <= 8 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
                        }
                }
        } else {
set sql(1) "BEGIN dbms_stats.gather_schema_stats('$tpch_user'); END;"
if {[ catch {orasql $curn1 $sql(1)} message ] } {
puts "$message $sql(1)"
puts [ oramsg $curn1 all ]
	}
}
oraclose $curn1
return
}

proc CreateUser { lda tpch_user tpch_pass tpch_def_tab tpch_def_temp} {
puts "CREATING USER $tpch_user"
set curn1 [ oraopen $lda ]
set sql(1) "create user $tpch_user identified by $tpch_pass default tablespace $tpch_def_tab temporary tablespace $tpch_def_temp\n"
set sql(2) "grant connect,resource, create view to $tpch_user\n"
set sql(3) "alter user $tpch_user quota unlimited on $tpch_def_tab\n"
for { set i 1 } { $i <= 3 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc CreateTables { lda timesten } {
puts "CREATING TPCH TABLES"
set curn1 [ oraopen $lda ]
if { $timesten } {
set sql(1) "CREATE TABLE ORDERS (O_ORDERDATE DATE, O_ORDERKEY TT_BIGINT NOT NULL, O_CUSTKEY TT_BIGINT NOT NULL, O_ORDERPRIORITY CHAR(15), O_SHIPPRIORITY TT_INTEGER, O_CLERK CHAR(15), O_ORDERSTATUS CHAR(1), O_TOTALPRICE BINARY_DOUBLE, O_COMMENT VARCHAR(79))"
set sql(2) "CREATE TABLE PARTSUPP (PS_PARTKEY TT_BIGINT NOT NULL, PS_SUPPKEY TT_BIGINT NOT NULL, PS_SUPPLYCOST BINARY_DOUBLE NOT NULL, PS_AVAILQTY TT_INTEGER, PS_COMMENT VARCHAR(199))"
set sql(3) "CREATE TABLE CUSTOMER(C_CUSTKEY TT_BIGINT NOT NULL, C_MKTSEGMENT CHAR(10), C_NATIONKEY TT_INTEGER, C_NAME VARCHAR(25), C_ADDRESS VARCHAR(40), C_PHONE CHAR(15), C_ACCTBAL BINARY_FLOAT, C_COMMENT VARCHAR(118))"
set sql(4) "CREATE TABLE PART(P_PARTKEY TT_BIGINT NOT NULL, P_TYPE VARCHAR(25), P_SIZE TT_INTEGER, P_BRAND CHAR(10), P_NAME VARCHAR(55), P_CONTAINER CHAR(10), P_MFGR CHAR(25), P_RETAILPRICE BINARY_FLOAT, P_COMMENT VARCHAR(23))"
set sql(5) "CREATE TABLE SUPPLIER(S_SUPPKEY TT_BIGINT NOT NULL, S_NATIONKEY TT_INTEGER, S_COMMENT VARCHAR(102), S_NAME CHAR(25), S_ADDRESS VARCHAR(40), S_PHONE CHAR(15), S_ACCTBAL BINARY_FLOAT)"
set sql(6) "CREATE TABLE NATION(N_NATIONKEY TT_INTEGER NOT NULL, N_NAME CHAR(25), N_REGIONKEY TT_INTEGER, N_COMMENT VARCHAR(152))" 
set sql(7) "CREATE TABLE REGION(R_REGIONKEY TT_INTEGER NOT NULL, R_NAME CHAR(25), R_COMMENT VARCHAR(152))"
set sql(8) "CREATE TABLE LINEITEM(L_SHIPDATE DATE, L_ORDERKEY TT_BIGINT NOT NULL, L_DISCOUNT BINARY_FLOAT NOT NULL, L_EXTENDEDPRICE BINARY_FLOAT NOT NULL, L_SUPPKEY TT_BIGINT NOT NULL, L_QUANTITY TT_INTEGER NOT NULL, L_RETURNFLAG CHAR(1), L_PARTKEY TT_BIGINT NOT NULL, L_LINESTATUS CHAR(1), L_TAX BINARY_FLOAT NOT NULL, L_COMMITDATE DATE, L_RECEIPTDATE DATE, L_SHIPMODE CHAR(10), L_LINENUMBER TT_BIGINT NOT NULL, L_SHIPINSTRUCT CHAR(25), L_COMMENT VARCHAR(44))"
	} else {
set sql(1) "CREATE TABLE ORDERS (O_ORDERDATE DATE, O_ORDERKEY NUMBER NOT NULL, O_CUSTKEY NUMBER NOT NULL, O_ORDERPRIORITY CHAR(15), O_SHIPPRIORITY NUMBER, O_CLERK CHAR(15), O_ORDERSTATUS CHAR(1), O_TOTALPRICE NUMBER, O_COMMENT VARCHAR(79)) PCTFREE 2 PCTUSED 98  INITRANS 8  PARALLEL"
set sql(2) "CREATE TABLE PARTSUPP (PS_PARTKEY NUMBER NOT NULL, PS_SUPPKEY NUMBER NOT NULL, PS_SUPPLYCOST NUMBER NOT NULL, PS_AVAILQTY NUMBER, PS_COMMENT VARCHAR(199)) PARALLEL"
set sql(3) "CREATE TABLE CUSTOMER(C_CUSTKEY NUMBER NOT NULL, C_MKTSEGMENT CHAR(10), C_NATIONKEY NUMBER, C_NAME VARCHAR(25), C_ADDRESS VARCHAR(40), C_PHONE CHAR(15), C_ACCTBAL NUMBER, C_COMMENT VARCHAR(118)) PCTFREE 0 PCTUSED 99 PARALLEL"
set sql(4) "CREATE TABLE PART(P_PARTKEY NUMBER NOT NULL, P_TYPE VARCHAR(25), P_SIZE NUMBER, P_BRAND CHAR(10), P_NAME VARCHAR(55), P_CONTAINER CHAR(10), P_MFGR CHAR(25), P_RETAILPRICE NUMBER, P_COMMENT VARCHAR(23)) PARALLEL"
set sql(5) "CREATE TABLE SUPPLIER(S_SUPPKEY NUMBER NOT NULL, S_NATIONKEY NUMBER, S_COMMENT VARCHAR(102), S_NAME CHAR(25), S_ADDRESS VARCHAR(40), S_PHONE CHAR(15), S_ACCTBAL NUMBER) PCTFREE 0 PCTUSED 99 PARALLEL"
set sql(6) "CREATE TABLE NATION(N_NATIONKEY NUMBER NOT NULL, N_NAME CHAR(25), N_REGIONKEY NUMBER, N_COMMENT VARCHAR(152))" 
set sql(7) "CREATE TABLE REGION(R_REGIONKEY NUMBER, R_NAME CHAR(25), R_COMMENT VARCHAR(152))"
set sql(8) "CREATE TABLE LINEITEM(L_SHIPDATE DATE, L_ORDERKEY NUMBER NOT NULL, L_DISCOUNT NUMBER NOT NULL, L_EXTENDEDPRICE NUMBER NOT NULL, L_SUPPKEY NUMBER NOT NULL, L_QUANTITY NUMBER NOT NULL, L_RETURNFLAG CHAR(1), L_PARTKEY NUMBER NOT NULL, L_LINESTATUS CHAR(1), L_TAX NUMBER NOT NULL, L_COMMITDATE DATE, L_RECEIPTDATE DATE, L_SHIPMODE CHAR(10), L_LINENUMBER NUMBER NOT NULL, L_SHIPINSTRUCT CHAR(25), L_COMMENT VARCHAR(44)) PCTFREE 2 PCTUSED 98 INITRANS 8 PARALLEL"
	}
for { set i 1 } { $i <= 8 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc SetNLS { lda } {
set curn_nls [oraopen $lda ]
set nls(1) "alter session set NLS_LANGUAGE = AMERICAN"
set nls(2) "alter session set NLS_TERRITORY = AMERICA"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn_nls $nls($i)} message ] } {
puts "$message $nls($i)"
puts [ oramsg $curn_nls all ]
			}
	}
oraclose $curn_nls
}

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

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

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

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

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

proc gen_phone {} {
set acode [ RandomNumber 100 999 ]
set exchg [ RandomNumber 100 999 ]
set number [ RandomNumber 1000 9999 ]
return [ concat $acode-$exchg-$number ]
}

proc MakeAlphaString { min max chArray chalen } {
set len [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

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

proc pick_str { name } {
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

proc txt_vp {} {
set verb_list [ split [ pick_str vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str np ] ]
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
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
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

proc V_STR { avg } {
set globArray [ list , \  0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
return [ MakeAlphaString [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] $globArray $chalen ] 
}

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}

proc mk_region { lda } {
set sql "INSERT INTO REGION (R_REGIONKEY, R_NAME, R_COMMENT) VALUES (:R_REGIONKEY, :R_NAME, :R_COMMENT)"
set statement {orabind $curn1 :R_REGIONKEY $code :R_NAME $text :R_COMMENT $comment}
set curn1 [oraopen $lda ]
oraparse $curn1 $sql
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT 72 ]
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
 }
oracommit $lda
oraclose $curn1
}

proc mk_nation { lda } {
set sql "INSERT INTO NATION (N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT) VALUES (:N_NATIONKEY, :N_NAME, :N_REGIONKEY, :N_COMMENT)"
set statement {orabind $curn1 :N_NATIONKEY $code :N_NAME $text :N_REGIONKEY $join :N_COMMENT $comment}
set curn1 [oraopen $lda ]
oraparse $curn1 $sql
for { set i 1 } { $i <= 25 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists nations ] [ expr {$i - 1} ] ] 0 ]
set nind [ lsearch -glob [ get_dists nations ] \*$text\* ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set join 0 }
1 - 2 - 3 - 17 - 24 { set join 1 }
8 - 9 - 12 - 18 - 21 { set join 2 }
6 - 7 - 19 - 22 - 23 { set join 3 }
10 - 11 - 13 - 20 { set join 4 }
}
set comment [ TEXT 72 ]
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
}
oracommit $lda
oraclose $curn1
}

proc mk_supp { lda start_rows end_rows } {
set sql "INSERT INTO SUPPLIER (S_SUPPKEY, S_NATIONKEY, S_COMMENT, S_NAME, S_ADDRESS, S_PHONE, S_ACCTBAL) VALUES (:S_SUPPKEY, :S_NATIONKEY, :S_COMMENT, :S_NAME, :S_ADDRESS, :S_PHONE, :S_ACCTBAL)"
set statement {orabind $curn1 -arraydml :S_SUPPKEY $suppkey_c1 :S_NATIONKEY $nation_code_c1 :S_COMMENT $comment_c1 :S_NAME $name_c1 :S_ADDRESS $address_c1 :S_PHONE $phone_c1 :S_ACCTBAL $acctbal_c1}
set curn1 [oraopen $lda ]
set BBB_COMMEND   "Recommends"
set BBB_COMPLAIN  "Complaints"
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set suppkey $i
set name [ concat Supplier#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
#random format to 2 floating point places 1681.00
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set comment [ TEXT 63 ]
set bad_press [ RandomNumber 1 10000 ]
set type [ RandomNumber 0 100 ]
set noise [ RandomNumber 0 19 ]
set offset [ RandomNumber 0 [ expr {19 + $noise} ] ]
if { $bad_press <= 10 } {
set st [ expr {9 + $offset + $noise} ]
set fi [ expr {$st + 10} ]
if { $type < 50 } {
set comment [ string replace $comment $st $fi $BBB_COMPLAIN ]
} else {
set comment [ string replace $comment $st $fi $BBB_COMMEND ]
	}
}
foreach x {suppkey_c1 nation_code_c1 comment_c1 name_c1 address_c1 phone_c1 acctbal_c1} y {suppkey nation_code comment name address phone acctbal} {
lappend $x [set $y] 
}
if { ![ expr {$i % 1000} ] || $i eq $end_rows } {    
oraparse $curn1 $sql
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
		}
unset suppkey_c1 nation_code_c1 comment_c1 name_c1 address_c1 phone_c1 acctbal_c1 
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading SUPPLIER...$i"
	}
if { ![ expr {$i % 50000} ] } {
	oracommit $lda
	}
   }
oracommit $lda
oraclose $curn1
puts "SUPPLIER Done Rows $start_rows..$end_rows"
return
}

proc mk_TTsupp { lda start_rows end_rows timesten } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen
set curn1 [oraopen $lda ]
set sql "INSERT INTO SUPPLIER (S_SUPPKEY, S_NATIONKEY, S_COMMENT, S_NAME, S_ADDRESS, S_PHONE, S_ACCTBAL) VALUES (:S_SUPPKEY, :S_NATIONKEY, :S_COMMENT, :S_NAME, :S_ADDRESS, :S_PHONE, :S_ACCTBAL)"
set statement {orabind $curn1 :S_SUPPKEY $suppkey :S_NATIONKEY $nation_code :S_COMMENT $comment :S_NAME $name :S_ADDRESS $address :S_PHONE $phone :S_ACCTBAL $acctbal}
oraparse $curn1 $sql
set BBB_COMMEND   "Recommends"
set BBB_COMPLAIN  "Complaints"
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set suppkey $i
set name [ concat Supplier#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
#random format to 2 floating point places 1681.00
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set comment [ TEXT 63 ]
set bad_press [ RandomNumber 1 10000 ]
set type [ RandomNumber 0 100 ]
set noise [ RandomNumber 0 19 ]
set offset [ RandomNumber 0 [ expr {19 + $noise} ] ]
if { $bad_press <= 10 } {
set st [ expr {9 + $offset + $noise} ]
set fi [ expr {$st + 10} ]
if { $type < 50 } {
set comment [ string replace $comment $st $fi $BBB_COMPLAIN ]
} else {
set comment [ string replace $comment $st $fi $BBB_COMMEND ]
	}
}
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
		}
if { ![ expr {$i % 10000} ] } {
	puts "Loading SUPPLIER...$i"
	}
if { ![ expr {$i % 50000} ] } {
	oracommit $lda
	}
   }
oracommit $lda
oraclose $curn1
puts "SUPPLIER Done Rows $start_rows..$end_rows"
return
}

proc mk_cust { lda start_rows end_rows } {
set sql "INSERT INTO CUSTOMER (C_CUSTKEY, C_MKTSEGMENT, C_NATIONKEY, C_NAME, C_ADDRESS, C_PHONE, C_ACCTBAL, C_COMMENT) values (:C_CUSTKEY, :C_MKTSEGMENT, :C_NATIONKEY, :C_NAME, :C_ADDRESS, :C_PHONE, :C_ACCTBAL, :C_COMMENT)"
set statement {orabind $curn1 -arraydml :C_CUSTKEY $custkey_c1 :C_MKTSEGMENT $mktsegment_c1 :C_NATIONKEY $nation_code_c1 :C_NAME $name_c1 :C_ADDRESS $address_c1 :C_PHONE $phone_c1 :C_ACCTBAL $acctbal_c1 :C_COMMENT $comment_c1}
set curn1 [oraopen $lda ]
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set custkey $i
set name [ concat Customer#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set mktsegment [ pick_str msegmnt ]
set comment [ TEXT 73 ]
foreach x {custkey_c1 mktsegment_c1 nation_code_c1 name_c1 address_c1 phone_c1 acctbal_c1 comment_c1} y {custkey mktsegment nation_code name address phone acctbal comment} {
lappend $x [set $y] 
}
if { ![ expr {$i % 1000} ] || $i eq $end_rows } {    
oraparse $curn1 $sql
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
unset custkey_c1 mktsegment_c1 nation_code_c1 name_c1 address_c1 phone_c1 acctbal_c1 comment_c1
   }
if { ![ expr {$i % 10000} ] } {
	puts "Loading CUSTOMER...$i"
	}
if { ![ expr {$i % 50000} ] } {
	oracommit $lda
	}
}
oracommit $lda
oraclose $curn1
puts "Customer Done Rows $start_rows..$end_rows"
return
}

proc mk_TTcust { lda start_rows end_rows timesten } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen
set curn1 [oraopen $lda ]
set sql "INSERT INTO CUSTOMER (C_CUSTKEY, C_MKTSEGMENT, C_NATIONKEY, C_NAME, C_ADDRESS, C_PHONE, C_ACCTBAL, C_COMMENT) values (:C_CUSTKEY, :C_MKTSEGMENT, :C_NATIONKEY, :C_NAME, :C_ADDRESS, :C_PHONE, :C_ACCTBAL, :C_COMMENT)"
set statement {orabind $curn1 :C_CUSTKEY $custkey :C_MKTSEGMENT $mktsegment :C_NATIONKEY $nation_code :C_NAME $name :C_ADDRESS $address :C_PHONE $phone :C_ACCTBAL $acctbal :C_COMMENT $comment}
oraparse $curn1 $sql
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set custkey $i
set name [ concat Customer#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set mktsegment [ pick_str msegmnt ]
set comment [ TEXT 73 ]
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading CUSTOMER...$i"
	}
if { ![ expr {$i % 50000} ] } {
	oracommit $lda
	}
}
oracommit $lda
oraclose $curn1
puts "Customer Done Rows $start_rows..$end_rows"
return
}

proc mk_part { lda start_rows end_rows scale_factor } {
set sql "INSERT INTO PART (P_PARTKEY, P_TYPE, P_SIZE, P_BRAND, P_NAME, P_CONTAINER, P_MFGR, P_RETAILPRICE, P_COMMENT) VALUES (:P_PARTKEY, :P_TYPE, :P_SIZE, :P_BRAND, :P_NAME, :P_CONTAINER, :P_MFGR, :P_RETAILPRICE, :P_COMMENT)"
set statement {orabind $curn1 -arraydml :P_PARTKEY $partkey_c1 :P_TYPE $type_c1 :P_SIZE $size_c1 :P_BRAND $brand_c1 :P_NAME $name_c1 :P_CONTAINER $container_c1 :P_MFGR $mfgr_c1 :P_RETAILPRICE $price_c1 :P_COMMENT $comment_c1 }
set sql2 "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_SUPPLYCOST, PS_AVAILQTY, PS_COMMENT) VALUES (:PS_PARTKEY, :PS_SUPPKEY, :PS_SUPPLYCOST, :PS_AVAILQTY, :PS_COMMENT)"
set statement2 {orabind $curn2 -arraydml :PS_PARTKEY $psupp_pkey_c2 :PS_SUPPKEY $psupp_suppkey_c2 :PS_SUPPLYCOST $psupp_scost_c2 :PS_AVAILQTY $psupp_qty_c2 :PS_COMMENT $psupp_comment_c2 }
set curn1 [oraopen $lda ]
set curn2 [oraopen $lda ]
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set partkey $i
unset -nocomplain name
for {set j 0} {$j < [ expr {5 - 1} ] } {incr j } {
append name [ pick_str colors ] " "
}
append name [ pick_str colors ]
set mf [ RandomNumber 1 5 ]
set mfgr [ concat Manufacturer#$mf ]
set brand [ concat Brand#[ expr {$mf * 10 + [ RandomNumber 1 5 ]} ] ]
set type [ pick_str p_types ] 
set size [ RandomNumber 1 50 ]
set container [ pick_str p_cntr ] 
set price [ rpb_routine $i ]
set comment [ TEXT 14 ]
foreach x {partkey_c1 type_c1 size_c1 brand_c1 name_c1 container_c1 mfgr_c1 price_c1 comment_c1} y {partkey type size brand name container mfgr price comment} {
lappend $x [set $y] 
}
#Part Supp Loop
for {set k 0} {$k < 4 } {incr k } {
set psupp_pkey $partkey
set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $scale_factor ]
set psupp_qty [ RandomNumber 1 9999 ]
set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
set psupp_comment [ TEXT 124 ]
foreach x {psupp_pkey_c2 psupp_suppkey_c2 psupp_scost_c2 psupp_qty_c2 psupp_comment_c2 } y {psupp_pkey psupp_suppkey psupp_scost psupp_qty psupp_comment} {
lappend $x [set $y] 
	}
}
# end of psupp loop
if { ![ expr {$i % 1000} ]  || $i eq $end_rows } {     
oraparse $curn1 $sql
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
unset partkey_c1 type_c1 size_c1 brand_c1 name_c1 container_c1 mfgr_c1 price_c1 comment_c1
oraparse $curn2 $sql2
eval $statement2
if {[ catch {oraexec $curn2} message ] } {
puts "Error in cursor 2:$curn2 $message"
puts [ oramsg $curn2 all ]
	}
unset psupp_pkey_c2 psupp_suppkey_c2 psupp_scost_c2 psupp_qty_c2 psupp_comment_c2
}
if { ![ expr {$i % 10000} ] } {
	puts "Loading PART/PARTSUPP...$i"
	}
if { ![ expr {$i % 50000} ] } {
	oracommit $lda
	}
}
oracommit $lda
oraclose $curn1
oraclose $curn2
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_TTpart { lda start_rows end_rows scale_factor timesten } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen
set sql "INSERT INTO PART (P_PARTKEY, P_TYPE, P_SIZE, P_BRAND, P_NAME, P_CONTAINER, P_MFGR, P_RETAILPRICE, P_COMMENT) VALUES (:P_PARTKEY, :P_TYPE, :P_SIZE, :P_BRAND, :P_NAME, :P_CONTAINER, :P_MFGR, :P_RETAILPRICE, :P_COMMENT)"
set statement {orabind $curn1 :P_PARTKEY $partkey :P_TYPE $type :P_SIZE $size :P_BRAND $brand :P_NAME $name :P_CONTAINER $container :P_MFGR $mfgr :P_RETAILPRICE $price :P_COMMENT $comment }
set sql2 "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_SUPPLYCOST, PS_AVAILQTY, PS_COMMENT) VALUES (:PS_PARTKEY, :PS_SUPPKEY, :PS_SUPPLYCOST, :PS_AVAILQTY, :PS_COMMENT)"
set statement2 {orabind $curn2 :PS_PARTKEY $psupp_pkey :PS_SUPPKEY $psupp_suppkey :PS_SUPPLYCOST $psupp_scost :PS_AVAILQTY $psupp_qty :PS_COMMENT $psupp_comment }
set curn1 [oraopen $lda ]
oraparse $curn1 $sql
set curn2 [oraopen $lda ]
oraparse $curn2 $sql2
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set partkey $i
unset -nocomplain name
for {set j 0} {$j < [ expr {5 - 1} ] } {incr j } {
append name [ pick_str colors ] " "
}
append name [ pick_str colors ]
set mf [ RandomNumber 1 5 ]
set mfgr [ concat Manufacturer#$mf ]
set brand [ concat Brand#[ expr {$mf * 10 + [ RandomNumber 1 5 ]} ] ]
set type [ pick_str p_types ] 
set size [ RandomNumber 1 50 ]
set container [ pick_str p_cntr ] 
set price [ rpb_routine $i ]
set comment [ TEXT 14 ]
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
#Part Supp Loop
for {set k 0} {$k < 4 } {incr k } {
set psupp_pkey $partkey
set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $scale_factor ]
set psupp_qty [ RandomNumber 1 9999 ]
set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
set psupp_comment [ TEXT 124 ]
eval $statement2
if {[ catch {oraexec $curn2} message ] } {
puts "Error in cursor 2:$curn2 $message"
puts [ oramsg $curn2 all ]
	}
}
# end of psupp loop
if { ![ expr {$i % 10000} ] } {
	puts "Loading PART/PARTSUPP...$i"
	}
if { ![ expr {$i % 50000} ] } {
	oracommit $lda
	}
 }
oracommit $lda
oraclose $curn1
oraclose $curn2
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_order { lda start_rows end_rows upd_num scale_factor } {
set sql "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES (TO_DATE(:O_ORDERDATE,'YYYY-MM-DD'), :O_ORDERKEY, :O_CUSTKEY, :O_ORDERPRIORITY, :O_SHIPPRIORITY, :O_CLERK, :O_ORDERSTATUS, :O_TOTALPRICE, :O_COMMENT)"
set statement {orabind $curn1 -arraydml :O_ORDERDATE $date_1 :O_ORDERKEY $okey_1 :O_CUSTKEY $custkey_1 :O_ORDERPRIORITY $opriority_1 :O_SHIPPRIORITY $spriority_1 :O_CLERK $clerk_1 :O_ORDERSTATUS $orderstatus_1 :O_TOTALPRICE $totalprice_1 :O_COMMENT $comment_1}
set sql2 "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) values (TO_DATE(:L_SHIPDATE,'YYYY-MM-DD'), :L_ORDERKEY, :L_DISCOUNT, :L_EXTENDEDPRICE, :L_SUPPKEY, :L_QUANTITY, :L_RETURNFLAG, :L_PARTKEY, :L_LINESTATUS, :L_TAX, TO_DATE(:L_COMMITDATE,'YYYY-MM-DD'), TO_DATE(:L_RECEIPTDATE,'YYYY-MM-DD'), :L_SHIPMODE, :L_LINENUMBER, :L_SHIPINSTRUCT, :L_COMMENT)"
set statement2 {orabind $curn2 -arraydml :L_SHIPDATE $lsdate_2 :L_ORDERKEY $lokey_2 :L_DISCOUNT $ldiscount_2 :L_EXTENDEDPRICE $leprice_2 :L_SUPPKEY $lsuppkey_2 :L_QUANTITY $lquantity_2 :L_RETURNFLAG $lrflag_2 :L_PARTKEY $lpartkey_2 :L_LINESTATUS $lstatus_2 :L_TAX $ltax_2 :L_COMMITDATE $lcdate_2 :L_RECEIPTDATE $lrdate_2 :L_SHIPMODE $lsmode_2 :L_LINENUMBER $llcnt_2 :L_SHIPINSTRUCT $linstruct_2 :L_COMMENT $lcomment_2}
set curn1 [oraopen $lda ]
set curn2 [oraopen $lda ]
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
for { set i $start_rows } { $i <= $end_rows } { incr i } {
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str instruct ] 
set lsmode [ pick_str smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
foreach x {lsdate_2 lokey_2 ldiscount_2 leprice_2 lsuppkey_2 lquantity_2 lrflag_2 lpartkey_2 lstatus_2 ltax_2 lcdate_2 lrdate_2 lsmode_2 llcnt_2 linstruct_2 lcomment_2} y {lsdate lokey ldiscount leprice lsuppkey lquantity lrflag lpartkey lstatus ltax lcdate lrdate lsmode llcnt linstruct lcomment} {
lappend $x [set $y]
	}
  }
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
foreach x {date_1 okey_1 custkey_1 opriority_1 spriority_1 clerk_1 orderstatus_1 totalprice_1 comment_1} y {date okey custkey opriority spriority clerk orderstatus totalprice comment} {
lappend $x [set $y]
	}
if { ![ expr {$i % 1000} ]  || $i eq $end_rows } {     
oraparse $curn2 $sql2
eval $statement2
if {[ catch {oraexec $curn2} message ] } {
puts "Error in cursor 2:$curn2 $message"
puts [ oramsg $curn2 all ]
	}
unset lsdate_2 lokey_2 ldiscount_2 leprice_2 lsuppkey_2 lquantity_2 lrflag_2 lpartkey_2 lstatus_2 ltax_2 lcdate_2 lrdate_2 lsmode_2 llcnt_2 linstruct_2 lcomment_2
oraparse $curn1 $sql
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
unset date_1 okey_1 custkey_1 opriority_1 spriority_1 clerk_1 orderstatus_1 totalprice_1 comment_1
   }
if { ![ expr {$i % 10000} ] } {
	puts "Loading ORDERS/LINEITEM...$i"
	oracommit $lda
	}
if { ![ expr {$i % 50000} ] } {
	oracommit $lda
	}
}
oracommit $lda
oraclose $curn1
oraclose $curn2
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc mk_TTorder { lda start_rows end_rows upd_num scale_factor timesten} {
set sql "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES (TO_DATE(:O_ORDERDATE,'YYYY-MM-DD'), :O_ORDERKEY, :O_CUSTKEY, :O_ORDERPRIORITY, :O_SHIPPRIORITY, :O_CLERK, :O_ORDERSTATUS, :O_TOTALPRICE, :O_COMMENT)"
set statement {orabind $curn1 :O_ORDERDATE $date :O_ORDERKEY $okey :O_CUSTKEY $custkey :O_ORDERPRIORITY $opriority :O_SHIPPRIORITY $spriority :O_CLERK $clerk :O_ORDERSTATUS $orderstatus :O_TOTALPRICE $totalprice :O_COMMENT $comment}
set sql2 "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) values (TO_DATE(:L_SHIPDATE,'YYYY-MM-DD'), :L_ORDERKEY, :L_DISCOUNT, :L_EXTENDEDPRICE, :L_SUPPKEY, :L_QUANTITY, :L_RETURNFLAG, :L_PARTKEY, :L_LINESTATUS, :L_TAX, TO_DATE(:L_COMMITDATE,'YYYY-MM-DD'), TO_DATE(:L_RECEIPTDATE,'YYYY-MM-DD'), :L_SHIPMODE, :L_LINENUMBER, :L_SHIPINSTRUCT, :L_COMMENT)"
set statement2 {orabind $curn2 :L_SHIPDATE $lsdate :L_ORDERKEY $lokey :L_DISCOUNT $ldiscount :L_EXTENDEDPRICE $leprice :L_SUPPKEY $lsuppkey :L_QUANTITY $lquantity :L_RETURNFLAG $lrflag :L_PARTKEY $lpartkey :L_LINESTATUS $lstatus :L_TAX $ltax :L_COMMITDATE $lcdate :L_RECEIPTDATE $lrdate :L_SHIPMODE $lsmode :L_LINENUMBER $llcnt :L_SHIPINSTRUCT $linstruct :L_COMMENT $lcomment}
set curn1 [oraopen $lda ]
oraparse $curn1 $sql
set curn2 [oraopen $lda ]
oraparse $curn2 $sql2
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
for { set i $start_rows } { $i <= $end_rows } { incr i } {
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str instruct ] 
set lsmode [ pick_str smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
eval $statement2
if {[ catch {oraexec $curn2} message ] } {
puts "Error in cursor 2:$curn2 $message"
puts [ oramsg $curn2 all ]
	}
  }
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading ORDERS/LINEITEM...$i"
	oracommit $lda
	}
if { ![ expr {$i % 50000} ] } {
	oracommit $lda
	}
}
oracommit $lda
oraclose $curn1
oraclose $curn2
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc CreateIndexes { lda timesten } {
puts "CREATING TPCH INDEXES"
set curn1 [ oraopen $lda ]
if { $timesten } {
set stmt_cnt 16
set sql(1) "ALTER TABLE REGION ADD CONSTRAINT REGION_PK PRIMARY KEY (R_REGIONKEY)"
set sql(2) "ALTER TABLE NATION ADD CONSTRAINT NATION_PK PRIMARY KEY (N_NATIONKEY)"
set sql(3) "ALTER TABLE SUPPLIER ADD CONSTRAINT SUPPLIER_PK PRIMARY KEY (S_SUPPKEY)"
set sql(4) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_PK PRIMARY KEY(PS_PARTKEY,PS_SUPPKEY)"
set sql(5) "ALTER TABLE PART ADD CONSTRAINT PART_PK PRIMARY KEY (P_PARTKEY)"
set sql(6) "ALTER TABLE ORDERS ADD CONSTRAINT ORDERS_PK PRIMARY KEY (O_ORDERKEY)"
set sql(7) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_PK PRIMARY KEY (L_LINENUMBER, L_ORDERKEY)"
set sql(8) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_PK PRIMARY KEY (C_CUSTKEY)"
set sql(9) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_PARTSUPP_FK FOREIGN KEY (L_PARTKEY, L_SUPPKEY) REFERENCES PARTSUPP(PS_PARTKEY, PS_SUPPKEY)"
set sql(10) "ALTER TABLE ORDERS ADD CONSTRAINT ORDER_CUSTOMER_FK FOREIGN KEY (O_CUSTKEY) REFERENCES CUSTOMER (C_CUSTKEY)"
set sql(11) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_PART_FK FOREIGN KEY (PS_PARTKEY) REFERENCES PART (P_PARTKEY)"
set sql(12) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_SUPPLIER_FK FOREIGN KEY (PS_SUPPKEY) REFERENCES SUPPLIER (S_SUPPKEY)"
set sql(13) "ALTER TABLE SUPPLIER ADD CONSTRAINT SUPPLIER_NATION_FK FOREIGN KEY (S_NATIONKEY) REFERENCES NATION (N_NATIONKEY)"
set sql(14) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_NATION_FK FOREIGN KEY (C_NATIONKEY) REFERENCES NATION (N_NATIONKEY)"
set sql(15) "ALTER TABLE NATION ADD CONSTRAINT NATION_REGION_FK FOREIGN KEY (N_REGIONKEY) REFERENCES REGION (R_REGIONKEY)"
set sql(16) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_ORDER_FK FOREIGN KEY (L_ORDERKEY) REFERENCES ORDERS (O_ORDERKEY)"
	} else {
set stmt_cnt 21
set sql(1) "ALTER TABLE REGION ADD CONSTRAINT REGION_PK PRIMARY KEY (R_REGIONKEY)"
set sql(2) "ALTER TABLE NATION ADD CONSTRAINT NATION_PK PRIMARY KEY (N_NATIONKEY)"
set sql(3) "ALTER TABLE SUPPLIER ADD CONSTRAINT SUPPLIER_PK PRIMARY KEY (S_SUPPKEY)"
set sql(4) "CREATE UNIQUE INDEX PARTSUPP_PK ON PARTSUPP(PS_PARTKEY,PS_SUPPKEY) PCTFREE 2 PARALLEL"
set sql(5) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_PK PRIMARY KEY(PS_PARTKEY,PS_SUPPKEY) USING INDEX PARTSUPP_PK"
set sql(6) "CREATE UNIQUE INDEX PART_PK ON PART(P_PARTKEY) PCTFREE 2 PARALLEL"
set sql(7) "ALTER TABLE PART ADD CONSTRAINT PART_PK PRIMARY KEY (P_PARTKEY) USING INDEX PART_PK"
set sql(8) "CREATE UNIQUE INDEX ORDERS_PK ON ORDERS(O_ORDERKEY) PCTFREE 2 PARALLEL"
set sql(9) "ALTER TABLE ORDERS ADD CONSTRAINT ORDERS_PK PRIMARY KEY (O_ORDERKEY) USING INDEX ORDERS_PK"
set sql(10) "CREATE UNIQUE INDEX LINEITEM_PK ON LINEITEM(L_LINENUMBER, L_ORDERKEY) PCTFREE 2 PARALLEL"
set sql(11) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_PK PRIMARY KEY (L_LINENUMBER, L_ORDERKEY)  USING INDEX LINEITEM_PK"
set sql(12) "CREATE UNIQUE INDEX CUSTOMER_PK ON CUSTOMER(C_CUSTKEY) PCTFREE 2 PARALLEL"
set sql(13) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_PK PRIMARY KEY (C_CUSTKEY) USING INDEX CUSTOMER_PK"
set sql(14) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_PARTSUPP_FK FOREIGN KEY (L_PARTKEY, L_SUPPKEY) REFERENCES PARTSUPP(PS_PARTKEY, PS_SUPPKEY) NOT DEFERRABLE"
set sql(15) "ALTER TABLE ORDERS ADD CONSTRAINT ORDER_CUSTOMER_FK FOREIGN KEY (O_CUSTKEY) REFERENCES CUSTOMER (C_CUSTKEY) NOT DEFERRABLE"
set sql(16) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_PART_FK FOREIGN KEY (PS_PARTKEY) REFERENCES PART (P_PARTKEY) NOT DEFERRABLE"
set sql(17) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_SUPPLIER_FK FOREIGN KEY (PS_SUPPKEY) REFERENCES SUPPLIER (S_SUPPKEY) NOT DEFERRABLE"
set sql(18) "ALTER TABLE SUPPLIER ADD CONSTRAINT SUPPLIER_NATION_FK FOREIGN KEY (S_NATIONKEY) REFERENCES NATION (N_NATIONKEY) NOT DEFERRABLE"
set sql(19) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_NATION_FK FOREIGN KEY (C_NATIONKEY) REFERENCES NATION (N_NATIONKEY) NOT DEFERRABLE"
set sql(20) "ALTER TABLE NATION ADD CONSTRAINT NATION_REGION_FK FOREIGN KEY (N_REGIONKEY) REFERENCES REGION (R_REGIONKEY) NOT DEFERRABLE"
set sql(21) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_ORDER_FK FOREIGN KEY (L_ORDERKEY) REFERENCES ORDERS (O_ORDERKEY) NOT DEFERRABLE"
	}
for { set i 1 } { $i <= $stmt_cnt } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc start_end { sup_rows myposition my_mult num_threads } {
set sf_chunk [ expr $sup_rows / $num_threads ]
set sf_rem [ expr $sup_rows % $num_threads ]
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
if  { $myposition eq $num_threads + 1 } { set myend [ expr {$sup_rows * $my_mult} ] }
return $mystart:$myend
}

proc do_tpch { system_password instance scale_fact tpch_user tpch_pass tpch_def_tab tpch_def_temp timesten num_threads } {
global dist_names dist_weights weights dists weights
###############################################
#Generating following rows
#5 rows in region table
#25 rows in nation table
#SF * 10K rows in Supplier table
#SF * 150K rows in Customer table
#SF * 200K rows in Part table
#SF * 800K rows in Partsupp table
#SF * 1500K rows in Orders table
#SF * 6000K rows in Lineitem table
###############################################
#update number always zero for first load
if { [ string toupper $timesten ] eq "TRUE"} { set timesten 1 } else { set timesten 0 }
set upd_num 0
if { ![ array exists dists ] } { set_dists }
foreach i [ array names dists ] {
set_dist_list $i
}
set sup_rows [ expr {$scale_fact * 10000} ]
set max_threads 256
set sf_mult 1
set cust_mult 15
set part_mult 20
set ord_mult 150
if { $num_threads > $max_threads } { set num_threads $max_threads }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
	1 { 
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
			}
tsv::set application load "WAIT"
		}
	}
	default { 
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $tpch_user ] SCHEMA"
if { $timesten } {
puts "TimesTen expects the Database [ string toupper $instance ] and User [ string toupper $tpch_user ] to have been created by the instance administrator in advance and be granted create table, session, procedure (and admin for checkpoints) privileges"
        } else {
set connect system/$system_password@$instance
set lda [ oralogon $connect ]
SetNLS $lda
CreateUser $lda $tpch_user $tpch_pass $tpch_def_tab $tpch_def_temp
oralogoff $lda
	}
set connect $tpch_user/$tpch_pass@$instance
set lda [ oralogon $connect ]
if { $timesten } { ; } else { SetNLS $lda }
oraautocom $lda off
CreateTables $lda $timesten
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
puts "Loading REGION..."
mk_region $lda
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $lda
puts "Loading NATION COMPLETE"
puts "Monitoring Workers..."
after 10000
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
puts "Loading REGION..."
mk_region $lda
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $lda
puts "Loading NATION COMPLETE"
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
set connect $tpch_user/$tpch_pass@$instance
set lda [ oralogon $connect ]
if { $timesten } { ; } else { SetNLS $lda }
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
if { [ expr $num_threads + 1 ] > $max_threads } { set num_threads $max_threads }
set sf_chunk [ split [ start_end $sup_rows $myposition $sf_mult $num_threads ] ":" ]
set cust_chunk [ split [ start_end $sup_rows $myposition $cust_mult $num_threads ] ":" ]
set part_chunk [ split [ start_end $sup_rows $myposition $part_mult $num_threads ] ":" ]
set ord_chunk [ split [ start_end $sup_rows $myposition $ord_mult $num_threads ] ":" ]
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set sf_chunk "1 $sup_rows"
set cust_chunk "1 [ expr {$sup_rows * $cust_mult} ]" 
set part_chunk "1 [ expr {$sup_rows * $part_mult} ]" 
set ord_chunk "1 [ expr {$sup_rows * $ord_mult} ]"
}
puts "Start:[ clock format [ clock seconds ] ]"
  if { $timesten } {
puts "Loading SUPPLIER..."
mk_TTsupp $lda [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ] $timesten
puts "Loading CUSTOMER..."
mk_TTcust $lda [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ] $timesten
puts "Loading PART and PARTSUPP..."
mk_TTpart $lda [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact $timesten
puts "Loading ORDERS and LINEITEM..."
mk_TTorder $lda [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact $timesten
	} else {
puts "Loading SUPPLIER..."
mk_supp $lda [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ]
puts "Loading CUSTOMER..."
mk_cust $lda [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ]
puts "Loading PART and PARTSUPP..."
mk_part $lda [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact
puts "Loading ORDERS and LINEITEM..."
mk_order $lda [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact 
	}
puts "Loading TPCH TABLES COMPLETE"
puts "End:[ clock format [ clock seconds ] ]"
oracommit $lda
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
oracommit $lda
CreateIndexes $lda $timesten
GatherStatistics $lda [ string toupper $tpch_user ] $timesten
puts "[ string toupper $tpch_user ] SCHEMA COMPLETE"
oralogoff $lda
return
		}
	}
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1156.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "do_tpch $system_password $instance  $scale_fact $tpch_user $tpch_pass $tpch_def_tab $tpch_def_temp $tpch_tt_compat $num_tpch_threads"
update
run_virtual
	} else { return }
}

proc check_mytpch {} {
global mysql_host mysql_port mysql_scale_fact mysql_tpch_user mysql_tpch_pass mysql_tpch_dbase mysql_num_tpch_threads mysql_tpch_storage_engine maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_scale_fact ] } { set mysql_scale_fact "1" }
if {  ![ info exists mysql_tpch_user ] } { set mysql_tpch_user "root" }
if {  ![ info exists mysql_tpch_pass ] } { set mysql_tpch_pass "mysql" }
if {  ![ info exists mysql_tpch_dbase ] } { set mysql_tpch_dbase "tpch" }
if {  ![ info exists mysql_num_tpch_threads ] } { set mysql_num_tpch_threads "1" }
if {  ![ info exists mysql_tpch_storage_engine ] } { set mysql_tpch_storage_engine "myisam" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a Scale Factor $mysql_scale_fact TPC-H schema\n in host [string toupper $mysql_host:$mysql_port] under user [ string toupper $mysql_tpch_user ] in database [ string toupper $mysql_tpch_dbase ] with storage engine [ string toupper $mysql_tpch_storage_engine ]?" -type yesno ] == yes} { 
if { $mysql_num_tpch_threads eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $mysql_num_tpch_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "MySQL TPC-H creation"
if { [catch {load_virtual} message]} {
puts "Failed to create threads for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require mysqltcl} ] { error "Failed to load mysqltcl - MySQL Library Error" }

proc GatherStatistics { mysql_handler } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "analyze table ORDERS, PARTSUPP, CUSTOMER, PART, SUPPLIER, NATION, REGION, LINEITEM"
mysqlexec $mysql_handler $sql(1)
return
}

proc CreateDatabase { mysql_handler db } {
puts "CREATING DATABASE $db"
set sql(1) "SET FOREIGN_KEY_CHECKS = 0"
set sql(2) "CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET latin1 COLLATE latin1_swedish_ci"
for { set i 1 } { $i <= 2 } { incr i } {
mysqlexec $mysql_handler $sql($i)
                }
return
}

proc CreateTables { mysql_handler storage_engine } {
puts "CREATING TPCH TABLES"
set sql(1) "CREATE TABLE `ORDERS` (
`O_ORDERDATE` DATE NULL,
`O_ORDERKEY` INT NOT NULL,
`O_CUSTKEY` INT NOT NULL,
`O_ORDERPRIORITY` CHAR(15) BINARY NULL,
`O_SHIPPRIORITY` INT NULL,
`O_CLERK` CHAR(15) BINARY NULL,
`O_ORDERSTATUS` CHAR(1) BINARY NULL,
`O_TOTALPRICE` DECIMAL(10,2) NULL,
`O_COMMENT` VARCHAR(79) BINARY NULL,
PRIMARY KEY (`O_ORDERKEY`),
FOREIGN KEY ORDERS_FK1(`O_CUSTKEY`) REFERENCES CUSTOMER(`C_CUSTKEY`),
INDEX ORDERS_DT_IDX (`O_ORDERDATE`)
)
ENGINE = $storage_engine"
set sql(2) "CREATE TABLE `PARTSUPP` (
PS_PARTKEY INT NOT NULL,
PS_SUPPKEY INT NOT NULL,
PS_SUPPLYCOST INT NOT NULL,
PS_AVAILQTY INT NULL,
PS_COMMENT VARCHAR(199) BINARY NULL,
PRIMARY KEY (`PS_PARTKEY`,`PS_SUPPKEY`),
FOREIGN KEY PARTSUPP_FK1(`PS_PARTKEY`) REFERENCES PART(`P_PARTKEY`),
FOREIGN KEY PARTSUPP_FK2(`PS_SUPPKEY`) REFERENCES SUPPLIER(`S_SUPPKEY`)
)
ENGINE = $storage_engine"
set sql(3) "CREATE TABLE `CUSTOMER` (
C_CUSTKEY INT NOT NULL,
C_MKTSEGMENT CHAR(10) BINARY NULL,
C_NATIONKEY INT NULL,
C_NAME VARCHAR(25) BINARY NULL,
C_ADDRESS VARCHAR(40) BINARY NULL,
C_PHONE CHAR(15) BINARY NULL,
C_ACCTBAL DECIMAL(10,2) NULL,
C_COMMENT VARCHAR(118) BINARY NULL,
PRIMARY KEY (`C_CUSTKEY`),
FOREIGN KEY CUSTOMER_FK1(`C_NATIONKEY`) REFERENCES NATION(`N_NATIONKEY`)
) 
ENGINE = $storage_engine"
set sql(4) "CREATE TABLE `PART` (
P_PARTKEY INT NOT NULL,
P_TYPE VARCHAR(25) BINARY NULL,
P_SIZE INT NULL,
P_BRAND CHAR(10) BINARY NULL,
P_NAME VARCHAR(55) BINARY NULL,
P_CONTAINER CHAR(10) BINARY NULL,
P_MFGR CHAR(25) BINARY NULL,
P_RETAILPRICE DECIMAL(10,2) NULL,
P_COMMENT VARCHAR(23) BINARY NULL,
PRIMARY KEY (`P_PARTKEY`)
)
ENGINE = $storage_engine"
set sql(5) "CREATE TABLE `SUPPLIER` (
S_SUPPKEY INT NOT NULL,
S_NATIONKEY INT NULL,
S_COMMENT VARCHAR(102) BINARY NULL,
S_NAME CHAR(25) BINARY NULL,
S_ADDRESS VARCHAR(40) BINARY NULL,
S_PHONE CHAR(15) BINARY NULL,
S_ACCTBAL DECIMAL(10,2) NULL,
PRIMARY KEY (`S_SUPPKEY`),
FOREIGN KEY SUPPLIER_FK1(`S_NATIONKEY`) REFERENCES NATION(`N_NATIONKEY`)
)
ENGINE = $storage_engine"
set sql(6) "CREATE TABLE `NATION` (
N_NATIONKEY INT NOT NULL,
N_NAME CHAR(25) BINARY NULL,
N_REGIONKEY INT NULL,
N_COMMENT VARCHAR(152) BINARY NULL,
PRIMARY KEY (`N_NATIONKEY`),
FOREIGN KEY NATION_FK1(`N_REGIONKEY`) REFERENCES REGION(`R_REGIONKEY`)
)
ENGINE = $storage_engine"
set sql(7) "CREATE TABLE `REGION` (
R_REGIONKEY INT NOT NULL,
R_NAME CHAR(25) BINARY NULL,
R_COMMENT VARCHAR(152) BINARY NULL,
PRIMARY KEY (`R_REGIONKEY`)
)
ENGINE = $storage_engine"
set sql(8) "CREATE TABLE `LINEITEM` (
L_SHIPDATE DATE NULL,
L_ORDERKEY INT NOT NULL,
L_DISCOUNT DECIMAL(10,2) NOT NULL,
L_EXTENDEDPRICE DECIMAL(10,2) NOT NULL,
L_SUPPKEY INT NOT NULL,
L_QUANTITY INT NOT NULL,
L_RETURNFLAG CHAR(1) BINARY NULL,
L_PARTKEY INT NOT NULL,
L_LINESTATUS CHAR(1) BINARY NULL,
L_TAX DECIMAL(10,2) NOT NULL,
L_COMMITDATE DATE NULL,
L_RECEIPTDATE DATE NULL,
L_SHIPMODE CHAR(10) BINARY NULL,
L_LINENUMBER INT NOT NULL,
L_SHIPINSTRUCT CHAR(25) BINARY NULL,
L_COMMENT VARCHAR(44) BINARY NULL,
PRIMARY KEY (`L_ORDERKEY`, `L_LINENUMBER`),
FOREIGN KEY LINEITEM_FK1(`L_ORDERKEY`) REFERENCES ORDERS(`O_ORDERKEY`),
FOREIGN KEY LINEITEM_FK2(`L_SUPPKEY`) REFERENCES SUPPLIER(`S_SUPPKEY`),
FOREIGN KEY LINEITEM_FK3(`L_PARTKEY`, `L_SUPPKEY`) REFERENCES PARTSUPP(`PS_PARTKEY`, `PS_SUPPKEY`),
FOREIGN KEY LINEITEM_FK4(`L_PARTKEY`) REFERENCES PART(`P_PARTKEY`),
INDEX LI_SHP_DT_IDX (`L_SHIPDATE`),
INDEX LI_COM_DT_IDX (`L_COMMITDATE`),
INDEX LI_RCPT_DT_IDX (`L_RECEIPTDATE`)
) 
ENGINE = $storage_engine"
for { set i 1 } { $i <= 8 } { incr i } {
mysqlexec $mysql_handler $sql($i)
                }
return
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

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

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

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

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

proc gen_phone {} {
set acode [ RandomNumber 100 999 ]
set exchg [ RandomNumber 100 999 ]
set number [ RandomNumber 1000 9999 ]
return [ concat $acode-$exchg-$number ]
}

proc MakeAlphaString { min max chArray chalen } {
set len [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

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

proc pick_str { name } {
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

proc txt_vp {} {
set verb_list [ split [ pick_str vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str np ] ]
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
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
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

proc V_STR { avg } {
set globArray [ list , \  0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
return [ MakeAlphaString [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] $globArray $chalen ] 
}

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}

proc mk_region { mysql_handler } {
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT 72 ]
mysql::exec $mysql_handler "INSERT INTO REGION (`R_REGIONKEY`,`R_NAME`,`R_COMMENT`) VALUES ('$code' , '$text' , '$comment')"
	}
mysql::commit $mysql_handler 
 }

proc mk_nation { mysql_handler } {
for { set i 1 } { $i <= 25 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists nations ] [ expr {$i - 1} ] ] 0 ]
set nind [ lsearch -glob [ get_dists nations ] \*$text\* ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set join 0 }
1 - 2 - 3 - 17 - 24 { set join 1 }
8 - 9 - 12 - 18 - 21 { set join 2 }
6 - 7 - 19 - 22 - 23 { set join 3 }
10 - 11 - 13 - 20 { set join 4 }
}
set comment [ TEXT 72 ]
mysql::exec $mysql_handler "INSERT INTO NATION (`N_NATIONKEY`, `N_NAME`, `N_REGIONKEY`, `N_COMMENT`) VALUES ('$code' , '$text' , '$join' , '$comment')"
}
mysql::commit $mysql_handler
}

proc mk_supp { mysql_handler start_rows end_rows } {
set BBB_COMMEND   "Recommends"
set BBB_COMPLAIN  "Complaints"
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set suppkey $i
set name [ concat Supplier#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
#random format to 2 floating point places 1681.00
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set comment [ TEXT 63 ]
set bad_press [ RandomNumber 1 10000 ]
set type [ RandomNumber 0 100 ]
set noise [ RandomNumber 0 19 ]
set offset [ RandomNumber 0 [ expr {19 + $noise} ] ]
if { $bad_press <= 10 } {
set st [ expr {9 + $offset + $noise} ]
set fi [ expr {$st + 10} ]
if { $type < 50 } {
set comment [ string replace $comment $st $fi $BBB_COMPLAIN ]
} else {
set comment [ string replace $comment $st $fi $BBB_COMMEND ]
	}
}
append supp_val_list ('$suppkey', '$nation_code', '$comment', '$name', '$address', '$phone', '$acctbal')
if { ![ expr {$i % 1000} ] || $i eq $end_rows } {    
mysql::exec $mysql_handler "INSERT INTO SUPPLIER (`S_SUPPKEY`, `S_NATIONKEY`, `S_COMMENT`, `S_NAME`, `S_ADDRESS`, `S_PHONE`, `S_ACCTBAL`) VALUES $supp_val_list"
	mysql::commit $mysql_handler
	unset supp_val_list
	} else {
	append supp_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading SUPPLIER...$i"
	}
   }
mysql::commit $mysql_handler
puts "SUPPLIER Done Rows $start_rows..$end_rows"
return
}

proc mk_cust { mysql_handler start_rows end_rows } {
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set custkey $i
set name [ concat Customer#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set mktsegment [ pick_str msegmnt ]
set comment [ TEXT 73 ]
append cust_val_list ('$custkey', '$mktsegment', '$nation_code', '$name', '$address', '$phone', '$acctbal', '$comment') 
if { ![ expr {$i % 1000} ] || $i eq $end_rows } {    
mysql::exec $mysql_handler "INSERT INTO CUSTOMER (`C_CUSTKEY`, `C_MKTSEGMENT`, `C_NATIONKEY`, `C_NAME`, `C_ADDRESS`, `C_PHONE`, `C_ACCTBAL`, `C_COMMENT`) values $cust_val_list"
	mysql::commit $mysql_handler
	unset cust_val_list
   	} else { 
	append cust_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading CUSTOMER...$i"
	}
}
mysql::commit $mysql_handler
puts "Customer Done Rows $start_rows..$end_rows"
return
}

proc mk_part { mysql_handler start_rows end_rows scale_factor } {
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set partkey $i
unset -nocomplain name
for {set j 0} {$j < [ expr {5 - 1} ] } {incr j } {
append name [ pick_str colors ] " "
}
append name [ pick_str colors ]
set mf [ RandomNumber 1 5 ]
set mfgr [ concat Manufacturer#$mf ]
set brand [ concat Brand#[ expr {$mf * 10 + [ RandomNumber 1 5 ]} ] ]
set type [ pick_str p_types ] 
set size [ RandomNumber 1 50 ]
set container [ pick_str p_cntr ] 
set price [ rpb_routine $i ]
set comment [ TEXT 14 ]
append part_val_list ('$partkey', '$type', '$size', '$brand', '$name', '$container', '$mfgr', '$price', '$comment')
#Part Supp Loop
for {set k 0} {$k < 4 } {incr k } {
set psupp_pkey $partkey
set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $scale_factor ]
set psupp_qty [ RandomNumber 1 9999 ]
set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
set psupp_comment [ TEXT 124 ]
append psupp_val_list ('$psupp_pkey', '$psupp_suppkey', '$psupp_scost', '$psupp_qty', '$psupp_comment') 
if { $k<=2 } { 
append psupp_val_list ,
	}
}
# end of psupp loop
if { ![ expr {$i % 1000} ]  || $i eq $end_rows } {     
mysql::exec $mysql_handler "INSERT INTO PART (`P_PARTKEY`, `P_TYPE`, `P_SIZE`, `P_BRAND`, `P_NAME`, `P_CONTAINER`, `P_MFGR`, `P_RETAILPRICE`, `P_COMMENT`) VALUES $part_val_list"
mysql::exec $mysql_handler "INSERT INTO PARTSUPP (`PS_PARTKEY`, `PS_SUPPKEY`, `PS_SUPPLYCOST`, `PS_AVAILQTY`, `PS_COMMENT`) VALUES $psupp_val_list"
	mysql::commit $mysql_handler
	unset part_val_list
	unset psupp_val_list
	} else {
	append part_val_list ,
	append psupp_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading PART/PARTSUPP...$i"
	}
}
mysql::commit $mysql_handler
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_order { mysql_handler start_rows end_rows upd_num scale_factor } {
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
for { set i $start_rows } { $i <= $end_rows } { incr i } {
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str instruct ] 
set lsmode [ pick_str smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
append lineit_val_list (str_to_date('$lsdate','%Y-%M-%d'),'$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', str_to_date('$lcdate','%Y-%M-%d'), str_to_date('$lrdate','%Y-%M-%d'), '$lsmode', '$llcnt', '$linstruct', '$lcomment') 
if { $l < [ expr $lcnt - 1 ] } { 
append lineit_val_list ,
	} 
  }
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
append order_val_list (str_to_date('$date','%Y-%M-%d'), '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment') 
if { ![ expr {$i % 1000} ]  || $i eq $end_rows } {     
mysql::exec $mysql_handler "INSERT INTO LINEITEM (`L_SHIPDATE`, `L_ORDERKEY`, `L_DISCOUNT`, `L_EXTENDEDPRICE`, `L_SUPPKEY`, `L_QUANTITY`, `L_RETURNFLAG`, `L_PARTKEY`, `L_LINESTATUS`, `L_TAX`, `L_COMMITDATE`, `L_RECEIPTDATE`, `L_SHIPMODE`, `L_LINENUMBER`, `L_SHIPINSTRUCT`, `L_COMMENT`) VALUES $lineit_val_list"
mysql::exec $mysql_handler "INSERT INTO ORDERS (`O_ORDERDATE`, `O_ORDERKEY`, `O_CUSTKEY`, `O_ORDERPRIORITY`, `O_SHIPPRIORITY`, `O_CLERK`, `O_ORDERSTATUS`, `O_TOTALPRICE`, `O_COMMENT`) VALUES $order_val_list"
	mysql::commit $mysql_handler
	unset lineit_val_list
	unset order_val_list
   } else {
	append order_val_list ,
        append lineit_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading ORDERS/LINEITEM...$i"
	}
}
mysql::commit $mysql_handler
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc start_end { sup_rows myposition my_mult num_threads } {
set sf_chunk [ expr $sup_rows / $num_threads ]
set sf_rem [ expr $sup_rows % $num_threads ]
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
if  { $myposition eq $num_threads + 1 } { set myend [ expr {$sup_rows * $my_mult} ] }
return $mystart:$myend
}

proc do_tpch { host port scale_fact user password db storage_engine num_threads } {
global mysqlstatus
global dist_names dist_weights weights dists weights
###############################################
#Generating following rows
#5 rows in region table
#25 rows in nation table
#SF * 10K rows in Supplier table
#SF * 150K rows in Customer table
#SF * 200K rows in Part table
#SF * 800K rows in Partsupp table
#SF * 1500K rows in Orders table
#SF * 6000K rows in Lineitem table
###############################################
#update number always zero for first load
set upd_num 0
if { ![ array exists dists ] } { set_dists }
foreach i [ array names dists ] {
set_dist_list $i
}
set sup_rows [ expr {$scale_fact * 10000} ]
set max_threads 256
set sf_mult 1
set cust_mult 15
set part_mult 20
set ord_mult 150
if { $num_threads > $max_threads } { set num_threads $max_threads }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
	1 { 
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
			}
tsv::set application load "WAIT"
		}
	}
	default { 
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $user ] SCHEMA"
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
CreateDatabase $mysql_handler $db
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
CreateTables $mysql_handler $storage_engine
	}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
puts "Loading REGION..."
mk_region $mysql_handler
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $mysql_handler
puts "Loading NATION COMPLETE"
puts "Monitoring Workers..."
after 10000
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
puts "Loading REGION..."
mk_region $mysql_handler
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $mysql_handler
puts "Loading NATION COMPLETE"
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
}
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
if { [ expr $num_threads + 1 ] > $max_threads } { set num_threads $max_threads }
set sf_chunk [ split [ start_end $sup_rows $myposition $sf_mult $num_threads ] ":" ]
set cust_chunk [ split [ start_end $sup_rows $myposition $cust_mult $num_threads ] ":" ]
set part_chunk [ split [ start_end $sup_rows $myposition $part_mult $num_threads ] ":" ]
set ord_chunk [ split [ start_end $sup_rows $myposition $ord_mult $num_threads ] ":" ]
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set sf_chunk "1 $sup_rows"
set cust_chunk "1 [ expr {$sup_rows * $cust_mult} ]" 
set part_chunk "1 [ expr {$sup_rows * $part_mult} ]" 
set ord_chunk "1 [ expr {$sup_rows * $ord_mult} ]"
}
puts "Start:[ clock format [ clock seconds ] ]"
puts "Loading SUPPLIER..."
mk_supp $mysql_handler [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ]
puts "Loading CUSTOMER..."
mk_cust $mysql_handler [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ]
puts "Loading PART and PARTSUPP..."
mk_part $mysql_handler [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact
puts "Loading ORDERS and LINEITEM..."
mk_order $mysql_handler [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact 
puts "Loading TPCH TABLES COMPLETE"
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
GatherStatistics $mysql_handler
puts "[ string toupper $db ] SCHEMA COMPLETE"
return
		}
	}
  }
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 831.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "do_tpch $mysql_host $mysql_port $mysql_scale_fact $mysql_tpch_user $mysql_tpch_pass $mysql_tpch_dbase $mysql_tpch_storage_engine $mysql_num_tpch_threads"
update
run_virtual
	} else { return }
}

proc check_mssqltpch {} {
global mssqls_server mssqls_port mssqls_scale_fact mssqls_maxdop mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass mssqls_tpch_dbase mssqls_num_tpch_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_scale_fact ] } { set mssqls_scale_fact "1" }
if {  ![ info exists mssqls_maxdop ] } { set mssqls_maxdop "2" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_tpch_dbase ] } { set mssqls_tpch_dbase "tpch" }
if {  ![ info exists mssqls_num_tpch_threads ] } { set mssqls_num_tpch_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a Scale Factor $mssqls_scale_fact MS SQL Server TPC-H schema\nin host [string toupper $mssqls_server:$mssqls_port] in database [ string toupper $mssqls_tpch_dbase ]?" -type yesno ] == yes} { 
if { $mssqls_num_tpch_threads eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $mssqls_num_tpch_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "SQL Server TPC-H creation"
if { [catch {load_virtual} message]} {
puts "Failed to create threads for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require tclodbc 2.5.1} ] { error "Failed to load tclodbc - ODBC Library Error" }
proc UpdateStatistics { odbc db } {
puts "UPDATING SCHEMA STATISTICS"
set sql(1) "USE $db"
set sql(2) "EXEC sp_updatestats"
for { set i 1 } { $i <= 2 } { incr i } {
odbc  $sql($i)
		}
return
}

proc CreateDatabase { odbc db } {
set table_count 0
puts "CHECKING IF DATABASE $db EXISTS"
set db_exists [ odbc "IF DB_ID('$db') is not null SELECT 1 AS res ELSE SELECT 0 AS res" ]
if { $db_exists } {
odbc "use $db"
set table_count [ odbc "select COUNT(*) from sys.tables" ]
if { $table_count == 0 } {
puts "Empty database $db exists"
puts "Using existing empty Database $db for Schema build"
        } else {
puts "Database with tables $db exists"
error "Database $db exists but is not empty, specify a new or empty database name"
        }
} else {
puts "CREATING DATABASE $db"
odbc "create database $db"
        }
}

proc CreateTables { odbc } {
puts "CREATING TPCC TABLES"
set sql(1) "create table dbo.customer (c_custkey int not null, c_mktsegment char(10) null, c_nationkey int null, c_name varchar(25) null, c_address varchar(40) null, c_phone char(15) null, c_acctbal money null, c_comment varchar(118) null)" 
set sql(2) "create table dbo.lineitem (l_shipdate date null, l_orderkey int not null, l_discount money not null, l_extendedprice money not null, l_suppkey int not null, l_quantity int not null, l_returnflag char(1) null, l_partkey int not null, l_linestatus char(1) null, l_tax money not null, l_commitdate date null, l_receiptdate date null, l_shipmode char(10) null, l_linenumber int not null, l_shipinstruct char(25) null, l_comment varchar(44) null)" 
set sql(3) "create table dbo.nation(n_nationkey int not null, n_name char(25) null, n_regionkey int null, n_comment varchar(152) null)" 
set sql(4) "create table dbo.part( p_partkey int not null, p_type varchar(25) null, p_size int null, p_brand char(10) null, p_name varchar(55) null, p_container char(10) null, p_mfgr char(25) null, p_retailprice money null, p_comment varchar(23) null)" 
set sql(5) "create table dbo.partsupp( ps_partkey int not null, ps_suppkey int not null, ps_supplycost money not null, ps_availqty int null, ps_comment varchar(199) null)" 
set sql(6) "create table dbo.region(r_regionkey int not null, r_name char(25) null, r_comment varchar(152) null)"
set sql(7) "create table dbo.supplier( s_suppkey int not null, s_nationkey int null, s_comment varchar(102) null, s_name char(25) null, s_address varchar(40) null, s_phone char(15) null, s_acctbal money null)" 
set sql(8) "create table dbo.orders( o_orderdate date null, o_orderkey int not null, o_custkey int not null, o_orderpriority char(15) null, o_shippriority int null, o_clerk char(15) null, o_orderstatus char(1) null, o_totalprice money null, o_comment varchar(79) null)"
for { set i 1 } { $i <= 8 } { incr i } {
odbc  $sql($i)
		}
return
	}

proc CreateIndexes { odbc maxdop } {
puts "CREATING TPCH INDEXES"
set sql(1) "alter table dbo.nation add constraint nation_pk primary key (n_nationkey)"
set sql(2) "alter table dbo.region add constraint region_pk primary key (r_regionkey)"
set sql(3) "alter table dbo.customer add constraint customer_pk primary key (c_custkey) with (maxdop=$maxdop)"
set sql(4) "alter table dbo.part add constraint part_pk primary key (p_partkey) with (maxdop=$maxdop)"
set sql(5) "alter table dbo.partsupp add constraint partsupp_pk primary key (ps_partkey, ps_suppkey) with (maxdop=$maxdop)"
set sql(6) "alter table dbo.supplier add constraint supplier_pk primary key (s_suppkey) with (maxdop=$maxdop)"
set sql(7) "create clustered index o_orderdate_ind on orders(o_orderdate) with (fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(8) "alter table dbo.orders add constraint orders_pk primary key (o_orderkey) with (fillfactor = 95, maxdop=$maxdop)"
set sql(9) "create index n_regionkey_ind on dbo.nation(n_regionkey) with (fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(10) "create index ps_suppkey_ind on dbo.partsupp(ps_suppkey) with(fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(11) "create index s_nationkey_ind on dbo.supplier(s_nationkey) with (fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(12) "create clustered index l_shipdate_ind on dbo.lineitem(l_shipdate) with (fillfactor=95, sort_in_tempdb=off, maxdop=$maxdop)"
set sql(13) "create index l_orderkey_ind on dbo.lineitem(l_orderkey) with ( fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(14) "create index l_partkey_ind on dbo.lineitem(l_partkey) with (fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(15) "alter table dbo.customer with nocheck add  constraint customer_nation_fk foreign key(c_nationkey) references dbo.nation (n_nationkey)"
set sql(16) "alter table dbo.lineitem with nocheck add  constraint lineitem_order_fk foreign key(l_orderkey) references dbo.orders (o_orderkey)"
set sql(17) "alter table dbo.lineitem with nocheck add constraint lineitem_partkey_fk foreign key (l_partkey) references dbo.part(p_partkey)"
set sql(18) "alter table dbo.lineitem with nocheck add constraint lineitem_suppkey_fk foreign key (l_suppkey) references dbo.supplier(s_suppkey)"
set sql(19) "alter table dbo.lineitem with nocheck add  constraint lineitem_partsupp_fk foreign key(l_partkey,l_suppkey) references partsupp(ps_partkey, ps_suppkey)"
set sql(20) "alter table dbo.nation  with nocheck add  constraint nation_region_fk foreign key(n_regionkey) references dbo.region (r_regionkey)"
set sql(21) "alter table dbo.partsupp  with nocheck add  constraint partsupp_part_fk foreign key(ps_partkey) references dbo.part (p_partkey)"
set sql(22) "alter table dbo.partsupp  with nocheck add  constraint partsupp_supplier_fk foreign key(ps_suppkey) references dbo.supplier (s_suppkey)"
set sql(23) "alter table dbo.supplier  with nocheck add  constraint supplier_nation_fk foreign key(s_nationkey) references dbo.nation (n_nationkey)"
set sql(24) "alter table dbo.orders  with nocheck add  constraint order_customer_fk foreign key(o_custkey) references dbo.customer (c_custkey)"
set sql(25) "alter table dbo.customer check constraint customer_nation_fk"
set sql(26) "alter table dbo.lineitem check constraint lineitem_order_fk"
set sql(27) "alter table dbo.lineitem check constraint lineitem_partkey_fk"
set sql(28) "alter table dbo.lineitem check constraint lineitem_suppkey_fk"
set sql(29) "alter table dbo.lineitem check constraint lineitem_partsupp_fk"
set sql(30) "alter table dbo.nation check constraint nation_region_fk"
set sql(31) "alter table dbo.partsupp check constraint partsupp_part_fk"
set sql(32) "alter table dbo.partsupp check constraint partsupp_part_fk"
set sql(33) "alter table dbo.supplier check constraint supplier_nation_fk"
set sql(34) "alter table dbo.orders check constraint order_customer_fk"
for { set i 1 } { $i <= 34 } { incr i } {
odbc  $sql($i)
		}
return
	}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

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

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

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

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

proc gen_phone {} {
set acode [ RandomNumber 100 999 ]
set exchg [ RandomNumber 100 999 ]
set number [ RandomNumber 1000 9999 ]
return [ concat $acode-$exchg-$number ]
}

proc MakeAlphaString { min max chArray chalen } {
set len [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

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

proc pick_str { name } {
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

proc txt_vp {} {
set verb_list [ split [ pick_str vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str np ] ]
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
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
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

proc V_STR { avg } {
set globArray [ list , \  0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
return [ MakeAlphaString [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] $globArray $chalen ] 
}

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}

proc mk_region { odbc } {
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT 72 ]
odbc "INSERT INTO REGION (R_REGIONKEY,R_NAME,R_COMMENT) VALUES ('$code' , '$text' , '$comment')"
	}
odbc commit
 }

proc mk_nation { odbc } {
for { set i 1 } { $i <= 25 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists nations ] [ expr {$i - 1} ] ] 0 ]
set nind [ lsearch -glob [ get_dists nations ] \*$text\* ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set join 0 }
1 - 2 - 3 - 17 - 24 { set join 1 }
8 - 9 - 12 - 18 - 21 { set join 2 }
6 - 7 - 19 - 22 - 23 { set join 3 }
10 - 11 - 13 - 20 { set join 4 }
}
set comment [ TEXT 72 ]
odbc "INSERT INTO NATION (N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT) VALUES ('$code' , '$text' , '$join' , '$comment')"
	}
odbc commit
}

proc mk_supp { odbc start_rows end_rows } {
set bld_cnt 1
set BBB_COMMEND   "Recommends"
set BBB_COMPLAIN  "Complaints"
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set suppkey $i
set name [ concat Supplier#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
#random format to 2 floating point places 1681.00
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set comment [ TEXT 63 ]
set bad_press [ RandomNumber 1 10000 ]
set type [ RandomNumber 0 100 ]
set noise [ RandomNumber 0 19 ]
set offset [ RandomNumber 0 [ expr {19 + $noise} ] ]
if { $bad_press <= 10 } {
set st [ expr {9 + $offset + $noise} ]
set fi [ expr {$st + 10} ]
if { $type < 50 } {
set comment [ string replace $comment $st $fi $BBB_COMPLAIN ]
} else {
set comment [ string replace $comment $st $fi $BBB_COMMEND ]
	}
}
append supp_val_list ('$suppkey', '$nation_code', '$comment', '$name', '$address', '$phone', '$acctbal')
if { $bld_cnt<= 1 } { 
append supp_val_list ,
}
incr bld_cnt
if { ![ expr {$i % 2} ] || $i eq $end_rows } {    
odbc "INSERT INTO SUPPLIER (S_SUPPKEY, S_NATIONKEY, S_COMMENT, S_NAME, S_ADDRESS, S_PHONE, S_ACCTBAL) VALUES $supp_val_list"
	odbc commit
	set bld_cnt 1
	unset supp_val_list
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading SUPPLIER...$i"
	}
   }
	odbc commit
puts "SUPPLIER Done Rows $start_rows..$end_rows"
return
}

proc mk_cust { odbc start_rows end_rows } {
set bld_cnt 1
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set custkey $i
set name [ concat Customer#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set mktsegment [ pick_str msegmnt ]
set comment [ TEXT 73 ]
append cust_val_list ('$custkey', '$mktsegment', '$nation_code', '$name', '$address', '$phone', '$acctbal', '$comment') 
if { $bld_cnt<= 1 } { 
append cust_val_list ,
}
incr bld_cnt
if { ![ expr {$i % 2} ] || $i eq $end_rows } {    
odbc "INSERT INTO CUSTOMER (C_CUSTKEY, C_MKTSEGMENT, C_NATIONKEY, C_NAME, C_ADDRESS, C_PHONE, C_ACCTBAL, C_COMMENT) values $cust_val_list"
	odbc commit
	set bld_cnt 1
	unset cust_val_list
   }
if { ![ expr {$i % 10000} ] } {
	puts "Loading CUSTOMER...$i"
	}
}
odbc commit
puts "Customer Done Rows $start_rows..$end_rows"
return
}

proc mk_part { mysql_handler start_rows end_rows scale_factor } {
set bld_cnt 1
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set partkey $i
unset -nocomplain name
for {set j 0} {$j < [ expr {5 - 1} ] } {incr j } {
append name [ pick_str colors ] " "
}
append name [ pick_str colors ]
set mf [ RandomNumber 1 5 ]
set mfgr [ concat Manufacturer#$mf ]
set brand [ concat Brand#[ expr {$mf * 10 + [ RandomNumber 1 5 ]} ] ]
set type [ pick_str p_types ] 
set size [ RandomNumber 1 50 ]
set container [ pick_str p_cntr ] 
set price [ rpb_routine $i ]
set comment [ TEXT 14 ]
append part_val_list ('$partkey', '$type', '$size', '$brand', '$name', '$container', '$mfgr', '$price', '$comment')
if { $bld_cnt<= 1 } { 
append part_val_list ,
}
#Part Supp Loop
for {set k 0} {$k < 4 } {incr k } {
set psupp_pkey $partkey
set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $scale_factor ]
set psupp_qty [ RandomNumber 1 9999 ]
set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
set psupp_comment [ TEXT 124 ]
append psupp_val_list ('$psupp_pkey', '$psupp_suppkey', '$psupp_scost', '$psupp_qty', '$psupp_comment') 
if { $k<=2 } { 
append psupp_val_list ,
	}
}
if { $bld_cnt<= 1 } { 
append psupp_val_list ,
}
incr bld_cnt
# end of psupp loop
if { ![ expr {$i % 2} ]  || $i eq $end_rows } {     
odbc "INSERT INTO PART (P_PARTKEY, P_TYPE, P_SIZE, P_BRAND, P_NAME, P_CONTAINER, P_MFGR, P_RETAILPRICE, P_COMMENT) VALUES $part_val_list"
odbc "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_SUPPLYCOST, PS_AVAILQTY, PS_COMMENT) VALUES $psupp_val_list"
	odbc commit
	set bld_cnt 1
	unset part_val_list
	unset psupp_val_list
}
if { ![ expr {$i % 10000} ] } {
	puts "Loading PART/PARTSUPP...$i"
	}
}
odbc commit
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_order { mysql_handler start_rows end_rows upd_num scale_factor } {
set bld_cnt 1
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
for { set i $start_rows } { $i <= $end_rows } { incr i } {
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str instruct ] 
set lsmode [ pick_str smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
append lineit_val_list ('$lsdate','$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', '$lcdate', '$lrdate', '$lsmode', '$llcnt', '$linstruct', '$lcomment') 
if { $l < [ expr $lcnt - 1 ] } { 
append lineit_val_list ,
	} else {
if { $bld_cnt<= 1 } { 
append lineit_val_list ,
		}
	}
  }
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
append order_val_list ('$date', '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment') 
if { $bld_cnt<= 1 } { 
append order_val_list ,
}
incr bld_cnt
if { ![ expr {$i % 2} ]  || $i eq $end_rows } {     
odbc "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES $lineit_val_list"
odbc "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES $order_val_list"
	odbc commit
	set bld_cnt 1
	unset lineit_val_list
	unset order_val_list
   }
if { ![ expr {$i % 10000} ] } {
	puts "Loading ORDERS/LINEITEM...$i"
	}
}
odbc commit
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc start_end { sup_rows myposition my_mult num_threads } {
set sf_chunk [ expr $sup_rows / $num_threads ]
set sf_rem [ expr $sup_rows % $num_threads ]
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
if  { $myposition eq $num_threads + 1 } { set myend [ expr {$sup_rows * $my_mult} ] }
return $mystart:$myend
}

proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
	} else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
}
return $connection
}

proc do_tpch { server port scale_fact odbc_driver authentication uid pwd db maxdop num_threads } {
global dist_names dist_weights weights dists weights
###############################################
#Generating following rows
#5 rows in region table
#25 rows in nation table
#SF * 10K rows in Supplier table
#SF * 150K rows in Customer table
#SF * 200K rows in Part table
#SF * 800K rows in Partsupp table
#SF * 1500K rows in Orders table
#SF * 6000K rows in Lineitem table
###############################################
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
#update number always zero for first load
set upd_num 0
if { ![ array exists dists ] } { set_dists }
foreach i [ array names dists ] {
set_dist_list $i
}
set sup_rows [ expr {$scale_fact * 10000} ]
set max_threads 256
set sf_mult 1
set cust_mult 15
set part_mult 20
set ord_mult 150
if { $num_threads > $max_threads } { set num_threads $max_threads }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
	1 { 
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
			}
tsv::set application load "WAIT"
		}
	}
	default { 
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $db ] SCHEMA"
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
CreateDatabase odbc $db
odbc "use $db"
CreateTables odbc
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
puts "Loading REGION..."
mk_region odbc
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation odbc
puts "Loading NATION COMPLETE"
puts "Monitoring Workers..."
after 10000
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
puts "Loading REGION..."
mk_region odbc
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation odbc
puts "Loading NATION COMPLETE"
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if [catch {database connect odbc $connection} message ] {
puts stderr "error, the database connection to $connection could not be established"
error $message
return
 } else {
odbc "use $db"
odbc set autocommit off 
} 
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
if { [ expr $num_threads + 1 ] > $max_threads } { set num_threads $max_threads }
set sf_chunk [ split [ start_end $sup_rows $myposition $sf_mult $num_threads ] ":" ]
set cust_chunk [ split [ start_end $sup_rows $myposition $cust_mult $num_threads ] ":" ]
set part_chunk [ split [ start_end $sup_rows $myposition $part_mult $num_threads ] ":" ]
set ord_chunk [ split [ start_end $sup_rows $myposition $ord_mult $num_threads ] ":" ]
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set sf_chunk "1 $sup_rows"
set cust_chunk "1 [ expr {$sup_rows * $cust_mult} ]" 
set part_chunk "1 [ expr {$sup_rows * $part_mult} ]" 
set ord_chunk "1 [ expr {$sup_rows * $ord_mult} ]"
}
puts "Start:[ clock format [ clock seconds ] ]"
puts "Loading SUPPLIER..."
mk_supp odbc [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ]
puts "Loading CUSTOMER..."
mk_cust odbc [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ]
puts "Loading PART and PARTSUPP..."
mk_part odbc [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact
puts "Loading ORDERS and LINEITEM..."
mk_order odbc [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact 
puts "Loading TPCH TABLES COMPLETE"
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes odbc $maxdop
UpdateStatistics odbc $db
puts "[ string toupper $db ] SCHEMA COMPLETE"
odbc disconnect
return
		}
	}
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 806.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "do_tpch {$mssqls_server} $mssqls_port $mssqls_scale_fact {$mssqls_odbc_driver} $mssqls_authentication $mssqls_uid $mssqls_pass $mssqls_tpch_dbase $mssqls_maxdop $mssqls_num_tpch_threads"
update
run_virtual
	} else { return }
}

proc check_pgtpch {} {
global global pg_host pg_port pg_scale_fact pg_tpch_superuser pg_tpch_superuserpass pg_tpch_defaultdbase pg_tpch_user pg_tpch_pass pg_tpch_dbase pg_tpch_gpcompat pg_tpch_gpcompress pg_num_tpch_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_scale_fact ] } { set pg_scale_fact "1" }
if {  ![ info exists pg_tpch_superuser ] } { set pg_tpch_superuser "postgres" }
if {  ![ info exists pg_tpch_superuserpass ] } { set pg_tpch_superuserpass "postgres" }
if {  ![ info exists pg_tpch_defaultdbase ] } { set pg_tpch_defaultdbase "postgres" }
if {  ![ info exists pg_tpch_user ] } { set pg_tpch_user "tpch" }
if {  ![ info exists pg_tpch_pass ] } { set pg_tpch_pass "tpch" }
if {  ![ info exists pg_tpch_dbase ] } { set pg_tpch_dbase "tpch" }
if {  ![ info exists pg_tpch_gpcompat ] } { set pg_tpch_gpcompat "false" }
if {  ![ info exists pg_tpch_gpcompress ] } { set pg_tpch_gpcompress "false" }
if {  ![ info exists pg_num_tpch_threads ] } { set pg_num_tpch_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a Scale Factor $pg_scale_fact TPC-H schema\n in host [string toupper $pg_host:$pg_port] under user [ string toupper $pg_tpch_user ] in database [ string toupper $pg_tpch_dbase ]?" -type yesno ] == yes} {
if { $pg_num_tpch_threads eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $pg_num_tpch_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "PostgreSQL TPC-H creation"
if { [catch {load_virtual} message]} {
puts "Failed to create threads for schema creation: $message"
        return
        }
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require Pgtcl} ] { error "Failed to load Pgtcl - Postgres Library Error" }
proc GatherStatistics { lda } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "ANALYZE ORDERS"
set sql(2) "ANALYZE PARTSUPP"
set sql(3) "ANALYZE CUSTOMER"
set sql(4) "ANALYZE PART"
set sql(5) "ANALYZE SUPPLIER"
set sql(6) "ANALYZE NATION"
set sql(7) "ANALYZE REGION"
set sql(8) "ANALYZE LINEITEM"
for { set i 1 } { $i <= 8 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
return
}

proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]}]} {
puts stderr "Error, the database connection to $host could not be established"
set lda "Failed"
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}

proc CreateUserDatabase { lda db user password } {
puts "CREATING DATABASE $db under OWNER $user"  
set sql(1) "CREATE USER $user PASSWORD '$password'"
set sql(2) "CREATE DATABASE $db OWNER $user"
for { set i 1 } { $i <= 2 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
return
}

proc CreateTables { lda greenplum gpcompress } {
puts "CREATING TPCH TABLES"
if { $greenplum } {
if { $gpcompress } {
set compression "WITH (appendonly=true, orientation=column, compresstype=zlib, compresslevel=5)"
	} else {
set compression ""
	}
set sql(1) "CREATE TABLE ORDERS (O_ORDERDATE TIMESTAMP, O_ORDERKEY NUMERIC NOT NULL, O_CUSTKEY NUMERIC NOT NULL, O_ORDERPRIORITY CHAR(15), O_SHIPPRIORITY NUMERIC, O_CLERK CHAR(15), O_ORDERSTATUS CHAR(1), O_TOTALPRICE NUMERIC, O_COMMENT VARCHAR(79)) $compression DISTRIBUTED BY (O_ORDERKEY)"
set sql(2) "CREATE TABLE PARTSUPP (PS_PARTKEY NUMERIC NOT NULL, PS_SUPPKEY NUMERIC NOT NULL, PS_SUPPLYCOST NUMERIC NOT NULL, PS_AVAILQTY NUMERIC, PS_COMMENT VARCHAR(199)) $compression DISTRIBUTED BY (PS_PARTKEY,PS_SUPPKEY)"
set sql(3) "CREATE TABLE CUSTOMER(C_CUSTKEY NUMERIC NOT NULL, C_MKTSEGMENT CHAR(10), C_NATIONKEY NUMERIC, C_NAME VARCHAR(25), C_ADDRESS VARCHAR(40), C_PHONE CHAR(15), C_ACCTBAL NUMERIC, C_COMMENT VARCHAR(118)) $compression DISTRIBUTED BY (C_CUSTKEY)"
set sql(4) "CREATE TABLE PART(P_PARTKEY NUMERIC NOT NULL, P_TYPE VARCHAR(25), P_SIZE NUMERIC, P_BRAND CHAR(10), P_NAME VARCHAR(55), P_CONTAINER CHAR(10), P_MFGR CHAR(25), P_RETAILPRICE NUMERIC, P_COMMENT VARCHAR(23)) $compression DISTRIBUTED BY (P_PARTKEY)"
set sql(5) "CREATE TABLE SUPPLIER(S_SUPPKEY NUMERIC NOT NULL, S_NATIONKEY NUMERIC, S_COMMENT VARCHAR(102), S_NAME CHAR(25), S_ADDRESS VARCHAR(40), S_PHONE CHAR(15), S_ACCTBAL NUMERIC)  $compression DISTRIBUTED BY (S_SUPPKEY)"
set sql(6) "CREATE TABLE NATION(N_NATIONKEY NUMERIC NOT NULL, N_NAME CHAR(25), N_REGIONKEY NUMERIC, N_COMMENT VARCHAR(152)) $compression DISTRIBUTED BY (N_NATIONKEY)" 
set sql(7) "CREATE TABLE REGION(R_REGIONKEY NUMERIC, R_NAME CHAR(25), R_COMMENT VARCHAR(152)) $compression DISTRIBUTED BY (R_REGIONKEY)"
set sql(8) "CREATE TABLE LINEITEM(L_SHIPDATE TIMESTAMP, L_ORDERKEY NUMERIC NOT NULL, L_DISCOUNT NUMERIC NOT NULL, L_EXTENDEDPRICE NUMERIC NOT NULL, L_SUPPKEY NUMERIC NOT NULL, L_QUANTITY NUMERIC NOT NULL, L_RETURNFLAG CHAR(1), L_PARTKEY NUMERIC NOT NULL, L_LINESTATUS CHAR(1), L_TAX NUMERIC NOT NULL, L_COMMITDATE TIMESTAMP, L_RECEIPTDATE TIMESTAMP, L_SHIPMODE CHAR(10), L_LINENUMBER NUMERIC NOT NULL, L_SHIPINSTRUCT CHAR(25), L_COMMENT VARCHAR(44)) $compression DISTRIBUTED BY (L_LINENUMBER, L_ORDERKEY)"
	} else {
set sql(1) "CREATE TABLE ORDERS (O_ORDERDATE TIMESTAMP, O_ORDERKEY NUMERIC NOT NULL, O_CUSTKEY NUMERIC NOT NULL, O_ORDERPRIORITY CHAR(15), O_SHIPPRIORITY NUMERIC, O_CLERK CHAR(15), O_ORDERSTATUS CHAR(1), O_TOTALPRICE NUMERIC, O_COMMENT VARCHAR(79))"
set sql(2) "CREATE TABLE PARTSUPP (PS_PARTKEY NUMERIC NOT NULL, PS_SUPPKEY NUMERIC NOT NULL, PS_SUPPLYCOST NUMERIC NOT NULL, PS_AVAILQTY NUMERIC, PS_COMMENT VARCHAR(199))"
set sql(3) "CREATE TABLE CUSTOMER(C_CUSTKEY NUMERIC NOT NULL, C_MKTSEGMENT CHAR(10), C_NATIONKEY NUMERIC, C_NAME VARCHAR(25), C_ADDRESS VARCHAR(40), C_PHONE CHAR(15), C_ACCTBAL NUMERIC, C_COMMENT VARCHAR(118))"
set sql(4) "CREATE TABLE PART(P_PARTKEY NUMERIC NOT NULL, P_TYPE VARCHAR(25), P_SIZE NUMERIC, P_BRAND CHAR(10), P_NAME VARCHAR(55), P_CONTAINER CHAR(10), P_MFGR CHAR(25), P_RETAILPRICE NUMERIC, P_COMMENT VARCHAR(23))"
set sql(5) "CREATE TABLE SUPPLIER(S_SUPPKEY NUMERIC NOT NULL, S_NATIONKEY NUMERIC, S_COMMENT VARCHAR(102), S_NAME CHAR(25), S_ADDRESS VARCHAR(40), S_PHONE CHAR(15), S_ACCTBAL NUMERIC)"
set sql(6) "CREATE TABLE NATION(N_NATIONKEY NUMERIC NOT NULL, N_NAME CHAR(25), N_REGIONKEY NUMERIC, N_COMMENT VARCHAR(152))" 
set sql(7) "CREATE TABLE REGION(R_REGIONKEY NUMERIC, R_NAME CHAR(25), R_COMMENT VARCHAR(152))"
set sql(8) "CREATE TABLE LINEITEM(L_SHIPDATE TIMESTAMP, L_ORDERKEY NUMERIC NOT NULL, L_DISCOUNT NUMERIC NOT NULL, L_EXTENDEDPRICE NUMERIC NOT NULL, L_SUPPKEY NUMERIC NOT NULL, L_QUANTITY NUMERIC NOT NULL, L_RETURNFLAG CHAR(1), L_PARTKEY NUMERIC NOT NULL, L_LINESTATUS CHAR(1), L_TAX NUMERIC NOT NULL, L_COMMITDATE TIMESTAMP, L_RECEIPTDATE TIMESTAMP, L_SHIPMODE CHAR(10), L_LINENUMBER NUMERIC NOT NULL, L_SHIPINSTRUCT CHAR(25), L_COMMENT VARCHAR(44))"
	}
for { set i 1 } { $i <= 8 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

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

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

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

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

proc gen_phone {} {
set acode [ RandomNumber 100 999 ]
set exchg [ RandomNumber 100 999 ]
set number [ RandomNumber 1000 9999 ]
return [ concat $acode-$exchg-$number ]
}

proc MakeAlphaString { min max chArray chalen } {
set len [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

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

proc pick_str { name } {
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

proc txt_vp {} {
set verb_list [ split [ pick_str vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str np ] ]
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
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
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

proc V_STR { avg } {
set globArray [ list , \  0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
return [ MakeAlphaString [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] $globArray $chalen ] 
}

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}

proc mk_region { lda } {
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT 72 ]
set result [ pg_exec $lda "INSERT INTO REGION (R_REGIONKEY, R_NAME, R_COMMENT) VALUES ('$code','$text','$comment')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
	    return
        } else {
	pg_result $result -clear
	}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "Region done"
	return
}

proc mk_nation { lda } {
for { set i 1 } { $i <= 25 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists nations ] [ expr {$i - 1} ] ] 0 ]
set nind [ lsearch -glob [ get_dists nations ] \*$text\* ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set join 0 }
1 - 2 - 3 - 17 - 24 { set join 1 }
8 - 9 - 12 - 18 - 21 { set join 2 }
6 - 7 - 19 - 22 - 23 { set join 3 }
10 - 11 - 13 - 20 { set join 4 }
}
set comment [ TEXT 72 ]
set result [ pg_exec $lda "INSERT INTO NATION (N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT) VALUES ('$code','$text','$join','$comment')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
	    return
        } else {
	pg_result $result -clear
	}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "Nation done"
	return
}

proc mk_supp { lda start_rows end_rows greenplum } {
set BBB_COMMEND   "Recommends"
set BBB_COMPLAIN  "Complaints"
if { $greenplum } { set rowcount 1 } else { set rowcount 1000 }
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set suppkey $i
set name [ concat Supplier#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
#random format to 2 floating point places 1681.00
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set comment [ TEXT 63 ]
set bad_press [ RandomNumber 1 10000 ]
set type [ RandomNumber 0 100 ]
set noise [ RandomNumber 0 19 ]
set offset [ RandomNumber 0 [ expr {19 + $noise} ] ]
if { $bad_press <= 10 } {
set st [ expr {9 + $offset + $noise} ]
set fi [ expr {$st + 10} ]
if { $type < 50 } {
set comment [ string replace $comment $st $fi $BBB_COMPLAIN ]
} else {
set comment [ string replace $comment $st $fi $BBB_COMMEND ]
	}
}
append supp_val_list ('$suppkey', '$nation_code', '$comment', '$name', '$address', '$phone', '$acctbal')
if { ![ expr {$i % $rowcount} ] || $i eq $end_rows } {    
set result [ pg_exec $lda "INSERT INTO SUPPLIER (S_SUPPKEY, S_NATIONKEY, S_COMMENT, S_NAME, S_ADDRESS, S_PHONE, S_ACCTBAL) VALUES $supp_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if {!$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
	unset supp_val_list
	} else {
if {!$greenplum} {
append supp_val_list ,
		} 
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading SUPPLIER...$i"
if {$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
     }
   }
puts "SUPPLIER Done Rows $start_rows..$end_rows"
return
}

proc mk_cust { lda start_rows end_rows greenplum } {
if { $greenplum } { set rowcount 1 } else { set rowcount 1000 }
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set custkey $i
set name [ concat Customer#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set mktsegment [ pick_str msegmnt ]
set comment [ TEXT 73 ]
append cust_val_list ('$custkey', '$mktsegment', '$nation_code', '$name', '$address', '$phone', '$acctbal', '$comment') 
if { ![ expr {$i % $rowcount} ] || $i eq $end_rows } {    
set result [ pg_exec $lda "INSERT INTO CUSTOMER (C_CUSTKEY, C_MKTSEGMENT, C_NATIONKEY, C_NAME, C_ADDRESS, C_PHONE, C_ACCTBAL, C_COMMENT) values $cust_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if {!$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
	unset cust_val_list
	} else {
if {!$greenplum} {
append cust_val_list ,
 		}
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading CUSTOMER...$i"
if {$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
    }
}
puts "Customer Done Rows $start_rows..$end_rows"
return
}

proc mk_part { lda start_rows end_rows scale_factor greenplum } {
if { $greenplum } { set rowcount 1 } else { set rowcount 1000 }
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set partkey $i
unset -nocomplain name
for {set j 0} {$j < [ expr {5 - 1} ] } {incr j } {
append name [ pick_str colors ] " "
}
append name [ pick_str colors ]
set mf [ RandomNumber 1 5 ]
set mfgr [ concat Manufacturer#$mf ]
set brand [ concat Brand#[ expr {$mf * 10 + [ RandomNumber 1 5 ]} ] ]
set type [ pick_str p_types ] 
set size [ RandomNumber 1 50 ]
set container [ pick_str p_cntr ] 
set price [ rpb_routine $i ]
set comment [ TEXT 14 ]
append part_val_list ('$partkey', '$type', '$size', '$brand', '$name', '$container', '$mfgr', '$price', '$comment')
#Part Supp Loop
for {set k 0} {$k < 4 } {incr k } {
set psupp_pkey $partkey
set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $scale_factor ]
set psupp_qty [ RandomNumber 1 9999 ]
set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
set psupp_comment [ TEXT 124 ]
append psupp_val_list ('$psupp_pkey', '$psupp_suppkey', '$psupp_scost', '$psupp_qty', '$psupp_comment')
if {!$greenplum} {
if { $k<=2 } {
append psupp_val_list ,
        }
    }
if {!$greenplum} {
#PostgreSQL does multi-line inserts later, Greenplum does line-by-line
 } else { 
set result [ pg_exec $lda "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_SUPPLYCOST, PS_AVAILQTY, PS_COMMENT) VALUES $psupp_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
        unset psupp_val_list
	}
   }
# end of psupp loop
if { ![ expr {$i % $rowcount} ]  || $i eq $end_rows } {     
set result [ pg_exec $lda "INSERT INTO PART (P_PARTKEY, P_TYPE, P_SIZE, P_BRAND, P_NAME, P_CONTAINER, P_MFGR, P_RETAILPRICE, P_COMMENT) VALUES $part_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if {!$greenplum} {
set result [ pg_exec $lda "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_SUPPLYCOST, PS_AVAILQTY, PS_COMMENT) VALUES $psupp_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	}
if {!$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
        unset part_val_list
        unset -nocomplain psupp_val_list
	} else {
if {!$greenplum} {
append part_val_list ,
append psupp_val_list ,
		}
	}
if { ![ expr {$i % 10000} ] } {
        puts "Loading PART/PARTSUPP...$i"
if {$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
		}
        }
}
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_order { lda start_rows end_rows upd_num scale_factor greenplum } {
if { $greenplum } { set rowcount 1 } else { set rowcount 1000 }
proc date_function {} {
set df "to_timestamp"
return $df
	}
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
for { set i $start_rows } { $i <= $end_rows } { incr i } {
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str instruct ] 
set lsmode [ pick_str smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
append lineit_val_list ([ date_function ]('$lsdate','YYYY-Mon-DD'),'$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', [ date_function ]('$lcdate','YYYY-Mon-DD'), [ date_function ]('$lrdate','YYYY-Mon-DD'), '$lsmode', '$llcnt', '$linstruct', '$lcomment') 
if {!$greenplum} {
if { $l < [ expr $lcnt - 1 ] } { 
append lineit_val_list ,
	} 
      } else {
set result [ pg_exec $lda "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES $lineit_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	unset lineit_val_list
    }
}
#End Lineitem Loop
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
append order_val_list ([ date_function ]('$date','YYYY-Mon-DD'), '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment') 
if { ![ expr {$i % $rowcount} ]  || $i eq $end_rows } {     
if {!$greenplum} {
set result [ pg_exec $lda "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES $lineit_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
   }
set result [ pg_exec $lda "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES $order_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	if {!$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
	unset -nocomplain lineit_val_list
	unset order_val_list	
   	} else {
	if {!$greenplum} {
	append order_val_list ,
	append lineit_val_list ,
		}
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading ORDERS/LINEITEM...$i"
if {$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
		}
	}
}
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc CreateIndexes { lda greenplum gpcompress } {
puts "CREATING TPCH INDEXES"
if { $greenplum && $gpcompress } {
set ind_cnt 8
set sql(1) "CREATE INDEX REGION_PK ON REGION (R_REGIONKEY)"
set sql(2) "CREATE INDEX NATION_PK ON NATION (N_NATIONKEY)"
set sql(3) "CREATE INDEX SUPPLIER_PK ON SUPPLIER (S_SUPPKEY)"
set sql(4) "CREATE INDEX PARTSUPP_PK ON PARTSUPP (PS_PARTKEY,PS_SUPPKEY)"
set sql(5) "CREATE INDEX PART_PK ON PART (P_PARTKEY)"
set sql(6) "CREATE INDEX ORDERS_PK ON ORDERS (O_ORDERKEY)"
set sql(7) "CREATE INDEX LINEITEM_PK ON LINEITEM (L_LINENUMBER, L_ORDERKEY)"
set sql(8) "CREATE INDEX CUSTOMER_PK ON CUSTOMER (C_CUSTKEY)"
	} else {
set ind_cnt 16
set sql(1) "ALTER TABLE REGION ADD CONSTRAINT REGION_PK PRIMARY KEY (R_REGIONKEY)"
set sql(2) "ALTER TABLE NATION ADD CONSTRAINT NATION_PK PRIMARY KEY (N_NATIONKEY)"
set sql(3) "ALTER TABLE SUPPLIER ADD CONSTRAINT SUPPLIER_PK PRIMARY KEY (S_SUPPKEY)"
set sql(4) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_PK PRIMARY KEY (PS_PARTKEY,PS_SUPPKEY)"
set sql(5) "ALTER TABLE PART ADD CONSTRAINT PART_PK PRIMARY KEY (P_PARTKEY)"
set sql(6) "ALTER TABLE ORDERS ADD CONSTRAINT ORDERS_PK PRIMARY KEY (O_ORDERKEY)"
set sql(7) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_PK PRIMARY KEY (L_LINENUMBER, L_ORDERKEY)"
set sql(8) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_PK PRIMARY KEY (C_CUSTKEY)"
set sql(9) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_PARTSUPP_FK FOREIGN KEY (L_PARTKEY, L_SUPPKEY) REFERENCES PARTSUPP(PS_PARTKEY, PS_SUPPKEY) NOT DEFERRABLE"
set sql(10) "ALTER TABLE ORDERS ADD CONSTRAINT ORDER_CUSTOMER_FK FOREIGN KEY (O_CUSTKEY) REFERENCES CUSTOMER (C_CUSTKEY) NOT DEFERRABLE"
set sql(11) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_PART_FK FOREIGN KEY (PS_PARTKEY) REFERENCES PART (P_PARTKEY) NOT DEFERRABLE"
set sql(12) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_SUPPLIER_FK FOREIGN KEY (PS_SUPPKEY) REFERENCES SUPPLIER (S_SUPPKEY) NOT DEFERRABLE"
set sql(13) "ALTER TABLE SUPPLIER ADD CONSTRAINT SUPPLIER_NATION_FK FOREIGN KEY (S_NATIONKEY) REFERENCES NATION (N_NATIONKEY) NOT DEFERRABLE"
set sql(14) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_NATION_FK FOREIGN KEY (C_NATIONKEY) REFERENCES NATION (N_NATIONKEY) NOT DEFERRABLE"
set sql(15) "ALTER TABLE NATION ADD CONSTRAINT NATION_REGION_FK FOREIGN KEY (N_REGIONKEY) REFERENCES REGION (R_REGIONKEY) NOT DEFERRABLE"
set sql(16) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_ORDER_FK FOREIGN KEY (L_ORDERKEY) REFERENCES ORDERS (O_ORDERKEY) NOT DEFERRABLE"
	}
for { set i 1 } { $i <= $ind_cnt } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	}  else {
	pg_result $result -clear
	}
    }
return
}

proc start_end { sup_rows myposition my_mult num_threads } {
set sf_chunk [ expr $sup_rows / $num_threads ]
set sf_rem [ expr $sup_rows % $num_threads ]
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
if  { $myposition eq $num_threads + 1 } { set myend [ expr {$sup_rows * $my_mult} ] }
return $mystart:$myend
}

proc do_tpch { host port scale_fact superuser superuser_password defaultdb db user password greenplum gpcompress num_threads } {
global dist_names dist_weights weights dists weights
###############################################
#Generating following rows
#5 rows in region table
#25 rows in nation table
#SF * 10K rows in Supplier table
#SF * 150K rows in Customer table
#SF * 200K rows in Part table
#SF * 800K rows in Partsupp table
#SF * 1500K rows in Orders table
#SF * 6000K rows in Lineitem table
###############################################
#update number always zero for first load
set upd_num 0
if { ![ array exists dists ] } { set_dists }
foreach i [ array names dists ] {
set_dist_list $i
}
set sup_rows [ expr {$scale_fact * 10000} ]
set max_threads 256
set sf_mult 1
set cust_mult 15
set part_mult 20
set ord_mult 150
if { [ string toupper $greenplum ] eq "TRUE"} { set greenplum 1 } else { set greenplum 0 }
if { [ string toupper $gpcompress ] eq "TRUE"} { set gpcompress 1 } else { set gpcompress 0 }
if { $num_threads > $max_threads } { set num_threads $max_threads }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
switch $myposition {
	1 { 
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
			}
tsv::set application load "WAIT"
		}
	}
	default { 
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_threads 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $user ] SCHEMA"
set lda [ ConnectToPostgres $host $port $superuser $superuser_password $defaultdb ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
CreateUserDatabase $lda $db $user $password
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
pg_disconnect $lda
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
CreateTables $lda $greenplum $gpcompress
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
	}
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
puts "Loading REGION..."
mk_region $lda
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $lda
puts "Loading NATION COMPLETE"
puts "Monitoring Workers..."
after 10000
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
puts "Loading REGION..."
mk_region $lda
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $lda
puts "Loading NATION COMPLETE"
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 }
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
if { [ expr $num_threads + 1 ] > $max_threads } { set num_threads $max_threads }
set sf_chunk [ split [ start_end $sup_rows $myposition $sf_mult $num_threads ] ":" ]
set cust_chunk [ split [ start_end $sup_rows $myposition $cust_mult $num_threads ] ":" ]
set part_chunk [ split [ start_end $sup_rows $myposition $part_mult $num_threads ] ":" ]
set ord_chunk [ split [ start_end $sup_rows $myposition $ord_mult $num_threads ] ":" ]
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set sf_chunk "1 $sup_rows"
set cust_chunk "1 [ expr {$sup_rows * $cust_mult} ]" 
set part_chunk "1 [ expr {$sup_rows * $part_mult} ]" 
set ord_chunk "1 [ expr {$sup_rows * $ord_mult} ]"
}
puts "Start:[ clock format [ clock seconds ] ]"
puts "Loading SUPPLIER..."
mk_supp $lda [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ] $greenplum
puts "Loading CUSTOMER..."
mk_cust $lda [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ] $greenplum
puts "Loading PART and PARTSUPP..."
mk_part $lda [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact $greenplum
puts "Loading ORDERS and LINEITEM..."
mk_order $lda [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact $greenplum
puts "Loading TPCH TABLES COMPLETE"
puts "End:[ clock format [ clock seconds ] ]"
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes $lda $greenplum $gpcompress
GatherStatistics $lda
puts "[ string toupper $user ] SCHEMA COMPLETE"
pg_disconnect $lda
return
		}
	}
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 934.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "do_tpch $pg_host $pg_port $pg_scale_fact $pg_tpch_superuser $pg_tpch_superuserpass $pg_tpch_defaultdbase $pg_tpch_dbase $pg_tpch_user $pg_tpch_pass $pg_tpch_gpcompat $pg_tpch_gpcompress $pg_num_tpch_threads"
update
run_virtual
	} else { return }
}

proc loadoratpch { } { 
global instance tpch_user tpch_pass total_querysets raise_query_error verbose degree_of_parallel refresh_on update_sets trickle_refresh refresh_verbose scale_fact tpch_tt_compat _ED
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists tpch_user ] } { set tpch_user "tpch" }
if {  ![ info exists tpch_pass ] } { set tpch_pass "tpch" }
if {  ![ info exists scale_fact ] } { set scale_fact 1 }
if {  ![ info exists total_querysets ] } { set total_querysets 1 }
if {  ![ info exists raise_query_error ] } { set raise_query_error "false" }
if {  ![ info exists verbose ] } { set verbose "false" }
if {  ![ info exists degree_of_parallel ] } { set degree_of_parallel "1" }
if {  ![ info exists refresh_on ] } { set refresh_on "false" }
if {  ![ info exists update_sets ] } { set update_sets "1" }
if {  ![ info exists trickle_refresh ] } { set trickle_refresh "1000" }
if {  ![ info exists refresh_verbose ] } { set refresh_verbose "false" }
if {  ![ info exists tpch_tt_compat ] } { set tpch_tt_compat "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Oracle TPC-H"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Oratcl} \] { error \"Failed to load Oratcl - Oracle OCI Library Error\" }
#EDITABLE OPTIONS##################################################
set total_querysets $total_querysets ;# Number of query sets before logging off
set RAISEERROR \"$raise_query_error\" ;# Exit script on Oracle query error (true or false)
set VERBOSE \"$verbose\" ;# Show query text and output
set degree_of_parallel \"$degree_of_parallel\" ;# Degree of Parallelism
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 8.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "set scale_factor $scale_fact ;#Scale factor of the tpc-h schema\nset timesten \"$tpch_tt_compat\" ;# Database is TimesTen\nset connect $tpch_user/$tpch_pass@$instance ;# Oracle connect string for tpc-h user
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 11.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "set refresh_on \"$refresh_on\" ;#First User does refresh function
set update_sets $update_sets ;#Number of sets of refresh function to complete
set trickle_refresh $trickle_refresh ;#time delay (ms) to trickle refresh function
set REFRESH_VERBOSE \"$refresh_verbose\" ;#report refresh function activity
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 17.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act {proc standsql { curn sql RAISEERROR } {
set ftch ""
if {[catch {orasql $curn $sql} message]} {
if { $RAISEERROR } {
error "Query Error : $message [ oramsg $curn all ]"
	} else {
puts "Query Failed: $sql : $message"
	}
} else {
orafetch  $curn -datavariable output
while { [ oramsg  $curn ] == 0 } {
lappend ftch $output
orafetch  $curn -datavariable output
		}
return $ftch
   } 
}

proc printlist { inlist } {
    foreach item $inlist {
    if { [llength $item] > 1 } {  printlist $item  } else { puts $item }
    }
}

proc SetNLS { lda } {
set curn_nls [oraopen $lda ]
set nls(1) "alter session set NLS_LANGUAGE = AMERICAN"
set nls(2) "alter session set NLS_TERRITORY = AMERICA"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn_nls $nls($i)} message ] } {
puts "$message $nls($i)"
puts [ oramsg $curn_nls all ]
			}
	}
oraclose $curn_nls
}

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

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

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

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

proc pick_str { dists name } {
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

proc txt_vp {} {
set verb_list [ split [ pick_str [ get_dists vp ] vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str [ get_dists np ] np ] ]
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
append verb_p [ pick_str [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str [ get_dists grammar ] grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str [ get_dists prepositions ] prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str [ get_dists terminators ] terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
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

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}
#########################
#TPCH REFRESH PROCEDURE
proc mk_order_ref { lda upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
set sql "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES (TO_DATE(:O_ORDERDATE,'YYYY-MM-DD'), :O_ORDERKEY, :O_CUSTKEY, :O_ORDERPRIORITY, :O_SHIPPRIORITY, :O_CLERK, :O_ORDERSTATUS, :O_TOTALPRICE, :O_COMMENT)"
set statement {orabind $curn1 :O_ORDERDATE $date :O_ORDERKEY $okey :O_CUSTKEY $custkey :O_ORDERPRIORITY $opriority :O_SHIPPRIORITY $spriority :O_CLERK $clerk :O_ORDERSTATUS $orderstatus :O_TOTALPRICE $totalprice :O_COMMENT $comment}
set sql2 "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) values (TO_DATE(:L_SHIPDATE,'YYYY-MM-DD'), :L_ORDERKEY, :L_DISCOUNT, :L_EXTENDEDPRICE, :L_SUPPKEY, :L_QUANTITY, :L_RETURNFLAG, :L_PARTKEY, :L_LINESTATUS, :L_TAX, TO_DATE(:L_COMMITDATE,'YYYY-MM-DD'), TO_DATE(:L_RECEIPTDATE,'YYYY-MM-DD'), :L_SHIPMODE, :L_LINENUMBER, :L_SHIPINSTRUCT, :L_COMMENT)"
set statement2 {orabind $curn2 :L_SHIPDATE $lsdate :L_ORDERKEY $lokey :L_DISCOUNT $ldiscount :L_EXTENDEDPRICE $leprice :L_SUPPKEY $lsuppkey :L_QUANTITY $lquantity :L_RETURNFLAG $lrflag :L_PARTKEY $lpartkey :L_LINESTATUS $lstatus :L_TAX $ltax :L_COMMITDATE $lcdate :L_RECEIPTDATE $lrdate :L_SHIPMODE $lsmode :L_LINENUMBER $llcnt :L_SHIPINSTRUCT $linstruct :L_COMMENT $lcomment }
set curn1 [oraopen $lda ]
oraparse $curn1 $sql
set curn2 [oraopen $lda ]
oraparse $curn2 $sql2
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str [ get_dists o_oprio ] o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
if { $REFRESH_VERBOSE } {
puts "Refresh Insert Orderkey $okey..."
	}
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str [ get_dists instruct ] instruct ] 
set lsmode [ pick_str [ get_dists smode ] smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str [ get_dists rflag ] rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
eval $statement2
if {[ catch {oraexec $curn2} message ] } {
puts "Error in cursor 2:$curn2 $message"
puts [ oramsg $curn2 all ]
	}
  }
if { ![ expr {$i % 1000} ] } {     
	  oracommit $lda
        update
   }
}
oracommit $lda
oraclose $curn1
oraclose $curn2
update
}

proc del_order_ref { lda upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.28.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#DELETE FROM ORDERS WHERE O_ORDERKEY = [value]
#DELETE FROM LINEITEM WHERE L_ORDERKEY = [value]
#END LOOP
set sql "DELETE FROM ORDERS WHERE O_ORDERKEY = :O_ORDERKEY"
set sql2 "DELETE FROM LINEITEM WHERE L_ORDERKEY = :L_ORDERKEY"
set statement {orabind $curn1 :O_ORDERKEY $okey }
set statement2 {orabind $curn2 :L_ORDERKEY $okey }
set curn1 [oraopen $lda ]
oraparse $curn1 $sql
set curn2 [oraopen $lda ]
oraparse $curn2 $sql2
set refresh 100
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {$upd_num / (10000 / $refresh)} ] ]
}
eval $statement2
if {[ catch {oraexec $curn2} message ] } {
puts "Error in cursor 2:$curn2 $message"
puts [ oramsg $curn2 all ]
	}
eval $statement
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
	}
if { $REFRESH_VERBOSE } {
puts "Refresh Delete Orderkey $okey..."
	}
if { ![ expr {$i % 1000} ] } {     
	  oracommit $lda
        update
   }
}
oracommit $lda
oraclose $curn1
oraclose $curn2
update
}

proc do_refresh { connect scale_factor update_sets trickle_refresh REFRESH_VERBOSE RF_SET timesten } {
set lda [ oralogon $connect ]
if { !$timesten } { SetNLS $lda }
oraautocom $lda off
set upd_num 1
for { set set_counter 1 } {$set_counter <= $update_sets } {incr set_counter} {
if {  [ tsv::get application abort ]  } { break }
if { $RF_SET eq "RF1" || $RF_SET eq "BOTH" } {
puts "New Sales refresh"
set r0 [clock clicks -millisec]
mk_order_ref $lda $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
set r1 [clock clicks -millisec]
set rvalnew [expr {double($r1-$r0)/1000}]
puts "New Sales refresh complete in $rvalnew seconds"
        }
if { $RF_SET eq "RF2" || $RF_SET eq "BOTH" } {
puts "Old Sales refresh"
set r3 [clock clicks -millisec]
del_order_ref $lda $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
set r4 [clock clicks -millisec]
set rvalold [expr {double($r4-$r3)/1000}]
puts "Old Sales refresh complete in $rvalold seconds"
        }
if { $RF_SET eq "BOTH" } {
set rvaltot [expr {double($r4-$r0)/1000}]
puts "Completed update set(s) $set_counter in $rvaltot seconds"
        }
incr upd_num
        }
puts "Completed $update_sets update set(s)"
oralogoff $lda
}
#########################
#TPCH QUERY GENERATION
proc set_query { myposition timesten } {
global sql
if { !$timesten } { 
set sql(1) "select l_returnflag, l_linestatus, sum(l_quantity) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(l_quantity) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count(*) as count_order from lineitem where l_shipdate <= date '1998-12-01' - interval ':1' day (3) group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus"
	} else {
set sql(1) "select l_returnflag, l_linestatus, sum(cast(l_quantity as NUMBER)) as sum_qty, cast(sum(l_extendedprice) as NUMBER) as sum_base_price, cast(sum((l_extendedprice) * (1 - l_discount)) as NUMBER) as sum_disc_price, cast(sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as NUMBER) as sum_charge, avg(cast(l_quantity as NUMBER)) as avg_qty, avg(cast(l_extendedprice as NUMBER)) as avg_price, avg(cast(l_discount as NUMBER)) as avg_disc, cast(count(*) as NUMBER) as count_order from lineitem where l_shipdate <= date '1998-12-01' - interval ':1' day group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus"
	}
set sql(2) "select s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from part, supplier, partsupp, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from partsupp, supplier, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey"
set sql(3) "select l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from customer, orders, lineitem where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < date ':2' and l_shipdate > date ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate"
if { !$timesten } { 
set sql(4) "select o_orderpriority, count(*) as order_count from orders where o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3' month and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority"
	} else {
set sql(4) "select o_orderpriority, cast(count(*) as NUMBER) as order_count from orders where o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3' month and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority"
	}
set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from customer, orders, lineitem, supplier, nation, region where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= date ':2' and o_orderdate < date ':2' + interval '1' year group by n_name order by revenue desc"
if { !$timesten } { 
set sql(6) "select sum(l_extendedprice * l_discount) as revenue from lineitem where l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1' year and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3"
	} else {
set sql(6) "select cast(sum(l_extendedprice * l_discount) as NUMBER) as revenue from lineitem where l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1' year and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3"
	}
set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, extract(year from l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from supplier, lineitem, orders, customer, nation n1, nation n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between date '1995-01-01' and date '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year"
set sql(8) "select o_year, sum(case when nation = ':1' then volume else 0 end) / sum(volume) as mkt_share from ( select extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as nation from part, supplier, lineitem, orders, customer, nation n1, nation n2, region where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between date '1995-01-01' and date '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year"
set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from part, supplier, lineitem, partsupp, orders, nation where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc"
set sql(10) "select c_custkey, c_name, sum(l_extendedprice * (1 - l_discount)) as revenue, c_acctbal, n_name, c_address, c_phone, c_comment from customer, orders, lineitem, nation where c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3' month and l_returnflag = 'R' and c_nationkey = n_nationkey group by c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment order by revenue desc"
set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc"
set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from orders, lineitem where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= date ':3' and l_receiptdate < date ':3' + interval '1' year group by l_shipmode order by l_shipmode"
if { !$timesten } { 
set sql(13) "select c_count, count(*) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc"
	} else {
set sql(13) "select c_count, cast(count(*) as NUMBER) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc"
	}
set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from lineitem, part where l_partkey = p_partkey and l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1' month"
if { !$timesten } { 
set sql(15) "create or replace view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from lineitem where l_shipdate >= to_date( ':1', 'YYYY-MM-DD') and l_shipdate < add_months( to_date (':1', 'YYYY-MM-DD'), 3) group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from supplier, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey; drop view revenue$myposition"
	} else {
set sql(15) "create view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from lineitem where l_shipdate >= to_date( ':1', 'YYYY-MM-DD') and l_shipdate < add_months( to_date (':1', 'YYYY-MM-DD'), 3) group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from supplier, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey; drop view revenue$myposition"
	}
set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from partsupp, part where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from supplier where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size"
if { !$timesten } { 
set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey)"
	} else {
set sql(17) "select cast(sum(l_extendedprice) as NUMBER) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey)"
	}
set sql(18) "select c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from customer, orders, lineitem where o_orderkey in ( select l_orderkey from lineitem group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate"
set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from lineitem, part where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON')"
set sql(20) "select s_name, s_address from supplier, nation where s_suppkey in ( select ps_suppkey from partsupp where ps_partkey in ( select p_partkey from part where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from lineitem where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= date ':2' and l_shipdate < date ':2' + interval '1' year)) and s_nationkey = n_nationkey and n_name = ':3' order by s_name"
set sql(21) "select s_name, count(*) as numwait from supplier, lineitem l1, orders, nation where s_suppkey = l1.l_suppkey and o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and exists ( select * from lineitem l2 where l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey) and not exists ( select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) and s_nationkey = n_nationkey and n_name = ':1' group by s_name order by numwait desc, s_name"
if { !$timesten } { 
set sql(22) "select cntrycode, count(*) as numcust, sum(c_acctbal) as totacctbal from ( select substr(c_phone, 1, 2) as cntrycode, c_acctbal from customer where substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select avg(c_acctbal) from customer where c_acctbal > 0.00 and substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from orders where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode"
	} else {
set sql(22) "select cntrycode, cast(count(*) as NUMBER) as numcust, cast(sum(c_acctbal) as NUMBER) as totacctbal from ( select substr(c_phone, 1, 2) as cntrycode, c_acctbal from customer where substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select cast(avg(c_acctbal) as NUMBER) from customer where c_acctbal > 0.00 and substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from orders where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode"
	}
}

proc get_query { query_no myposition timesten } {
global sql
if { ![ array exists sql ] } { set_query $myposition $timesten }
return $sql($query_no)
}

proc sub_query { query_no scale_factor myposition timesten } {
set P_SIZE_MIN 1
set P_SIZE_MAX 50
set MAX_PARAM 10
set q2sub [get_query $query_no $myposition $timesten ]
switch $query_no {
1 {
regsub -all {:1} $q2sub [RandomNumber 60 120] q2sub
  }
2 {
regsub -all {:1} $q2sub [RandomNumber $P_SIZE_MIN $P_SIZE_MAX] q2sub
set qc [ lindex [ split [ pick_str [ get_dists p_types ] p_types ] ] 2 ]
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str [ get_dists regions ] regions ]
regsub -all {:3} $q2sub $qc q2sub
  }
3 {
set qc [ pick_str [ get_dists msegmnt ] msegmnt ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 1 31]
if { [ string length $tmp_date ] eq 1 } {set tmp_date [ concat 0$tmp_date ]  }
regsub -all {:2} $q2sub [concat 1995-03-$tmp_date] q2sub
  }
4 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
  }
5 {
set qc [ pick_str [ get_dists regions ] regions ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
  }
6 {
set tmp_date [RandomNumber 93 97]
regsub -all {:1} $q2sub [concat 19$tmp_date-01-01] q2sub
regsub -all {:2} $q2sub [concat 0.0[RandomNumber 2 9]] q2sub
regsub -all {:3} $q2sub [RandomNumber 24 25] q2sub
  }
7 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str [ get_dists nations2 ] nations2 ] }
regsub -all {:2} $q2sub $qc2 q2sub
  }
8 {
set nationlist [ get_dists nations2 ]
set regionlist [ get_dists regions ]
set qc [ pick_str $nationlist nations2 ] 
regsub -all {:1} $q2sub $qc q2sub
set nind [ lsearch -glob $nationlist [concat \*$qc\*] ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set qc "AFRICA" }
1 - 2 - 3 - 17 - 24 { set qc "AMERICA" }
8 - 9 - 12 - 18 - 21 { set qc "ASIA" }
6 - 7 - 19 - 22 - 23 { set qc "EUROPE"}
10 - 11 - 13 - 20 { set qc "MIDDLE EAST"}
}
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str [ get_dists p_types ] p_types ]
regsub -all {:3} $q2sub $qc q2sub
  }
9 {
set qc [ pick_str [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
  }
10 {
set tmp_date [RandomNumber 1 24]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
   }
11 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set q11_fract [ format %11.10f [ expr 0.0001 / $scale_factor ] ]
regsub -all {:2} $q2sub $q11_fract q2sub
}
12 {
set qc [ pick_str [ get_dists smode ] smode ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str [ get_dists smode ] smode ] }
regsub -all {:2} $q2sub $qc2 q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:3} $q2sub [concat 19$tmp_date-01-01] q2sub
}
13 {
set qc [ pick_str [ get_dists Q13a ] Q13a ]
regsub -all {:1} $q2sub $qc q2sub
set qc [ pick_str [ get_dists Q13b ] Q13b ]
regsub -all {:2} $q2sub $qc q2sub
}
14 {
set tmp_date [RandomNumber 1 60]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
15 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
16 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set p_type [ split [ pick_str [ get_dists p_types ] p_types ] ]
set qc [ concat [ lindex $p_type 0 ] [ lindex $p_type 1 ] ]
regsub -all {:2} $q2sub $qc q2sub
set permute [list]
for {set i 3} {$i <= $MAX_PARAM} {incr i} {
set tmp3 [RandomNumber 1 50] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 1 50] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
   }
17 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set qc [ pick_str [ get_dists p_cntr ] p_cntr ]
regsub -all {:2} $q2sub $qc q2sub
 }
18 {
regsub -all {:1} $q2sub [RandomNumber 312 315] q2sub
}
19 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:2} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:3} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
regsub -all {:4} $q2sub [RandomNumber 1 10] q2sub
regsub -all {:5} $q2sub [RandomNumber 10 20] q2sub
regsub -all {:6} $q2sub [RandomNumber 20 30] q2sub
}
20 {
set qc [ pick_str [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:3} $q2sub $qc q2sub
	}
21 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
}
22 {
set permute [list]
for {set i 0} {$i <= 7} {incr i} {
set tmp3 [RandomNumber 10 34] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 10 34] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
    }
}
return $q2sub
}

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
#########################
#TPCH QUERY SETS PROCEDURE
proc do_tpch { connect  scale_factor RAISEERROR VERBOSE degree_of_parallel total_querysets timesten myposition } {
set lda [ oralogon $connect ]
if { !$timesten } { SetNLS $lda }
set curn1 [ oraopen $lda ]
if { !$timesten } {
set sql(1) "alter session force parallel dml parallel (degree $degree_of_parallel)"
set sql(2) "alter session force parallel ddl parallel (degree $degree_of_parallel)"
set sql(3) "alter session force parallel query parallel (degree $degree_of_parallel)"
for { set i 1 } { $i <= 3 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
	} else {
#Parallel Query currently not supported in TimesTen
set degree_of_parallel 1
	}
for {set it 0} {$it < $total_querysets} {incr it} {
if {  [ tsv::get application abort ]  } { break }
set start [ clock seconds ]
for { set q 1 } { $q <= 22 } { incr q } {
set dssquery($q)  [sub_query $q $scale_factor $myposition $timesten ]
if {$q != 15} {
	;
} else {
set query15list [split $dssquery($q) "\;"]
            set q15length [llength $query15list]
            set q15c 0
            while {$q15c <= [expr $q15length - 1]} {
            set dssquery($q,$q15c) [lindex $query15list $q15c]
            incr q15c
		}
	}
}
set o_s_list [ ordered_set $myposition ]
for { set q 1 } { $q <= 22 } { incr q } {
if {  [ tsv::get application abort ]  } { break }
set qos [ lindex $o_s_list [ expr $q - 1 ] ]
puts "Executing Query $qos ($q of 22)"
if {$VERBOSE} { puts $dssquery($qos) }
if {$qos != 15} {
set t0 [clock clicks -millisec]
set oput [ standsql $curn1 $dssquery($qos) $RAISEERROR ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
puts "query $qos completed in $value seconds"
	      } else {
            set q15c 0
            while {$q15c <= [expr $q15length - 1] } {
	if { $q15c != 1 } {
if {[ catch {orasql $curn1 $dssquery($qos,$q15c)} message ] } {
puts "$message $dssquery($qos,$q15c)"
puts [ oramsg $curn1 all ]
	  }
	} else {
set t0 [clock clicks -millisec]
set oput [ standsql $curn1 $dssquery($qos,$q15c) $RAISEERROR ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
puts "query $qos completed in $value seconds"
		}
            incr q15c
		}
        }
  }
set end [ clock seconds ]
set wall [ expr $end - $start ]
set qsets [ expr $it + 1 ]
puts "Completed $qsets query set(s) in $wall seconds"
	}
oralogoff $lda
 }
#########################
#RUN TPC-H
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set power_test "false"
if { $totalvirtualusers eq 1 } {
#Power Test
set power_test "true"
set myposition 0
        } else {
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
        }
if { $refresh_on } {
if { $power_test } {
set trickle_refresh 0
set update_sets 1
set REFRESH_VERBOSE "false"
do_refresh $connect $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF1 $timesten
do_tpch $connect $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets $timesten 0
do_refresh $connect $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF2 $timesten
        } else {
switch $myposition {
1 {
do_refresh $connect $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE BOTH $timesten
        }
default {
do_tpch $connect $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets $timesten [ expr $myposition - 1 ]
        }
    }
 }
} else {
do_tpch $connect $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets $timesten $myposition
		}
	}
}

proc loadmytpch { } { 
global mysql_host mysql_port mysql_scale_fact mysql_tpch_user mysql_tpch_pass mysql_tpch_dbase boxes runworld mysql_refresh_on mysql_total_querysets mysql_raise_query_error mysql_verbose mysql_update_sets mysql_trickle_refresh mysql_refresh_verbose
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_scale_fact ] } { set mysql_scale_fact "1" }
if {  ![ info exists mysql_tpch_user ] } { set mysql_tpch_user "root" }
if {  ![ info exists mysql_tpch_pass ] } { set mysql_tpch_pass "mysql" }
if {  ![ info exists mysql_tpch_dbase ] } { set mysql_tpch_dbase "tpch" }
if {  ![ info exists mysql_refresh_on ] } { set  mysql_refresh_on "false" }
if {  ![ info exists mysql_total_querysets ] } { set mysql_total_querysets "1" }
if {  ![ info exists mysql_raise_query_error ] } { set mysql_raise_query_error "false" }
if {  ![ info exists mysql_verbose ] } { set mysql_verbose "false" }
if {  ![ info exists mysql_update_sets ] } { set mysql_update_sets "1" }
if {  ![ info exists mysql_trickle_refresh ] } { set mysql_trickle_refresh "1000" }
if {  ![ info exists mysql_refresh_verbose ] } { set mysql_refresh_verbose "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "MySQL TPC-H"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "#!/usr/local/bin/tclsh8.6
if \[ catch {package require mysqltcl} \] { error \"Failed to load mysqltcl - MySQL Library Error\" }
#EDITABLE OPTIONS##################################################
set total_querysets $mysql_total_querysets ;# Number of query sets before logging off
set RAISEERROR \"$mysql_raise_query_error\" ;# Exit script on MySQL query error (true or false)
set VERBOSE \"$mysql_verbose\" ;# Show query text and output
set scale_factor $mysql_scale_fact ;#Scale factor of the tpc-h schema
set host \"$mysql_host\" ;# Address of the server hosting MySQL 
set port \"$mysql_port\" ;# Port of the MySQL Server, defaults to 3306
set user \"$mysql_tpch_user\" ;# MySQL user
set password \"$mysql_tpch_pass\" ;# Password for the MySQL user
set db \"$mysql_tpch_dbase\" ;# Database containing the TPC Schema
set refresh_on \"$mysql_refresh_on\" ;#First User does refresh function
set update_sets $mysql_update_sets ;#Number of sets of refresh function to complete
set trickle_refresh $mysql_trickle_refresh ;#time delay (ms) to trickle refresh function
set REFRESH_VERBOSE \"$mysql_refresh_verbose\" ;#report refresh function activity
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 18.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act {proc standsql { mysql_handler sql RAISEERROR } {
global mysqlstatus
catch { set oput [ join [ mysql::sel $mysql_handler "$sql" -list ] ] }
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Query Error : $mysqlstatus(message)"
         } else { puts $mysqlstatus(message)
      }
   }
return $oput
}

proc printlist { inlist } {
    foreach item $inlist {
    if { [llength $item] > 1 } {  printlist $item  } else { puts $item }
    }
}

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

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

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

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

proc pick_str { dists name } {
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

proc txt_vp {} {
set verb_list [ split [ pick_str [ get_dists vp ] vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str [ get_dists np ] np ] ]
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
append verb_p [ pick_str [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str [ get_dists grammar ] grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str [ get_dists prepositions ] prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str [ get_dists terminators ] terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
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

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}
#########################
#TPCH REFRESH PROCEDURE
proc mk_order_ref { mysql_handler upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str [ get_dists o_oprio ] o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
if { $REFRESH_VERBOSE } {
puts "Refresh Insert Orderkey $okey..."
	}
mysql::exec $mysql_handler "INSERT INTO ORDERS (`O_ORDERDATE`, `O_ORDERKEY`, `O_CUSTKEY`, `O_ORDERPRIORITY`, `O_SHIPPRIORITY`, `O_CLERK`, `O_ORDERSTATUS`, `O_TOTALPRICE`, `O_COMMENT`) VALUES (str_to_date('$date','%Y-%M-%d'), '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment')"
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str [ get_dists instruct ] instruct ] 
set lsmode [ pick_str [ get_dists smode ] smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str [ get_dists rflag ] rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
mysql::exec $mysql_handler "INSERT INTO LINEITEM (`L_SHIPDATE`, `L_ORDERKEY`, `L_DISCOUNT`, `L_EXTENDEDPRICE`, `L_SUPPKEY`, `L_QUANTITY`, `L_RETURNFLAG`, `L_PARTKEY`, `L_LINESTATUS`, `L_TAX`, `L_COMMITDATE`, `L_RECEIPTDATE`, `L_SHIPMODE`, `L_LINENUMBER`, `L_SHIPINSTRUCT`, `L_COMMENT`) VALUES (str_to_date('$lsdate','%Y-%M-%d'),'$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', str_to_date('$lcdate','%Y-%M-%d'), str_to_date('$lrdate','%Y-%M-%d'), '$lsmode', '$llcnt', '$linstruct', '$lcomment')"
  }
if { ![ expr {$i % 1000} ] } {     
mysql::commit $mysql_handler
   }
}
mysql::commit $mysql_handler
}

proc del_order_ref { mysql_handler upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.28.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#DELETE FROM ORDERS WHERE O_ORDERKEY = [value]
#DELETE FROM LINEITEM WHERE L_ORDERKEY = [value]
#END LOOP
set refresh 100
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {$upd_num / (10000 / $refresh)} ] ]
}
mysql::exec $mysql_handler "DELETE FROM LINEITEM WHERE L_ORDERKEY = $okey"
mysql::exec $mysql_handler "DELETE FROM ORDERS WHERE O_ORDERKEY = $okey"
if { $REFRESH_VERBOSE } {
puts "Refresh Delete Orderkey $okey..."
	}
if { ![ expr {$i % 1000} ] } {     
mysql::commit $mysql_handler
   }
}
mysql::commit $mysql_handler
}

proc do_refresh { host port user password db scale_factor update_sets trickle_refresh REFRESH_VERBOSE RF_SET } {
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
	}
set upd_num 1
for { set set_counter 1 } {$set_counter <= $update_sets } {incr set_counter} {
if {  [ tsv::get application abort ]  } { break }
if { $RF_SET eq "RF1" || $RF_SET eq "BOTH" } {
puts "New Sales refresh"
set r0 [clock clicks -millisec]
mk_order_ref $mysql_handler $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
set r1 [clock clicks -millisec]
set rvalnew [expr {double($r1-$r0)/1000}]
puts "New Sales refresh complete in $rvalnew seconds"
        }
if { $RF_SET eq "RF2" || $RF_SET eq "BOTH" } {
puts "Old Sales refresh"
set r3 [clock clicks -millisec]
del_order_ref $mysql_handler $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
set r4 [clock clicks -millisec]
set rvalold [expr {double($r4-$r3)/1000}]
puts "Old Sales refresh complete in $rvalold seconds"
        }
if { $RF_SET eq "BOTH" } {
set rvaltot [expr {double($r4-$r0)/1000}]
puts "Completed update set(s) $set_counter in $rvaltot seconds"
        }
incr upd_num
        }
puts "Completed $update_sets update set(s)"
mysqlclose $mysql_handler
}
#########################
#TPCH QUERY GENERATION
proc set_query { myposition } {
global sql
set sql(1) "select l_returnflag, l_linestatus, sum(l_quantity) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(l_quantity) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count(*) as count_order from LINEITEM where l_shipdate <= date '1998-12-01' - interval ':1' day group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus"
set sql(2) "select s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from PART, SUPPLIER, PARTSUPP, NATION, REGION where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from PARTSUPP, SUPPLIER, NATION, REGION where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey limit 100"
set sql(3) "select l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from CUSTOMER, ORDERS, LINEITEM where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < date ':2' and l_shipdate > date ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate limit 10"
set sql(4) "select o_orderpriority, count(*) as order_count from ORDERS where o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3' month and exists ( select * from LINEITEM where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority"
set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from CUSTOMER, ORDERS, LINEITEM, SUPPLIER, NATION, REGION where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= date ':2' and o_orderdate < date ':2' + interval '1' year group by n_name order by revenue desc"
set sql(6) "select sum(l_extendedprice * l_discount) as revenue from LINEITEM where l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1' year and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3"
set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, extract(year from l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from SUPPLIER, LINEITEM, ORDERS, CUSTOMER, NATION n1, NATION n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between date '1995-01-01' and date '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year"
set sql(8) "select o_year, sum(case when NATION = ':1' then volume else 0 end) / sum(volume) as mkt_share from ( select extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as NATION from PART, SUPPLIER, LINEITEM, ORDERS, CUSTOMER, NATION n1, NATION n2, REGION where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between date '1995-01-01' and date '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year"
set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from PART, SUPPLIER, LINEITEM, PARTSUPP, ORDERS, NATION where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc"
set sql(10) "select c_custkey, c_name, sum(l_extendedprice * (1 - l_discount)) as revenue, c_acctbal, n_name, c_address, c_phone, c_comment from CUSTOMER, ORDERS, LINEITEM, NATION where c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3' month and l_returnflag = 'R' and c_nationkey = n_nationkey group by c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment order by revenue desc limit 20"
set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from PARTSUPP, SUPPLIER, NATION where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from PARTSUPP, SUPPLIER, NATION where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc"
set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from ORDERS, LINEITEM where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= date ':3' and l_receiptdate < date ':3' + interval '1' year group by l_shipmode order by l_shipmode"
set sql(13) "select c_count, count(*) as custdist from ( select c_custkey as c_custkey, count(o_orderkey) as c_count from CUSTOMER left outer join ORDERS on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) as c_orders group by c_count order by custdist desc, c_count desc"
set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from LINEITEM, PART where l_partkey = p_partkey and l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1' month"
set sql(15) "create or replace view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from LINEITEM where l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '3' month group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from SUPPLIER, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey; drop view revenue$myposition"
set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from PARTSUPP, PART where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from SUPPLIER where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size"
set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from LINEITEM, PART where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from LINEITEM where l_partkey = p_partkey)"
set sql(18) "select c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from CUSTOMER, ORDERS, LINEITEM where o_orderkey in ( select l_orderkey from LINEITEM group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate limit 100"
set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from LINEITEM, PART where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON')"
set sql(20) "select s_name, s_address from SUPPLIER, NATION where s_suppkey in ( select ps_suppkey from PARTSUPP where ps_partkey in ( select p_partkey from PART where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from LINEITEM where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= date ':2' and l_shipdate < date ':2' + interval '1' year)) and s_nationkey = n_nationkey and n_name = ':3' order by s_name"
set sql(21) "select s_name, count(*) as numwait from SUPPLIER, LINEITEM l1, ORDERS, NATION where s_suppkey = l1.l_suppkey and o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and exists ( select * from LINEITEM l2 where l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey) and not exists ( select * from LINEITEM l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) and s_nationkey = n_nationkey and n_name = ':1' group by s_name order by numwait desc, s_name limit 100"
set sql(22) "select cntrycode, count(*) as numcust, sum(c_acctbal) as totacctbal from ( select substr(c_phone, 1, 2) as cntrycode, c_acctbal from CUSTOMER where substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select avg(c_acctbal) from CUSTOMER where c_acctbal > 0.00 and substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from ORDERS where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode"
}

proc get_query { query_no myposition } {
global sql
if { ![ array exists sql ] } { set_query $myposition }
return $sql($query_no)
}

proc sub_query { query_no scale_factor myposition } {
set P_SIZE_MIN 1
set P_SIZE_MAX 50
set MAX_PARAM 10
set q2sub [get_query $query_no $myposition ]
switch $query_no {
1 {
regsub -all {:1} $q2sub [RandomNumber 60 120] q2sub
  }
2 {
regsub -all {:1} $q2sub [RandomNumber $P_SIZE_MIN $P_SIZE_MAX] q2sub
set qc [ lindex [ split [ pick_str [ get_dists p_types ] p_types ] ] 2 ]
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str [ get_dists regions ] regions ]
regsub -all {:3} $q2sub $qc q2sub
  }
3 {
set qc [ pick_str [ get_dists msegmnt ] msegmnt ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 1 31]
if { [ string length $tmp_date ] eq 1 } {set tmp_date [ concat 0$tmp_date ]  }
regsub -all {:2} $q2sub [concat 1995-03-$tmp_date] q2sub
  }
4 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
  }
5 {
set qc [ pick_str [ get_dists regions ] regions ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
  }
6 {
set tmp_date [RandomNumber 93 97]
regsub -all {:1} $q2sub [concat 19$tmp_date-01-01] q2sub
regsub -all {:2} $q2sub [concat 0.0[RandomNumber 2 9]] q2sub
regsub -all {:3} $q2sub [RandomNumber 24 25] q2sub
  }
7 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str [ get_dists nations2 ] nations2 ] }
regsub -all {:2} $q2sub $qc2 q2sub
  }
8 {
set nationlist [ get_dists nations2 ]
set regionlist [ get_dists regions ]
set qc [ pick_str $nationlist nations2 ] 
regsub -all {:1} $q2sub $qc q2sub
set nind [ lsearch -glob $nationlist [concat \*$qc\*] ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set qc "AFRICA" }
1 - 2 - 3 - 17 - 24 { set qc "AMERICA" }
8 - 9 - 12 - 18 - 21 { set qc "ASIA" }
6 - 7 - 19 - 22 - 23 { set qc "EUROPE"}
10 - 11 - 13 - 20 { set qc "MIDDLE EAST"}
}
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str [ get_dists p_types ] p_types ]
regsub -all {:3} $q2sub $qc q2sub
  }
9 {
set qc [ pick_str [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
  }
10 {
set tmp_date [RandomNumber 1 24]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
   }
11 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set q11_fract [ format %11.10f [ expr 0.0001 / $scale_factor ] ]
regsub -all {:2} $q2sub $q11_fract q2sub
}
12 {
set qc [ pick_str [ get_dists smode ] smode ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str [ get_dists smode ] smode ] }
regsub -all {:2} $q2sub $qc2 q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:3} $q2sub [concat 19$tmp_date-01-01] q2sub
}
13 {
set qc [ pick_str [ get_dists Q13a ] Q13a ]
regsub -all {:1} $q2sub $qc q2sub
set qc [ pick_str [ get_dists Q13b ] Q13b ]
regsub -all {:2} $q2sub $qc q2sub
}
14 {
set tmp_date [RandomNumber 1 60]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
15 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
16 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set p_type [ split [ pick_str [ get_dists p_types ] p_types ] ]
set qc [ concat [ lindex $p_type 0 ] [ lindex $p_type 1 ] ]
regsub -all {:2} $q2sub $qc q2sub
set permute [list]
for {set i 3} {$i <= $MAX_PARAM} {incr i} {
set tmp3 [RandomNumber 1 50] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 1 50] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
   }
17 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set qc [ pick_str [ get_dists p_cntr ] p_cntr ]
regsub -all {:2} $q2sub $qc q2sub
 }
18 {
regsub -all {:1} $q2sub [RandomNumber 312 315] q2sub
}
19 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:2} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:3} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
regsub -all {:4} $q2sub [RandomNumber 1 10] q2sub
regsub -all {:5} $q2sub [RandomNumber 10 20] q2sub
regsub -all {:6} $q2sub [RandomNumber 20 30] q2sub
}
20 {
set qc [ pick_str [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:3} $q2sub $qc q2sub
	}
21 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
}
22 {
set permute [list]
for {set i 0} {$i <= 7} {incr i} {
set tmp3 [RandomNumber 10 34] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 10 34] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
    }
}
return $q2sub
}

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
#########################
#TPCH QUERY SETS PROCEDURE
proc do_tpch { host port user password db scale_factor RAISEERROR VERBOSE total_querysets myposition } {
global mysqlstatus
#Query 18 is long running on MySQL
set SKIP_QUERY_18 "false" 
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
}
for {set it 0} {$it < $total_querysets} {incr it} {
if {  [ tsv::get application abort ]  } { break }
set start [ clock seconds ]
for { set q 1 } { $q <= 22 } { incr q } {
set dssquery($q)  [sub_query $q $scale_factor $myposition ]
if {$q != 15} {
	;
} else {
set query15list [split $dssquery($q) "\;"]
            set q15length [llength $query15list]
            set q15c 0
            while {$q15c <= [expr $q15length - 1]} {
            set dssquery($q,$q15c) [lindex $query15list $q15c]
            incr q15c
		}
	}
}
set o_s_list [ ordered_set $myposition ]
for { set q 1 } { $q <= 22 } { incr q } {
if {  [ tsv::get application abort ]  } { break }
set qos [ lindex $o_s_list [ expr $q - 1 ] ]
puts "Executing Query $qos ($q of 22)"
if {$VERBOSE} { puts $dssquery($qos) }
if {$qos != 15} {
if {$qos eq 18 && $SKIP_QUERY_18 eq "true" } { 
puts "Long Running Query 18 Not Executed"
	} else {
set t0 [clock clicks -millisec]
set oput [ standsql $mysql_handler $dssquery($qos) $RAISEERROR ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
puts "query $qos completed in $value seconds"
		} 
	      } else {
            set q15c 0
            while {$q15c <= [expr $q15length - 1] } {
	if { $q15c != 1 } {
if {[ catch {mysqlexec $mysql_handler $dssquery($qos,$q15c)} ] } {
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Query Error : $mysqlstatus(message)"
        } else { 
	puts $mysqlstatus(message)
    	 }
       }
 }
} else {
set t0 [clock clicks -millisec]
catch { set oput [ mysql::sel $mysql_handler $dssquery($qos,$q15c) ] }
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Query Error : $mysqlstatus(message)"
        } else { 
	puts $mysqlstatus(message)
      }
}
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
puts "query $qos completed in $value seconds"
		}
            incr q15c
		}
        }
  }
set end [ clock seconds ]
set wall [ expr $end - $start ]
set qsets [ expr $it + 1 ]
puts "Completed $qsets query set(s) in $wall seconds"
	}
mysqlclose $mysql_handler
 }
#########################
#RUN TPC-H
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set power_test "false"
if { $totalvirtualusers eq 1 } {
#Power Test
set power_test "true"
set myposition 0
        } else {
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
        }
if { $refresh_on } {
if { $power_test } {
set trickle_refresh 0
set update_sets 1
set REFRESH_VERBOSE "false"
do_refresh $host $port $user $password $db $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF1
do_tpch $host $port $user $password $db $scale_factor $RAISEERROR $VERBOSE $total_querysets 0
do_refresh $host $port $user $password $db $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF2
        } else {
switch $myposition {
1 {
do_refresh $host $port $user $password $db $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE BOTH
        }
default {
do_tpch $host $port $user $password $db $scale_factor $RAISEERROR $VERBOSE $total_querysets [ expr $myposition - 1 ]
        }
     }
  }
} else {
do_tpch $host $port $user $password $db $scale_factor $RAISEERROR $VERBOSE $total_querysets $myposition
		}
	}
}

proc loadmssqlstpch {} {
global mssqls_server mssqls_port mssqls_scale_fact mssqls_maxdop mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass mssqls_tpch_dbase mssqls_refresh_on mssqls_total_querysets mssqls_raise_query_error mssqls_verbose mssqls_update_sets mssqls_trickle_refresh mssqls_refresh_verbose _ED
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_scale_fact ] } { set mssqls_scale_fact "1" }
if {  ![ info exists mssqls_maxdop ] } { set mssqls_maxdop "2" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_tpch_dbase ] } { set mssqls_tpch_dbase "tpch" }
if {  ![ info exists mssqls_refresh_on ] } { set  mssqls_refresh_on "false" }
if {  ![ info exists mssqls_total_querysets ] } { set mssqls_total_querysets "1" }
if {  ![ info exists mssqls_raise_query_error ] } { set mssqls_raise_query_error "false" }
if {  ![ info exists mssqls_verbose ] } { set mssqls_verbose "false" }
if {  ![ info exists mssqls_update_sets ] } { set mssqls_update_sets "1" }
if {  ![ info exists mssqls_trickle_refresh ] } { set mssqls_trickle_refresh "1000" }
if {  ![ info exists mssqls_refresh_verbose ] } { set mssqls_refresh_verbose "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "SQL Server TPC-H"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require tclodbc 2.5.1} \] { error \"Failed to load tclodbc - ODBC Library Error\" }
#EDITABLE OPTIONS##################################################
set total_querysets $mssqls_total_querysets ;# Number of query sets before logging off
set RAISEERROR \"$mssqls_raise_query_error\" ;# Exit script on SQL Server query error (true or false)
set VERBOSE \"$mssqls_verbose\" ;# Show query text and output
set maxdop $mssqls_maxdop ;# Maximum Degree of Parallelism
set scale_factor $mssqls_scale_fact ;#Scale factor of the tpc-h schema
set authentication \"$mssqls_authentication\";# Authentication Mode (WINDOWS or SQL)
set server {$mssqls_server};# Microsoft SQL Server Database Server
set port \"$mssqls_port\";# Microsoft SQL Server Port 
set odbc_driver {$mssqls_odbc_driver};# ODBC Driver
set uid \"$mssqls_uid\";#User ID for SQL Server Authentication
set pwd \"$mssqls_pass\";#Password for SQL Server Authentication
set database \"$mssqls_tpch_dbase\";# Database containing the TPC Schema
set refresh_on \"$mssqls_refresh_on\" ;#First User does refresh function
set update_sets $mssqls_update_sets ;#Number of sets of refresh function to complete
set trickle_refresh $mssqls_trickle_refresh ;#time delay (ms) to trickle refresh function
set REFRESH_VERBOSE \"$mssqls_refresh_verbose\" ;#report refresh function activity
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 21.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act {proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
	} else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
}
return $connection
}

proc standsql { odbc sql RAISEERROR } {
if {[ catch {set sql_output [odbc $sql ]} message]} {
if { $RAISEERROR } {
error "Query Error :$message"
	} else {
puts "$message"
	}
} else {
return $sql_output
	}
} 

proc printlist { inlist } {
    foreach item $inlist {
    if { [llength $item] > 1 } {  printlist $item  } else { puts $item }
    }
}

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

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

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

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

proc pick_str { dists name } {
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

proc txt_vp {} {
set verb_list [ split [ pick_str [ get_dists vp ] vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str [ get_dists np ] np ] ]
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
append verb_p [ pick_str [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str [ get_dists grammar ] grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str [ get_dists prepositions ] prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str [ get_dists terminators ] terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
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

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}
#########################
#TPCH REFRESH PROCEDURE
proc mk_order_ref { odbc upd_num scale_factor trickle_refresh REFRESH_VERBOSE } { 
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str [ get_dists o_oprio ] o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
if { $REFRESH_VERBOSE } {
puts "Refresh Insert Orderkey $okey..."
	}
odbc "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES ('$date', '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment')"
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str [ get_dists instruct ] instruct ] 
set lsmode [ pick_str [ get_dists smode ] smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str [ get_dists rflag ] rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
odbc "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES ('$lsdate','$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', '$lcdate', '$lrdate', '$lsmode', '$llcnt', '$linstruct', '$lcomment')"
  }
if { ![ expr {$i % 1000} ] } {     
odbc commit
        update
   }
}
odbc commit
update
}

proc del_order_ref { odbc upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.28.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#DELETE FROM ORDERS WHERE O_ORDERKEY = [value]
#DELETE FROM LINEITEM WHERE L_ORDERKEY = [value]
#END LOOP
set refresh 100
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {$upd_num / (10000 / $refresh)} ] ]
}
odbc "DELETE FROM LINEITEM WHERE L_ORDERKEY = $okey"
odbc "DELETE FROM ORDERS WHERE O_ORDERKEY = $okey"
if { $REFRESH_VERBOSE } {
puts "Refresh Delete Orderkey $okey..."
	}
if { ![ expr {$i % 1000} ] } {     
odbc commit
        update
   }
}
odbc commit
update
}

proc do_refresh { server port scale_factor odbc_driver authentication uid pwd database update_sets trickle_refresh REFRESH_VERBOSE RF_SET } {
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
} else {
database connect odbc $connection
odbc "use $database"
odbc set autocommit off
}
set upd_num 1
for { set set_counter 1 } {$set_counter <= $update_sets } {incr set_counter} {
if {  [ tsv::get application abort ]  } { break }
if { $RF_SET eq "RF1" || $RF_SET eq "BOTH" } {
puts "New Sales refresh"
set r0 [clock clicks -millisec]
mk_order_ref odbc $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
set r1 [clock clicks -millisec]
set rvalnew [expr {double($r1-$r0)/1000}]
puts "New Sales refresh complete in $rvalnew seconds"
        }
if { $RF_SET eq "RF2" || $RF_SET eq "BOTH" } {
puts "Old Sales refresh"
set r3 [clock clicks -millisec]
del_order_ref odbc $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
set r4 [clock clicks -millisec]
set rvalold [expr {double($r4-$r3)/1000}]
puts "Old Sales refresh complete in $rvalold seconds"
        }
if { $RF_SET eq "BOTH" } {
set rvaltot [expr {double($r4-$r0)/1000}]
puts "Completed update set(s) $set_counter in $rvaltot seconds"
        }
incr upd_num
        }
puts "Completed $update_sets update set(s)"
odbc commit
odbc disconnect
}
#########################
#TPCH QUERY GENERATION
proc set_query { maxdop myposition } {
global sql
set sql(1) "select l_returnflag, l_linestatus, sum(cast(l_quantity as bigint)) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(l_quantity) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count(*) as count_order from lineitem where l_shipdate <= dateadd(dd,-:1,cast('1998-12-01'as datetime)) group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus option (maxdop $maxdop)"
set sql(2) "select top 100 s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from part, supplier, partsupp, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from partsupp, supplier, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey option (maxdop $maxdop)"
set sql(3) "select top 10 l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from customer, orders, lineitem where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < ':2' and l_shipdate > ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate option (maxdop $maxdop)"
set sql(4) "select o_orderpriority, count(*) as order_count from orders where o_orderdate >= ':1' and o_orderdate < dateadd(mm,3,cast(':1'as datetime)) and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority option (maxdop $maxdop)"
set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from customer, orders, lineitem, supplier, nation, region where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= ':2' and o_orderdate < dateadd(yy,1,cast(':2'as datetime)) group by n_name order by revenue desc option (maxdop $maxdop)"
set sql(6) "select sum(l_extendedprice * l_discount) as revenue from lineitem where l_shipdate >= ':1' and l_shipdate < dateadd(yy,1,cast(':1'as datetime)) and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3 option (maxdop $maxdop)"
set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, datepart(yy,l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from supplier, lineitem, orders, customer, nation n1, nation n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between '1995-01-01' and '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year option (maxdop $maxdop)"
set sql(8) "select o_year, sum(case when nation = ':1' then volume else 0 end) / sum(volume) as mkt_share from (select datepart(yy,o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as nation from part, supplier, lineitem, orders, customer, nation n1, nation n2, region where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between '1995-01-01' and '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year option (maxdop $maxdop)"
set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, datepart(yy,o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from part, supplier, lineitem, partsupp, orders, nation where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc option (maxdop $maxdop)"
set sql(10) "select top 20 c_custkey, c_name, sum(l_extendedprice * (1 - l_discount)) as revenue, c_acctbal, n_name, c_address, c_phone, c_comment from customer, orders, lineitem, nation where c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate >= ':1' and o_orderdate < dateadd(mm,3,cast(':1'as datetime)) and l_returnflag = 'R' and c_nationkey = n_nationkey group by c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment order by revenue desc option (maxdop $maxdop)"
set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc option (maxdop $maxdop)"
set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from orders, lineitem where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= ':3' and l_receiptdate < dateadd(mm,1,cast(':3' as datetime)) group by l_shipmode order by l_shipmode option (maxdop $maxdop)"
set sql(13) "select c_count, count(*) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc option (maxdop $maxdop)"
set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from lineitem, part where l_partkey = p_partkey and l_shipdate >= ':1' and l_shipdate < dateadd(mm,1,':1') option (maxdop $maxdop)"
set sql(15) "create view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from lineitem where l_shipdate >= ':1' and l_shipdate < dateadd(mm,3,cast(':1' as datetime)) group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from supplier, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey option (maxdop $maxdop); drop view revenue$myposition"
set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from partsupp, part where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from supplier where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size option (maxdop $maxdop)"
set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey) option (maxdop $maxdop)"
set sql(18) "select top 100 c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from customer, orders, lineitem where o_orderkey in ( select l_orderkey from lineitem group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate option (maxdop $maxdop)"
set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from lineitem, part where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') option (maxdop $maxdop)"
set sql(20) "select s_name, s_address from supplier, nation where s_suppkey in ( select ps_suppkey from partsupp where ps_partkey in ( select p_partkey from part where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from lineitem where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= ':2' and l_shipdate < dateadd(yy,1,':2'))) and s_nationkey = n_nationkey and n_name = ':3' order by s_name option (maxdop $maxdop)"
set sql(21) "select top 100 s_name, count(*) as numwait from supplier, lineitem l1, orders, nation where s_suppkey = l1.l_suppkey and o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and exists ( select * from lineitem l2 where l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey) and not exists ( select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) and s_nationkey = n_nationkey and n_name = ':1' group by s_name order by numwait desc, s_name option (maxdop $maxdop)"
set sql(22) "select cntrycode, count(*) as numcust, sum(c_acctbal) as totacctbal from ( select substring(c_phone, 1, 2) as cntrycode, c_acctbal from customer where substring(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select avg(c_acctbal) from customer where c_acctbal > 0.00 and substring(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from orders where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode option (maxdop $maxdop)"
}

proc get_query { query_no maxdop myposition } {
global sql
if { ![ array exists sql ] } { set_query $maxdop $myposition }
return $sql($query_no)
}

proc sub_query { query_no scale_factor maxdop myposition } {
set P_SIZE_MIN 1
set P_SIZE_MAX 50
set MAX_PARAM 10
set q2sub [get_query $query_no $maxdop $myposition ]
switch $query_no {
1 {
regsub -all {:1} $q2sub [RandomNumber 60 120] q2sub
  }
2 {
regsub -all {:1} $q2sub [RandomNumber $P_SIZE_MIN $P_SIZE_MAX] q2sub
set qc [ lindex [ split [ pick_str [ get_dists p_types ] p_types ] ] 2 ]
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str [ get_dists regions ] regions ]
regsub -all {:3} $q2sub $qc q2sub
  }
3 {
set qc [ pick_str [ get_dists msegmnt ] msegmnt ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 1 31]
if { [ string length $tmp_date ] eq 1 } {set tmp_date [ concat 0$tmp_date ]  }
regsub -all {:2} $q2sub [concat 1995-03-$tmp_date] q2sub
  }
4 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
  }
5 {
set qc [ pick_str [ get_dists regions ] regions ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
  }
6 {
set tmp_date [RandomNumber 93 97]
regsub -all {:1} $q2sub [concat 19$tmp_date-01-01] q2sub
regsub -all {:2} $q2sub [concat 0.0[RandomNumber 2 9]] q2sub
regsub -all {:3} $q2sub [RandomNumber 24 25] q2sub
  }
7 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str [ get_dists nations2 ] nations2 ] }
regsub -all {:2} $q2sub $qc2 q2sub
  }
8 {
set nationlist [ get_dists nations2 ]
set regionlist [ get_dists regions ]
set qc [ pick_str $nationlist nations2 ] 
regsub -all {:1} $q2sub $qc q2sub
set nind [ lsearch -glob $nationlist [concat \*$qc\*] ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set qc "AFRICA" }
1 - 2 - 3 - 17 - 24 { set qc "AMERICA" }
8 - 9 - 12 - 18 - 21 { set qc "ASIA" }
6 - 7 - 19 - 22 - 23 { set qc "EUROPE"}
10 - 11 - 13 - 20 { set qc "MIDDLE EAST"}
}
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str [ get_dists p_types ] p_types ]
regsub -all {:3} $q2sub $qc q2sub
  }
9 {
set qc [ pick_str [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
  }
10 {
set tmp_date [RandomNumber 1 24]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
   }
11 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set q11_fract [ format %11.10f [ expr 0.0001 / $scale_factor ] ]
regsub -all {:2} $q2sub $q11_fract q2sub
}
12 {
set qc [ pick_str [ get_dists smode ] smode ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str [ get_dists smode ] smode ] }
regsub -all {:2} $q2sub $qc2 q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:3} $q2sub [concat 19$tmp_date-01-01] q2sub
}
13 {
set qc [ pick_str [ get_dists Q13a ] Q13a ]
regsub -all {:1} $q2sub $qc q2sub
set qc [ pick_str [ get_dists Q13b ] Q13b ]
regsub -all {:2} $q2sub $qc q2sub
}
14 {
set tmp_date [RandomNumber 1 60]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
15 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
16 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set p_type [ split [ pick_str [ get_dists p_types ] p_types ] ]
set qc [ concat [ lindex $p_type 0 ] [ lindex $p_type 1 ] ]
regsub -all {:2} $q2sub $qc q2sub
set permute [list]
for {set i 3} {$i <= $MAX_PARAM} {incr i} {
set tmp3 [RandomNumber 1 50] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 1 50] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
   }
17 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set qc [ pick_str [ get_dists p_cntr ] p_cntr ]
regsub -all {:2} $q2sub $qc q2sub
 }
18 {
regsub -all {:1} $q2sub [RandomNumber 312 315] q2sub
}
19 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:2} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:3} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
regsub -all {:4} $q2sub [RandomNumber 1 10] q2sub
regsub -all {:5} $q2sub [RandomNumber 10 20] q2sub
regsub -all {:6} $q2sub [RandomNumber 20 30] q2sub
}
20 {
set qc [ pick_str [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:3} $q2sub $qc q2sub
	}
21 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
}
22 {
set permute [list]
for {set i 0} {$i <= 7} {incr i} {
set tmp3 [RandomNumber 10 34] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 10 34] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
    }
}
return $q2sub
}

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
#########################
#TPCH QUERY SETS PROCEDURE
proc do_tpch { server port scale_factor odbc_driver authentication uid pwd db RAISEERROR VERBOSE maxdop total_querysets myposition } {
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
} else {
database connect odbc $connection
odbc "use $db"
odbc set autocommit off
}
for {set it 0} {$it < $total_querysets} {incr it} {
if {  [ tsv::get application abort ]  } { break }
set start [ clock seconds ]
for { set q 1 } { $q <= 22 } { incr q } {
set dssquery($q)  [sub_query $q $scale_factor $maxdop $myposition ]
if {$q != 15} {
	;
} else {
set query15list [split $dssquery($q) "\;"]
            set q15length [llength $query15list]
            set q15c 0
            while {$q15c <= [expr $q15length - 1]} {
            set dssquery($q,$q15c) [lindex $query15list $q15c]
            incr q15c
		}
	}
}
set o_s_list [ ordered_set $myposition ]
for { set q 1 } { $q <= 22 } { incr q } {
if {  [ tsv::get application abort ]  } { break }
set qos [ lindex $o_s_list [ expr $q - 1 ] ]
puts "Executing Query $qos ($q of 22)"
if {$VERBOSE} { puts $dssquery($qos) }
if {$qos != 15} {
set t0 [clock clicks -millisec]
set oput [ standsql odbc $dssquery($qos) $RAISEERROR ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
puts "query $qos completed in $value seconds"
	      } else {
            set q15c 0
            while {$q15c <= [expr $q15length - 1] } {
	if { $q15c != 1 } {
if {[ catch {set sql_output [odbc $dssquery($qos,$q15c)]} message]} {
if { $RAISEERROR } {
error "Query Error :$message"
	} else {
puts "$message"
		}
	  }
	} else {
set t0 [clock clicks -millisec]
set oput [ standsql odbc $dssquery($qos,$q15c) $RAISEERROR ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
puts "query $qos completed in $value seconds"
		}
            incr q15c
		}
        }
  }
set end [ clock seconds ]
set wall [ expr $end - $start ]
set qsets [ expr $it + 1 ]
puts "Completed $qsets query set(s) in $wall seconds"
	}
odbc commit
odbc disconnect
 }
#########################
#RUN TPC-H
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set power_test "false"
if { $totalvirtualusers eq 1 } {
#Power Test
set power_test "true"
set myposition 0
        } else {
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
        }
if { $refresh_on } {
if { $power_test } {
set trickle_refresh 0
set update_sets 1
set REFRESH_VERBOSE "false"
do_refresh $server $port $scale_factor $odbc_driver $authentication $uid $pwd $database $update_sets $trickle_refresh $REFRESH_VERBOSE RF1
do_tpch $server $port $scale_factor $odbc_driver $authentication $uid $pwd $database $RAISEERROR $VERBOSE $maxdop $total_querysets 0
do_refresh $server $port $scale_factor $odbc_driver $authentication $uid $pwd $database $update_sets $trickle_refresh $REFRESH_VERBOSE RF2
        } else {
switch $myposition {
1 {
do_refresh $server $port $scale_factor $odbc_driver $authentication $uid $pwd $database $update_sets $trickle_refresh $REFRESH_VERBOSE BOTH
        }
default {
do_tpch $server $port $scale_factor $odbc_driver $authentication $uid $pwd $database $RAISEERROR $VERBOSE $maxdop $total_querysets [ expr $myposition - 1 ]
        }
    }
 }
} else {
do_tpch $server $port $scale_factor $odbc_driver $authentication $uid $pwd $database $RAISEERROR $VERBOSE $maxdop $total_querysets $myposition
		}
	}
}

proc loadpgtpch {} {
global pg_host pg_port pg_scale_fact pg_tpch_user pg_tpch_pass pg_tpch_dbase pg_total_querysets pg_raise_query_error pg_verbose pg_refresh_on pg_update_sets pg_trickle_refresh pg_refresh_verbose _ED
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_scale_fact ] } { set pg_scale_fact "1" }
if {  ![ info exists pg_tpch_superuser ] } { set pg_tpch_superuser "postgres" }
if {  ![ info exists pg_tpch_superuserpass ] } { set pg_tpch_superuserpass "postgres" }
if {  ![ info exists pg_tpch_defaultdbase ] } { set pg_tpch_defaultdbase "postgres" }
if {  ![ info exists pg_tpch_user ] } { set pg_tpch_user "tpch" }
if {  ![ info exists pg_tpch_pass ] } { set pg_tpch_pass "tpch" }
if {  ![ info exists pg_tpch_dbase ] } { set pg_tpch_dbase "tpch" }
if {  ![ info exists pg_tpch_gpcompat ] } { set pg_tpch_gpcompat "false" }
if {  ![ info exists pg_num_tpch_threads ] } { set pg_num_tpch_threads "1" }
if {  ![ info exists pg_refresh_on ] } { set  pg_refresh_on "false" }
if {  ![ info exists pg_total_querysets ] } { set pg_total_querysets "1" }
if {  ![ info exists pg_raise_query_error ] } { set pg_raise_query_error "false" }
if {  ![ info exists pg_verbose ] } { set pg_verbose "false" }
if {  ![ info exists pg_update_sets ] } { set pg_update_sets "1" }
if {  ![ info exists pg_trickle_refresh ] } { set pg_trickle_refresh "1000" }
if {  ![ info exists pg_refresh_verbose ] } { set pg_refresh_verbose "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "PostgreSQL TPC-H"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Pgtcl} \] { error \"Failed to load Pgtcl - Postgres Library Error\" }
#EDITABLE OPTIONS##################################################
set total_querysets $pg_total_querysets ;# Number of query sets before logging off
set RAISEERROR \"$pg_raise_query_error\" ;# Exit script on PostgreSQL query error (true or false)
set VERBOSE \"$pg_verbose\" ;# Show query text and output
set scale_factor $pg_scale_fact ;#Scale factor of the tpc-h schema
set host \"$pg_host\" ;# Address of the server hosting PostgreSQL
set port \"$pg_port\" ;# Port of the PostgreSQL Server
set user \"$pg_tpch_user\" ;# PostgreSQL user
set password \"$pg_tpch_pass\" ;# Password for the PostgreSQL user
set db \"$pg_tpch_dbase\" ;# Database containing the TPC Schema
set refresh_on \"$pg_refresh_on\" ;#First User does refresh function
set update_sets $pg_update_sets ;#Number of sets of refresh function to complete
set trickle_refresh $pg_trickle_refresh ;#time delay (ms) to trickle refresh function
set REFRESH_VERBOSE \"$pg_refresh_verbose\" ;#report refresh function activity
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 18.0 ]
.ed_mainFrame.mainwin.textFrame.left.text insert $act { proc standsql { lda sql RAISEERROR VERBOSE } {
if {[catch { pg_select $lda $sql var { if { $VERBOSE } { 
foreach index [array names var] { if { $index > 2} {puts $var($index)} } } } } message]} {
if { $RAISEERROR } {
error "Query Error : $message"
	} else {
puts "Query Failed : $sql : $message"
	}
      } 
}

proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]}]} {
puts stderr "Error, the database connection to $host could not be established"
set lda "Failed"
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

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

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

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

proc pick_str { dists name } {
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

proc txt_vp {} {
set verb_list [ split [ pick_str [ get_dists vp ] vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str [ get_dists np ] np ] ]
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
append verb_p [ pick_str [ get_dists $src ] $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str [ get_dists grammar ] grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str [ get_dists prepositions ] prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str [ get_dists terminators ] terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
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

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}
#########################
#TPCH REFRESH PROCEDURE
proc mk_order_ref { lda upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
proc date_function {} {
set df "to_timestamp"
return $df
	}
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str [ get_dists o_oprio ] o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
if { $REFRESH_VERBOSE } {
puts "Refresh Insert Orderkey $okey..."
	}
set result [ pg_exec $lda "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES ([ date_function ]('$date','YYYY-Mon-DD'), '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str [ get_dists instruct ] instruct ] 
set lsmode [ pick_str [ get_dists smode ] smode ] 
set lcomment [ TEXT 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str [ get_dists rflag ] rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
set result [ pg_exec $lda "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES ([ date_function ]('$lsdate','YYYY-Mon-DD'),'$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', [ date_function ]('$lcdate','YYYY-Mon-DD'), [ date_function ]('$lrdate','YYYY-Mon-DD'), '$lsmode', '$llcnt', '$linstruct', '$lcomment')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
  }
if { ![ expr {$i % 1000} ] } {     
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear	
   }
}
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
}

proc del_order_ref { lda upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.28.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#DELETE FROM ORDERS WHERE O_ORDERKEY = [value]
#DELETE FROM LINEITEM WHERE L_ORDERKEY = [value]
#END LOOP
set refresh 100
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {$upd_num / (10000 / $refresh)} ] ]
}
set result [ pg_exec $lda "DELETE FROM LINEITEM WHERE L_ORDERKEY = $okey" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
set result [ pg_exec $lda "DELETE FROM ORDERS WHERE O_ORDERKEY = $okey" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if { $REFRESH_VERBOSE } {
puts "Refresh Delete Orderkey $okey..."
	}
if { ![ expr {$i % 1000} ] } {     
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
   }
}
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
}

proc do_refresh { host port db user password scale_factor update_sets trickle_refresh REFRESH_VERBOSE RF_SET } {
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 	}
set upd_num 1
for { set set_counter 1 } {$set_counter <= $update_sets } {incr set_counter} {
if {  [ tsv::get application abort ]  } { break }
if { $RF_SET eq "RF1" || $RF_SET eq "BOTH" } {
puts "New Sales refresh"
set r0 [clock clicks -millisec]
mk_order_ref $lda $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE 
set r1 [clock clicks -millisec]
set rvalnew [expr {double($r1-$r0)/1000}]
puts "New Sales refresh complete in $rvalnew seconds"
	}
if { $RF_SET eq "RF2" || $RF_SET eq "BOTH" } {
puts "Old Sales refresh"
set r3 [clock clicks -millisec]
del_order_ref $lda $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE 
set r4 [clock clicks -millisec]
set rvalold [expr {double($r4-$r3)/1000}]
puts "Old Sales refresh complete in $rvalold seconds"
	}
if { $RF_SET eq "BOTH" } {
set rvaltot [expr {double($r4-$r0)/1000}]
puts "Completed update set(s) $set_counter in $rvaltot seconds"
	}
incr upd_num
	}
puts "Completed $update_sets update set(s)"
pg_disconnect $lda
}
#########################
#TPCH QUERY GENERATION
proc set_query { myposition } {
global sql
set sql(1) "select l_returnflag, l_linestatus, sum(l_quantity) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(l_quantity) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count(*) as count_order from lineitem where l_shipdate <= date '1998-12-01' - interval ':1 day' group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus"
set sql(2) "select s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from part, supplier, partsupp, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from partsupp, supplier, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey"
set sql(3) "select l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from customer, orders, lineitem where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < date ':2' and l_shipdate > date ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate"
set sql(4) "select o_orderpriority, count(*) as order_count from orders where o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3 month' and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority"
set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from customer, orders, lineitem, supplier, nation, region where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= date ':2' and o_orderdate < date ':2' + interval '1 year' group by n_name order by revenue desc"
set sql(6) "select sum(l_extendedprice * l_discount) as revenue from lineitem where l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1 year' and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3"
set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, extract(year from l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from supplier, lineitem, orders, customer, nation n1, nation n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between date '1995-01-01' and date '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year"
set sql(8) "select o_year, sum(case when nation = ':1' then volume else 0 end) / sum(volume) as mkt_share from ( select extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as nation from part, supplier, lineitem, orders, customer, nation n1, nation n2, region where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between date '1995-01-01' and date '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year"
set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from part, supplier, lineitem, partsupp, orders, nation where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc"
set sql(10) "select c_custkey, c_name, sum(l_extendedprice * (1 - l_discount)) as revenue, c_acctbal, n_name, c_address, c_phone, c_comment from customer, orders, lineitem, nation where c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3 month' and l_returnflag = 'R' and c_nationkey = n_nationkey group by c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment order by revenue desc"
set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc"
set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from orders, lineitem where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= date ':3' and l_receiptdate < date ':3' + interval '1 year' group by l_shipmode order by l_shipmode"
set sql(13) "select c_count, count(*) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc"
set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from lineitem, part where l_partkey = p_partkey and l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1 month'"
set sql(15) "create or replace view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from lineitem where l_shipdate >= to_date( ':1', 'YYYY-MM-DD') and l_shipdate < (to_date (':1', 'YYYY-MM-DD') + interval '3 month') group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from supplier, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey; drop view revenue$myposition"
set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from partsupp, part where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from supplier where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size"
set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey)"
set sql(18) "select c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from customer, orders, lineitem where o_orderkey in ( select l_orderkey from lineitem group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate"
set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from lineitem, part where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON')"
set sql(20) "select s_name, s_address from supplier, nation where s_suppkey in ( select ps_suppkey from partsupp where ps_partkey in ( select p_partkey from part where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from lineitem where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= date ':2' and l_shipdate < date ':2' + interval '1 year')) and s_nationkey = n_nationkey and n_name = ':3' order by s_name"
set sql(21) "select s_name, count(*) as numwait from supplier, lineitem l1, orders, nation where s_suppkey = l1.l_suppkey and o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and exists ( select * from lineitem l2 where l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey) and not exists ( select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) and s_nationkey = n_nationkey and n_name = ':1' group by s_name order by numwait desc, s_name"
set sql(22) "select cntrycode, count(*) as numcust, sum(c_acctbal) as totacctbal from ( select substr(c_phone, 1, 2) as cntrycode, c_acctbal from customer where substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select avg(c_acctbal) from customer where c_acctbal > 0.00 and substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from orders where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode"
}

proc get_query { query_no myposition } {
global sql
if { ![ array exists sql ] } { set_query $myposition }
return $sql($query_no)
}

proc sub_query { query_no scale_factor myposition } {
set P_SIZE_MIN 1
set P_SIZE_MAX 50
set MAX_PARAM 10
set q2sub [get_query $query_no $myposition ]
switch $query_no {
1 {
regsub -all {:1} $q2sub [RandomNumber 60 120] q2sub
  }
2 {
regsub -all {:1} $q2sub [RandomNumber $P_SIZE_MIN $P_SIZE_MAX] q2sub
set qc [ lindex [ split [ pick_str [ get_dists p_types ] p_types ] ] 2 ]
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str [ get_dists regions ] regions ]
regsub -all {:3} $q2sub $qc q2sub
  }
3 {
set qc [ pick_str [ get_dists msegmnt ] msegmnt ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 1 31]
if { [ string length $tmp_date ] eq 1 } {set tmp_date [ concat 0$tmp_date ]  }
regsub -all {:2} $q2sub [concat 1995-03-$tmp_date] q2sub
  }
4 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
  }
5 {
set qc [ pick_str [ get_dists regions ] regions ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
  }
6 {
set tmp_date [RandomNumber 93 97]
regsub -all {:1} $q2sub [concat 19$tmp_date-01-01] q2sub
regsub -all {:2} $q2sub [concat 0.0[RandomNumber 2 9]] q2sub
regsub -all {:3} $q2sub [RandomNumber 24 25] q2sub
  }
7 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str [ get_dists nations2 ] nations2 ] }
regsub -all {:2} $q2sub $qc2 q2sub
  }
8 {
set nationlist [ get_dists nations2 ]
set regionlist [ get_dists regions ]
set qc [ pick_str $nationlist nations2 ] 
regsub -all {:1} $q2sub $qc q2sub
set nind [ lsearch -glob $nationlist [concat \*$qc\*] ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set qc "AFRICA" }
1 - 2 - 3 - 17 - 24 { set qc "AMERICA" }
8 - 9 - 12 - 18 - 21 { set qc "ASIA" }
6 - 7 - 19 - 22 - 23 { set qc "EUROPE"}
10 - 11 - 13 - 20 { set qc "MIDDLE EAST"}
}
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str [ get_dists p_types ] p_types ]
regsub -all {:3} $q2sub $qc q2sub
  }
9 {
set qc [ pick_str [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
  }
10 {
set tmp_date [RandomNumber 1 24]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
   }
11 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set q11_fract [ format %11.10f [ expr 0.0001 / $scale_factor ] ]
regsub -all {:2} $q2sub $q11_fract q2sub
}
12 {
set qc [ pick_str [ get_dists smode ] smode ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str [ get_dists smode ] smode ] }
regsub -all {:2} $q2sub $qc2 q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:3} $q2sub [concat 19$tmp_date-01-01] q2sub
}
13 {
set qc [ pick_str [ get_dists Q13a ] Q13a ]
regsub -all {:1} $q2sub $qc q2sub
set qc [ pick_str [ get_dists Q13b ] Q13b ]
regsub -all {:2} $q2sub $qc q2sub
}
14 {
set tmp_date [RandomNumber 1 60]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
15 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
16 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set p_type [ split [ pick_str [ get_dists p_types ] p_types ] ]
set qc [ concat [ lindex $p_type 0 ] [ lindex $p_type 1 ] ]
regsub -all {:2} $q2sub $qc q2sub
set permute [list]
for {set i 3} {$i <= $MAX_PARAM} {incr i} {
set tmp3 [RandomNumber 1 50] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 1 50] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
   }
17 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set qc [ pick_str [ get_dists p_cntr ] p_cntr ]
regsub -all {:2} $q2sub $qc q2sub
 }
18 {
regsub -all {:1} $q2sub [RandomNumber 312 315] q2sub
}
19 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:2} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:3} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
regsub -all {:4} $q2sub [RandomNumber 1 10] q2sub
regsub -all {:5} $q2sub [RandomNumber 10 20] q2sub
regsub -all {:6} $q2sub [RandomNumber 20 30] q2sub
}
20 {
set qc [ pick_str [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:3} $q2sub $qc q2sub
	}
21 {
set qc [ pick_str [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
}
22 {
set permute [list]
for {set i 0} {$i <= 7} {incr i} {
set tmp3 [RandomNumber 10 34] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 10 34] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
    }
}
return $q2sub
}

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
#########################
#TPCH QUERY SETS PROCEDURE
proc do_tpch { host port db user password scale_factor RAISEERROR VERBOSE total_querysets myposition } {
#Queries 17 and 20 are long running on PostgreSQL
set SKIP_QUERY_17_20 "false" 
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 	}
for {set it 0} {$it < $total_querysets} {incr it} {
if {  [ tsv::get application abort ]  } { break }
set start [ clock seconds ]
for { set q 1 } { $q <= 22 } { incr q } {
set dssquery($q)  [sub_query $q $scale_factor $myposition ]
if {$q != 15} {
	;
} else {
set query15list [split $dssquery($q) "\;"]
            set q15length [llength $query15list]
            set q15c 0
            while {$q15c <= [expr $q15length - 1]} {
            set dssquery($q,$q15c) [lindex $query15list $q15c]
            incr q15c
		}
	}
}
set o_s_list [ ordered_set $myposition ]
for { set q 1 } { $q <= 22 } { incr q } {
if {  [ tsv::get application abort ]  } { break }
set qos [ lindex $o_s_list [ expr $q - 1 ] ]
puts "Executing Query $qos ($q of 22)"
if {$VERBOSE} { puts $dssquery($qos) }
if {$qos != 15} {
if {(($qos eq 17) || ($qos eq 20))  && $SKIP_QUERY_17_20 eq "true" } { 
puts "Long Running Queries 17 and 20 Not Executed"
	} else {
set t0 [clock clicks -millisec]
standsql $lda $dssquery($qos) $RAISEERROR $VERBOSE
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
puts "query $qos completed in $value seconds"
		}
	      } else {
            set q15c 0
            while {$q15c <= [expr $q15length - 1] } {
	if { $q15c != 1 } {
set result [ pg_exec $lda "$dssquery($qos,$q15c)" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Query 15 view error set RAISEERROR for Details"
		}  
	} else {
pg_result $result -clear
	}
	} else {
set t0 [clock clicks -millisec]
if {[catch { pg_select $lda $dssquery($qos,$q15c) var { if { $VERBOSE } { 
foreach index [array names var] { if { $index > 2} {puts $var($index)} } } } } message]} {
if { $RAISEERROR } {
error "Query Error : $message"
	} else {
puts "Query Failed : $dssquery($qos,$q15c) : $message"
	}
      } 
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
puts "query $qos completed in $value seconds"
		}
            incr q15c
		}
        }
  }
set end [ clock seconds ]
set wall [ expr $end - $start ]
set qsets [ expr $it + 1 ]
puts "Completed $qsets query set(s) in $wall seconds"
	}
pg_disconnect $lda
 }
#########################
#RUN TPC-H
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set power_test "false"
if { $totalvirtualusers eq 1 } {
#Power Test
set power_test "true"
set myposition 0
	} else {
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
	}
if { $refresh_on } {
if { $power_test } {
set trickle_refresh 0
set update_sets 1
set REFRESH_VERBOSE "false"
do_refresh $host $port $db $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF1
do_tpch $host $port $db $user $password $scale_factor $RAISEERROR $VERBOSE $total_querysets 0
do_refresh $host $port $db $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF2
	} else {
switch $myposition {
1 { 
do_refresh $host $port $db $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE BOTH
	}
default { 
do_tpch $host $port $db $user $password $scale_factor $RAISEERROR $VERBOSE $total_querysets [ expr $myposition - 1 ] 
	}
    }
 }
} else {
do_tpch $host $port $db $user $password $scale_factor $RAISEERROR $VERBOSE $total_querysets $myposition 
	}
   }
}
