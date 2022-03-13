TclTLS 1.7.22
==========

Release Date: Mon Oct 12 15:40:16 CDT 2020

https://tcltls.rkeene.org/

Original TLS Copyright (C) 1997-2000 Matt Newman <matt@novadigm.com>
TLS 1.4.1    Copyright (C) 2000 Ajuba Solutions
TLS 1.6      Copyright (C) 2008 ActiveState Software Inc.
TLS 1.7      Copyright (C) 2016 Matt Newman, Ajuba Solutions, ActiveState
                                Software Inc, Roy Keene <tcltls@rkeene.org>

TLS (aka SSL) Channel - can be layered on any bi-directional Tcl_Channel.

Both client and server-side sockets are possible, and this code should work
on any platform as it uses a generic mechanism for layering on SSL and Tcl.

Full filevent sematics should also be intact - see tests directory for
blocking and non-blocking examples.

The current release is TLS 1.6, with binaries built against OpenSSL 0.9.8g.
For best security and function, always compile from source with the latest
official release of OpenSSL (http://www.openssl.org/).

TLS 1.7 and newer require Tcl 8.4.0+, older versions may be used if older
versions of Tcl need to be used.

TclTLS requires OpenSSL or LibreSSL in order to be compiled and function.

Non-exclusive credits for TLS are:
   Original work: Matt Newman @ Novadigm
   Updates: Jeff Hobbs @ ActiveState
   Tcl Channel mechanism: Andreas Kupries
   Impetus/Related work: tclSSL (Colin McCormack, Shared Technology)
                         SSLtcl (Peter Antman)

This code is licensed under the same terms as the Tcl Core.
