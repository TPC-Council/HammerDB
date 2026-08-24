#########################################################################
# HammerDB
# Copyright (C) HammerDB Ltd
# Hosted by the TPC-Council
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#########################################################################
#
# quackci.tcl - Continuous-Integration hooks for the Quack (sqlxtc)
# database.
#
# The other drivers' CI procs (clone / build / package / test the target
# database server from source) manage a full DBMS installation.  sqlxtc
# is not a managed server product - it is the libxtc 06_sqlxtc example
# binary - so the clone/build/package lifecycle does not apply.  These
# stubs keep the CI dispatcher happy and report that Quack CI is limited
# to the schema-build + driver run exercised directly by HammerDB.
#

proc quack_ci_id {cidict refname} {
    if { [dict exists $cidict quack] } { return "quack" }
    return ""
}

proc quack_ci_safe_ref {refname} { return $refname }

proc quack_get_io_intensive {ci_id} { return 0 }

proc quack_clone {cidict refname} {
    puts "Quack CI: sqlxtc is the libxtc 06_sqlxtc example; build it from the libxtc tree, not via HammerDB CI."
    return 0
}

proc quack_build {cidict refname} {
    puts "Quack CI: no server build step (sqlxtc is an example binary)."
    return 0
}

proc quack_package {cidict refname} {
    puts "Quack CI: no packaging step for sqlxtc."
    return 0
}

proc quack_commit_msg {cidict refname} { return "quack ci" }
