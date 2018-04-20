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
