AC_DEFUN(AC_WITH_IBM_DB2,
[
AC_MSG_CHECKING(if IBM DB2 installed in system)
AC_ARG_WITH(ibm_db2, 
[  --with-ibm-db2=PATH     path to installed IBM DB2 (default /usr/IBMdb2/V7.1)])
if test "x$with_ibm_db2" = "x" ; then
    ibm_db2_locations="/usr/IBMdb2/V7.1 /home/db2inst1/sqllib $HOME/sqllib"

    for f in $ibm_db2_locations ; do
	if test -r "$f/include/db2ApiDf.h" -o -r "$f/include/db2AuCfg.h" ; then
    	    DB2HOME="$f"
    	    break
	fi
    done

    if test -z "$DB2HOME" -a -z "$DB2DIR" ; then
	AC_MSG_RESULT(IBM DB2 home directory not found in $ibm_db2_locations)
	AC_MSG_RESULT(You can adjust the IBM DB2 path to your directory with)
	AC_MSG_RESULT(your distribution --with-ibm-db2[=PATH])
	AC_ERROR(Could not find the IBM DB2 home header/library files.)
    fi
    
    if test -z "$DB2DIR" ; then
	CPPFLAGS="-I$DB2HOME/include $CPPFLAGS"
	LDFLAGS="-L$DB2HOME/lib $LDFLAGS"
    else
	CPPFLAGS="-I$DB2DIR/include $CPPFLAGS"
	LDFLAGS="-L$DB2DIR/lib $LDFLAGS"
    fi
else
    CPPFLAGS="-I$with_ibm_db2/include $CPPFLAGS"
    LDFLAGS="-L$with_ibm_db2/lib $LDFLAGS"
fi
    AC_MSG_RESULT(yes)
    AC_DEFINE(HAVE_IBMDB2, 1, [Define if UDB DB2 installed in system ])
])


