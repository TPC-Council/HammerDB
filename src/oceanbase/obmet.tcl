# Reuse the MySQL metrics presentation and lifecycle with OceanBase's native
# ASH provider. No MySQL performance_schema sampler is installed on OceanBase.
if {![namespace exists ::mysqlmet]} {
    source [file join [file dirname [file dirname [info script]]] mysql mysqlmet.tcl]
}
if {[catch {package require oceanbaseash}]} {
    source [file join [file dirname [info script]] .. .. modules oceanbaseash-1.0.tm]
}
namespace eval obmet {
    foreach name [namespace eval ::mysqlmet {namespace export}] {
        namespace export $name
        interp alias {} ::obmet::$name {} ::mysqlmet::$name
    }
    unset -nocomplain name
    namespace export obmetrics ob_post_kill_dbmon_cleanup
    interp alias {} ::obmet::obmetrics {} ::mysqlmet::mysqlmetrics
    interp alias {} ::obmet::ob_post_kill_dbmon_cleanup {} ::oceanbaseash::stop
}
