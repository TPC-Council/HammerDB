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
# quackolap.tcl - TPROC-H (analytic) schema build and driver for the
# Quack (sqlxtc) database.
#
# TPROC-H is NOT currently offered for Quack.  Almost every TPC-H query
# is a multi-table join with aggregation (SUM / AVG / COUNT ... GROUP
# BY over joined tables), and sqlxtc's native execution engine, while it
# supports single-table aggregation and projection joins, does not yet
# support JOIN combined with an aggregate - it returns
# "unsupported SQL (native engine)" for those.  Several reference
# queries additionally rely on server-side functions sqlxtc lacks
# (pgmedian, pgpercentile_cont, array_agg) and on date/interval
# literals.  Rather than ship a driver that fails partway through the
# query set, Quack advertises TPROC-C only (see config/database.xml).
#
# These procs exist so the driver source set loads cleanly and so the
# limitation is reported clearly if TPROC-H is somehow selected.  When
# sqlxtc gains JOIN-with-aggregation, port the single-table-friendly
# subset of pgolap.tcl here (Q1 and the IN-subquery queries already run;
# see the driver PR for the tested list).
#

proc build_quacktpch {} {
    puts "TPROC-H is not supported for Quack (sqlxtc)."
    puts "sqlxtc's native engine does not support JOIN combined with"
    puts "aggregation, which nearly every TPC-H query requires."
    puts "Use TPROC-C: dbset bm TPROC-C"
    return
}

proc loadquacktpch {} {
    puts "TPROC-H is not supported for Quack (sqlxtc); use TPROC-C."
    return
}

proc loadtimedquacktpch {} { loadquacktpch }
