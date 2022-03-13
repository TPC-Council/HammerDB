EXPVERSION = 5.31

CC = gcc
CPLUSPLUS = g++
CPLUSPLUSLIBDIR = -L/depot/gnu/arch/lib
CPLUSPLUSLIB = -lg++

CFLAGS = -g -I..
LIBEXPECT = -L.. -lexpect$(EXPVERSION)

LIBS = $(LIBEXPECT) -lm

SCRIPTS = su2 noidle script.exp bonfield.exp

all: chesslib chesslib2 chesslib++

# this can be compiled with either cc or gcc
chesslib: chesslib.o
	$(CC) -g -o chesslib chesslib.o $(LIBS)

# this can be compiled with either cc or gcc
chesslib2: chesslib2.o
	$(CC) -g -o chesslib2 chesslib2.o $(LIBS)

# this is compiled with c++
chesslib++: chesslib++.o
	$(CPLUSPLUS) -g -o chesslib++ chesslib++.o $(LIBS) \
		$(CPLUSPLUSLIBDIR) $(CPLUSPLUSLIB)

chesslib++.o: chesslib++.c
	$(CPLUSPLUS) -c $(CFLAGS) chesslib++.c

unbuffer-standalone: unbuffer.o
	$(CC) -g -o unbuffer-standalone unbuffer.o $(LIBS)

printvars: printvars.o
	$(CC) -o printvars printvars.o $(LIBS)

ftplib: ftplib.o
	$(CC) -g -o ftplib ftplib.o $(LIBS)

match_max: match_max.o
	$(CC) -g -o match_max match_max.o $(LIBS)

jaj1: jaj1.o
	$(CC) -g -o jaj1 jaj1.o $(LIBS)

jaj2: jaj2.o
	$(CC) -g -o jaj2 jaj2.o $(LIBS)

# wrap up password-generation examples
passgen:
	shar passgen.README tkpasswd mkpasswd mkpasswd.man > /tmp/passgen

cleanup:
	rm -f expect devtty exho dumb test.raw test.results test.tmp

# copy some contributed scripts over to public-accessible directory
SCRIPTDIR = ~ftp/pub/expect/scripts
ftp:
	rcp README.scripts durer:$(SCRIPTDIR)/README
	rcp $(SCRIPTS) durer:$(SCRIPTDIR)
	rsh durer ls -l $(SCRIPTDIR)
