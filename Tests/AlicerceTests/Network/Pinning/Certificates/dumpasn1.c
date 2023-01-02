/* ASN.1 data display code, copyright Peter Gutmann
   <pgut001@cs.auckland.ac.nz>, based on ASN.1 dump program by David Kemp,
   with contributions from various people including Matthew Hamrick, Bruno
   Couillard, Hallvard Furuseth, Geoff Thorpe, David Boyce, John Hughes,
   'Life is hard, and then you die', Hans-Olof Hermansson, Tor Rustad,
   Kjetil Barvik, James Sweeny, Chris Ridd, David Lemley, John Tobey, James
   Manger, Igor Perminov, and several other people whose names I've
   misplaced.

   Available from https://www.cs.auckland.ac.nz/~pgut001/dumpasn1.c. Last
   updated 22 April 2021 (version 20210422, if you prefer it that way,
   see also UPDATE_STRING below).  To build under Windows, use 
   'cl /MD dumpasn1.c'.  To build on OS390 or z/OS, use 
   '/bin/c89 -D OS390 -o dumpasn1 dumpasn1.c'.

   This code grew slowly over time without much design or planning, and with
   extra features being tacked on as required.  It's not representative of my
   normal coding style, and should only be used as a debugging/diagnostic
   tool and not in a production environment (I'm not sure how you'd use
   it in production anyway, but felt I should point that out).  cryptlib,
   https://www.cs.auckland.ac.nz/~pgut001/cryptlib/, does a much better job 
   of checking ASN.1 than this does, since dumpasn1 is a display program 
   written to accept the widest possible range of input and not a compliance 
   checker.  In other words it will bend over backwards to even accept 
   invalid data, since a common use for it is to try and locate encoding 
   problems that lead to invalid encoded data.  While it will warn about 
   some types of common errors, the fact that dumpasn1 will display an ASN.1 
   data item doesn't mean that the item is valid.

   dumpasn1 requires a config file dumpasn1.cfg to be present in the same
   location as the program itself or in a standard directory where binaries
   live (it will run without it but will display a warning message, you can
   configure the path either by hardcoding it in or using an environment
   variable as explained further down).  The config file is available from
   https://www.cs.auckland.ac.nz/~pgut001/dumpasn1.cfg.

   This code assumes that the input data is binary, having come from a MIME-
   aware mailer or been piped through a decoding utility if the original
   format used base64 encoding.  If you need to decode it, it's recommended
   that you use a utility like uudeview, which will strip most kinds of 
   encoding (MIME, PEM, PGP, whatever) to recover the binary original.

   You can use this code in whatever way you want, as long as you don't try
   to claim you wrote it.

   (Someone asked for clarification on what this means, treat it as a very
   mild form of the BSD license in which you're not required to include LONG
   LEGAL DISCLAIMERS IN ALL CAPS but just a small note in a corner somewhere
   (e.g. the back of a manual) that you're using the dumpasn1 code.  If you 
   do use it, please make sure you're using a recent version, I occasionally 
   see screen shots from incredibly ancient versions that are nowhere near 
   as good as what current versions produce.  Finally, see the note earlier
   about this being purely a debugging tool and not production-quality code).

   Editing notes: Tabs to 4, phasers to malky (and in case anyone wants to
   complain about that, see "Program Indentation and Comprehensiblity",
   Richard Miara, Joyce Musselman, Juan Navarro, and Ben Shneiderman,
   Communications of the ACM, Vol.26, No.11 (November 1983), p.861) */

#include <ctype.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef OS390
  #include <unistd.h>
#endif /* OS390 */

/* The update string, printed as part of the help screen */

#define UPDATE_YEAR		"2021"
#define UPDATE_STRING	"22 April 2021"

/* Useful defines */

#ifndef TRUE
  #define FALSE	0
  #define TRUE	( !FALSE )
#endif /* TRUE */
#ifndef BYTE
  typedef unsigned char		BYTE;
#endif /* BYTE */

/* Tandem Guardian NonStop Kernel options */

#ifdef __TANDEM
  #pragma nolist		/* Spare us the source listing, no GUI... */
  #pragma nowarn (1506)	/* Implicit type conversion: int to char etc */
#endif /* __TANDEM */

/* SunOS 4.x doesn't define seek codes or exit codes or FILENAME_MAX (it does
   define _POSIX_MAX_PATH, but in funny locations and to different values
   depending on which include file you use).  Strictly speaking this code
   isn't right since we need to use PATH_MAX, however not all systems define
   this, some use _POSIX_PATH_MAX, and then there are all sorts of variations
   and other defines that you have to check, which require about a page of
   code to cover each OS, so we just use max( FILENAME_MAX, 512 ) which
   should work for everything */

#ifndef SEEK_SET
  #define SEEK_SET			0
  #define SEEK_CUR			2
#endif /* No fseek() codes defined */
#ifndef EXIT_FAILURE
  #define EXIT_FAILURE		1
  #define EXIT_SUCCESS		( !EXIT_FAILURE )
#endif /* No exit() codes defined */
#ifndef FILENAME_MAX
  #define FILENAME_MAX		512
#else
  #if FILENAME_MAX < 128
	#undef FILENAME_MAX
	#define FILENAME_MAX	512
  #endif /* FILENAME_MAX < 128 */
#endif /* FILENAME_MAX */

/* Under Windows we can do special-case handling for paths and Unicode
   strings (although in practice it can't really handle much except
   latin-1) */

#if ( defined( _WINDOWS ) || defined( WIN32 ) || defined( _WIN32 ) || \
	  defined( __WIN32__ ) )
  #include <windows.h>
  #include <io.h>					/* For _setmode() */
  #include <fcntl.h>				/* For _setmode() codes */
  #ifndef _O_U16TEXT
	#define _O_U16TEXT		0x20000	/* _setmode() code */
  #endif /* !_O_U16TEXT */
  #define __WIN32__
#endif /* Win32 */

/* Under Unix we can do special-case handling for paths and Unicode strings.
   Detecting Unix systems is a bit tricky but the following should find most
   versions.  This define implicitly assumes that the system has wchar_t
   support, but this is almost always the case except for very old systems,
   so it's best to default to allow-all rather than deny-all */

#if defined( linux ) || defined( __linux__ ) || defined( sun ) || \
	defined( __bsdi__ ) || defined( __FreeBSD__ ) || defined( __NetBSD__ ) || \
	defined( __OpenBSD__ ) || defined( __hpux ) || defined( _M_XENIX ) || \
	defined( __osf__ ) || defined( _AIX ) || defined( __MACH__ )
  #define __UNIX__
#endif /* Every commonly-used Unix */
#if defined( linux ) || defined( __linux__ )
  #ifndef __USE_ISOC99
	#define __USE_ISOC99
  #endif /* __USE_ISOC99 */
  #include <wchar.h>
#endif /* Linux */

/* For IBM mainframe OSes we use the Posix environment, so it looks like
   Unix */

#ifdef OS390
  #define __OS390__
  #define __UNIX__
#endif /* OS390 / z/OS */

/* Tandem NSK: Don't tangle with Tandem OSS, which is almost UNIX */

#ifdef __TANDEM
  #ifdef _GUARDIAN_TARGET
	#define __TANDEM_NSK__
  #else
	#define __UNIX__
  #endif /* _GUARDIAN_TARGET */
#endif /* __TANDEM */

/* Some OSes don't define the min() macro */

#ifndef min
  #define min(a,b)		( ( a ) < ( b ) ? ( a ) : ( b ) )
#endif /* !min */

/* Macros to avoid problems with sign extension */

#define byteToInt( x )	( ( BYTE ) ( x ) )

/* Turn off pointless VC++ warnings */

#ifdef _MSC_VER
  #pragma warning( disable: 4018 )
  #pragma warning( disable: 4996 )
#endif /* VC++ */

/* When we dump a nested data object encapsulated within a larger object, the
   length is initially set to a magic value which is adjusted to the actual
   length once we start parsing the object */

#define LENGTH_MAGIC	177545L

/* Tag classes */

#define CLASS_MASK		0xC0	/* Bits 8 and 7 */
#define UNIVERSAL		0x00	/* 0 = Universal (defined by ITU X.680) */
#define APPLICATION		0x40	/* 1 = Application */
#define CONTEXT			0x80	/* 2 = Context-specific */
#define PRIVATE			0xC0	/* 3 = Private */

/* Encoding type */

#define FORM_MASK		0x20	/* Bit 6 */
#define PRIMITIVE		0x00	/* 0 = primitive */
#define CONSTRUCTED		0x20	/* 1 = constructed */

/* Universal tags */

#define TAG_MASK		0x1F	/* Bits 5 - 1 */
#define EOC				0x00	/*  0: End-of-contents octets */
#define BOOLEAN			0x01	/*  1: Boolean */
#define INTEGER			0x02	/*  2: Integer */
#define BITSTRING		0x03	/*  2: Bit string */
#define OCTETSTRING		0x04	/*  4: Byte string */
#define NULLTAG			0x05	/*  5: NULL */
#define OID				0x06	/*  6: Object Identifier */
#define OBJDESCRIPTOR	0x07	/*  7: Object Descriptor */
#define EXTERNAL		0x08	/*  8: External */
#define REAL			0x09	/*  9: Real */
#define ENUMERATED		0x0A	/* 10: Enumerated */
#define EMBEDDED_PDV	0x0B	/* 11: Embedded Presentation Data Value */
#define UTF8STRING		0x0C	/* 12: UTF8 string */
#define SEQUENCE		0x10	/* 16: Sequence/sequence of */
#define SET				0x11	/* 17: Set/set of */
#define NUMERICSTRING	0x12	/* 18: Numeric string */
#define PRINTABLESTRING	0x13	/* 19: Printable string (ASCII subset) */
#define T61STRING		0x14	/* 20: T61/Teletex string */
#define VIDEOTEXSTRING	0x15	/* 21: Videotex string */
#define IA5STRING		0x16	/* 22: IA5/ASCII string */
#define UTCTIME			0x17	/* 23: UTC time */
#define GENERALIZEDTIME	0x18	/* 24: Generalized time */
#define GRAPHICSTRING	0x19	/* 25: Graphic string */
#define VISIBLESTRING	0x1A	/* 26: Visible string (ASCII subset) */
#define GENERALSTRING	0x1B	/* 27: General string */
#define UNIVERSALSTRING	0x1C	/* 28: Universal string */
#define BMPSTRING		0x1E	/* 30: Basic Multilingual Plane/Unicode string */

/* Length encoding */

#define LEN_XTND  0x80		/* Indefinite or long form */
#define LEN_MASK  0x7F		/* Bits 7 - 1 */

/* The maximum complexity level for an object, meaning nesting level of data,
   before we declare an error and exit.  Given that this is ASN.1, which
   encourages the design of ridiculously-complex objects, we set a fairly
   high bound before we bail out (cryptlib uses 50 which handles all known
   certificate and CMS object types, so 80 provides a fairly safe margin) */

#define MAX_NESTING_LEVEL	80

/* Various special-case operations to perform on strings */

typedef enum {
	STR_NONE,				/* No special handling */
	STR_UTCTIME,			/* Check it's UTCTime */
	STR_GENERALIZED,		/* Check it's GeneralizedTime */
	STR_PRINTABLE,			/* Check it's a PrintableString */
	STR_IA5,				/* Check it's an IA5String */
	STR_LATIN1,				/* Read and display string as latin-1 */
	STR_UTF8,				/* Read and display string as UTF8 */
	STR_BMP,				/* Read and display string as Unicode */
	STR_BMP_REVERSED		/* STR_BMP with incorrect endianness */
	} STR_OPTION;

/* Structure to hold info on an ASN.1 item */

typedef struct {
	int id;						/* Tag class + primitive/constructed */
	int tag;					/* Tag */
	long length;				/* Data length */
	int indefinite;				/* Item has indefinite length */
	int nonCanonical;			/* Non-canonical length encoding used */
	BYTE header[ 16 ];			/* Tag+length data */
	int headerSize;				/* Size of tag+length */
	} ASN1_ITEM;

/* Configuration options */

static int printDots = FALSE;		/* Whether to print dots to align columns */
static int doPure = FALSE;			/* Print data without LHS info column */
static int doDumpHeader = FALSE;	/* Dump tag+len in hex (level = 0, 1, 2) */
static int extraOIDinfo = FALSE;	/* Print extra information about OIDs */
static int doHexValues = FALSE;		/* Display size, offset in hex not dec.*/
static int useStdin = FALSE;		/* Take input from stdin */
static int noWarnStdin = FALSE;		/* Don't warn about stdin disabling display options */
static int zeroLengthAllowed = FALSE;/* Zero-length items allowed */
static int dumpText = FALSE;		/* Dump text alongside hex data */
static int printAllData = FALSE;	/* Whether to print all data in long blocks */
static int checkEncaps = TRUE;		/* Print encaps.data in BIT/OCTET STRINGs */
static int checkCharset = TRUE;		/* Check val.of char strs.hidden in OCTET STRs */
#ifndef __OS390__
static int reverseBitString = TRUE;	/* Print BIT STRINGs in natural order */
#else
static int reverseBitString = FALSE;/* Natural order on OS390 is the same as ASN.1 */
#endif /* __OS390__ */
static int rawTimeString = FALSE;	/* Print raw time strings */
static int shallowIndent = FALSE;	/* Perform shallow indenting */
static int outputWidth = 80;		/* 80-column display */
static int maxNestLevel = MAX_NESTING_LEVEL;/* Maximum nesting level for which to display output */
static int doOutlineOnly = FALSE;	/* Only display constructed-object outline */

/* Formatting information used for the fixed informational column to the
   left of the displayed data */

static int infoWidth = 4;
static const char *indentStringTbl[] = {
	NULL, NULL, NULL,
	"       : ",			/* "xxx xxx: " (3) */
	"         : ",			/* "xxxx xxxx: " (4) */
	"           : ",		/* "xxxxx xxxxx: " (5) */
	"             : ",		/* "xxxxxx xxxxxx: " (6) */
	"               : ",	/* "xxxxxxx xxxxxxx: " (7) */
	"                 : ",	/* "xxxxxxxx xxxxxxxx: " (8) */
	"", "", "", ""
	};
static const char *lenTbl[] = {
	NULL, NULL, NULL,
	"%3ld %3ld: ", "%4ld %4ld: ", "%5ld %5ld: ",
	"%6ld %6ld: ", "%7ld %7ld: ", "%8ld %8ld: ",
	"", "", "", ""
	};
static const char *lenIndefTbl[] = {
	NULL, NULL, NULL,
	"%3ld NDF: ", "%4ld NDEF: ", "%5ld INDEF: ",
	"%6ld INDEF : ", "%7ld INDEF  : ", "%8ld INDEF   : ",
	"", "", "", ""
	};
static const char *lenHexTbl[] = {
	NULL, NULL, NULL,
	"%03lX %3lX: ", "%04lX %4lX: ", "%05lX %5lX: ",
	"%06lX %6lX: ", "%07lX %7lX: ", "%08lX %8lX: ",
	"", "", "", ""
	};
static const char *lenHexIndefTbl[] = {
	NULL, NULL, NULL,
	"%03lX NDF: ", "%04lX NDEF: ", "%05lX INDEF: ",
	"%06lX INDEF : ", "%07lX INDEF  : ", "%08lX INDEF   : ",
	"", "", "", ""
	};

#define INDENT_SIZE		( infoWidth + 1 + infoWidth + 1 + 1 )
#define INDENT_STRING	indentStringTbl[ infoWidth ]
#define LEN				lenTbl[ infoWidth ]
#define LEN_INDEF		lenIndefTbl[ infoWidth ]
#define LEN_HEX			lenHexTbl[ infoWidth ]
#define LEN_HEX_INDEF	lenHexIndefTbl[ infoWidth ]

/* Error and warning information */

static int noErrors = 0;			/* Number of errors found */
static int noWarnings = 0;			/* Number of warnings */

/* Position in the input stream */

static int fPos = 0;				/* Absolute position in data */

/* The output stream */

static FILE *output;				/* Output stream */

/* OID data sizes.  Because of Microsoft's "encode random noise and call it
   an OID" approach, we maintain two size limits, a sane one and one capable
   of holding the random-noise OID data, which we warn about */

#define MAX_OID_SIZE		40
#define MAX_SANE_OID_SIZE	32

/* Information on an ASN.1 Object Identifier */

typedef struct tagOIDINFO {
	struct tagOIDINFO *next;		/* Next item in list */
	BYTE oid[ MAX_OID_SIZE ];
	int oidLength;
	char *comment, *description;	/* Name, rank, serial number */
	int warn;						/* Whether to warn if OID encountered */
	} OIDINFO;

static OIDINFO *oidList = NULL;

/* If the config file isn't present in the current directory, we search the
   following paths (this is needed for Unix with dumpasn1 somewhere in the
   path, since this doesn't set up argv[0] to the full path).  Anything
   beginning with a '$' uses the appropriate environment variable.  In
   addition under Unix we also walk down $PATH looking for it */

#ifdef __TANDEM_NSK__
  #define CONFIG_NAME		"asn1cfg"
#else
  #define CONFIG_NAME		"dumpasn1.cfg"
#endif /* __TANDEM_NSK__ */

#if defined( __TANDEM_NSK__ )

static const char *configPaths[] = {
	"$system.security", "$system.system",

	NULL
	};

#elif defined( __WIN32__ )

static const char *configPaths[] = {
	/* Windoze absolute paths (yeah, this code has been around for awhile,
	   why do you ask?) */
	"c:\\windows\\", "c:\\winnt\\",

	/* It's my program, I'm allowed to hardcode in strange paths that no-one
	   else uses */
	"c:\\program files\\bin\\",
	"c:\\program files (x86)\\bin\\",

	/* This one seems to be popular as well */
	"c:\\program files\\utilities\\",
	"c:\\program files (x86)\\utilities\\",

	/* General environment-based paths */
	"$DUMPASN1_PATH/",

	NULL
	};

#elif defined( __OS390__ )

static const char *configPaths[] = {
	/* General environment-based paths */
	"$DUMPASN1_PATH/",

	NULL
	};

#else

static const char *configPaths[] = {
  #ifndef DEBIAN
	/* Unix absolute paths */
	"/usr/bin/", "/usr/local/bin/", "/etc/dumpasn1/",

	/* Unix environment-based paths */
	"$HOME/", "$HOME/bin/",

	/* It's my program, I'm allowed to hardcode in strange paths that no-one
	   else uses */
	"$HOME/BIN/",
  #else
	/* Debian has specific places where you're supposed to dump things.  Note
	   the dot after $HOME, since config files are supposed to start with a
	   dot for Debian */
	"$HOME/.", "/etc/dumpasn1/",
  #endif /* DEBIAN-specific paths */

	/* General environment-based paths */
	"$DUMPASN1_PATH/",

	NULL
	};
#endif /* OS-specific search paths */

#define isEnvTerminator( c )	\
	( ( ( c ) == '/' ) || ( ( c ) == '.' ) || ( ( c ) == '$' ) || \
	  ( ( c ) == '\0' ) || ( ( c ) == '~' ) )

/****************************************************************************
*																			*
*					Object Identification/Description Routines				*
*																			*
****************************************************************************/

/* Return descriptive strings for universal tags */

static char *idstr( const int tagID )
	{
	switch( tagID )
		{
		case EOC:
			return( "End-of-contents octets" );
		case BOOLEAN:
			return( "BOOLEAN" );
		case INTEGER:
			return( "INTEGER" );
		case BITSTRING:
			return( "BIT STRING" );
		case OCTETSTRING:
			return( "OCTET STRING" );
		case NULLTAG:
			return( "NULL" );
		case OID:
			return( "OBJECT IDENTIFIER" );
		case OBJDESCRIPTOR:
			return( "ObjectDescriptor" );
		case EXTERNAL:
			return( "EXTERNAL" );
		case REAL:
			return( "REAL" );
		case ENUMERATED:
			return( "ENUMERATED" );
		case EMBEDDED_PDV:
			return( "EMBEDDED PDV" );
		case UTF8STRING:
			return( "UTF8String" );
		case SEQUENCE:
			return( "SEQUENCE" );
		case SET:
			return( "SET" );
		case NUMERICSTRING:
			return( "NumericString" );
		case PRINTABLESTRING:
			return( "PrintableString" );
		case T61STRING:
			return( "TeletexString" );
		case VIDEOTEXSTRING:
			return( "VideotexString" );
		case IA5STRING:
			return( "IA5String" );
		case UTCTIME:
			return( "UTCTime" );
		case GENERALIZEDTIME:
			return( "GeneralizedTime" );
		case GRAPHICSTRING:
			return( "GraphicString" );
		case VISIBLESTRING:
			return( "VisibleString" );
		case GENERALSTRING:
			return( "GeneralString" );
		case UNIVERSALSTRING:
			return( "UniversalString" );
		case BMPSTRING:
			return( "BMPString" );
		default:
			return( "Unknown (Reserved)" );
		}
	}

/* Return information on an object identifier */

static OIDINFO *getOIDinfo( const BYTE *oid, const int oidLength )
	{
	const BYTE oidByte = oid[ 1 ];
	OIDINFO *oidPtr;

	for( oidPtr = oidList; oidPtr != NULL; oidPtr = oidPtr->next )
		{
		if( oidLength != oidPtr->oidLength - 2 )
			continue;	/* Quick-reject check */
		if( oidByte != oidPtr->oid[ 2 + 1 ] )
			continue;	/* Quick-reject check */
		if( !memcmp( oidPtr->oid + 2, oid, oidLength ) )
			return( oidPtr );
		}

	return( NULL );
	}

/* Add an OID attribute */

static int addAttribute( char **buffer, char *attribute )
	{
	if( ( *buffer = ( char * ) malloc( strlen( attribute ) + 1 ) ) == NULL )
		{
		puts( "Out of memory." );
		return( FALSE );
		}
	strcpy( *buffer, attribute );
	return( TRUE );
	}

/* Table to identify valid string chars (taken from cryptlib).  Note that
   IA5String also allows control chars, but we warn about these since
   finding them in a certificate is a sign that there's something
   seriously wrong */

#define P	1						/* PrintableString */
#define I	2						/* IA5String */
#define PI	3						/* IA5String and PrintableString */

static int charFlags[] = {
	/* 00  01  02  03  04  05  06  07  08  09  0A  0B  0C  0D  0E  0F */
		0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,
	/* 10  11  12  13  14  15  16  17  18  19  1A  1B  1C  1D  1E  1F */
		0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,
	/*		!	"	#	$	%	&	'	(	)	*	+	,	-	.	/ */
	   PI,	I,	I,	I,	I,	I,	I, PI, PI, PI,	I, PI, PI, PI, PI, PI,
	/*	0	1	2	3	4	5	6	7	8	9	:	;	<	=	>	? */
	   PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI,	I,	I, PI,	I, PI,
	/*	@	A	B	C	D	E	F	G	H	I	J	K	L	M	N	O */
		I, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI,
	/*	P	Q	R	S	T	U	V	W	X	Y	Z	[	\	]	^ _ */
	   PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI,	I,	I,	I,	I,	I,
	/*	`	a	b	c	d	e	f	g	h	i	j	k	l	m	n	o */
		I, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI,
	/*	p	q	r	s	t	u	v	w	x	y	z	{	|	}	~  DL */
	   PI, PI, PI, PI, PI, PI, PI, PI, PI, PI, PI,	I,	I,	I,	I,	0
	};

static int isPrintable( int ch )
	{
	if( ch >= 128 || !( charFlags[ ch ] & P ) )
		return( FALSE );
	return( TRUE );
	}

static int isIA5( int ch )
	{
	if( ch >= 128 || !( charFlags[ ch ] & I ) )
		return( FALSE );
	return( TRUE );
	}

/****************************************************************************
*																			*
*							Config File Read Routines						*
*																			*
****************************************************************************/

/* Files coming from DOS/Windows systems may have a ^Z (the CP/M EOF char)
   at the end, so we need to filter this out */

#define CPM_EOF	0x1A		/* ^Z = CPM EOF char */

/* The maximum input line length */

#define MAX_LINESIZE	512

/* Read a line of text from the config file */

static int lineNo;

static int readLine( FILE *file, char *buffer )
	{
	int bufCount = 0, ch;

	/* Skip whitespace */
	while( ( ( ch = getc( file ) ) == ' ' || ch == '\t' ) && !feof( file ) );

	/* Get a line into the buffer */
	while( ch != '\r' && ch != '\n' && ch != CPM_EOF && !feof( file ) )
		{
		/* Check for an illegal char in the data.  Note that we don't just
		   check for chars with high bits set because these are legal in
		   non-ASCII strings */
		if( !isprint( ch ) )
			{
			printf( "Bad character '%c' in config file line %d.\n",
					ch, lineNo );
			return( FALSE );
			}

		/* Check to see if it's a comment line */
		if( ch == '#' && !bufCount )
			{
			/* Skip comment section and trailing whitespace */
			while( ch != '\r' && ch != '\n' && ch != CPM_EOF && !feof( file ) )
				ch = getc( file );
			break;
			}

		/* Make sure that the line is of the correct length */
		if( bufCount > MAX_LINESIZE )
			{
			printf( "Config file line %d too long.\n", lineNo );
			return( FALSE );
			}
		else
			if( ch )	/* Can happen if we read a binary file */
				buffer[ bufCount++ ] = ch;

		/* Get next character */
		ch = getc( file );
		}

	/* If we've just passed a CR, check for a following LF */
	if( ch == '\r' )
		{
		if( ( ch = getc( file ) ) != '\n' )
			ungetc( ch, file );
		}

	/* Skip trailing whitespace and add der terminador */
	while( bufCount > 0 &&
		   ( ( ch = buffer[ bufCount - 1 ] ) == ' ' || ch == '\t' ) )
		bufCount--;
	buffer[ bufCount ] = '\0';

	/* Handle special-case of ^Z if file came off an MSDOS system */
	if( ch == CPM_EOF )
		{
		while( !feof( file ) )
			{
			/* Keep going until we hit the true EOF (or some sort of error) */
			( void ) getc( file );
			}
		}

	return( ferror( file ) ? FALSE : TRUE );
	}

/* Process an OID specified as space-separated decimal or hex digits */

static int processOID( OIDINFO *oidInfo, char *string )
	{
	BYTE binaryOID[ MAX_OID_SIZE ];
	long value;
	int firstValue = -1, valueIndex = 0, oidIndex = 3;

	memset( binaryOID, 0, MAX_OID_SIZE );
	binaryOID[ 0 ] = OID;
	while( *string && oidIndex < MAX_OID_SIZE )
		{
		if( oidIndex >= MAX_OID_SIZE - 4 )
			{
			printf( "Excessively long OID in config file line %d.\n",
					lineNo );
			return( FALSE );
			}
		if( sscanf( string, "%8ld", &value ) != 1 || value < 0 )
			{
			printf( "Invalid value in config file line %d.\n", lineNo );
			return( FALSE );
			}
		if( valueIndex == 0 )
			{
			firstValue = value;
			valueIndex++;
			}
		else
			{
			if( valueIndex == 1 )
				{
				if( firstValue < 0 || firstValue > 2 || value < 0 || \
					( ( firstValue < 2 && value > 39 ) || \
					  ( firstValue == 2 && value > 175 ) ) )
					{
					printf( "Invalid value in config file line %d.\n",
							lineNo );
					return( FALSE );
					}
				binaryOID[ 2 ] = ( firstValue * 40 ) + ( int ) value;
				valueIndex++;
				}
			else
				{
				int hasHighBits = FALSE;

				if( value >= 0x200000L )					/* 2^21 */
					{
					binaryOID[ oidIndex++ ] = 0x80 | ( int ) ( value >> 21 );
					value %= 0x200000L;
					hasHighBits = TRUE;
					}
				if( ( value >= 0x4000 ) || hasHighBits )	/* 2^14 */
					{
					binaryOID[ oidIndex++ ] = 0x80 | ( int ) ( value >> 14 );
					value %= 0x4000;
					hasHighBits = TRUE;
					}
				if( ( value >= 0x80 ) || hasHighBits )		/* 2^7 */
					{
					binaryOID[ oidIndex++ ] = 0x80 | ( int ) ( value >> 7 );
					value %= 128;
					}
				binaryOID[ oidIndex++ ] = ( int ) value;
				}
			}
		while( *string && isdigit( byteToInt( *string ) ) )
			string++;
		if( *string && *string++ != ' ' )
			{
			printf( "Invalid OID string in config file line %d.\n", lineNo );
			return( FALSE );
			}
		}
	binaryOID[ 1 ] = oidIndex - 2;
	memcpy( oidInfo->oid, binaryOID, oidIndex );
	oidInfo->oidLength = oidIndex;

	return( TRUE );
	}

static int processHexOID( OIDINFO *oidInfo, char *string )
	{
	int value, index = 0;

	while( *string && index < MAX_OID_SIZE - 1 )
		{
		if( sscanf( string, "%4x", &value ) != 1 || value < 0 || value > 255 )
			{
			printf( "Invalid hex value in config file line %d.\n", lineNo );
			return( FALSE );
			}
		oidInfo->oid[ index++ ] = value;
		string += 2;
		if( *string && *string++ != ' ' )
			{
			printf( "Invalid hex string in config file line %d.\n", lineNo );
			return( FALSE );
			}
		}
	oidInfo->oid[ index ] = 0;
	oidInfo->oidLength = index;
	if( index >= MAX_OID_SIZE - 1 )
		{
		printf( "OID value in config file line %d too long.\n", lineNo );
		return( FALSE );
		}
	return( TRUE );
	}

/* Read a config file */

static int readConfig( const char *path, const int isDefaultConfig )
	{
	OIDINFO dummyOID = { NULL, "Dummy", 0, "Dummy", "Dummy", 1 }, *oidPtr;
	FILE *file;
	int seenHexOID = FALSE;
	char buffer[ MAX_LINESIZE ];
	int status;

	/* Try and open the config file */
	if( ( file = fopen( path, "rb" ) ) == NULL )
		{
		/* If we can't open the default config file, issue a warning but
		   continue anyway */
		if( isDefaultConfig )
			{
			puts( "Cannot open config file 'dumpasn1.cfg', which should be in the same" );
			puts( "directory as the dumpasn1 program, a standard system directory, or" );
			puts( "in a location pointed to by the DUMPASN1_PATH environment variable." );
			puts( "Operation will continue without the ability to display Object " );
			puts( "Identifier information." );
			puts( "" );
			puts( "If the config file is located elsewhere, you can set the environment" );
			puts( "variable DUMPASN1_PATH to the path to the file." );
			return( TRUE );
			}

		printf( "Cannot open config file '%s'.\n", path );
		return( FALSE );
		}

	/* Add the new config entries at the appropriate point in the OID list */
	if( oidList == NULL )
		oidPtr = &dummyOID;
	else
		for( oidPtr = oidList; oidPtr->next != NULL; oidPtr = oidPtr->next );

	/* Read each line in the config file */
	lineNo = 1;
	while( ( status = readLine( file, buffer ) ) == TRUE && !feof( file ) )
		{
		/* If it's a comment line, skip it */
		if( !*buffer )
			{
			lineNo++;
			continue;
			}

		/* Check for an attribute tag */
		if( !strncmp( buffer, "OID = ", 6 ) )
			{
			/* Make sure that all of the required attributes for the current
			   OID are present */
			if( oidPtr->description == NULL )
				{
				printf( "OID ending on config file line %d has no "
						"description attribute.\n", lineNo - 1 );
				return( FALSE );
				}

			/* Allocate storage for the new OID */
			if( ( oidPtr->next = ( OIDINFO * ) malloc( sizeof( OIDINFO ) ) ) == NULL )
				{
				puts( "Out of memory." );
				return( FALSE );
				}
			oidPtr = oidPtr->next;
			if( oidList == NULL )
				oidList = oidPtr;
			memset( oidPtr, 0, sizeof( OIDINFO ) );

			/* Add the new OID */
			if( !strncmp( buffer + 6, "06", 2 ) )
				{
				seenHexOID = TRUE;
				if( !processHexOID( oidPtr, buffer + 6 ) )
					return( FALSE );
				}
			else
				{
				if( !processOID( oidPtr, buffer + 6 ) )
					return( FALSE );
				}

			/* Check that this OID isn't already present in the OID list.
			   This is a quick-and-dirty n^2 algorithm so it's not enabled
			   by default */
#if 0
			{
			OIDINFO *oidCursor;

			for( oidCursor = oidList; oidCursor->next != NULL; oidCursor = oidCursor->next )
				{
				if( oidCursor->oidLength == oidPtr->oidLength && \
					!memcmp( oidCursor->oid, oidPtr->oid, oidCursor->oidLength ) )
					{
					printf( "Duplicate OID '%s' at line %d.\n",
							buffer, lineNo );
					}
				}
			}
#endif /* 0 */
			}
		else if( !strncmp( buffer, "Description = ", 14 ) )
			{
			if( oidPtr->description != NULL )
				{
				printf( "Duplicate OID description in config file line %d.\n",
						lineNo );
				return( FALSE );
				}
			if( !addAttribute( &oidPtr->description, buffer + 14 ) )
				return( FALSE );
			}
		else if( !strncmp( buffer, "Comment = ", 10 ) )
			{
			if( oidPtr->comment != NULL )
				{
				printf( "Duplicate OID comment in config file line %d.\n",
						lineNo );
				return( FALSE );
				}
			if( !addAttribute( &oidPtr->comment, buffer + 10 ) )
				return( FALSE );
			}
		else if( !strncmp( buffer, "Warning", 7 ) )
			{
			if( oidPtr->warn )
				{
				printf( "Duplicate OID warning in config file line %d.\n",
						lineNo );
				return( FALSE );
				}
			oidPtr->warn = TRUE;
			}
		else
			{
			printf( "Unrecognised attribute '%s', line %d.\n", buffer,
					lineNo );
			return( FALSE );
			}

		lineNo++;
		}
	fclose( file );

	/* If we're processing an old-style config file, tell the user to
	   upgrade */
	if( seenHexOID )
		{
		puts( "\nWarning: Use of old-style hex OIDs detected in "
			  "configuration file, please\n         update your dumpasn1 "
			  "configuration file.\n" );
		}

	return( status );
	}

/* Check for the existence of a config file path (access() isn't available
   on all systems) */

static int testConfigPath( const char *path )
	{
	FILE *file;

	/* Try and open the config file */
	if( ( file = fopen( path, "rb" ) ) == NULL )
		return( FALSE );
	fclose( file );

	return( TRUE );
	}

/* Build a config path by substituting environment strings for $NAMEs */

static void buildConfigPath( char *path, const char *pathTemplate )
	{
	char pathBuffer[ FILENAME_MAX ], newPath[ FILENAME_MAX ];
	int pathLen, pathPos = 0, newPathPos = 0;

	/* Add the config file name at the end */
	strcpy( pathBuffer, pathTemplate );
	strcat( pathBuffer, CONFIG_NAME );
	pathLen = strlen( pathBuffer );

	while( pathPos < pathLen )
		{
		char *strPtr;
		int substringSize;

		/* Find the next $ and copy the data before it to the new path */
		if( ( strPtr = strstr( pathBuffer + pathPos, "$" ) ) != NULL )
			substringSize = ( int ) ( ( strPtr - pathBuffer ) - pathPos );
		else
			substringSize = pathLen - pathPos;
		if( substringSize > 0 )
			{
			memcpy( newPath + newPathPos, pathBuffer + pathPos,
					substringSize );
			}
		newPathPos += substringSize;
		pathPos += substringSize;

		/* Get the environment string for the $NAME */
		if( strPtr != NULL )
			{
			char envName[ MAX_LINESIZE ], *envString;
			int i;

			/* Skip the '$', find the end of the $NAME, and copy the name
			   into an internal buffer */
			pathPos++;	/* Skip the $ */
			for( i = 0; !isEnvTerminator( pathBuffer[ pathPos + i ] ); i++ );
			memcpy( envName, pathBuffer + pathPos, i );
			envName[ i ] = '\0';

			/* Get the env.string and copy it over */
			if( ( envString = getenv( envName ) ) != NULL )
				{
				const int envStrLen = strlen( envString );

				if( newPathPos + envStrLen < FILENAME_MAX - 2 )
					{
					memcpy( newPath + newPathPos, envString, envStrLen );
					newPathPos += envStrLen;
					}
				}
			pathPos += i;
			}
		}
	newPath[ newPathPos ] = '\0';	/* Add der terminador */

	/* Copy the new path to the output */
	strcpy( path, newPath );
	}

/* Read the global config file */

static int readGlobalConfig( const char *path )
	{
	char buffer[ FILENAME_MAX ];
	char *searchPos = ( char * ) path, *namePos, *lastPos = NULL;
#ifdef __UNIX__
	char *envPath;
#endif /* __UNIX__ */
#ifdef __WIN32__
	char filePath[ _MAX_PATH ];
	DWORD count;
#endif /* __WIN32__ */
	int i;

	/* First, try and find the config file in the same directory as the
	   executable by walking down the path until we find the last occurrence
	   of the program name.  This requires that argv[0] be set up properly,
	   which isn't the case if Unix search paths are being used and is a
	   bit hit-and-miss under Windows where the contents of argv[0] depend
	   on how the program is being executed.  To avoid this we perform some
	   Windows-specific processing to try and find the path to the
	   executable if we can't otherwise find it */
	do
		{
		namePos = lastPos;
		lastPos = strstr( searchPos, "dumpasn1" );
		if( lastPos == NULL )
			lastPos = strstr( searchPos, "DUMPASN1" );
		searchPos = lastPos + 1;
		}
	while( lastPos != NULL );
#ifdef __UNIX__
	if( namePos == NULL && ( namePos = strrchr( path, '/' ) ) != NULL )
		{
		const int endPos = ( int ) ( namePos - path ) + 1;

		/* If the executable isn't called dumpasn1, we won't be able to find
		   it with the above code, fall back to looking for directory
		   separators.  This requires a system where the only separator is
		   the directory separator (ie it doesn't work for Windows or most
		   mainframe environments) */
		if( endPos < FILENAME_MAX - 13 )
			{
			memcpy( buffer, path, endPos );
			strcpy( buffer + endPos, CONFIG_NAME );
			if( testConfigPath( buffer ) )
				return( readConfig( buffer, TRUE ) );
			}

		/* That didn't work, try the absolute locations and $PATH */
		namePos = NULL;
		}
#endif /* __UNIX__ */
	if( strlen( path ) < FILENAME_MAX - 13 && namePos != NULL )
		{
		strcpy( buffer, path );
		strcpy( buffer + ( int ) ( namePos - ( char * ) path ), CONFIG_NAME );
		if( testConfigPath( buffer ) )
			return( readConfig( buffer, TRUE ) );
		}

	/* Now try each of the possible absolute locations for the config file */
	for( i = 0; configPaths[ i ] != NULL; i++ )
		{
		buildConfigPath( buffer, configPaths[ i ] );
		if( testConfigPath( buffer ) )
			return( readConfig( buffer, TRUE ) );
		}

#ifdef __UNIX__
	/* On Unix systems we can also search for the config file on $PATH */
	if( ( envPath = getenv( "PATH" ) ) != NULL )
		{
		char *pathPtr = strtok( envPath, ":" );

		do
			{
			sprintf( buffer, "%s/%s", pathPtr, CONFIG_NAME );
			if( testConfigPath( buffer ) )
				return( readConfig( buffer, TRUE ) );
			pathPtr = strtok( NULL, ":" );
			}
		while( pathPtr != NULL );
		}
#endif /* __UNIX__ */
#ifdef __WIN32__
	/* Under Windows we can use GetModuleFileName() to find the location of
	   the program */
	count = GetModuleFileName ( NULL, filePath, _MAX_PATH );
	if( count > 0 )
		{
		char *progNameStart = strrchr( filePath, '\\' );
		if( progNameStart != NULL && \
			( progNameStart - filePath ) < _MAX_PATH - 13 )
			{
			/* Replace the program name with the config file name */
			strcpy( progNameStart + 1, CONFIG_NAME );
			if( testConfigPath( filePath ) )
				return( readConfig( filePath, TRUE ) );
			}
		}
#endif /*__WIN32__*/


	/* Default to just the config name (which should fail as it was the
	   first entry in configPaths[]).  readConfig() will display the
	   appropriate warning */
	return( readConfig( CONFIG_NAME, TRUE ) );
	}

/* Free the in-memory config data */

static void freeConfig( void )
	{
	OIDINFO *oidPtr = oidList;

	while( oidPtr != NULL )
		{
		OIDINFO *oidCursor = oidPtr;

		oidPtr = oidPtr->next;
		if( oidCursor->comment != NULL )
			free( oidCursor->comment );
		if( oidCursor->description != NULL )
			free( oidCursor->description );
		free( oidCursor );
		}
	}

/****************************************************************************
*																			*
*							Output/Formatting Routines						*
*																			*
****************************************************************************/

#ifdef __OS390__

static int asciiToEbcdic( const int ch )
	{
	char convBuffer[ 2 ];

	convBuffer[ 0 ] = ch;
	convBuffer[ 1 ] = '\0';
	__atoe( convBuffer ); /* Convert ASCII to EBCDIC for 390 */
	return( convBuffer[ 0 ] );
	}
#endif /* __OS390__ */

/* Output formatted text */

static int printString( const int level, const char *format, ... )
	{
	va_list argPtr;
	int length;

	if( level >= maxNestLevel )
		return( 0 );
	va_start( argPtr, format );
	length = vfprintf( output, format, argPtr );
	va_end( argPtr );

	return( length );
	}

/* Indent a string by the appropriate amount */

static void doIndent( const int level )
	{
	int i;

	if( level >= maxNestLevel )
		return;
	for( i = 0; i < level; i++ )
		{
		fprintf( output, printDots ? ". " : \
						 shallowIndent ? " " : "  " );
		}
	}

/* Complain about an error in the ASN.1 object */

static void complain( const char *message, const int messageParam,
					  const int level )
	{
	if( level < maxNestLevel )
		{
		if( !doPure )
			fprintf( output, "%s", INDENT_STRING );
		doIndent( level + 1 );
		}
	fputs( "Error: ", output );
	fprintf( output, message, messageParam );
	fputs( ".\n", output );
	noErrors++;
	}

static void complainLength( const ASN1_ITEM *item, const int level )
	{
#if 0
	/* This is a general error so we don't indent the message to the level
	   of the item */
#else
	if( level < maxNestLevel )
		{
		if( !doPure )
			fprintf( output, "%s", INDENT_STRING );
		doIndent( level + 1 );
		}
#endif /* 0 */
	fprintf( output, "Error: %s has invalid length %ld.\n",
			 idstr( item->tag ), item->length );
	noErrors++;
	}

static void complainLengthCanonical( const ASN1_ITEM *item, const int level )
	{
	int i;

#if 0
	/* This is a general error so we don't indent the message to the level
	   of the item */
#else
	if( level < maxNestLevel )
		{
		if( !doPure )
			fprintf( output, "%s", INDENT_STRING );
		doIndent( level + 1 );
		}
#endif /* 0 */
	fputs( "Error: Length '", output );
	for( i = item->nonCanonical; i < item->headerSize; i++ )
		{
		fprintf( output, "%02X", item->header[ i ] );
		if( i < item->headerSize - 1 )
			fputc( ' ', output );
		}
	fputs( "' has non-canonical encoding.\n", output );
	noErrors++;
	}

static void complainInt( const BYTE *intValue, const int level )
	{
	if( level < maxNestLevel )
		{
		if( !doPure )
			fprintf( output, "%s", INDENT_STRING );
		doIndent( level + 1 );
		}
	fprintf( output, "Error: Integer '%02X %02X ...' has non-DER encoding.\n",
			 intValue[ 0 ], intValue[ 1 ] );
	noErrors++;
	}

static void complainEOF( const int level, const int missingBytes )
	{
	printString( level, "%c", '\n' );
	complain( ( missingBytes > 1 ) ? \
				"Unexpected EOF, %d bytes missing" : \
				"Unexpected EOF, 1 byte missing", missingBytes, level );
	}

/* Warn about a (non-error) issue in the ASN.1 object */

static void warn( const char *message, const int messageParam,
				  const int level )
	{
	if( level < maxNestLevel )
		{
		if( !doPure )
			fprintf( output, "%s", INDENT_STRING );
		doIndent( level + 1 );
		}
	fputs( "Warning: ", output );
	fprintf( output, message, messageParam );
	fputs( ".\n", output );
	noWarnings++;
	}

/* Adjust the nesting-level value to make sure that we don't go off the edge
   of the screen via doIndent() when we're displaying a text or hex dump of
   data */

static int adjustLevel( const int level, const int maxLevel )
	{
	/* If we've been passed a very large pseudo-level to disable output then
	   we don't try and override this */
	if( level >= 1000 )
		return( level );

	/* If we've exceeded the maximum level for display, cap the value at
	   maxLevel to make sure that we don't end up indenting output off the
	   edge of the screen */
	if( level > maxLevel )
		return( maxLevel );

	return( level );
	}

#if defined( __WIN32__ ) || defined( __UNIX__ ) || defined( __OS390__ )

/* Try and display to display a Unicode character.  This is pretty hit and
   miss, and if it fails nothing is displayed.  Under Windows it just works,
   for anything else to try and detect this we use wcstombs() to see if 
   anything can be displayed, if it can't we drop back to trying to display 
   the data as non-Unicode */

#if defined( __WIN32__ )

static int displayUnicode( const wchar_t *wChBuf, const int level )
	{
	/* Under Windows fputwc() takes care of things */
	if( level < maxNestLevel )
		{
		int oldmode;

		/* To output Unicode to the Win32 console we need to switch the
		   output stream to Unicode-16 mode, but the following may also
		   depend on which code page is currently set for the console, which
		   font is being used, and the phase of the moon (including the moons
		   for Mars and Jupiter) */
		fflush( output );
		oldmode = _setmode( fileno( output ), _O_U16TEXT );
		fputwc( wChBuf[ 0 ], output );
		_setmode( fileno( output ), oldmode );
		}
	return( TRUE );
	}
#else

static int displayUnicode( const wchar_t *wChBuf, const int level )
	{
	char outBuf[ 8 ];
	int outLen;

	/* Check whether we can display this character.  On Unix systems this 
	   always fails (see below), so in order to test any of the subsequent
	   output options it's necessary to comment the following lines out */
#if 0
	outLen = wctomb( outBuf, wChBuf[ 0 ] );
#else
	outLen = wcstombs( outBuf, wChBuf, 8 );
#endif /* 0 */
	if( outLen < 1 )
		{
		/* Tell the caller that this can't be displayed as Unicode */
		return( FALSE );
		}
#if defined( __UNIX__ ) && !( defined( __MACH__ ) || defined( __OpenBSD__ ) )
	/* Unix environments are completely broken for Unicode, like Win32 the
	   output differentiates between char and widechar output but there's
	   no easy way to deal with this.  In theory fwide() can set it but it's
	   a one-way function, once we've set it a particular way we can't go 
	   back.  Exactly what level of braindamage it takes to have an
	   implementation function like this is a mystery, but the description
	   of the braindamage is in the section "Narrow and wide orientation" of
	   e.g. https://en.cppreference.com/w/c/io/FILE:

		A newly opened stream has no orientation. The first call to fwide or 
		to any I/O function establishes the orientation: a wide I/O function 
		makes the stream wide-oriented; a narrow I/O function makes the 
		stream narrow-oriented.  Once set, the orientation can be changed 
		with only freopen.  Narrow I/O functions cannot be called on a wide-
		oriented stream; wide I/O functions cannot be called on a narrow-
		oriented stream. 
		
	   What this means is that as soon as we output anything, the stream is 
	   locked into narrow mode and can never be used for wide characters.
	   Windows OTOH handles this without any problems, so presumably this
	   behaviour is someone's ideological preference.
	   
	   Other sources suggest using setlocale() tricks, printf() with "%lc" 
	   or "%ls" as the format specifier, and others, but none of these seem 
	   to work properly either */
	if( level < maxNestLevel )
		{
#if 0
		setlocale( LC_ALL, "" );
		fputwc( wChBuf[ 0 ], output );
#elif 0
		fwprintf( output, L"%c", wChBuf[ 0 ] );
#elif 1
		/* This (and the "%ls" variant below) seem to be the least broken
		   options */
		fprintf( output, "%lc", wChBuf[ 0 ] );
#elif 0
		fprintf( output, "%ls", wChBuf );
#else
		if( fwide( output, 1 ) > 0 )
			{
			fputwc( wChBuf[ 0 ], output );
			fwide( output, -1 );
			}
		else
			fputc( wChBuf[ 0 ], output );
#endif
		}
#else
  #ifdef __OS390__
	if( level < maxNestLevel )
		{
		char *p;

		/* This could use some improvement */
		for( p = outBuf; *p != '\0'; p++ )
			*p = asciiToEbcdic( *p );
		}
  #endif /* IBM ASCII -> EBCDIC conversion */
	printString( level, "%s", outBuf );
#endif /* OS-specific charset handling */

	return( TRUE );
	}
#endif /* Windows vs. Unix */

#endif /* __WIN32__ || __UNIX__ || __OS390__ */

/* Display an integer value */

static void printValue( FILE *inFile, const int valueLength,
					    const int level )
	{
	BYTE intBuffer[ 2 ];
	long value;
	int warnNegative = FALSE, warnNonDER = FALSE, i;

	value = getc( inFile );
	if( value == EOF )
		{
		complainEOF( level, valueLength );
		return;
		}
	if( value & 0x80 )
		warnNegative = TRUE;
	for( i = 0; i < valueLength - 1; i++ )
		{
		const int ch = getc( inFile );

		if( ch == EOF )
			{
			complainEOF( level, valueLength - i );
			return;
			}

		/* Check for the first 9 bits being identical */
		if( i == 0 )
			{
			if( ( value == 0x00 ) && ( ( ch & 0x80 ) == 0x00 ) )
				warnNonDER = TRUE;
			if( ( value == 0xFF ) && ( ( ch & 0x80 ) == 0x80 ) )
				warnNonDER = TRUE;
			if( warnNonDER )
				{
				intBuffer[ 0 ] = ( int ) value;
				intBuffer[ 1 ] = ch;
				}
			}
		value = ( value << 8 ) | ch;
		}
	fPos += valueLength;

	/* Display the integer value and any associated warnings.  Note that
	   this will display an incorrectly-encoded integer as a negative value
	   rather than the unsigned value that was probably intended to
	   emphasise that it's incorrect */
	printString( level, " %ld\n", value );
	if( warnNonDER )
		complainInt( intBuffer, level );
	if( warnNegative )
		complain( "Integer is encoded as a negative value", 0, level );
	}

/* Dump data as a string of hex digits up to a maximum of 128 bytes */

typedef enum {
	DUMPHEX_NORMAL, DUMPHEX_INTEGER, DUMPHEX_BITSTRING 
	} DUMPHEX_OPTION;

static void dumpHex( FILE *inFile, long length, int level,
					 const DUMPHEX_OPTION option, const int param )
	{
	const int lineLength = ( dumpText ) ? 8 : 16;
	const int displayHeaderLength = ( ( doPure ) ? 0 : INDENT_SIZE ) + 2;
	BYTE intBuffer[ 2 ];
	char printable[ 9 ];
	long noBytes = length;
	int singleLine = FALSE, warnPadding = FALSE; 
	int warnNegative = ( option == DUMPHEX_INTEGER ) ? TRUE : FALSE;
	int displayLength = displayHeaderLength, prevCh = -1, lastCh, i;

	memset( printable, 0, 9 );

	displayLength += ( length < lineLength ) ? ( length * 3 ) : \
											   ( lineLength * 3 );

	/* Check if the size of the displayed data (LHS status info + hex data)
	   plus the indent-level of spaces will fit into a single line behind
	   the initial label, e.g. "INTEGER" */
	if( displayHeaderLength + ( level * 2 ) + ( length * 3 ) < outputWidth )
		singleLine = TRUE;

	/* By default we only output a maximum of 128 bytes to avoid dumping
	   huge amounts of data, however if what's left is a partial lines'
	   worth then we output that as well to avoid displaying a line of text
	   indicating that less than a lines' worth of data remains to be
	   displayed */
	if( noBytes >= 128 + lineLength && !printAllData )
		noBytes = 128;

	/* Make sure that the indent level doesn't push the text off the edge of
	   the screen */
	level = adjustLevel( level, ( outputWidth - displayLength ) / 2 );
	for( i = 0; i < noBytes; i++ )
		{
		int ch;

		if( !( i % lineLength ) )
			{
			if( singleLine )
				printString( level, "%c", ' ' );
			else
				{
				if( dumpText )
					{
					/* If we're dumping text alongside the hex data, print
					   the accumulated text string */
					printString( level, "%s", "    " );
					printString( level, "%s", printable );
					}
				printString( level, "%c", '\n' );
				if( !doPure )
					printString( level, "%s", INDENT_STRING );
				doIndent( level + 1 );
				}
			}
		ch = getc( inFile );
		if( ch == EOF )
			{
			complainEOF( level, length - i );
			return;
			}
		lastCh = ch;
		printString( level, "%s%02X", ( i % lineLength ) ? " " : "", ch );
		printable[ i % 8 ] = ( ch >= ' ' && ch < 127 ) ? ch : '.';
		fPos++;

		/* If we need to check for negative values, check this now */
		if( i == 0 )
			{
			prevCh = ch;
			if( !( ch & 0x80 ) )
				warnNegative = FALSE;
			}
		if( i == 1 )
			{
			/* Check for the first 9 bits being identical */
			if( ( prevCh == 0x00 ) && ( ( ch & 0x80 ) == 0x00 ) )
				warnPadding = TRUE;
			if( ( prevCh == 0xFF ) && ( ( ch & 0x80 ) == 0x80 ) )
				warnPadding = TRUE;
			if( warnPadding )
				{
				intBuffer[ 0 ] = prevCh;
				intBuffer[ 1 ] = ch;
				}
			}
		}
	if( dumpText )
		{
		/* Print any remaining text */
		i %= lineLength;
		printable[ i ] = '\0';
		while( i < lineLength )
			{
			printString( level, "%s", "   " );
			i++;
			}
		printString( level, "%s", "    " );
		printString( level, "%s", printable );
		}
	if( length >= 128 + lineLength && !printAllData )
		{
		length -= 128;
		printString( level, "%c", '\n' );
		if( !doPure )
			printString( level, "%s", INDENT_STRING );
		doIndent( level + 5 );
		printString( level, "[ Another %ld bytes skipped ]", length );
		fPos += length;
		if( useStdin )
			{
			int ch;

			while( length-- )
				{
				ch = getc( inFile );
				if( ch == EOF )
					{
					complainEOF( level, length - i );
					return;
					}
				lastCh = ch;
				}
			}
		else
			fseek( inFile, length, SEEK_CUR );
		}
	printString( level, "%c", '\n' );

	if( option == DUMPHEX_INTEGER )
		{
		if( warnPadding )
			complainInt( intBuffer, level );
		if( warnNegative )
			complain( "Integer is encoded as a negative value", 0, level );
		}
	if( option == DUMPHEX_BITSTRING )
		{
		/* We have to be a bit careful here with BIT STRING holes which are 
		   encoded as if they were OCTET STRING holes and therefore don't 
		   obey the BIT STRING DER encoding rules.  To deal with this we 
		   assume that anything over 4 bytes/32 bits and with an unused bit
		   count of zero is a hole encoding */
		if( ( length <= 4 || param != 0 ) && \
			!( lastCh & ( 1 << param ) ) )
			{
			/* The last valid bit should be a one bit */
			complain( "Spurious zero bits in bitstring", 0, level );
			}
		if( ( ( 0xFF >> ( 8 - param ) ) & lastCh ) )
			{
			/* There shouldn't be any bits set after the last valid one.  We
			   have to do the noBits check to avoid a fencepost error when
			   there's exactly 32 bits */
			complain( "Spurious one bits in bitstring", 0, level );
			}
		}
	}

/* Convert a binary OID to its string equivalent */

static int oidToString( char *textOID, int *textOIDlength,
						const BYTE *oid, const int oidLength )
	{
	BYTE uuidBuffer[ 32 ];
	long value;
	int length = 0, uuidBufPos = -1, uuidBitCount = 5, i;
	int validEncoding = TRUE, isUUID = FALSE;

	for( i = 0, value = 0; i < oidLength; i++ )
		{
		const BYTE data = oid[ i ];
		const long valTmp = value << 7;

		/* Pick apart the encoding.  We keep going after hitting an encoding
		   error at the start of an arc because the overall length is
		   bounded and we may still be able to recover something worth
		   printing */
		if( length > 128 - 32 )
			{
			/* Excessively long OID, add a continuation marker and exit */
			length += sprintf( textOID + length, "..." );
			validEncoding = FALSE;
			break;
			}
		if( value == 0 && data == 0x80 )
			{
			/* Invalid leading zero value, 0x80 & 0x7F == 0 */
			validEncoding = FALSE;
			}
		if( isUUID )
			{
			value = 1;	/* Set up dummy value since we're bypassing normal read */
			if( uuidBitCount == 0 )
				uuidBuffer[ uuidBufPos ] = data << 1;
			else
				{
				if( uuidBufPos >= 0 )
					uuidBuffer[ uuidBufPos ] |= ( data & 0x7F ) >> ( 7 - uuidBitCount );
				uuidBufPos++;
				if( uuidBitCount < 7 )
					uuidBuffer[ uuidBufPos ] = data << ( uuidBitCount + 1 );
				}
			uuidBitCount++;
			if( uuidBitCount > 7 )
				uuidBitCount = 0;
			if( !( data & 0x80 ) )
				{
				/* The following check isn't completely accurate since we
				   could have less than 16 bytes present if there are
				   leading zeroes, however to handle this properly we'd
				   have to decode the entire value as a bignum and then
				   format it appropriately, and given the fact that the use
				   of these things is practically nonexistent it's probably
				   not worth the code space to deal with this */
				if( uuidBufPos != 16 )
					{
					validEncoding = FALSE;
					break;
					}
				length += sprintf( textOID + length,
								   " { %02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x }",
								   uuidBuffer[ 0 ], uuidBuffer[ 1 ],
								   uuidBuffer[ 2 ], uuidBuffer[ 3 ],
								   uuidBuffer[ 4 ], uuidBuffer[ 5 ],
								   uuidBuffer[ 6 ], uuidBuffer[ 7 ],
								   uuidBuffer[ 8 ], uuidBuffer[ 9 ],
								   uuidBuffer[ 10 ], uuidBuffer[ 11 ],
								   uuidBuffer[ 12 ], uuidBuffer[ 13 ],
								   uuidBuffer[ 14 ], uuidBuffer[ 15 ] );
				value = 0;
				}
			continue;
			}
		if( value >= ( LONG_MAX >> 7 ) || \
			valTmp >= LONG_MAX - ( data & 0x7F ) )
			{
			validEncoding = FALSE;
			break;
			}
		value = valTmp | ( data & 0x7F );
		if( value < 0 || value > LONG_MAX / 2 )
			{
			validEncoding = FALSE;
			break;
			}
		if( !( data & 0x80 ) )
			{
			if( length == 0 )
				{
				long x, y;

				/* The first two levels are encoded into one byte since the
				   root level has only 3 nodes (40*x + y), however if x =
				   joint-iso-itu-t(2) then y may be > 39, so we have to add
				   special-case handling for this */
				x = value / 40;
				y = value % 40;
				if( x > 2 )
					{
					/* Handle special case for large y if x == 2 */
					y += ( x - 2 ) * 40;
					x = 2;
					}
				if( x < 0 || x > 2 || y < 0 || \
					( ( x < 2 && y > 39 ) || \
					  ( x == 2 && ( y > 50 && y != 100 ) ) ) )
					{
					/* If x = 0 or 1 then y has to be 0...39, for x = 3
					   it can take any value but there are no known
					   assigned values over 50 except for one contrived
					   example in X.690 which sets y = 100, so if we see
					   something outside this range it's most likely an
					   encoding error rather than some bizarre new ID
					   that's just appeared */
					validEncoding = FALSE;
					break;
					}
				length = sprintf( textOID, "%ld %ld", x, y );

				/* A totally stupid ITU facility lets people register UUIDs
				   as OIDs (see https://www.itu.int/ITU-T/asn1/uuid.html), 
				   if we find one of these, which live under the arc '2 25' 
				   = 0x69 we have to continue decoding the OID as a UUID
				   instead of a standard OID */
				if( data == 0x69 )
					isUUID = TRUE;
				}
			else
				length += sprintf( textOID + length, " %ld", value );
			value = 0;
			}
		}
	if( value != 0 )
		{
		/* We stopped in the middle of a continued value */
		validEncoding = FALSE;
		}
	textOID[ length ] = '\0';
	*textOIDlength = length;

	return( validEncoding );
	}

/* Dump a bitstring, reversing the bits into the standard order in the
   process */

static void dumpBitString( FILE *inFile, const int length, const int unused,
						   const int level )
	{
	unsigned int bitString = 0, currentBitMask = 0x80, remainderMask = 0xFF;
	int bitFlag, value = 0, noBits, bitNo = -1, i;
	char *errorStr = NULL;

	if( unused < 0 || unused > 7 )
		complain( "Invalid number %d of unused bits", unused, level );
	noBits = ( length * 8 ) - unused;

	/* ASN.1 bitstrings start at bit 0, so we need to reverse the order of
	   the bits if necessary */
	if( length > 0 )
		{
		bitString = fgetc( inFile );
		if( bitString == EOF )
			{
			noBits = 0;
			errorStr = "Truncated BIT STRING data";
			}
		fPos++;
		}
	for( i = noBits - 8; i > 0; i -= 8 )
		{
		const int ch = fgetc( inFile );

		if( ch == EOF )
			{
			errorStr = "Truncated BIT STRING data";
			break;
			}
		bitString = ( bitString << 8 ) | ch;
		currentBitMask <<= 8;
		remainderMask = ( remainderMask << 8 ) | 0xFF;
		fPos++;
		}
	if( errorStr != NULL )
		{
		printString( level, "%c", '\n' );
		complain( errorStr, 0, level );
		return;
		}
	if( reverseBitString )
		{
		for( i = 0, bitFlag = 1; i < noBits; i++ )
			{
			if( bitString & currentBitMask )
				value |= bitFlag;
			if( !( bitString & remainderMask ) && errorStr == NULL )
				{
				/* The last valid bit should be a one bit */
				errorStr = "Spurious zero bits in bitstring";
				}
			bitFlag <<= 1;
			bitString <<= 1;
			}
		if( noBits < sizeof( int ) && \
			( ( remainderMask << noBits ) & value ) && \
			errorStr != NULL )
			{
			/* There shouldn't be any bits set after the last valid one.  We
			   have to do the noBits check to avoid a fencepost error when
			   there's exactly 32 bits */
			errorStr = "Spurious one bits in bitstring";
			}
		}
	else
		{
		value = bitString;
		if( !( bitString & ( 1 << unused ) ) && errorStr == NULL )
			{
			/* The last valid bit should be a one bit */
			errorStr = "Spurious zero bits in bitstring";
			}
		if( noBits < sizeof( int ) && \
			( ( 0xFF >> ( 8 - unused ) ) & value ) && \
			errorStr != NULL )
			{
			/* There shouldn't be any bits set after the last valid one.  We
			   have to do the noBits check to avoid a fencepost error when
			   there's exactly 32 bits */
			errorStr = "Spurious one bits in bitstring";
			}
		}

	/* Now that it's in the right order, dump it.  If there's only one bit
	   set (which is often the case for bit flags) we also print the bit
	   number to save users having to count the zeroes to figure out which
	   flag is set */
	printString( level, "%c", '\n' );
	if( !doPure )
		printString( level, "%s", INDENT_STRING );
	doIndent( level + 1 );
	printString( level, "%c", '\'' );
	if( reverseBitString )
		currentBitMask = 1 << ( noBits - 1 );
	for( i = 0; i < noBits; i++ )
		{
		if( value & currentBitMask )
			{
			bitNo = ( bitNo == -1 ) ? ( noBits - 1 ) - i : -2;
			printString( level, "%c", '1' );
			}
		else
			printString( level, "%c", '0' );
		currentBitMask >>= 1;
		}
	if( bitNo >= 0 )
		printString( level, "'B (bit %d)\n", bitNo );
	else
		printString( level, "%s", "'B\n" );

	if( errorStr != NULL )
		complain( errorStr, 0, level );
	}

/* Display data as a text string up to a maximum of 240 characters (8 lines
   of 48 chars to match the hex limit of 8 lines of 16 bytes) with special
   treatement for control characters and other odd things that can turn up
   in BMPString and UniversalString types.

   If the string is less than 40 chars in length, we try to print it on the
   same line as the rest of the text (even if it wraps), otherwise we break
   it up into 48-char chunks in a somewhat less nice text-dump format */

static void displayString( FILE *inFile, long length, int level,
						   const STR_OPTION strOption )
	{
	char timeStr[ 64 ];
	long noBytes = length;
	int lineLength = 48, i;
	int firstTime = TRUE, doTimeStr = FALSE, warnIA5 = FALSE;
	int warnPrintable = FALSE, warnTime = FALSE, warnBMP = FALSE;
	int warnTimeT = FALSE, warnTimeCrazy = FALSE, warnTimeCrazyAlt = FALSE;

	if( noBytes > 384 && !printAllData )
		noBytes = 384;	/* Only output a maximum of 384 bytes */
	if( strOption == STR_UTCTIME || strOption == STR_GENERALIZED )
		{
		if( ( strOption == STR_UTCTIME && length != 13 ) || \
			( strOption == STR_GENERALIZED && length != 15 ) )
			warnTime = TRUE;
		else
			doTimeStr = rawTimeString ? FALSE : TRUE;
		}
	if( !doTimeStr && length <= 40 )
		printString( level, "%s", " '" );	/* Print string on same line */
	level = adjustLevel( level, ( doPure ) ? 15 : 8 );
	for( i = 0; i < noBytes; i++ )
		{
		int ch;

		/* If the string is longer than 40 chars, break it up into multiple
		   sections */
		if( length > 40 && !( i % lineLength ) )
			{
			if( !firstTime )
				printString( level, "%c", '\'' );
			printString( level, "%c", '\n' );
			if( !doPure )
				printString( level, "%s", INDENT_STRING );
			doIndent( level + 1 );
			printString( level, "%c", '\'' );
			firstTime = FALSE;
			}
		ch = getc( inFile );
		if( ch == EOF )
			{
			complainEOF( level, noBytes - i );
			return;
			}
#if defined( __WIN32__ ) || defined( __UNIX__ ) || defined( __OS390__ )
		if( strOption == STR_BMP )
			{
			wchar_t wChBuf[ 2 ];

			if( i == noBytes - 1 && ( noBytes & 1 ) )
				{
				/* Odd-length BMP string, complain */
				warnBMP = TRUE;
				}
			else
				{
				wChBuf[ 0 ] = ( ch << 8 ) | getc( inFile );
				wChBuf[ 1 ] = 0;
				if( displayUnicode( wChBuf, level ) )
					{
					lineLength++;
					i++;	/* We've read two characters for a wchar_t */
					fPos += 2;
					continue;
					}

				/* The value can't be displayed as Unicode, fall back to
				   displaying it as normal text */
				ungetc( wChBuf[ 0 ] & 0xFF, inFile );
				}
			}
		if( strOption == STR_UTF8 && ( ch & 0x80 ) )
			{
			wchar_t wChBuf[ 2 ];
			const int secondCh = getc( inFile );

			/* It's a multibyte UTF8 character, read it as a widechar */
			if( ( ch & 0xE0 ) == 0xC0 )		/* 111xxxxx -> 110xxxxx */
				{
				/* 2-byte character in the range 0x80...0x7FF */
				wChBuf[ 0 ] = ( ( ch & 0x1F ) << 6 ) | ( secondCh & 0x3F );
				i++;		/* We've read 2 characters */
				fPos += 2;
				}
			else
				{
				if( ( ch & 0xF0 ) == 0xE0 )	/* 1111xxxx -> 1110xxxx */
					{
					const int thirdCh = getc( inFile );

					/* 3-byte character in the range 0x800...0xFFFF */
					wChBuf[ 0 ] = ( ( ch & 0x1F ) << 12 ) | \
								  ( ( secondCh & 0x3F ) << 6 ) | \
									( thirdCh & 0x3F );
					}
				else
					{
					wChBuf[ 0 ] = '.';
					}
				i += 2;		/* We've read 3 characters */
				fPos += 3;
				}
			wChBuf[ 1 ] = 0;
			if( !displayUnicode( wChBuf, level ) )
				printString( level, "%lc", wChBuf );
			lineLength++;
			continue;
			}
#endif /* __WIN32__ || __UNIX__ || __OS390__ */
		switch( strOption )
			{
			case STR_PRINTABLE:
			case STR_IA5:
			case STR_LATIN1:
				if( strOption == STR_PRINTABLE && !isPrintable( ch ) )
					warnPrintable = TRUE;
				if( strOption == STR_IA5 && !isIA5( ch ) )
					warnIA5 = TRUE;
				if( strOption == STR_LATIN1 )
					{
					if( !isprint( ch & 0x7F ) )
						ch = '.';	/* Convert non-ASCII to placeholders */
					}
				else
					{
					if( !isprint( ch ) )
						ch = '.';	/* Convert non-ASCII to placeholders */
					}
#ifdef __OS390__
				ch = asciiToEbcdic( ch );
#endif /* __OS390__ */
				break;

			case STR_UTCTIME:
			case STR_GENERALIZED:
				if( !isdigit( ch ) && ch != 'Z' )
					{
					warnTime = TRUE;
					if( !isprint( ch ) )
						ch = '.';	/* Convert non-ASCII to placeholders */
					}
#ifdef __OS390__
				ch = asciiToEbcdic( ch );
#endif /* __OS390__ */
				break;

			case STR_BMP_REVERSED:
				if( i == noBytes - 1 && ( noBytes & 1 ) )
					{
					/* Odd-length BMP string, complain */
					warnBMP = TRUE;
					}

				/* Wrong-endianness BMPStrings (Microsoft Unicode) can't be
				   handled through the usual widechar-handling mechanism
				   above since the first widechar looks like an ASCII char
				   followed by a null terminator, so we just treat them as
				   ASCII chars, skipping the following zero byte.  This is
				   safe since the code that detects reversed BMPStrings
				   has already checked that every second byte is zero */
				getc( inFile );
				i++;
				fPos++;
				/* Fall through */

			default:
				if( !isprint( ch ) )
					ch = '.';	/* Convert control chars to placeholders */
#ifdef __OS390__
				ch = asciiToEbcdic( ch );
#endif /* __OS390__ */
			}
		if( doTimeStr )
			timeStr[ i ] = ch;
		else
			printString( level, "%c", ch );
		fPos++;
		}
	if( length > 384 && !printAllData )
		{
		length -= 384;
		printString( level, "%s", "'\n" );
		if( !doPure )
			printString( level, "%s", INDENT_STRING );
		doIndent( level + 5 );
		printString( level, "[ Another %ld characters skipped ]", length );
		fPos += length;
		while( length-- )
			{
			int ch = getc( inFile );

			if( ch == EOF )
				{
				complainEOF( level, length );
				return;
				}
			if( strOption == STR_PRINTABLE && !isPrintable( ch ) )
				warnPrintable = TRUE;
			if( strOption == STR_IA5 && !isIA5( ch ) )
				warnIA5 = TRUE;
			}
		}
	else
		{
		if( doTimeStr )
			{
			const char *timeStrPtr = ( strOption == STR_UTCTIME ) ? \
									 timeStr : timeStr + 2;

			printString( level, " %c%c/%c%c/",
						 timeStrPtr[ 4 ], timeStrPtr[ 5 ],
						 timeStrPtr[ 2 ], timeStrPtr[ 3 ] );
			if( strOption == STR_UTCTIME )
				{
				/* No centuries, timeStrPtr = timeStr */
				printString( level, "%s",
							 ( timeStr[ 0 ] < '5' ) ? "20" : "19" );
				if( ( timeStrPtr[ 0 ] == '3' && timeStrPtr[ 1 ] >= '8' ) || \
					( timeStrPtr[ 0 ] == '4' ) )
					{
					/* UTCTimes starting with '0' - '4' are 20xx, '5'-'9'  
					   are 19xx */
					warnTimeT = TRUE;
					}
				}
			else
				{
				/* Centuries, timeStrPtr = timeStr + 2 */
				printString( level, "%c%c", timeStr[ 0 ], timeStr[ 1 ] );
				if( ( timeStrPtr[ 0 ] == '3' && timeStrPtr[ 1 ] >= '8' ) || \
					( timeStrPtr[ 0 ] >= '4' ) )
					{
					/* GeneralizedTimes include centuries so anything past 
					   '38' will be 20xx */
					warnTimeT = TRUE;
					}
				if( timeStr[ 0 ] == '2' && timeStr[ 1 ] >= '1' )
					{
					/* There actually are certificates like this out 
					   there... */
					warnTimeT = warnTimeCrazy = TRUE;
					}
				if( timeStrPtr[ 0 ] >= '7' )
					warnTimeCrazy = warnTimeCrazyAlt = TRUE;
				}
			printString( level, "%c%c %c%c:%c%c:%c%c GMT",
						 timeStrPtr[ 0 ], timeStrPtr[ 1 ], timeStrPtr[ 6 ],
						 timeStrPtr[ 7 ], timeStrPtr[ 8 ], timeStrPtr[ 9 ],
						 timeStrPtr[ 10 ], timeStrPtr[ 11 ] );
			}
		else
			printString( level, "%c", '\'' );
		}
	printString( level, "%c", '\n' );

	/* Display any problems we encountered */
	if( warnPrintable )
		complain( "PrintableString contains illegal character(s)", 0, level );
	if( warnIA5 )
		complain( "IA5String contains illegal character(s)", 0, level );
	if( warnTime )
		complain( "Time is encoded incorrectly", 0, level );
	if( warnTimeT )
		warn( "Time value cannot be represented in a 32-bit time_t", 0, level );
	if( warnTimeCrazy )
		{
		complain( warnTimeCrazyAlt ? \
				  "Time value is either more than twenty years in the past or "
						"more than half a century in the future" : \
				  "Time value is more than half a century in the future", 0, level );
		}
	if( warnBMP )
		complain( "BMPString has missing final byte/half character", 0, level );
	}

/****************************************************************************
*																			*
*								ASN.1 Parsing Routines						*
*																			*
****************************************************************************/

/* Get an ASN.1 object's tag and length.  Returns TRUE for an item
   available, FALSE for end-of-data, and a negative value for an invalid
   data */

static int getItem( FILE *inFile, ASN1_ITEM *item )
	{
	int tag, length, index = 0;

	memset( item, 0, sizeof( ASN1_ITEM ) );
	item->indefinite = FALSE;
	tag = fgetc( inFile );
	if( tag == EOF )
		return( FALSE );
	item->header[ index++ ] = tag;
	fPos++;
	item->id = tag & ~TAG_MASK;
	tag &= TAG_MASK;
	if( tag == TAG_MASK )
		{
		int value;

		/* Long tag encoded as sequence of 7-bit values.  This doesn't try to
		   handle tags > INT_MAX, it'd be pretty peculiar ASN.1 if it had to
		   use tags this large */
		tag = 0;
		do
			{
			value = fgetc( inFile );
			if( value == EOF )
				return( FALSE );
			tag = ( tag << 7 ) | ( value & 0x7F );
			item->header[ index++ ] = value;
			fPos++;
			}
		while( value & LEN_XTND && index < 5 && !feof( inFile ) );
		if( index >= 5 )
			return( FALSE );
		}
	item->tag = tag;
	length = fgetc( inFile );
	if( length == EOF )
		return( FALSE );
	fPos++;
	item->header[ index++ ] = length;
	item->headerSize = index;
	if( length & LEN_XTND )
		{
		const int lengthStart = index;
		int i;

		length &= LEN_MASK;
		if( length > 4 )
			{
			/* Impossible length value, probably because we've run into
			   the weeds */
			return( -1 );
			}
		item->headerSize += length;
		item->length = 0;
		if( !length )
			item->indefinite = TRUE;
		for( i = 0; i < length; i++ )
			{
			int ch = fgetc( inFile );

			if( ch == EOF )
				{
				fPos += length - i;
				return( FALSE );
				}
			item->length = ( item->length << 8 ) | ch;
			item->header[ i + index ] = ch;
			}
		fPos += length;

		/* Check for the length being less then 128, which means it
		   shouldn't be encoded as a long length */
		if( !item->indefinite && item->length < 128 )
			item->nonCanonical = lengthStart;

		/* Check for the first 9 bits of the length being identical and
		   if they are, remember where the encoded non-canonical length
		   starts */
		if( item->headerSize - lengthStart > 1 )
			{
			if( ( item->header[ lengthStart ] == 0x00 ) && \
				( ( item->header[ lengthStart + 1 ] & 0x80 ) == 0x00 ) )
				item->nonCanonical = lengthStart - 1;
			if( ( item->header[ lengthStart ] == 0xFF ) && \
				( ( item->header[ lengthStart + 1 ] & 0x80 ) == 0x80 ) )
				item->nonCanonical = lengthStart - 1;
			}
		}
	else
		item->length = length;

	return( TRUE );
	}

/* Check whether a BIT STRING or OCTET STRING encapsulates another object */

static int checkEncapsulate( FILE *inFile, const int length )
	{
	ASN1_ITEM nestedItem;
	const int currentPos = fPos;
	int diffPos, status;

	/* If we're not looking for encapsulated objects, return */
	if( !checkEncaps )
		return( FALSE );

	/* An item of length < 2 can never have encapsulated data.  Even for
	   length 2 it can only be an encapsulated NULL, which is somewhat odd,
	   but no doubt there's some PKI protocol somewhere that does this */
	if( length < 2 )
		return( FALSE );

	/* Read the details of the next item in the input stream */
	status = getItem( inFile, &nestedItem );
	diffPos = fPos - currentPos;
	fPos = currentPos;
	fseek( inFile, -diffPos, SEEK_CUR );
	if( status <= 0 )
		return( FALSE );

	/* If it's not a standard tag class, don't try and dig down into it */
	if( ( nestedItem.id & CLASS_MASK ) != UNIVERSAL && \
		( nestedItem.id & CLASS_MASK ) != CONTEXT )
		return( FALSE );

	/* There is one special-case situation that overrides the check below,
	   which is when the nested content is indefinite-length.  This is
	   rather tricky to check for because we'd need to read some distance
	   ahead into the stream to be able to safely decide whether we've got
	   true nested content or a false positive, for now we require that
	   the nested content has to be a SEQUENCE containing valid ASN.1 at
	   the start, giving about 24 bits of checking.  There's a small risk
	   of false negatives for encapsulated primitive items, but since
	   they're primitive it should be relatively easy to make out the
	   contents inside the OCTET STRING */
	if( nestedItem.tag == SEQUENCE && nestedItem.indefinite )
		{
		/* Skip the indefinite-length SEQUENCE and make sure that it's
		   followed by a valid item */
		status = getItem( inFile, &nestedItem );
		if( status > 0 )
			status = getItem( inFile, &nestedItem );
		diffPos = fPos - currentPos;
		fPos = currentPos;
		fseek( inFile, -diffPos, SEEK_CUR );
		if( status <= 0 )
			return( FALSE );

		/* If the tag on the nest item looks vaguely valid, assume that we've
		   go nested content */
		if( ( nestedItem.tag <= 0 || nestedItem.tag > 0x31 ) || \
			( nestedItem.length >= length ) )
			return( FALSE );
		return( TRUE );
		}

	/* If it doesn't fit exactly within the current item it's not an
	   encapsulated object */
	if( nestedItem.length != length - diffPos )
		return( FALSE );

	/* If it doesn't have a valid-looking tag, don't try and go any further */
	if( nestedItem.tag <= 0 || nestedItem.tag > 0x31 )
		return( FALSE );

	/* Now things get a bit complicated because it's possible to get some
	   (very rare) false positives, for example if a NUMERICSTRING of
	   exactly the right length is nested within an OCTET STRING, since
	   numeric values all look like constructed tags of some kind.  To
	   handle this we look for nested constructed items that should really
	   be primitive */
	if( ( nestedItem.id & FORM_MASK ) == PRIMITIVE )
		return( TRUE );

	/* It's constructed, make sure that it's something for which it makes
	   sense as a constructed object.  At worst this will give some false
	   negatives for really wierd objects (nested constructed strings inside
	   OCTET STRINGs), but these should probably never occur anyway */
	if( nestedItem.tag == SEQUENCE || \
		nestedItem.tag == SET )
		return( TRUE );

	return( FALSE );
	}

/* Check whether a zero-length item is OK */

static int zeroLengthOK( const ASN1_ITEM *item )
	{
	/* An implicitly-tagged NULL can have a zero length.  An occurrence of this
	   type of item is almost always an error, however OCSP uses a weird status
	   encoding that encodes result values in tags and then has to use a NULL
	   value to indicate that there's nothing there except the tag that encodes
	   the status, so we allow this as well if zero-length content is explicitly
	   enabled */
	if( zeroLengthAllowed && ( item->id & CLASS_MASK ) == CONTEXT )
		return( TRUE );

	/* If we can't recognise the type from the tag, reject it */
	if( ( item->id & CLASS_MASK ) != UNIVERSAL )
		return( FALSE );

	/* The following types are zero-length by definition */
	if( item->tag == EOC || item->tag == NULLTAG )
		return( TRUE );

	/* A real with a value of zero has zero length */
	if( item->tag == REAL )
		return( TRUE );

	/* Everything after this point requires input from the user to say that
	   zero-length data is OK (usually it's not, so we flag it as a
	   problem) */
	if( !zeroLengthAllowed )
		return( FALSE );

	/* String types can have zero length except for the Unrestricted
	   Character String type ([UNIVERSAL 29]) which has to have at least one
	   octet for the CH-A/CH-B index */
	if( item->tag == OCTETSTRING || item->tag == NUMERICSTRING || \
		item->tag == PRINTABLESTRING || item->tag == T61STRING || \
		item->tag == VIDEOTEXSTRING || item->tag == VISIBLESTRING || \
		item->tag == IA5STRING || item->tag == GRAPHICSTRING || \
		item->tag == GENERALSTRING || item->tag == UNIVERSALSTRING || \
		item->tag == BMPSTRING || item->tag == UTF8STRING || \
		item->tag == OBJDESCRIPTOR )
		return( TRUE );

	/* SEQUENCE and SET can be zero if there are absent optional/default
	   components */
	if( item->tag == SEQUENCE || item->tag == SET )
		return( TRUE );

	return( FALSE );
	}

/* Check whether the next item looks like text */

static STR_OPTION checkForText( FILE *inFile, const int length )
	{
	char buffer[ 16 ];
	int isBMP = FALSE, isUnicode = FALSE;
	int sampleLength = min( length, 16 ), i;

	/* If the sample is very short, we're more careful about what we
	   accept */
	if( sampleLength < 4 )
		{
		/* If the sample size is too small, don't try anything */
		if( sampleLength <= 2 )
			return( STR_NONE );

		/* For samples of 3-4 characters we only allow ASCII text.  These
		   short strings are used in some places (eg PKCS #12 files) as
		   IDs */
		sampleLength = fread( buffer, 1, sampleLength, inFile );
		if( sampleLength <= 0 )
			return( STR_NONE );
		fseek( inFile, -sampleLength, SEEK_CUR );
		for( i = 0; i < sampleLength; i++ )
			{
			const int ch = byteToInt( buffer[ i ] );

			if( !( isalpha( ch ) || isdigit( ch ) || isspace( ch ) ) )
				return( STR_NONE );
			}
		return( STR_IA5 );
		}

	/* Check for ASCII-looking text */
	sampleLength = fread( buffer, 1, sampleLength, inFile );
	if( sampleLength <= 0 )
		return( STR_NONE );
	fseek( inFile, -sampleLength, SEEK_CUR );
	if( isdigit( byteToInt( buffer[ 0 ] ) ) && \
		( length == 13 || length == 15 ) && \
		buffer[ length - 1 ] == 'Z' )
		{
		/* It looks like a time string, make sure that it really is one */
		for( i = 0; i < length - 1; i++ )
			{
			if( !isdigit( byteToInt( buffer[ i ] ) ) )
				break;
			}
		if( i == length - 1 )
			return( ( length == 13 ) ? STR_UTCTIME : STR_GENERALIZED );
		}
	for( i = 0; i < sampleLength; i++ )
		{
		/* If even bytes are zero, it could be a BMPString.  Initially
		   we set isBMP to FALSE, if it looks like a BMPString we set it to
		   TRUE, if we then encounter a nonzero byte it's neither an ASCII
		   nor a BMPString */
		if( !( i & 1 ) )
			{
			if( !buffer[ i ] )
				{
				/* If we thought we were in a Unicode string but we've found a
				   zero byte where it'd occur in a BMP string, it's neither a
				   Unicode nor BMP string */
				if( isUnicode )
					return( STR_NONE );

				/* We've collapsed the eigenstate (in an earlier incarnation
				   isBMP could take values of -1, 0, or 1, with 0 being
				   undecided, in which case this comment made a bit more
				   sense) */
				if( i < sampleLength - 2 )
					{
					/* If the last char(s) are zero but preceding ones
					   weren't, don't treat it as a BMP string.  This can
					   happen when storing a null-terminated string if the
					   implementation gets the length wrong and stores the
					   null as well */
					isBMP = TRUE;
					}
				continue;
				}
			else
				{
				/* If we thought we were in a BMPString but we've found a
				   nonzero byte where there should be a zero, it's neither
				   an ASCII nor BMP string */
				if( isBMP )
					return( STR_NONE );
				}
			}
		else
			{
			/* Just to make it tricky, Microsoft stuff Unicode strings into
			   some places (to avoid having to convert them to BMPStrings,
			   presumably) so we have to check for these as well */
			if( !buffer[ i ] )
				{
				if( isBMP )
					return( STR_NONE );
				isUnicode = TRUE;
				continue;
				}
			else
				{
				if( isUnicode )
					return( STR_NONE );
				}
			}
		if( buffer[ i ] < 0x20 || buffer[ i ] > 0x7E )
			return( STR_NONE );
		}

	/* It looks like a text string */
	return( isUnicode ? STR_BMP_REVERSED : isBMP ? STR_BMP : STR_IA5 );
	}

/* Dump the header bytes for an object, useful for vgrepping the original
   object from a hex dump */

static void dumpHeader( FILE *inFile, const ASN1_ITEM *item, const int level )
	{
	int extraLen = 24 - item->headerSize, i;

	/* Dump the tag and length bytes */
	if( !doPure )
		printString( level, "%s", "    " );
	printString( level, "<%02X", *item->header );
	for( i = 1; i < item->headerSize; i++ )
		printString( level, " %02X", item->header[ i ] );

	/* If we're asked for more, dump enough extra data to make up 24 bytes.
	   This is somewhat ugly since it assumes we can seek backwards over the
	   data, which means it won't always work on streams */
	if( extraLen > 0 && doDumpHeader > 1 )
		{
		/* Make sure that we don't print too much data.  This doesn't work
		   for indefinite-length data, we don't try and guess the length with
		   this since it involves picking apart what we're printing */
		if( extraLen > item->length && !item->indefinite )
			extraLen = ( int ) item->length;

		for( i = 0; i < extraLen; i++ )
			{
			const int ch = fgetc( inFile );

			if( ch == EOF )
				{
				/* Exit loop and get fseek() offset correct */
				extraLen = i;
				break;
				}
			printString( level, " %02X", ch );
			}
		fseek( inFile, -extraLen, SEEK_CUR );
		}

	printString( level, "%s", ">\n" );
	}

/* Print a constructed ASN.1 object */

static int printAsn1( FILE *inFile, const int level, long length,
					  const int isIndefinite );

static void markConstructed( const int level, const ASN1_ITEM *item )
	{
	/* If it's a type that's not normally constructed, tag it as such */
	if( item->id == BOOLEAN || item->id == INTEGER || \
		item->id == BITSTRING || item->id == OCTETSTRING || \
		item->id == ENUMERATED	|| item->id == UTF8STRING || \
		( item->id >= NUMERICSTRING && item->id <= BMPSTRING ) )
		printString( level, "%s", " (constructed)" );
	}

static void printConstructed( FILE *inFile, int level, const ASN1_ITEM *item )
	{
	int result;

	/* Special case for zero-length objects */
	if( !item->length && !item->indefinite )
		{
		printString( level, "%s", " {}\n" );
		if( item->nonCanonical )
			complainLengthCanonical( item, level );
		return;
		}

	printString( level, "%s", " {\n" );
	if( item->nonCanonical )
		complainLengthCanonical( item, level );
	result = printAsn1( inFile, level + 1, item->length, item->indefinite );
	if( result )
		{
		fprintf( output, "Error: Inconsistent object length, %d byte%s "
				 "difference.\n", result, ( result > 1 ) ? "s" : "" );
		noErrors++;
		}
	if( !doPure )
		printString( level, "%s", INDENT_STRING );
	printString( level, "%s", ( printDots ) ? ". " : "  " );
	doIndent( level );
	printString( level, "%s", "}\n" );
	}

/* Print a single ASN.1 object */

static void printASN1object( FILE *inFile, ASN1_ITEM *item, int level )
	{
	OIDINFO *oidInfo;
	STR_OPTION stringType;
	BYTE buffer[ MAX_OID_SIZE ];
	const int nonOutlineObject = \
			( doOutlineOnly && ( item->id & FORM_MASK ) != CONSTRUCTED ) ? \
			TRUE : FALSE;
	int ch;

	if( ( item->id & CLASS_MASK ) != UNIVERSAL )
		{
		static const char *const classtext[] =
			{ "UNIVERSAL ", "APPLICATION ", "", "PRIVATE " };

		/* Print the object type */
		if( !nonOutlineObject )
			{
			printString( level, "[%s%d]",
						 classtext[ ( item->id & CLASS_MASK ) >> 6 ], item->tag );
			}

		/* Perform a sanity check */
		if( ( item->tag != NULLTAG ) && ( item->length < 0 ) )
			{
			int i;

			fflush( stdout );
			fprintf( stderr, "\nError: Object has bad length field, tag = %02X, "
					 "length = %lX, value =", item->tag, item->length );
			fprintf( stderr, "<%02X", *item->header );
			for( i = 1; i < item->headerSize; i++ )
				fprintf( stderr, " %02X", item->header[ i ] );
			fputs( ">.\n", stderr );
			exit( EXIT_FAILURE );
			}

		if( !item->length && !item->indefinite && !zeroLengthOK( item ) )
			{
			printString( level, "%c", '\n' );
			complain( "Object has zero length", 0, level );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			return;
			}

		/* If it's constructed, print the various fields in it */
		if( ( item->id & FORM_MASK ) == CONSTRUCTED )
			{
			markConstructed( level, item );
			printConstructed( inFile, level, item );
			return;
			}

		/* It'sprimitive, if we're only displaying the ASN.1 in outline
		   form, supress the display by dumping it with a nesting level that
		   ensures it won't get output (this clears the data from the input
		   without displaying it) */
		if( nonOutlineObject )
			{
			dumpHex( inFile, item->length, 1000, DUMPHEX_NORMAL, 0 );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			printString( level, "%c", '\n' );
			return;
			}

		/* It's primitive, if it's a seekable stream try and determine
		   whether it's text so we can display it as such */
		if( !useStdin && \
			( stringType = checkForText( inFile, item->length ) ) != STR_NONE )
			{
			/* It looks like a text string, dump it as text */
			displayString( inFile, item->length, level, stringType );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			return;
			}

		/* This could be anything, dump it as hex data */
		dumpHex( inFile, item->length, level, DUMPHEX_NORMAL, 0 );
		if( item->nonCanonical )
			complainLengthCanonical( item, level );

		return;
		}

	/* Print the object type */
	if( !doOutlineOnly || ( item->id & FORM_MASK ) == CONSTRUCTED )
		printString( level, "%s", idstr( item->tag ) );

	/* Perform a sanity check */
	if( ( item->tag != NULLTAG ) && ( item->length < 0 ) )
		{
		int i;

		fflush( stdout );
		fprintf( stderr, "\nError: Object has bad length field, tag = %02X, "
				 "length = %lX, value =", item->tag, item->length );
		fprintf( stderr, "<%02X", *item->header );
		for( i = 1; i < item->headerSize; i++ )
			fprintf( stderr, " %02X", item->header[ i ] );
		fputs( ">.\n", stderr );
		exit( EXIT_FAILURE );
		}

	/* If it's constructed, print the various fields in it */
	if( ( item->id & FORM_MASK ) == CONSTRUCTED )
		{
		markConstructed( level, item );
		printConstructed( inFile, level, item );
		return;
		}

	/* It's primitive */
	if( doOutlineOnly )
		{
		/* If we're only displaying the ASN.1 in outline form, set an
		   artificially high nesting level that ensures it won't get output
		   (this clears the data from the input without displaying it) */
		level = 1000;
		}
	if( !item->length && !zeroLengthOK( item ) )
		{
		printString( level, "%c", '\n' );
		complain( "Object has zero length", 0, level );
		if( item->nonCanonical )
			complainLengthCanonical( item, level );
		return;
		}
	switch( item->tag )
		{
		case BOOLEAN:
			if( item->length != 1 )
				complainLength( item, level );
			ch = getc( inFile );
			if( ch == EOF )
				{
				complainEOF( level, 1 );
				return;
				}
			printString( level, " %s\n", ch ? "TRUE" : "FALSE" );
			if( ch != 0 && ch != 0xFF )
				{
				complain( "BOOLEAN '%02X' has non-DER encoding", ch,
						  level );
				}
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			fPos++;
			break;

		case INTEGER:
		case ENUMERATED:
			if( item->length > 4 )
				{
				dumpHex( inFile, item->length, level, DUMPHEX_INTEGER, 0 );
				if( item->nonCanonical )
					complainLengthCanonical( item, level );
				}
			else
				{
				printValue( inFile, item->length, level );
				if( item->nonCanonical )
					complainLengthCanonical( item, level );
				}
			break;

		case BITSTRING:
			if( item->length < 1 )
				{
				/* A bitstring always has to contain at least one byte, the unused-bits 
				   count */
				complainLength( item, level );
				}
			if( ( ch = getc( inFile ) ) != 0 )
				{
				if( ch == EOF )
					{
					complainEOF( level, item->length );
					return;
					}
				printString( level, " %d unused bit%s",
							 ch, ( ch != 1 ) ? "s" : "" );
				if( item->length <= 1 )
					{
					complain( "Empty BIT STRING has non-zero unused-bits "
							  "value", 0, level );
					return;
					}
				}
			item->length--;
			fPos++;
			if( item->length <= 0 )
				{
				printString( level, " %s\n", "(no bits set)" );
				if( item->nonCanonical )
					complainLengthCanonical( item, level );
				return;
				}
			if( item->length <= sizeof( int ) )
				{
				/* It's short enough to be a bit flag, dump it as a sequence
				   of bits */
				dumpBitString( inFile, ( int ) item->length, ch, level );
				if( item->nonCanonical )
					complainLengthCanonical( item, level );
				break;
				}
			/* Fall through to dump it as an octet string */

		case OCTETSTRING:
			if( checkEncapsulate( inFile, item->length ) )
				{
				/* It's something encapsulated inside the string, print it as
				   a constructed item */
				printString( level, "%s", ", encapsulates" );
				printConstructed( inFile, level, item );
				break;
				}
			if( !useStdin && !dumpText && \
				( stringType = checkForText( inFile, item->length ) ) != STR_NONE )
				{
				/* If we'd be doing a straight hex dump and it looks like
				   encapsulated text, display it as such.  If the user has
				   overridden character set type checking and it's a string
				   type for which we normally perform type checking, we reset
				   its type to none */
				displayString( inFile, item->length, level, \
					( !checkCharset && ( stringType == STR_IA5 || \
										 stringType == STR_PRINTABLE ) ) ? \
					STR_NONE : stringType );
				if( item->nonCanonical )
					complainLengthCanonical( item, level );
				return;
				}
			if( item->tag == BITSTRING )
				dumpHex( inFile, item->length, level, DUMPHEX_BITSTRING, ch );
			else
				dumpHex( inFile, item->length, level, DUMPHEX_NORMAL, 0 );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;

		case OID:
			{
			char textOID[ 128 ];
			int length, isValid;

			/* Hierarchical Object Identifier */
			if( item->length <= 0 || item->length >= MAX_OID_SIZE )
				{
				fflush( stdout );
				fprintf( stderr, "\nError: Object identifier length %ld too "
						 "large.\n", item->length );
				exit( EXIT_FAILURE );
				}
			length = fread( buffer, 1, ( size_t ) item->length, inFile );
			fPos += item->length;
			if( item->length < 3 )
				{
				fputs( ".\n", output );
				complainLength( item, level );
				break;
				}
			if( length < item->length )
				{
				fputs( ".\n", output );
				complain( "Invalid OID data", 0, level );
				break;
				}
			if( ( oidInfo = getOIDinfo( buffer, ( int ) item->length ) ) != NULL )
				{
				/* Convert the binary OID to text form */
				isValid = oidToString( textOID, &length, buffer,
									   ( int ) item->length );

				/* Check if LHS status info + indent + "OID " string + oid
				   name + "(" + oid value + ")" will wrap */
				if( ( ( doPure ) ? 0 : INDENT_SIZE ) + ( level * 2 ) + 18 + \
					strlen( oidInfo->description ) + 2 + length >= outputWidth )
					{
					printString( level, "%c", '\n' );
					if( !doPure )
						printString( level, "%s", INDENT_STRING );
					doIndent( level + 1 );
					}
				else
					printString( level, "%c", ' ' );
				printString( level, "%s (%s)\n", oidInfo->description, textOID );

				/* Display extra comments about the OID if required */
				if( extraOIDinfo && oidInfo->comment != NULL )
					{
					if( !doPure )
						printString( level, "%s", INDENT_STRING );
					doIndent( level + 1 );
					printString( level, "(%s)\n", oidInfo->comment );
					}
				if( !isValid )
					complain( "OID has invalid encoding", 0, level );
				if( item->nonCanonical )
					complainLengthCanonical( item, level );

				/* If there's a warning associated with this OID, remember
				   that there was a problem */
				if( oidInfo->warn )
					noWarnings++;

				break;
				}

			/* Print the OID as a text string */
			isValid = oidToString( textOID, &length, buffer,
								   ( int ) item->length );
			printString( level, " '%s'\n", textOID );
			if( isValid )
				{
				if( item->length > MAX_SANE_OID_SIZE )
					{
					/* This typically only occurs with Microsoft's "encode 
					   random noise and call it an OID" values, so we warn 
					   about the fact that it's not really an OID */
					complain( "OID contains random garbage", 0, level );
					}
				}			
			else
				complain( "OID has invalid encoding", 0, level );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;
			}

		case EOC:
			printString( level, "<<EOC>> %c", '\n' );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;

		case NULLTAG:
			printString( level, "%c", '\n' );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;

		case OBJDESCRIPTOR:
		case GRAPHICSTRING:
		case VISIBLESTRING:
		case GENERALSTRING:
		case UNIVERSALSTRING:
		case NUMERICSTRING:
		case VIDEOTEXSTRING:
		case PRINTABLESTRING:
			displayString( inFile, item->length, level, STR_PRINTABLE );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;
		case UTF8STRING:
			displayString( inFile, item->length, level, STR_UTF8 );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;
		case BMPSTRING:
			displayString( inFile, item->length, level, STR_BMP );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;
		case UTCTIME:
			displayString( inFile, item->length, level, STR_UTCTIME );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;
		case GENERALIZEDTIME:
			displayString( inFile, item->length, level, STR_GENERALIZED );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;
		case IA5STRING:
			displayString( inFile, item->length, level, STR_IA5 );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;
		case T61STRING:
			displayString( inFile, item->length, level, STR_LATIN1 );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			break;

		case SEQUENCE:
			printString( level, "%c", '\n' );
			complain( "SEQUENCE has invalid primitive encoding", 0, level );
			break;

		case SET:
			printString( level, "%c", '\n' );
			complain( "SET has invalid primitive encoding", 0, level );
			break;

		default:
			printString( level, "%c", '\n' );
			if( !doPure )
				printString( level, "%s", INDENT_STRING );
			doIndent( level + 1 );
			printString( level, "%s",
						 "Unrecognised primitive, hex value is:");
			dumpHex( inFile, item->length, level, DUMPHEX_NORMAL, 0 );
			if( item->nonCanonical )
				complainLengthCanonical( item, level );
			noErrors++;		/* Treat it as an error */
		}
	}

/* Print a complex ASN.1 object */

static long processObjectStart( FILE *inFile, const ASN1_ITEM *item )
	{
	long length = LENGTH_MAGIC;

	/* If the length isn't known and the item has a definite length, set the
	   length to the item's length */
	if( !item->indefinite )
		{
		length = item->headerSize + item->length;

		/* We can also adjust the width of the informational data column to
		   maximise the amount of screen real estate (for lengths less than
		   the default of four) or get rid of oversized columns (for lengths
		   greater than four) */
		if( length < 1000 )
			infoWidth = 3;
		else
		if( length > 9999999 )
			infoWidth = 8;
		else
		if( length > 999999 )
			infoWidth = 7;
		else
		if( length > 99999 )
			infoWidth = 6;
		else
		if( length > 9999 )
			infoWidth = 5;
		}

	/* If the input isn't seekable, turn off some options that require the
	   use of fseek().  This check isn't perfect (some streams are slightly
	   seekable due to buffering) but it's better than nothing.
	   
	   This is complicated by a problem under Windows for which running 
	   things in pipe mode is pretty erratic, in particular using fseek()
	   below results in all subsequent reads returning EOF.  To try and
	   ameliorate this we first try other checks to see if we're using 
	   stdin before trying the fseek() check */
#ifdef __WIN32__
	if( useStdin || inFile == stdin || \
		fseek( inFile, -item->headerSize, SEEK_CUR ) )
#else
	if( fseek( inFile, -item->headerSize, SEEK_CUR ) )
#endif /* __WIN32__ */
		{
		useStdin = TRUE;
		checkEncaps = FALSE;
		if( !noWarnStdin )
			{
			puts( "Warning: Input is non-seekable, some functionality has "
				  "been disabled." );
			}

		return( length );
		}

	/* If it looks like we've been given a text file, typically due to the
	   input being base64-encoded, check whether it is all text */
	if( ( isalnum( item->header[ 0 ] ) && isalnum( item->header[ 1 ] ) ) || \
		  ( item->header[ 0 ] == '-' && item->header[ 1 ] == '-' ) )
		{
		BYTE buffer[ 4 ];
		int count, i;

		count = fread( buffer, 1, 4, inFile );
		for( i = 0; i < count; i++ )
			{
			if( buffer[ i ] != '-' && !isalnum( buffer[ i ] ) )
				break;
			}
		if( i >= 4 && \
			item->header[ 0 ] == 0x30 || item->header[ 0 ] == 0x31 )
			{
			/* Special-case handling for situations that would produce a 
			   false positive, items containing nested SEQUENCE (0x30)/SET 
			   (0x31) of an appropriate length will look like ASCII since
			   the encoding is 0x30 0xXX 0x30 0xXX 0x30 0xXX, e.g. "0g0e0c",
			   so we check for the pattern [0|1] alnum [0|1] alnum ... */
			if( buffer[ 2 ] == 0x30 || buffer[ 2 ] == 0x31 )
				{
				/* It's at least 0x30 0xXX 0x30 0xXX, assume it's binary.
				   This can lead to a minute number of false negatives, but 
				   that's OK since (a) it's no any normal encoding format 
				   for ASN.1 binary data and (b) all it'll do is produce
				   an attempt to decode text as ASN.1 */
				i = 0;
				}
			}
		if( i >= 4 )
			{
			fputs( "Error: This file appears to be a base64-encoded text "
				   "file, not binary data.\n", stderr );
			fputs( "       In order to display it you first need to decode "
				   "it into its\n", stderr );
			fputs( "       binary form.\n", stderr );
			exit( EXIT_FAILURE );
			}
		fseek( inFile, -4, SEEK_CUR );
		}

	/* Undo the fseek() that we used to determine whether the input was
	   seekable */
	fseek( inFile, item->headerSize, SEEK_CUR );

	return( length );
	}

static int printAsn1( FILE *inFile, const int level, long length,
					  const int isIndefinite )
	{
	ASN1_ITEM item;
	long lastPos = fPos;
	int seenEOC = FALSE, status;

	/* Bail out on suspiciously complex data */
	if( level > MAX_NESTING_LEVEL )
		{
		complain( "Object contains more than %d levels of nesting", 
				  MAX_NESTING_LEVEL, level );
		exit( EXIT_FAILURE );
		}

	/* Special-case for zero-length objects */
	if( !length && !isIndefinite )
		return( 0 );

	while( ( status = getItem( inFile, &item ) ) > 0 )
		{
		int nonOutlineObject = FALSE;

		/* Perform various special checks the first time that we're called */
		if( length == LENGTH_MAGIC )
			length = processObjectStart( inFile, &item );

		/* Dump the header as hex data if requested */
		if( doDumpHeader )
			dumpHeader( inFile, &item, level );

		/* If we're displaying the ASN.1 outline only and it's not a
		   constructed object, don't display anything */
		if( doOutlineOnly && ( item.id & FORM_MASK ) != CONSTRUCTED )
			nonOutlineObject = TRUE;

		/* Print the offset and length, unless we're in pure ASN.1-only
		   output mode or we're displaying the outline only and it's not
		   a constructed object */
		if( item.header[ 0 ] == EOC )
			{
			seenEOC = TRUE;
			if( !isIndefinite)
				complain( "Spurious EOC in definite-length item", 0, level );
			}
		if( !doPure && !nonOutlineObject )
			{
			if( item.indefinite )
				{
				printString( level, ( doHexValues ) ? \
								LEN_HEX_INDEF : LEN_INDEF, lastPos );
				}
			else
				{
				if( !seenEOC )
					{
					printString( level, ( doHexValues ) ? \
									LEN_HEX : LEN, lastPos, item.length );
					}
				}
			}

		/* Print details on the item */
		if( !seenEOC )
			{
			if( !nonOutlineObject )
				doIndent( level );
			printASN1object( inFile, &item, level );
			}

		/* If it was an indefinite-length object (no length was ever set) and
		   we've come back to the top level, exit */
		if( length == LENGTH_MAGIC )
			return( 0 );

		length -= fPos - lastPos;
		lastPos = fPos;
		if( isIndefinite )
			{
			if( seenEOC )
				return( 0 );
			}
		else
			{
			if( length <= 0 )
				{
				if( length < 0 )
					return( ( int ) -length );
				return( 0 );
				}
			else
				{
				if( length == 1 )
					{
					const int ch = fgetc( inFile );

					/* If we've run out of input but there should be more
					   present, let the caller know */
					if( ch == EOF )
						return( 1 );

					/* No object can be one byte long, try and recover.  This
					   only works sometimes because it can be caused by
					   spurious data in an OCTET STRING hole or an incorrect
					   length encoding.  The following workaround tries to
					   recover from spurious data by skipping the byte if
					   it's zero or a non-basic-ASN.1 tag, but keeping it if
					   it could be valid ASN.1 */
					if( ch > 0 && ch <= 0x31 )
						ungetc( ch, inFile );
					else
						{
						fPos++;
						return( 1 );
						}
					}
				}
			}
		}
	if( status == -1 )
		{
		int i;

		fflush( stdout );
		fprintf( stderr, "\nError: Invalid data encountered at position "
				 "%d:", fPos );
		for( i = 0; i < item.headerSize; i++ )
			fprintf( stderr, " %02X", item.header[ i ] );
		fprintf( stderr, ".\n" );
		exit( EXIT_FAILURE );
		}

	/* If we see an EOF and there's supposed to be more data present,
	   complain */
	if( length && length != LENGTH_MAGIC )
		{
		fprintf( output, "Error: Inconsistent object length, %ld byte%s "
				 "difference.\n", length, ( length > 1 ) ? "s" : "" );
		noErrors++;
		}
	return( 0 );
	}

/* Show usage and exit */

static void usageExit( void )
	{
	puts( "DumpASN1 - ASN.1 object dump/syntax check program." );
	puts( "Copyright Peter Gutmann 1997 - " UPDATE_YEAR ".  Last updated " UPDATE_STRING "." );
	puts( "" );

	puts( "Usage: dumpasn1 [-acdefghilmopqrstuvwxz] <file>" );
	puts( "  Input options:" );
	puts( "       - = Take input from stdin (some display options will be disabled)" );
	puts( "       -q = Disable warning about stdin use affecting display options" );
	puts( "       -<number> = Start <number> bytes into the file" );
	puts( "       -- = End of arg list" );
	puts( "       -c<file> = Read Object Identifier info from alternate config file" );
	puts( "            (values will override equivalents in global config file)" );
	puts( "" );

	puts( "  Output options:" );
	puts( "       -f<file> = Dump object at offset -<number> to file (allows data to be" );
	puts( "            extracted from encapsulating objects)" );
	puts( "       -w<number> = Set width of output, default = 80 columns" );
	puts( "" );

	puts( "  Display options:" );
	puts( "       -a = Print all data in long data blocks, not just the first 128 bytes" );
	puts( "       -d = Print dots to show column alignment" );
	puts( "       -g = Display ASN.1 structure outline only (no primitive objects)" );
	puts( "       -h = Hex dump object header (tag+length) before the decoded output" );
	puts( "       -hh = Same as -h but display more of the object as hex data" );
	puts( "       -i = Use shallow indenting, for deeply-nested objects" );
	puts( "       -l = Long format, display extra info about Object Identifiers" );
	puts( "       -m<number>  = Maximum nesting level for which to display content" );
	puts( "       -p = Pure ASN.1 output without encoding information" );
	puts( "       -t = Display text values next to hex dump of data" );
	puts( "       -v = Verbose mode, equivalent to -ahlt" );
	puts( "" );

	puts( "  Format options:" );
	puts( "       -e = Don't print encapsulated data inside OCTET/BIT STRINGs" );
	puts( "       -r = Print bits in BIT STRING as encoded in reverse order" );
	puts( "       -u = Don't format UTCTime/GeneralizedTime string data" );
	puts( "       -x = Display size and offset in hex not decimal" );
	puts( "" );

	puts( "  Checking options:" );
	puts( "       -o = Don't check validity of character strings hidden in octet strings" );
	puts( "       -s = Syntax check only, don't dump ASN.1 structures" );
	puts( "       -z = Allow zero-length items" );
	puts( "" );

	puts( "Warnings generated by deprecated OIDs require the use of '-l' to be displayed." );
	puts( "Program return code is the number of errors found or EXIT_SUCCESS." );
	exit( EXIT_FAILURE );
	}

int main( int argc, char *argv[] )
	{
	FILE *inFile, *outFile = NULL;
#ifdef __WIN32__
	CONSOLE_SCREEN_BUFFER_INFO csbiInfo;
#endif /* __WIN32__ */
#ifdef __OS390__
	char pathPtr[ FILENAME_MAX ];
#else
	char *pathPtr = argv[ 0 ];
#endif /* __OS390__ */
	long offset = 0;
	int moreArgs = TRUE, doCheckOnly = FALSE;

#ifdef __OS390__
	memset( pathPtr, '\0', sizeof( pathPtr ) );
	getcwd( pathPtr, sizeof( pathPtr ) );
	strcat( pathPtr, "/" );
#endif /* __OS390__ */

	/* Skip the program name */
	argv++; argc--;

	/* Display usage if no args given */
	if( argc < 1 )
		usageExit();
	output = stdout;	/* Needs to be assigned at runtime */

	/* Get the output width.  Under Unix there's no safe way to do this, so
	   we default to 80 columns */
#ifdef __WIN32__
	if( GetConsoleScreenBufferInfo( GetStdHandle( STD_OUTPUT_HANDLE ),
									&csbiInfo ) )
		outputWidth = csbiInfo.dwSize.X;
#endif /* __WIN32__ */

	/* Check for arguments */
	while( argc && *argv[ 0 ] == '-' && moreArgs )
		{
		char *argPtr = argv[ 0 ] + 1;

		if( !*argPtr )
			useStdin = TRUE;
		while( *argPtr )
			{
			if( isdigit( byteToInt( *argPtr ) ) )
				{
				offset = atol( argPtr );
				break;
				}
			switch( toupper( byteToInt( *argPtr ) ) )
				{
				case '-':
					moreArgs = FALSE;	/* GNU-style end-of-args flag */
					break;

				case 'A':
					printAllData = TRUE;
					break;

				case 'C':
					if( !readConfig( argPtr + 1, FALSE ) )
						exit( EXIT_FAILURE );
					while( argPtr[ 1 ] )
						argPtr++;	/* Skip rest of arg */
					break;

				case 'D':
					printDots = TRUE;
					break;

				case 'E':
					checkEncaps = FALSE;
					break;

				case 'F':
					if( ( outFile = fopen( argPtr + 1, "wb" ) ) == NULL )
						{
						perror( argPtr + 1 );
						exit( EXIT_FAILURE );
						}
					while( argPtr[ 1 ] )
						argPtr++;	/* Skip rest of arg */
					break;

				case 'G':
					doOutlineOnly = TRUE;
					break;

				case 'H':
					doDumpHeader++;
					break;

				case 'I':
					shallowIndent = TRUE;
					break;

				case 'L':
					extraOIDinfo = TRUE;
					break;

				case 'M':
					maxNestLevel = atoi( argPtr + 1 );
					if( maxNestLevel < 1 || maxNestLevel > MAX_NESTING_LEVEL )
						{
						puts( "Invalid maximum nesting level." );
						exit( EXIT_FAILURE );
						}
					while( argPtr[ 1 ] )
						argPtr++;	/* Skip rest of arg */
					break;

				case 'O':
					checkCharset = FALSE;
					break;

				case 'P':
					doPure = TRUE;
					break;

				case 'Q':
					noWarnStdin = TRUE;
					break;

				case 'R':
					reverseBitString = !reverseBitString;
					break;

				case 'S':
					doCheckOnly = TRUE;
#if defined( __WIN32__ )
					/* Under Windows we can't fclose( stdout ) because the
					   VC++ runtime reassigns the stdout handle to the next
					   open file (which is valid) but then scribbles stdout
					   garbage all over it for files larger than about 16K
					   (which isn't), so we have to make sure that the
					   stdout handle is pointed to something somewhere */
					( void ) freopen( "nul", "w", stdout );
#elif defined( __UNIX__ )
					/* Safety feature in case any Unix libc is as broken
					   as the Win32 version */
					( void ) freopen( "/dev/null", "w", stdout );
#else
					fclose( stdout );
#endif /* OS-specific bypassing of stdout */
					break;

				case 'T':
					dumpText = TRUE;
					break;

				case 'U':
					rawTimeString = TRUE;
					break;

				case 'V':
					printAllData = doDumpHeader = TRUE;
					extraOIDinfo = dumpText = TRUE;
					break;

				case 'W':
					outputWidth = atoi( argPtr + 1 );
					if( outputWidth < 40 || outputWidth > 500 )
						{
						puts( "Invalid output width." );
						exit( EXIT_FAILURE );
						}
					while( argPtr[ 1 ] )
						argPtr++;	/* Skip rest of arg */
					break;

				case 'X':
					doHexValues = TRUE;
					break;

				case 'Z':
					zeroLengthAllowed = TRUE;
					break;

				default:
					printf( "Unknown argument '%c'.\n", *argPtr );
					return( EXIT_SUCCESS );
				}
			argPtr++;
			}
		argv++;
		argc--;
		}

	/* We can't use options that perform an fseek() if reading from stdin */
	if( useStdin && ( doDumpHeader || outFile != NULL ) )
		{
		puts( "Can't use -f or -h when taking input from stdin" );
		exit( EXIT_FAILURE );
		}

	/* Check args and read the config file.  We don't bother weeding out
	   dups during the read because (a) the linear search would make the
	   process n^2, (b) during the dump process the search will terminate on
	   the first match so dups aren't that serious, and (c) there should be
	   very few if any dups present */
	if( argc != 1 && !useStdin )
		usageExit();
	if( !readGlobalConfig( pathPtr ) )
		exit( EXIT_FAILURE );

	/* Dump the given file */
	if( useStdin )
		inFile = stdin;
	else
		{
		if( ( inFile = fopen( argv[ 0 ], "rb" ) ) == NULL )
			{
			perror( argv[ 0 ] );
			freeConfig();
			exit( EXIT_FAILURE );
			}
		}
	if( useStdin )
		{
		while( offset-- )
			getc( inFile );
		}
	else
		fseek( inFile, offset, SEEK_SET );
	if( outFile != NULL )
		{
		ASN1_ITEM item;
		long length;
		int i, status;

		/* Make sure that there's something there, and that it has a
		   definite length */
		status = getItem( inFile, &item );
		if( status == -1 )
			{
			puts( "Non-ASN.1 data encountered." );
			freeConfig();
			exit( EXIT_FAILURE );
			}
		if( status == 0 )
			{
			puts( "Nothing to read." );
			freeConfig();
			exit( EXIT_FAILURE );
			}
		if( item.indefinite )
			{
			puts( "Cannot process indefinite-length item." );
			freeConfig();
			exit( EXIT_FAILURE );
			}

		/* Copy the item across, first the header and then the data */
		for( i = 0; i < item.headerSize; i++ )
			putc( item.header[ i ], outFile );
		for( length = 0; length < item.length && !feof( inFile ); length++ )
			putc( getc( inFile ), outFile );
		fclose( outFile );

		fseek( inFile, offset, SEEK_SET );
		}
	printAsn1( inFile, 0, LENGTH_MAGIC, 0 );
	if( !useStdin && offset == 0 )
		{
		BYTE buffer[ 16 ];
		long position = ftell( inFile );

		/* If we're dumping a standalone ASN.1 object and there's further
		   data appended to it, warn the user of its existence.  This is a
		   bit hit-and-miss since there may or may not be additional EOCs
		   present, dumpasn1 always stops once it knows that the data should
		   end (without trying to read any trailing EOCs) because data from
		   some sources has the EOCs truncated, and most apps know that they
		   have to stop at min( data_end, EOCs ).  To avoid false positives,
		   we skip at least 4 EOCs worth of data and if there's still more
		   present, we complain */
		( void ) fread( buffer, 1, 8, inFile );		/* Skip 4 EOCs */
		if( !feof( inFile ) )
			{
			warn( "Further data follows ASN.1 data at position %ld.\n", 
				  position, 0 );
			}
		}
	fclose( inFile );
	freeConfig();

	/* Print a summary of warnings/errors if it's required or appropriate */
	if( !doPure )
		{
		fflush( stdout );
		if( !doCheckOnly )
			fputc( '\n', stderr );
		fprintf( stderr, "%d warning%s, %d error%s.\n", noWarnings,
				( noWarnings != 1 ) ? "s" : "", noErrors,
				( noErrors != 1 ) ? "s" : "" );
		}

	return( ( noErrors ) ? noErrors : EXIT_SUCCESS );
	}

