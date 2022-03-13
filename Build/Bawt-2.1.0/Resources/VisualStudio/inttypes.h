/***
*complex.h - definitions and declarations for complex math library
*
*       Copyright (c) Microsoft Corporation. All rights reserved.
*
*Purpose:
*       This file contains constant definitions and external subroutine
*       declarations for the complex math subroutine library.
*
*       [Public]
*
****/

#pragma once

#ifndef _INTTYPES
#define _INTTYPES
#include <stdint.h>

#pragma pack(push,_CRT_PACKING)

#ifdef __cplusplus
extern "C" {
#endif  /* __cplusplus */

typedef struct
{  /* result of long long divide */
  intmax_t quot;
  intmax_t rem;
} _Lldiv_t;

#pragma pack(pop)

typedef _Lldiv_t imaxdiv_t;

intmax_t _CRTIMP __cdecl imaxabs(_In_ intmax_t);
imaxdiv_t _CRTIMP __cdecl imaxdiv(_In_ intmax_t, _In_ intmax_t);

intmax_t _CRTIMP __cdecl strtoimax(_In_z_ const char *, _Out_opt_ _Deref_post_z_ char **, int);
intmax_t _CRTIMP __cdecl _strtoimax_l(_In_z_ const char *, _Out_opt_ _Deref_post_z_ char **, int, _In_opt_ _locale_t);
uintmax_t _CRTIMP __cdecl strtoumax(_In_z_ const char *, _Out_opt_ _Deref_post_z_ char **, int);
uintmax_t _CRTIMP __cdecl _strtoumax_l(_In_z_ const char *, _Out_opt_ _Deref_post_z_ char **, int, _In_opt_ _locale_t);
intmax_t _CRTIMP __cdecl wcstoimax(_In_z_ const wchar_t *, _Out_opt_ _Deref_post_z_ wchar_t **, int);
intmax_t _CRTIMP __cdecl _wcstoimax_l(_In_z_ const wchar_t *, _Out_opt_ _Deref_post_z_ wchar_t **, int, _In_opt_ _locale_t);
uintmax_t _CRTIMP __cdecl wcstoumax(_In_z_ const wchar_t *, _Out_opt_ _Deref_post_z_ wchar_t **, int);
uintmax_t _CRTIMP __cdecl _wcstoumax_l(_In_z_ const wchar_t *, _Out_opt_ _Deref_post_z_ wchar_t **, int, _In_opt_ _locale_t);

#define _PFX_8   "hh"
#define _PFX_16  "h"
#define _PFX_32  "l"
#define _PFX_64  "ll"

#ifdef _WIN64
#define _PFX_PTR  "ll"
#else
#define _PFX_PTR  "l"
#endif

#ifdef _FAST16_IS_32 /* compiler test */
#define _PFX_F16  _PFX_32
#else /* _FAST16_IS_32 */
#define _PFX_F16  _PFX_16
#endif /* _FAST16_IS_32 */

/* PRINT FORMAT MACROS */
#define PRId8        _PFX_8 "d"
#define PRId16       _PFX_16 "d"
#define PRId32       _PFX_32 "d"
#define PRIdLEAST8   _PFX_8 "d"
#define PRIdLEAST16  _PFX_16 "d"
#define PRIdLEAST32  _PFX_32 "d"
#define PRIdFAST8    _PFX_8 "d"
#define PRIdFAST16   _PFX_F16 "d"
#define PRIdFAST32   _PFX_32 "d"

#define PRIi8        _PFX_8 "i"
#define PRIi16       _PFX_16 "i"
#define PRIi32       _PFX_32 "i"
#define PRIiLEAST8   _PFX_8 "i"
#define PRIiLEAST16  _PFX_16 "i"
#define PRIiLEAST32  _PFX_32 "i"
#define PRIiFAST8    _PFX_8 "i"
#define PRIiFAST16   _PFX_F16 "i"
#define PRIiFAST32   _PFX_32 "i"

#define PRIo8        _PFX_8 "o"
#define PRIo16       _PFX_16 "o"
#define PRIo32       _PFX_32 "o"
#define PRIoLEAST8   _PFX_8 "o"
#define PRIoLEAST16  _PFX_16 "o"
#define PRIoLEAST32  _PFX_32 "o"
#define PRIoFAST8    _PFX_8 "o"
#define PRIoFAST16   _PFX_F16 "o"
#define PRIoFAST32   _PFX_32 "o"

#define PRIu8        _PFX_8 "u"
#define PRIu16       _PFX_16 "u"
#define PRIu32       _PFX_32 "u"
#define PRIuLEAST8   _PFX_8 "u"
#define PRIuLEAST16  _PFX_16 "u"
#define PRIuLEAST32  _PFX_32 "u"
#define PRIuFAST8    _PFX_8 "u"
#define PRIuFAST16   _PFX_F16 "u"
#define PRIuFAST32   _PFX_32 "u"

#define PRIx8        _PFX_8 "x"
#define PRIx16       _PFX_16 "x"
#define PRIx32       _PFX_32 "x"
#define PRIxLEAST8   _PFX_8 "x"
#define PRIxLEAST16  _PFX_16 "x"
#define PRIxLEAST32  _PFX_32 "x"
#define PRIxFAST8    _PFX_8 "x"
#define PRIxFAST16   _PFX_F16 "x"
#define PRIxFAST32   _PFX_32 "x"

#define PRIX8        _PFX_8 "X"
#define PRIX16       _PFX_16 "X"
#define PRIX32       _PFX_32 "X"
#define PRIXLEAST8   _PFX_8 "X"
#define PRIXLEAST16  _PFX_16 "X"
#define PRIXLEAST32  _PFX_32 "X"
#define PRIXFAST8    _PFX_8 "X"
#define PRIXFAST16   _PFX_F16 "X"
#define PRIXFAST32   _PFX_32 "X"

#define PRId64       _PFX_64 "d"
#define PRIdLEAST64  _PFX_64 "d"
#define PRIdFAST64   _PFX_64 "d"
#define PRIdMAX      _PFX_64 "d"
#define PRIdPTR      _PFX_PTR "d"

#define PRIi64       _PFX_64 "i"
#define PRIiLEAST64  _PFX_64 "i"
#define PRIiFAST64   _PFX_64 "i"
#define PRIiMAX      _PFX_64 "i"
#define PRIiPTR      _PFX_PTR "i"

#define PRIo64       _PFX_64 "o"
#define PRIoLEAST64  _PFX_64 "o"
#define PRIoFAST64   _PFX_64 "o"
#define PRIoMAX      _PFX_64 "o"
#define PRIoPTR      _PFX_PTR "o"

#define PRIu64       _PFX_64 "u"
#define PRIuLEAST64  _PFX_64 "u"
#define PRIuFAST64   _PFX_64 "u"
#define PRIuMAX      _PFX_64 "u"
#define PRIuPTR      _PFX_PTR "u"

#define PRIx64       _PFX_64 "x"
#define PRIxLEAST64  _PFX_64 "x"
#define PRIxFAST64   _PFX_64 "x"
#define PRIxMAX      _PFX_64 "x"
#define PRIxPTR      _PFX_PTR "x"

#define PRIX64       _PFX_64 "X"
#define PRIXLEAST64  _PFX_64 "X"
#define PRIXFAST64   _PFX_64 "X"
#define PRIXMAX      _PFX_64 "X"
#define PRIXPTR      _PFX_PTR "X"

/* SCAN FORMAT MACROS */
#define SCNd8        _PFX_8 "d"
#define SCNd16       _PFX_16 "d"
#define SCNd32       _PFX_32 "d"
#define SCNdLEAST8   _PFX_8 "d"
#define SCNdLEAST16  _PFX_16 "d"
#define SCNdLEAST32  _PFX_32 "d"
#define SCNdFAST8    _PFX_8 "d"
#define SCNdFAST16   _PFX_F16 "d"
#define SCNdFAST32   _PFX_32 "d"

#define SCNi8        _PFX_8 "i"
#define SCNi16       _PFX_16 "i"
#define SCNi32       _PFX_32 "i"
#define SCNiLEAST8   _PFX_8 "i"
#define SCNiLEAST16  _PFX_16 "i"
#define SCNiLEAST32  _PFX_32 "i"
#define SCNiFAST8    _PFX_8 "i"
#define SCNiFAST16   _PFX_F16 "i"
#define SCNiFAST32   _PFX_32 "i"

#define SCNo8        _PFX_8 "o"
#define SCNo16       _PFX_16 "o"
#define SCNo32       _PFX_32 "o"
#define SCNoLEAST8   _PFX_8 "o"
#define SCNoLEAST16  _PFX_16 "o"
#define SCNoLEAST32  _PFX_32 "o"
#define SCNoFAST8    _PFX_8 "o"
#define SCNoFAST16   _PFX_F16 "o"
#define SCNoFAST32   _PFX_32 "o"

#define SCNu8        _PFX_8 "u"
#define SCNu16       _PFX_16 "u"
#define SCNu32       _PFX_32 "u"
#define SCNuLEAST8   _PFX_8 "u"
#define SCNuLEAST16  _PFX_16 "u"
#define SCNuLEAST32  _PFX_32 "u"
#define SCNuFAST8    _PFX_8 "u"
#define SCNuFAST16   _PFX_F16 "u"
#define SCNuFAST32   _PFX_32 "u"

#define SCNx8        _PFX_8 "x"
#define SCNx16       _PFX_16 "x"
#define SCNx32       _PFX_32 "x"
#define SCNxLEAST8   _PFX_8 "x"
#define SCNxLEAST16  _PFX_16 "x"
#define SCNxLEAST32  _PFX_32 "x"
#define SCNxFAST8    _PFX_8 "x"
#define SCNxFAST16   _PFX_F16 "x"
#define SCNxFAST32   _PFX_32 "x"

#define SCNd64       _PFX_64 "d"
#define SCNdLEAST64  _PFX_64 "d"
#define SCNdFAST64   _PFX_64 "d"
#define SCNdMAX      _PFX_64 "d"
#define SCNdPTR      _PFX_PTR "d"

#define SCNi64       _PFX_64 "i"
#define SCNiLEAST64  _PFX_64 "i"
#define SCNiFAST64   _PFX_64 "i"
#define SCNiMAX      _PFX_64 "i"
#define SCNiPTR      _PFX_PTR "i"

#define SCNo64       _PFX_64 "o"
#define SCNoLEAST64  _PFX_64 "o"
#define SCNoFAST64   _PFX_64 "o"
#define SCNoMAX      _PFX_64 "o"
#define SCNoPTR      _PFX_PTR "o"

#define SCNu64       _PFX_64 "u"
#define SCNuLEAST64  _PFX_64 "u"
#define SCNuFAST64   _PFX_64 "u"
#define SCNuMAX      _PFX_64 "u"
#define SCNuPTR      _PFX_PTR "u"

#define SCNx64       _PFX_64 "x"
#define SCNxLEAST64  _PFX_64 "x"
#define SCNxFAST64   _PFX_64 "x"
#define SCNxMAX      _PFX_64 "x"
#define SCNxPTR      _PFX_PTR "x"

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* _INTTYPES */
