/*
 * Copyright (C) 1997-2000 Sensus Consulting Ltd.
 * Matt Newman <matt@sensus.org>
 */
#include "tlsInt.h"

/*
 *  Ensure these are not macros - known to be defined on Win32 
 */
#ifdef min
#undef min
#endif

#ifdef max
#undef max
#endif

static int min(int a, int b)
{
    return (a < b) ? a : b;
}

static int max(int a, int b)
{
    return (a > b) ? a : b;
}

/*
 * ASN1_UTCTIME_tostr --
 */
static char *
ASN1_UTCTIME_tostr(ASN1_UTCTIME *tm)
{
    static char bp[128];
    char *v;
    int gmt=0;
    static char *mon[12]={
        "Jan","Feb","Mar","Apr","May","Jun",
        "Jul","Aug","Sep","Oct","Nov","Dec"};
    int i;
    int y=0,M=0,d=0,h=0,m=0,s=0;
    
    i=tm->length;
    v=(char *)tm->data;
    
    if (i < 10) goto err;
    if (v[i-1] == 'Z') gmt=1;
    for (i=0; i<10; i++)
        if ((v[i] > '9') || (v[i] < '0')) goto err;
    y= (v[0]-'0')*10+(v[1]-'0');
    if (y < 70) y+=100;
    M= (v[2]-'0')*10+(v[3]-'0');
    if ((M > 12) || (M < 1)) goto err;
    d= (v[4]-'0')*10+(v[5]-'0');
    h= (v[6]-'0')*10+(v[7]-'0');
    m=  (v[8]-'0')*10+(v[9]-'0');
    if (	(v[10] >= '0') && (v[10] <= '9') &&
		(v[11] >= '0') && (v[11] <= '9'))
        s=  (v[10]-'0')*10+(v[11]-'0');
    
    sprintf(bp,"%s %2d %02d:%02d:%02d %d%s",
                   mon[M-1],d,h,m,s,y+1900,(gmt)?" GMT":"");
    return bp;
 err:
    return "Bad time value";
}

/*
 *------------------------------------------------------*
 *
 *	Tls_NewX509Obj --
 *
 *	------------------------------------------------*
 *	Converts a X509 certificate into a Tcl_Obj
 *	------------------------------------------------*
 *
 *	Sideeffects:
 *		None
 *
 *	Result:
 *		A Tcl List Object representing the provided
 *		X509 certificate.
 *
 *------------------------------------------------------*
 */

#define CERT_STR_SIZE 16384

Tcl_Obj*
Tls_NewX509Obj( interp, cert)
    Tcl_Interp *interp;
    X509 *cert;
{
    Tcl_Obj *certPtr = Tcl_NewListObj( 0, NULL);
    BIO *bio;
    int n;
    unsigned long flags;
    char subject[BUFSIZ];
    char issuer[BUFSIZ];
    char serial[BUFSIZ];
    char notBefore[BUFSIZ];
    char notAfter[BUFSIZ];
    char certStr[CERT_STR_SIZE], *certStr_p;
    int certStr_len, toRead;
#ifndef NO_SSL_SHA
    int shai;
    char sha_hash_ascii[SHA_DIGEST_LENGTH * 2 + 1];
    unsigned char sha_hash_binary[SHA_DIGEST_LENGTH];
    const char *shachars="0123456789ABCDEF";

    sha_hash_ascii[SHA_DIGEST_LENGTH * 2] = '\0';
#endif

    certStr[0] = 0;
    if ((bio = BIO_new(BIO_s_mem())) == NULL) {
	subject[0] = 0;
	issuer[0]  = 0;
	serial[0]  = 0;
    } else {
	flags = XN_FLAG_RFC2253 | ASN1_STRFLGS_UTF8_CONVERT;
	flags &= ~ASN1_STRFLGS_ESC_MSB;

	X509_NAME_print_ex(bio, X509_get_subject_name(cert), 0, flags); 
	n = BIO_read(bio, subject, min(BIO_pending(bio), BUFSIZ - 1));
	n = max(n, 0);
	subject[n] = 0;
	(void)BIO_flush(bio);

	X509_NAME_print_ex(bio, X509_get_issuer_name(cert), 0, flags);
	n = BIO_read(bio, issuer, min(BIO_pending(bio), BUFSIZ - 1));
	n = max(n, 0);
	issuer[n] = 0;
	(void)BIO_flush(bio);

	i2a_ASN1_INTEGER(bio, X509_get_serialNumber(cert));
	n = BIO_read(bio, serial, min(BIO_pending(bio), BUFSIZ - 1));
	n = max(n, 0);
	serial[n] = 0;
	(void)BIO_flush(bio);

        if (PEM_write_bio_X509(bio, cert)) {
            certStr_p = certStr;
            certStr_len = 0;
            while (1) {
                toRead = min(BIO_pending(bio), CERT_STR_SIZE - certStr_len - 1);
                toRead = min(toRead, BUFSIZ);
                if (toRead == 0) {
                    break;
                }
                dprintf("Reading %i bytes from the certificate...", toRead);
                n = BIO_read(bio, certStr_p, toRead);
                if (n <= 0) {
                    break;
                }
                certStr_len += n;
                certStr_p   += n;
            }
            *certStr_p = '\0';
            (void)BIO_flush(bio);
        }

	BIO_free(bio);
    }

    strcpy( notBefore, ASN1_UTCTIME_tostr( X509_get_notBefore(cert) ));
    strcpy( notAfter, ASN1_UTCTIME_tostr( X509_get_notAfter(cert) ));

#ifndef NO_SSL_SHA
    X509_digest(cert, EVP_sha1(), sha_hash_binary, NULL);
    for (shai = 0; shai < SHA_DIGEST_LENGTH; shai++) {
        sha_hash_ascii[shai * 2]     = shachars[(sha_hash_binary[shai] & 0xF0) >> 4];
        sha_hash_ascii[shai * 2 + 1] = shachars[(sha_hash_binary[shai] & 0x0F)];
    }
    Tcl_ListObjAppendElement( interp, certPtr, Tcl_NewStringObj("sha1_hash", -1) );
    Tcl_ListObjAppendElement( interp, certPtr, Tcl_NewStringObj(sha_hash_ascii, SHA_DIGEST_LENGTH * 2) );

#endif
    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( "subject", -1) );
    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( subject, -1) );

    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( "issuer", -1) );
    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( issuer, -1) );

    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( "notBefore", -1) );
    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( notBefore, -1) );

    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( "notAfter", -1) );
    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( notAfter, -1) );

    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( "serial", -1) );
    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( serial, -1) );

    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( "certificate", -1) );
    Tcl_ListObjAppendElement( interp, certPtr,
	    Tcl_NewStringObj( certStr, -1) );

    return certPtr;
}
