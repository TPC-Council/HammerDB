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
# quackmet.tcl - live database-metrics dashboard for the Quack (sqlxtc)
# database.
#
# The rich per-database metrics screen the other drivers provide (Active
# Session History, wait-event analysis, SQL-over-time) is built entirely
# on server-internal catalog / performance views (pg_stat_activity,
# performance_schema, v$ views, etc.).  sqlxtc, being a compact example
# engine, exposes none of these, so a comparable dashboard cannot be
# implemented against it.  The NOPM / TPM transaction-counter graph
# (see quackotc.tcl) is fully functional; only the deep metrics screen
# is unavailable.  This stub keeps the driver loadable and reports that
# clearly rather than failing.
#
namespace eval quackmet {
    namespace export create_metrics_screen quackmetrics

    proc create_metrics_screen { } {
        catch { ed_stop_metrics }
        tk_messageBox -title "Quack Metrics" -icon info -message \
            "Live database metrics are not available for Quack (sqlxtc):\nsqlxtc exposes no server-side performance views.\nUse the Transaction Counter for NOPM/TPM."
        return
    }

    proc quackmetrics { args } {
        return "Quack (sqlxtc) exposes no server-side metrics views; metrics screen unavailable."
    }
}
