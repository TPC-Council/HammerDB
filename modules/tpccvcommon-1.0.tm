package provide tpccvcommon 1.0
namespace eval tpccvcommon {
    namespace export load_vector_data get_distance_op get_vector_query

    proc load_vector_data { path is_ground_truth } {
    #TODO: Make it singleton
    set file [open $path r]
    set file_content [read $file]
    close $file
    set lines [split $file_content "\n"]
    set data {}
    for {set i 0} {$i < [llength $lines]} {incr i} {
        set first_comma_index [string first "," [lindex $lines $i]]
        set id [string range [lindex $lines $i] 0 [expr {$first_comma_index - 1}]]
        set line [string range [lindex $lines $i] [expr {$first_comma_index + 2}] end] ;# +2 to skip comma and space
        # Remove the quotes from id and emb
        set id [string trim $id {"}]
        set line [string trim $line {"}]
        if { $is_ground_truth } {
            set line [string map {"," " "} $line]
        }
        lappend data [list $id $line]
    }
    return $data
    }

    proc get_distance_op { dist_op } {
        set operator <=>
        if { $dist_op eq "cosine" } {
            set operator <=>
        } elseif { $dist_op eq "euclidean" } {
            set operator <->
        } elseif { $dist_op eq "neg_inner_product" } {
            set operator <#>
        } elseif { $dist_op eq "taxicab" } {
            set operator <+>
        } elseif { $dist_op eq "hamming" } {
            set operator <~>
        }
        return $operator
    }

    proc get_vector_query { vector_table_name dist_op vindex bq_params } {
        set dist_op [get_distance_op $dist_op]
        if { $vindex eq "hnsw" || $vindex eq "pgdiskann" } {
            return "PREPARE knn(VECTOR, INT) AS SELECT id FROM $vector_table_name ORDER BY embedding $dist_op \$1 LIMIT \$2;"
        } elseif { $vindex eq "hnsw_bq" } {
            set reranking [ dict get $bq_params reranking ]
            set rerank_dist_op [get_distance_op [ dict get $bq_params rerank_distance ]]
            set dim [ dict get $bq_params dim ]
            set fetch_limit [ dict get $bq_params quantized_fetch_limit ]

            if { $reranking == "true" } {
                set query "SELECT i.id FROM (SELECT id, embedding $dist_op \$1\:\:vector AS distance 
                    FROM $vector_table_name ORDER BY binary_quantize(embedding)\:\:bit($dim) $rerank_dist_op binary_quantize(\$2) LIMIT $fetch_limit ) i 
                    ORDER BY i.distance LIMIT \$3;"
                return "PREPARE knn(VECTOR, VECTOR, INT) AS $query"
            } else {
                set query "SELECT id FROM $vector_table_name ORDER BY binary_quantize(embedding)\:\:bit($dim) $rerank_dist_op binary_quantize(\$1) LIMIT $fetch_limit;"
                return "PREPARE knn(VECTOR, INT) AS $query"
            }
        }
    }
}
