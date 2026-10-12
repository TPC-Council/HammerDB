# OceanBase category entry point. Backend names come from this registry, never
# from a user-supplied Tcl command or file path.
package require oceanbaseconfig
namespace eval oceanbase {
    variable backends [dict create mysql ::oceanbase::mysql]
    proc supported_modes {} {
        variable backends
        return [dict keys $backends]
    }
    proc backend {configuration} {
        variable backends
        # Configurations created before the mode field existed are MySQL tenants.
        set mode mysql
        if {[dict exists $configuration connection ob_compatibility_mode]} {
            set mode [string tolower [dict get $configuration connection ob_compatibility_mode]]
        }
        if {![dict exists $backends $mode]} {
            error "OceanBase tenant mode '$mode' is not implemented; supported modes: [join [supported_modes] {, }]"
        }
        return [dict get $backends $mode]
    }
    proc validate {configuration} {
        set implementation [backend $configuration]
        return [${implementation}::validate $configuration]
    }
    proc dispatch {operation args} {
        global configoceanbase
        if {$operation ni {generate counter options counter_options}} {error "Unknown OceanBase operation: $operation"}
        set implementation [backend $configoceanbase]
        return [${implementation}::$operation {*}$args]
    }
}
source [file join [file dirname [info script]] mysql adapter.tcl]
proc configobtpcc {option} {oceanbase::dispatch options tpcc $option}
proc configobtpch {option} {oceanbase::dispatch options tpch $option}
proc countobopts {bm} {oceanbase::dispatch counter_options $bm}
