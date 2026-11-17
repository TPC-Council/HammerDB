proc build_obtpcc {} {oceanbase::dispatch generate tpcc build}
proc loadobtpcc {} {oceanbase::dispatch generate tpcc test}
proc loadtimedobtpcc {} {oceanbase::dispatch generate tpcc timed}
proc check_obtpcc {} {oceanbase::dispatch generate tpcc check}
proc delete_obtpcc {} {oceanbase::dispatch generate tpcc delete}
