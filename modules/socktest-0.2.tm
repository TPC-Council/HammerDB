#Manual socket test as comm hangs if wrong host/port
package provide socktest 0.2
namespace eval socktest {
   namespace export socktest sockmesg localsockfree

   variable resulttext
   array set resulttext {
      -2 SocketError
      -1 NameError
       0 Timeout
       1 OK
       9 Undefined
   }

   # test if port 'sock' at adress 'host' is responding within timeout
   # note: socket -async requires a running eventloop
   proc socktest {host sock {timeout 1000}} {
        if {$timeout == 0} {
           # return codes compatible
           if {[catch {socket $host $sock} s]} {
              return -2
           } else {
              catch {close $s}
              return 1
           }
        }
        if {[catch {socket -async $host $sock} s]} {
           return -1
        }
        variable done$sock 9; # allow parallel instances
        # if socket becomes writable, test further
        fileevent $s writable [list namespace eval socktest "sockvrfy $s done$sock"]
        # prepare for cancellation after user supplied timeout
        set aid [after $timeout namespace eval socktest "set done$sock 0"]
        # waiting for timeout or other result
        vwait [namespace current]::done$sock
        catch {close $s}
        after cancel $aid; # catch not neccessary
        set ret [set done$sock]
        unset done$sock; # save mem
        return $ret
   }

   proc sockvrfy {sock flag} {
        upvar $flag done
set done -2
        if {[string length [fconfigure $sock -error]] == 0} {
           set done  1
        } else {
           set done -2
        }
   }

   proc sockmesg {rc} {
        variable resulttext
        catch {set resulttext($rc)} ret
        return $ret
   }

   # test if port 'sock' at localhost is available or already in use
   proc localsockfree {sock} {
        if {[catch {socket -server {} $sock} rc]} {
           return 0
        } else {
           # server could be started, so the port is not in use locally
           catch {close $rc}
           return 1
        }
   }

}
