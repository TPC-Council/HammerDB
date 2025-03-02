#!/usr/bin/tclsh

set dbdict [tsv::get recallconfig dbdict]
set configpostgresql [tsv::get recallconfig configpostgresql]

if {[dict exists $dbdict postgresql library ]} {
    set library [ dict get $dbdict postgresql library ]
} else { set library "Pgtcl" }

if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
if [catch {package require tpccvcommon} ] { error "Failed to load tpccv common functions" } else { namespace import tpccvcommon::* }
if [catch [source ./src/generic/gentpcc.tcl]] {
    puts "Error while loading gentpcc.tcl"
    # TODO - extract and assign db config from $configpostgresql
} else {
    #set variables to values in dict
    setlocaltpccvars $configpostgresql
}


proc ConnectToPostgres { host port sslmode user password dbname } {
    global tcl_platform
    if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port sslmode = $sslmode user = $user password = $password dbname = $dbname ]]} message]} {
        set lda "Failed" ; puts $message
        error $message
    } else {
        pg_notice_handler $lda puts
        set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
        pg_result $result -clear
    }
    return $lda
}

proc calc_recall {embeddings ground_truth k} {
    set matched_embs 0
    foreach emb $embeddings {
        if {[lsearch -exact $ground_truth $emb] != -1} {
            incr matched_embs
        }
    }
    set recall [expr {$matched_embs / double([llength $ground_truth])}]
    return $recall
}

set vector_test_dataset [ load_vector_data "./dataset/vector/test/output.csv" "false" ]
set vector_ground_truth [ load_vector_data "./dataset/vector/ground_truth/output_gt.csv" "false" ]

set k 10
set all_recalls {}

set lda [ ConnectToPostgres $pg_host $pg_port $pg_sslmode $pg_user $pg_pass $pg_dbase ]
if { $lda eq "Failed" } {
    error "error, the database connection to $host could not be established"
}

set result [pg_exec $lda "SET hnsw.ef_search=100"]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
    if { $RAISEERROR } {
        error "[pg_result $result -error]"
    } else {
        puts "Setting HNSW ef_search Query Error set RAISEERROR for Details"
    }
    pg_result $result -clear
}

pg_exec $lda "prepare semantic_search (VECTOR, INTEGER) AS \
 SELECT id FROM public.pg_vector_collection ORDER BY embedding <=> \$1 LIMIT \$2"

puts "CALCULATING RECALL"
puts "lenght: [llength $vector_test_dataset]"
puts "lenght: [llength $vector_ground_truth]"
for {set idx 1} {$idx < [expr [llength $vector_test_dataset] - 1]} {incr idx} {
    set row [lindex $vector_test_dataset $idx]
    set id [lindex $row 0]
    set emb [lindex $row 1]
    
    set result [pg_exec_prepared $lda "semantic_search" {} {} "\[$emb\]" $k]
    if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
        if { $RAISEERROR } {
            error "[pg_result $result -error]"
        } else {
            puts "Vector query failed during recall calculation"
        }
    } else {
        set embeddings [pg_result $result -list]
        set row [lindex $vector_ground_truth $id]
        set n_id [lindex $row 0]
        set gt [lindex $row 1]

        set gt [lrange $gt 0 [expr $k-1]]
        set query_recall [calc_recall $embeddings $gt $k]
        lappend all_recalls $query_recall
    }
    pg_result $result -clear

}
set recall [expr [expr {[tcl::mathop::+ {*}$all_recalls] / double([llength $all_recalls])}] * 100]
puts "Recall Score: $recall%"
puts "RECALL CALCULATION COMPLETE"
