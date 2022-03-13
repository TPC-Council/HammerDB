#
# cleanup.tcl
#
# Finalize the tests.
#
# Copyright (c) 2000 by Todd M. Helfter
# All rights reserved.

if {[catch {set ora_lda [oralogon $ora_constr]}] != 0} {
    puts "can't logon to oracle server"
    exit
} else {
    if {[catch {set ora_cur [oraopen $ora_lda]}] != 0} {
        oralogoff $ora_lda
        puts "can't open cursor for handle  $ora_lda"
        exit
    }
    if {[catch {set ora_cur2 [oraopen $ora_lda]}] != 0} {
        oralogoff $ora_lda
        puts "can't open cursor for handle  $ora_lda"
        exit
    }
    if {[catch {set ora_cur3 [oraopen $ora_lda]}] != 0} {
        oralogoff $ora_lda
        puts "can't open cursor for handle  $ora_lda"
        exit
    }
}

puts "\tUsing login handle   :: $ora_lda"
puts "\tUsing cursor handle  :: $ora_cur"
puts "\tUsing cursor handle  :: $ora_cur2"
puts "\tUsing cursor handle  :: $ora_cur3"
puts {}
flush stdout

proc truncate_table {} {
    global ora_lda ora_cur
    oraparse $ora_cur {truncate table oratcl___tests}
    oraexec $ora_cur
}

proc drop_table {} {
    global ora_lda ora_cur

    set sql1 {drop procedure oratcl___test1}
    set sql2 {drop procedure oratcl___test2}
    set sql3 {drop table oratcl___tests}

    foreach sql [list $sql1 $sql2 $sql3] {
        catch {
	    oraparse $ora_cur $sql
            oraexec $ora_cur
        }
    }

}

set sql {select table_name from user_tables where table_name = 'ORATCL___TESTS'}
oraparse $ora_cur $sql
oraexec $ora_cur
set table_exists 0
set column {}
orafetch $ora_cur -datavariable column
puts $column

if {[string compare $column ORATCL___TESTS] == 0} {
        set table_exists 1
}
unset column

if {$table_exists} {
    puts {oratcl___tests exists,}
    puts -nonewline {  do you want to drop and re-create it (yes/no, default=no)
: }
    flush stdout
    gets stdin res
    if {[string match $res yes]} {
        drop_table
    } else {
        exit
    }
}

unset table_exists

proc create_table {} {
    global ora_lda ora_cur

    set sql {create table oratcl___tests (
                v_number       number(2),
                v_date         date,
                v_char         char(2),
                v_varchar2     varchar2(36))
    }

    set res [catch { 
	oraparse $ora_cur $sql
	oraexec $ora_cur
    } reason]

    if {$res != 0} {
        oraclose $ora_cur
        oralogoff $ora_lda
        puts "can't create table oratcl___tests"
        puts "$reason:\n[oramsg $ora_cur error]"
        exit
    }
}

proc insert_data {} {
        global ora_cur ora_lda

        set sql {alter session set nls_date_format = 'DD-MON-YYYY'}
        oraparse $ora_cur $sql
        oraexec $ora_cur

	set ins_sql { \
		insert into oratcl___tests ( \
			v_number, \
			v_date,  \
			v_char,  \
			v_varchar2 \
		)  values (  \
			:cnt1, \
			:cnt2, \
			:cnt3, \
			:cnt4 \
		) \
	}

	oraparse $ora_cur $ins_sql
        for {set cnt 0} {$cnt < 30} {incr cnt} {
		set clk [clock format [clock seconds] -format {%d-%b-%Y}]
		set str "$cnt 1234567890"
		orabind $ora_cur :cnt1 $cnt :cnt2 $clk :cnt3 $cnt :cnt4 $str
		oraexec $ora_cur
                puts -nonewline "." ; flush stdout
	}
        puts "\ndone.\n" ; flush stdout

}

puts "creating test table oratcl___tests & procedure oratcl___test1"
flush stdout
create_table
insert_data
oracommit $ora_lda
