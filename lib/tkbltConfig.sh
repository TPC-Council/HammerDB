# tkbltConfig.sh --
#
# This shell script (for sh) is generated automatically by tkblt's
# configure script.  It will create shell variables for most of
# the configuration options discovered by the configure script.
# This script is intended to be included by the configure scripts
# for tkblt extensions so that they don't have to figure this all
# out for themselves.  This file does not duplicate information
# already provided by tclConfig.sh, so you may need to use that
# file in addition to this one.
#
# The information in this file is specific to a single platform.

# tkblt's version number.
tkblt_VERSION='3.2'

# The name of the tkblt library (may be either a .a file or a shared library):
tkblt_LIB_FILE=libtkblt3.2.so

# String to pass to linker to pick up the tkblt library from its
# build directory.
tkblt_BUILD_LIB_SPEC='-L/opt/HammerDB-master/Build/BawtBuild/Linux/x64/Release/Build/tkblt -ltkblt3.2'

# String to pass to linker to pick up the tkblt library from its
# installed directory.
tkblt_LIB_SPEC='-L/opt/HammerDB-master/Build/BawtBuild/Linux/x64/Release/Install/tkblt/lib/tkblt3.2 -ltkblt3.2'

# The name of the tkblt stub library (a .a file):
tkblt_STUB_LIB_FILE=libtkbltstub3.2.a

# String to pass to linker to pick up the tkblt stub library from its
# build directory.
tkblt_BUILD_STUB_LIB_SPEC='-L/opt/HammerDB-master/Build/BawtBuild/Linux/x64/Release/Build/tkblt -ltkbltstub3.2'

# String to pass to linker to pick up the tkblt stub library from its
# installed directory.
tkblt_STUB_LIB_SPEC='-L/opt/HammerDB-master/Build/BawtBuild/Linux/x64/Release/Install/tkblt/lib/tkblt3.2 -ltkbltstub3.2'

# String to pass to linker to pick up the tkblt stub library from its
# build directory.
tkblt_BUILD_STUB_LIB_PATH='/opt/HammerDB-master/Build/BawtBuild/Linux/x64/Release/Build/tkblt/libtkbltstub3.2.a'

# String to pass to linker to pick up the tkblt stub library from its
# installed directory.
tkblt_STUB_LIB_PATH='/opt/HammerDB-master/Build/BawtBuild/Linux/x64/Release/Install/tkblt/lib/tkblt3.2/libtkbltstub3.2.a'
