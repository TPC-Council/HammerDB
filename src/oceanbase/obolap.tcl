proc build_obtpch {} {oceanbase::dispatch generate tpch build}
proc loadobtpch {} {oceanbase::dispatch generate tpch test}
proc loadobcloud {} {oceanbase::dispatch generate tpch cloud}
proc check_obtpch {} {oceanbase::dispatch generate tpch check}
proc delete_obtpch {} {oceanbase::dispatch generate tpch delete}
