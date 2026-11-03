# OceanBase Tcl binding

`obmysqltcl 0.1` is a separate binding to OceanBase Connector/C (`libobclnt`).
It does not provide `mysqltcl` or replace the MySQL client library.

Its commands follow mysqltcl's arguments and results, using `::obmysql::*`
and legacy names such as `obmysqlconnect`, `obmysqluse` and `obmysqlexec`.
The status array is `::obmysqlstatus`; connection and statement handles use
the `obmysql` prefix, query handles use `obquery`, and the Tcl object types
are `obmysqlhandle` and `obmysqlnull`. Handles belong to the binding and
interpreter that created them.

## Build on Linux

Provide a C compiler, a configured or installed Tcl 9 development tree with
its stub library, and the OceanBase Connector/C SDK. The SDK must contain
`include/mysql.h` and `lib/libobclnt.so` (or `lib64/libobclnt.so`).

```sh
./build.sh --tcl-config /path/to/tcl/lib/tclConfig.sh \
  --sdk /path/to/obclient \
  --output /path/to/packages/obmysqltcl0.1
```

`TCL_CONFIG` and `OBCLIENT_ROOT` can supply the SDK paths. `CC`, `CFLAGS` and
`LDFLAGS` can supply build options. The compiler is invoked without an
embedded client-library RPATH. The output contains the binding, package
index, build information and notices; no database client library is copied.

To use the resulting package in a separate test process:

```sh
export TCLLIBPATH=/path/to/packages
export LD_LIBRARY_PATH=/path/to/obclient/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
```

Then `package require obmysqltcl 0.1` selects this binding. The package's
unique name allows `mysqltcl` to keep using its existing binding and library.
The adapter must explicitly request `obmysqltcl` and use its command names.

`-ssl true` requires TLS, validates the server certificate and checks the
requested host name. Supply `-sslca` or `-sslcapath` for a private CA; without
one, the client uses its default trust paths. An unavailable TLS endpoint or
an untrusted certificate is an error, not a fallback to an unencrypted login.

The initial target is Linux with Tcl 9 and OceanBase Connector/C 2.2.14.
Other client versions and platforms require validation.
The mysqltcl API's optional C prepared-statement commands remain disabled,
as in the original HammerDB binding; SQL `PREPARE`/`EXECUTE` remains available.

See `NOTICE` for the original source and changes, and `COPYING` for the
binding and Tcl stub notices. This directory supplies a build input for
HammerDB packaging, not a complete database-client distribution.
