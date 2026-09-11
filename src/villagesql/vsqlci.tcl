# vsqlci.tcl — VillageSQL CI harness stub.
# The full MySQL CI harness (clone/build/install/test a server) is not provided
# for VillageSQL yet. This stub exists so hammerdbcli's dbsrclist loader (which
# unconditionally sources <prefix>ci.tcl) does not print a load error.
# Add the real ${prefix}_build/_start/... procs here to enable the CI feature.
