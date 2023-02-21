 proc stdout { switch { file "" } } {
     if { ! [ llength [ info command __puts ] ] && \
            [ string equal off $switch ] } {
        rename puts __puts
        if { [ string length $file ] } {
           eval [ subst -nocommands {proc puts { args } {
              set fid [ open [ file normalize $file ] a+ ]
              if { [ llength \$args ] > 1 && \
                   [ lsearch \$args stdout ] == 0 } {
                 set args [ lreplace \$args 0 0 \$fid ]
              } elseif {  [ llength \$args ] == 1 } {
                 set args [ list \$fid \$args ]
              }
              if { [ catch {
                 eval __puts [ join \$args ]
              } err ] } {
                 close \$fid
                 return -code error \$err
              }
              close \$fid
           }} ]
        } else {
           eval [ subst -nocommands {proc puts { args } {
              if { [ llength \$args ] > 1 && \
                   [ lsearch \$args stdout ] == 0 || \
                   [ llength \$args ] == 1 } {
                 # no-op
              } else {
                 eval __puts [ join \$args ]
              }
           }} ]   
        }
     } elseif { [ llength [ info command __puts ] ] && \
                [ string equal on $switch ] } {
        rename puts {}
        rename __puts puts
     }
 }

proc getjobid {filename} {
set fd [ open $filename r ]
set jobid [ lindex [ split [ gets $fd ] = ] 1 ]
close $fd
return $jobid
}

proc getoutput {filename} {
set fd [ open $filename r ]
set output [ read $fd ]
close $fd
return $output
}
set filename $::outputfile
set jobid [ getjobid $filename ]
set filename [ file normalize "${filename}_${jobid}.out"  ]
stdout off $filename
puts "TRANSACTION RESPONSE TIMES"
job $jobid timing
puts "TRANSACTION COUNT"
job $jobid tcount
puts "HAMMERDB RESULT"
job $jobid result
stdout on
set output [ getoutput $filename ]
puts $output
