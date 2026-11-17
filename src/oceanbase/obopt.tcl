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

# Reuse the existing host CPU agent controls. Database metrics use the selected
# OceanBase workload's connection, including tenant routing and TLS settings.
proc metobopts {} {
    global cpu_only
    if {![info exists cpu_only]} {set cpu_only false}
    set ::oceanbase::metrics_cpu_only $cpu_only
    metgenopts
    wm title .metric {OceanBase Metrics Options}
    .metric.f1.h2 configure -text {OceanBase Metrics}
    ttk::label .metric.f1.ash -text {ASH uses the current OceanBase workload connection and credentials.} -wraplength 360
    grid .metric.f1.ash -row 1 -column 0 -columnspan 2 -sticky w -pady 5
    ttk::label .metric.f1.cpu_label -text {CPU Metrics Only :}
    ttk::checkbutton .metric.f1.cpu_only -variable ::oceanbase::metrics_cpu_only -onvalue true -offvalue false
    grid .metric.f1.cpu_label -row 2 -column 0 -sticky e
    grid .metric.f1.cpu_only -row 2 -column 1 -sticky w
    ttk::label .metric.f1.agent_label -text {The agent settings below apply to host CPU metrics.}
    grid .metric.f1.agent_label -row 3 -column 0 -columnspan 2 -sticky w -pady 5
    .metric.b5 configure -command [list ::oceanbase::accept_metrics_options [.metric.b5 cget -command]]
    .metric.f1.e3 configure -command [list ::oceanbase::accept_metrics_options [.metric.f1.e3 cget -command]]
    update idletasks
}

proc oceanbase::accept_metrics_options {agent_command} {
    set ::cpu_only $::oceanbase::metrics_cpu_only
    uplevel #0 $agent_command
}
