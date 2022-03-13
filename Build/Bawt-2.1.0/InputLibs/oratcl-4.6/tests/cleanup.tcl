# 
# cleanup.tcl
#
# Finalize the tests.
#
# Copyright (c) 2017 Todd M. Helfter
# All rights reserved.

puts "\n\ncleaning up oratcl test objects"
puts "\t(dropping table and procedures, deleting test file)"

catch {drop_table}
catch {file delete oratcl.dat}

catch {oraclose $ora_cur}
unset ora_cur
catch {oraclose $ora_cur2}
unset ora_cur2
catch {oraclose $ora_cur3}
unset ora_cur3
catch {oralogoff $ora_lda}
unset ora_lda

# if memory debugging turned on, checkpoint memory usage
#catch {checkmem oratcl.mem}
