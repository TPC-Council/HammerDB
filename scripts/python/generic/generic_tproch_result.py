redirect_stdout = (r'''proc stdout { switch { file "" } } {
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
 }''')

def getjobid(filename):
    fd = open(filename, "r")
    line = fd.readlines(0)
    a = "".join(line[0])
    L1 = a.split("=")
    job = (L1[1])
    fd.close
    return job

def getoutput(filename):
    with open(filename) as f:
        contents = f.read()
        print(contents)

tclpy.eval(redirect_stdout)
filename=outputfile
jobident = getjobid(filename)
jobid = jobident.strip()
filename = "".join([filename, "_", jobid, ".out"])
filename = filename.replace(os.sep, '/')
cmd = 'stdout off ' + filename 
tclpy.eval(cmd)
tclpy.eval('puts \"\nHAMMERDB RESULT\"')
job(jobid,'1')
tclpy.eval('stdout on')
getoutput(filename)
