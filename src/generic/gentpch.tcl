proc setlocaltpchvars { configdict } {
    #set variables to values in dict
    dict for {descriptor attributes} $configdict  {
        if {$descriptor eq "connection" || $descriptor eq "tpch" } {
            foreach { val } [ dict keys $attributes ] {
                uplevel "variable $val"
                upvar 1 $val $val
                if {[dict exists $attributes $val]} {
                    set $val [ dict get $attributes $val ]
    }}}}
}
#if quotemeta doesn't exist from tpcc create it for tpch
if { [llength [info procs quotemeta]] eq 0} {
global quote_passwords
if { $quote_passwords } {
regsub -all -- {[][#$\;{}]} $str {\\\0} str
regsub -all {\\\\} $str "\\" str
        }
   return $str
}
