#!/depot/path/expect --

# This is a CGI script to process requests created by the accompanying
# passwd.html form.  This script is pretty basic, although it is
# reasonably robust.  (Purposely intent users can make the script bomb
# by mocking up their own HTML form, however they can't expose or steal
# passwords or otherwise open any security holes.)  This script doesn't
# need any special permissions.  The usual (ownership nobody) is fine.
#
# With a little more code, the script can do much more exotic things -
# for example, you could have the script:
#
# - telnet to another host first (useful if you run CGI scripts on a
#   firewall), or
#
# - change passwords on multiple password server hosts, or
# 
# - verify that passwords aren't in the dictionary, or
# 
# - verify that passwords are at least 8 chars long and have at least 2
#   digits, 2 uppercase, 2 lowercase, or whatever restrictions you like,
#   or
#
# - allow short passwords by responding appropriately to passwd
#
# and so on.  Have fun!
#
# Don Libes, NIST

puts "Content-type: text/html\n"	;# note extra newline

puts "
<head>
<title>Passwd Change Acknowledgment</title>
</head>

<h2>Passwd Change Acknowledgment</h2>
"

proc cgi2ascii {buf} {
    regsub -all {\+} $buf { } buf
    regsub -all {([\\["$])} $buf {\\\1} buf
    regsub -all -nocase "%0d%0a" $buf "\n" buf
    regsub -all -nocase {%([a-f0-9][a-f0-9])} $buf {[format %c 0x\1]} buf
    eval return \"$buf\"
}

foreach pair [split [read stdin $env(CONTENT_LENGTH)] &] {
	regexp (.*)=(.*) $pair dummy varname val
	set val [cgi2ascii $val]
	set var($varname) $val
}

log_user 0

proc errormsg {s} {puts "<h3>Error: $s</h3>"}
proc successmsg {s} {puts "<h3>$s</h3>"}

# Need to su first to get around passwd's requirement that passwd cannot
# be run by a totally unrelated user.  Seems rather pointless since it's
# so easy to satisfy, eh?

# Change following line appropriately for your site.
# (We use yppasswd, but you might use something else.)
spawn /bin/su $var(name) -c "/bin/yppasswd $var(name)"
# This fails on SunOS 4.1.3 (passwd says "you don't have a login name")
# run on (or telnet first to) host running SunOS 4.1.4 or later.

expect {
	"Unknown login:" {
		errormsg "unknown user: $var(name)"
		exit
	} default {
		errormsg "$expect_out(buffer)"
		exit
	} "Password:"
}
send "$var(old)\r"
expect {
	"unknown user" {
		errormsg "unknown user: $var(name)"
		exit
	} "Sorry" {
		errormsg "Old password incorrect"
		exit
	} default {
		errormsg "$expect_out(buffer)"
		exit
	} "Old password:"
}
send "$var(old)\r"
expect "New password:"
send "$var(new1)\r"
expect "New password:"
send "$var(new2)\r"
expect -re (.*)\r\n {
	set error $expect_out(1,string)
}
close
wait

if {[info exists error]} {
	errormsg "$error"
} else {
	successmsg "Password changed successfully."
}
