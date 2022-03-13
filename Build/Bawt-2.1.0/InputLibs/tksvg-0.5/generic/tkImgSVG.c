/*
 * tkImgSVGnano.c
 *
 *	A photo file handler for SVG files.
 *
 * Copyright (c) 2013-14 Mikko Mononen memon@inside.org
 * Copyright (c) 2018 Christian Gollwitzer auriocus@gmx.de
 * Copyright (c) 2018 Rene Zaumseil r.zaumseil@freenet.de
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * This handler is build using the original nanosvg library files from
 * https://github.com/memononen/nanosvg and the tcl extension files from
 * https://github.com/auriocus/tksvg
 *
 */

/* vim: set ts=8 sts=4 sw=4 : */

#include <tcl.h>
#ifndef MODULE_SCOPE
#define MODULE_SCOPE extern
#endif
#include <stdio.h>
#include <string.h>
#ifdef _MSC_VER
#define strcasecmp _stricmp
#endif
#include <math.h>
#include <float.h>
#define NANOSVG_malloc	ckalloc
#define NANOSVG_realloc	ckrealloc
#define NANOSVG_free	ckfree
#define NANOSVG_SCOPE MODULE_SCOPE
#define NANOSVG_ALL_COLOR_KEYWORDS
#define NANOSVG_IMPLEMENTATION
#include "nanosvg.h"
#define NANOSVGRAST_IMPLEMENTATION
#include "nanosvgrast.h"
#include <tk.h>

#define MAX_MATCH_BYTES 4096

/* Additional parameters to nsvgRasterize() */

typedef struct {
    double scale;
    double dpi;
    int scaleToHeight;
    int scaleToWidth;
} RastOpts;

static int      FileMatchSVG(Tcl_Channel chan, const char *fileName,
                Tcl_Obj *format, int *widthPtr, int *heightPtr,
                Tcl_Interp *interp);
static int      FileReadSVG(Tcl_Interp *interp, Tcl_Channel chan,
                const char *fileName, Tcl_Obj *format,
                Tk_PhotoHandle imageHandle, int destX, int destY,
                int width, int height, int srcX, int srcY);
static int      StringMatchSVG(Tcl_Obj *dataObj, Tcl_Obj *format,
                int *widthPtr, int *heightPtr, Tcl_Interp *interp);
static int      StringReadSVG(Tcl_Interp *interp, Tcl_Obj *dataObj,
                Tcl_Obj *format, Tk_PhotoHandle imageHandle,
                int destX, int destY, int width, int height,
                int srcX, int srcY);
static NSVGimage * ParseSVGWithOptions(Tcl_Interp *interp,
                const char *input, int length, Tcl_Obj *format,
                RastOpts *ropts);
static int      ParseFormatOptions( Tcl_Interp *interp,
                Tcl_Obj *formatObj, RastOpts *ropts);
static int      RasterizeSVG(Tcl_Interp *interp,
                Tk_PhotoHandle imageHandle, NSVGimage *nsvgImage,
                int destX, int destY, int width, int height,
                int srcX, int srcY, RastOpts *ropts);
static double   GetScaleFromParameters(float svgWidth, float svgHeight,
                RastOpts *ropts, int *widthPtr, int *heightPtr);

/*
 * The format record for the SVG nano file format:
 */

static Tk_PhotoImageFormat tkImgFmtSVGnano = {
    "svg",              /* name */
    FileMatchSVG,       /* fileMatchProc */
    StringMatchSVG,     /* stringMatchProc */
    FileReadSVG,        /* fileReadProc */
    StringReadSVG,      /* stringReadProc */
    NULL,               /* fileWriteProc */
    NULL,               /* stringWriteProc */
    NULL
};

/*
 *----------------------------------------------------------------------
 *
 * FileMatchSVG --
 *
 *  This function is invoked by the photo image type to see if a file
 *	contains image data in SVG format.
 *
 * Results:
 *  The return value is >0 if the file can be successfully parsed,
 *  and 0 otherwise.
 *
 *----------------------------------------------------------------------
 */

static int svg_parseUnits(const char* units)
{
    if (units[0] == 'p' && units[1] == 'x')
        return NSVG_UNITS_PX;
    else if (units[0] == 'p' && units[1] == 't')
        return NSVG_UNITS_PT;
    else if (units[0] == 'p' && units[1] == 'c')
        return NSVG_UNITS_PC;
    else if (units[0] == 'm' && units[1] == 'm')
        return NSVG_UNITS_MM;
    else if (units[0] == 'c' && units[1] == 'm')
        return NSVG_UNITS_CM;
    else if (units[0] == 'i' && units[1] == 'n')
        return NSVG_UNITS_IN;
    else if (units[0] == '%')
        return NSVG_UNITS_PERCENT;
    else if (units[0] == 'e' && units[1] == 'm')
        return NSVG_UNITS_EM;
    else if (units[0] == 'e' && units[1] == 'x')
        return NSVG_UNITS_EX;
    return NSVG_UNITS_USER;
}

static NSVGcoordinate svg_parseCoordinateRaw(const char* str)
{
    NSVGcoordinate coord = {0, NSVG_UNITS_USER};
    char units[32]="";
    sscanf(str, "%f%2s", &coord.value, units);
    coord.units = svg_parseUnits(units);
    return coord;
}

static float svg_convertToPixels(NSVGcoordinate c, float dpi)
{
    switch (c.units) {
        case NSVG_UNITS_USER:    return c.value;
        case NSVG_UNITS_PX:      return c.value;
        case NSVG_UNITS_PT:      return c.value / 72.0f * dpi;
        case NSVG_UNITS_PC:      return c.value / 6.0f * dpi;
        case NSVG_UNITS_MM:      return c.value / 25.4f * dpi;
        case NSVG_UNITS_CM:      return c.value / 2.54f * dpi;
        case NSVG_UNITS_IN:      return c.value * dpi;
        case NSVG_UNITS_PERCENT: return 0.0f;
        default:                 return c.value;
    }
    return c.value;
}

static float svg_parseCoordinate(const char* str, float dpi)
{
    NSVGcoordinate coord = svg_parseCoordinateRaw(str);
    return svg_convertToPixels(coord, dpi);
}

static int
IsSvgFile(
    const char *data,
    int maxInd,
    float dpi,
    float *svgWidth,
    float *svgHeight)
{
    int curInd = 0;
    const char *svgStart   = NULL;
    const char *svgEnd     = NULL;
    const char *widthStr   = NULL;
    const char *heightStr  = NULL;
    const char *viewBoxStr = NULL;

    svgEnd = data + maxInd;
    while (data[curInd] && curInd < maxInd) {
        if (data[curInd] == '<') {
            curInd++;
            if (curInd + 3 < maxInd && strncmp(&data[curInd], "svg", 3) == 0) {
                curInd += 3;
                svgStart = &data[curInd];
            }
        } else if (data[curInd] == '>' && svgStart) {
            svgEnd = &data[curInd];
            break;
        }
        curInd++;
    }
    if (!svgStart) {
        return 0;
    }
    widthStr   = strstr(svgStart, " width=");
    heightStr  = strstr(svgStart, " height=");
    viewBoxStr = strstr(svgStart, " viewBox=");
    if (viewBoxStr && viewBoxStr < svgEnd) {
        float viewMinx, viewMiny, viewWidth, viewHeight;
        sscanf(viewBoxStr + 10, "%f%*[%%, \t]%f%*[%%, \t]%f%*[%%, \t]%f", 
               &viewMinx, &viewMiny, &viewWidth, &viewHeight);
        *svgWidth  = viewWidth;
        *svgHeight = viewHeight;
    }
    if (widthStr && widthStr < svgEnd) {
        float val = svg_parseCoordinate( widthStr + 8, dpi);
        if (val > 0.0f) {
            *svgWidth = val;
        } else {
            return 0;
        }
    }
    if (heightStr && heightStr < svgEnd) {
        float val = svg_parseCoordinate( heightStr + 9, dpi);
        if (val > 0.0f) {
            *svgHeight = val;
        } else {
            return 0;
        }
    }
    if (*svgHeight == 0.0f && *svgWidth > 0.0f) {
        *svgHeight = *svgWidth;
    }
    if (*svgWidth == 0.0f && *svgHeight > 0.0f) {
        *svgWidth = *svgHeight;
    }
    if (*svgWidth == 0.0f) {
        *svgWidth = 300.0f;
    }
    if (*svgHeight == 0.0f) {
        *svgHeight = 300.0f;
    }
    return 1;
}

static int
FileMatchSVG(
    Tcl_Channel chan,
    const char *fileName,
    Tcl_Obj *formatObj,
    int *widthPtr, int *heightPtr,
    Tcl_Interp *interp)
{
    int length;
    Tcl_Obj *dataObj = Tcl_NewObj();
    const char *data;
    unsigned int maxInd;
    float svgWidth  = 0.0f;
    float svgHeight = 0.0f;
    RastOpts ropts;
    int numBytesRead;
    (void)fileName;

    if (!ParseFormatOptions(interp, formatObj, &ropts)) {
        return 0;
    }
    numBytesRead = Tcl_ReadChars(chan, dataObj, MAX_MATCH_BYTES, 0);
    if (numBytesRead == -1) {
        /* in case of an error reading the file */
        Tcl_DecrRefCount(dataObj);
        return 0;
    }
    data = Tcl_GetStringFromObj(dataObj, &length);
    maxInd = length < MAX_MATCH_BYTES? length: MAX_MATCH_BYTES;
    if (!IsSvgFile (data, maxInd, ropts.dpi, &svgWidth, &svgHeight)) {
        Tcl_DecrRefCount(dataObj);
        return 0;
    }
    GetScaleFromParameters(svgWidth, svgHeight, &ropts, widthPtr, heightPtr);
    Tcl_DecrRefCount(dataObj);
    if ((*widthPtr <= 0.0) || (*heightPtr <= 0.0)) {
        return 0;
    }
    return 1;
}

/*
 *----------------------------------------------------------------------
 *
 * FileReadSVG --
 *
 *  This function is called by the photo image type to read SVG format
 *  data from a file and write it into a given photo image.
 *
 * Results:
 *  A standard TCL completion code. If TCL_ERROR is returned then an error
 *  message is left in the interp's result.
 *
 * Side effects:
 *  The access position in file f is changed, and new data is added to the
 *  image given by imageHandle.
 *
 *----------------------------------------------------------------------
 */

static int
FileReadSVG(
    Tcl_Interp *interp,
    Tcl_Channel chan,
    const char *fileName,
    Tcl_Obj *formatObj,
    Tk_PhotoHandle imageHandle,
    int destX, int destY,
    int width, int height,
    int srcX, int srcY)
{
    int length;
    const char *data;
    RastOpts ropts;
    NSVGimage *nsvgImage = NULL;
    Tcl_Obj *dataObj = Tcl_NewObj();
    (void)fileName;

    if (Tcl_ReadChars(chan, dataObj, -1, 0) == -1) {
        /* in case of an error reading the file */
        Tcl_DecrRefCount(dataObj);
        Tcl_SetObjResult(interp, Tcl_NewStringObj("read error", -1));
        Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "READ_ERROR", NULL);
        return TCL_ERROR;
    }
    data = Tcl_GetStringFromObj(dataObj, &length);
    nsvgImage = ParseSVGWithOptions(interp, data, length, formatObj, &ropts);
    Tcl_DecrRefCount(dataObj);
    if (nsvgImage == NULL) {
        return TCL_ERROR;
    }
    return RasterizeSVG(interp, imageHandle, nsvgImage, destX, destY,
                        width, height, srcX, srcY, &ropts);
}

/*
 *----------------------------------------------------------------------
 *
 * StringMatchSVG --
 *
 *  This function is invoked by the photo image type to see if a string
 *  contains image data in SVG format.
 *
 * Results:
 *  The return value is >0 if the file can be successfully parsed,
 *  and 0 otherwise.
 *
 *----------------------------------------------------------------------
 */

static int
StringMatchSVG(
    Tcl_Obj *dataObj,
    Tcl_Obj *formatObj,
    int *widthPtr, int *heightPtr,
    Tcl_Interp *interp)
{
    int length;
    const char *data;
    unsigned int maxInd;
    float svgWidth  = 0.0f;
    float svgHeight = 0.0f;
    RastOpts ropts;

    if (!ParseFormatOptions (interp, formatObj, &ropts)) {
        return 0;
    }

    data = Tcl_GetStringFromObj(dataObj, &length);
    maxInd = length < MAX_MATCH_BYTES? length: MAX_MATCH_BYTES;

    if (!IsSvgFile (data, maxInd, ropts.dpi, &svgWidth, &svgHeight)) {
        return 0;
    }

    GetScaleFromParameters (svgWidth, svgHeight, &ropts, widthPtr, heightPtr);
    if ((*widthPtr <= 0.0) || (*heightPtr <= 0.0)) {
        return 0;
    }
    return 1;
}

/*
 *----------------------------------------------------------------------
 *
 * StringReadSVG --
 *
 *  This function is called by the photo image type to read SVG format
 *  data from a string and write it into a given photo image.
 *
 * Results:
 *  A standard TCL completion code. If TCL_ERROR is returned then an error
 *  message is left in the interp's result.
 *
 * Side effects:
 *  New data is added to the image given by imageHandle.
 *
 *----------------------------------------------------------------------
 */

static int
StringReadSVG(
    Tcl_Interp *interp,
    Tcl_Obj *dataObj,
    Tcl_Obj *formatObj,
    Tk_PhotoHandle imageHandle,
    int destX, int destY,
    int width, int height,
    int srcX, int srcY)
{
    int length;
    const char *data;
    RastOpts ropts;
    NSVGimage *nsvgImage = NULL;

    data = Tcl_GetStringFromObj(dataObj, &length);
    nsvgImage = ParseSVGWithOptions(interp, data, length, formatObj, &ropts);
    if (nsvgImage == NULL) {
        return TCL_ERROR;
    }
    return RasterizeSVG(interp, imageHandle, nsvgImage, destX, destY,
                        width, height, srcX, srcY, &ropts);
}

/*
 *----------------------------------------------------------------------
 *
 * ParseSVGWithOptions --
 *
 *  This function is called to parse the given input string as SVG.
 *
 * Results:
 *  Return a newly create NSVGimage on success, and NULL otherwise.
 *
 * Side effects:
 *
 *----------------------------------------------------------------------
 */

static int
ParseFormatOptions(
    Tcl_Interp *interp,
    Tcl_Obj *formatObj,
    RastOpts *ropts)
{
    Tcl_Obj **objv = NULL;
    int objc = 0;
    int parameterScaleSeen = 0;
    static const char *const fmtOptions[] = {
        "-dpi", "-scale", "-scaletoheight", "-scaletowidth", NULL
    };
    enum fmtOptions {
        OPT_DPI, OPT_SCALE, OPT_SCALE_TO_HEIGHT, OPT_SCALE_TO_WIDTH
    };

    /*
     * Process elements of format specification as a list.
     */

    ropts->scale = 1.0;
    ropts->dpi   = 96.0;
    ropts->scaleToHeight = 0;
    ropts->scaleToWidth  = 0;
    if ((formatObj != NULL) &&
        Tcl_ListObjGetElements(interp, formatObj, &objc, &objv) != TCL_OK) {
        return 0;
    }
    for (; objc > 0 ; objc--, objv++) {
        int optIndex;

        /*
         * Ignore the "svg" part of the format specification.
         */

        if (!strcasecmp(Tcl_GetString(objv[0]), "svg")) {
            continue;
        }

        if (Tcl_GetIndexFromObjStruct(interp, objv[0], fmtOptions,
            sizeof(char *), "option", 0, &optIndex) == TCL_ERROR) {
            return 0;
        }

        if (objc < 2) {
            Tcl_WrongNumArgs(interp, 1, objv, "value");
            return 0;
        }

        objc--;
        objv++;

        /*
         * check that only one scale option is given
         */
        switch ((enum fmtOptions) optIndex) {
            case OPT_SCALE:
            case OPT_SCALE_TO_HEIGHT:
            case OPT_SCALE_TO_WIDTH:
                if ( parameterScaleSeen ) {
                    Tcl_SetObjResult(interp, Tcl_NewStringObj(
                        "only one of -scale, -scaletoheight, -scaletowidth may be given", -1));
                    Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "BAD_SCALE", NULL);
                    return 0;
                }
                parameterScaleSeen = 1;
                break;
            default:
                break;
        }

        /*
         * Decode parameters
         */
        switch ((enum fmtOptions) optIndex) {
            case OPT_DPI:
                if (Tcl_GetDoubleFromObj(interp, objv[0], &ropts->dpi) == TCL_ERROR) {
                    return 0;
                }
                if (ropts->dpi < 0.0) {
                    Tcl_SetObjResult(interp, Tcl_NewStringObj(
                        "-dpi value must be positive", -1));
                    Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "BAD_DPI", NULL);
                    return 0;
                }
                break;
            case OPT_SCALE:
                if (Tcl_GetDoubleFromObj(interp, objv[0], &ropts->scale) == TCL_ERROR) {
                    return 0;
                }
                if (ropts->scale <= 0.0) {
                    Tcl_SetObjResult(interp, Tcl_NewStringObj(
                        "-scale value must be positive", -1));
                    Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "BAD_SCALE", NULL);
                    return 0;
                }
                break;
            case OPT_SCALE_TO_HEIGHT:
                if (Tcl_GetIntFromObj(interp, objv[0], &ropts->scaleToHeight) == TCL_ERROR) {
                    return 0;
                }
                if (ropts->scaleToHeight <= 0) {
                    Tcl_SetObjResult(interp, Tcl_NewStringObj(
                        "-scaletoheight value must be positive", -1));
                    Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "BAD_SCALE", NULL);
                    return 0;
                }
                break;
            case OPT_SCALE_TO_WIDTH:
                if (Tcl_GetIntFromObj(interp, objv[0], &ropts->scaleToWidth) == TCL_ERROR) {
                    return 0;
                }
                if (ropts->scaleToWidth <= 0) {
                    Tcl_SetObjResult(interp, Tcl_NewStringObj(
                        "-scaletowidth value must be positive", -1));
                    Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "BAD_SCALE", NULL);
                    return 0;
                }
                break;
        }
    }
    return 1;
}

static NSVGimage *
ParseSVGWithOptions(
    Tcl_Interp *interp,
    const char *input,
    int length,
    Tcl_Obj *formatObj,
    RastOpts *ropts)
{
    char *inputCopy = NULL;
    NSVGimage *nsvgImage = NULL;

    /*
     * The parser destroys the original input string,
     * therefore first duplicate.
     */

    inputCopy = (char *)attemptckalloc(length+1);
    if (inputCopy == NULL) {
        Tcl_SetObjResult(interp, Tcl_NewStringObj("cannot alloc data buffer", -1));
        Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "OUT_OF_MEMORY", NULL);
        goto error;
    }
    memcpy(inputCopy, input, length);
    inputCopy[length] = '\0';

    ParseFormatOptions (interp, formatObj, ropts);

    nsvgImage = nsvgParse(inputCopy, "px", ropts->dpi);
    if (nsvgImage == NULL) {
        Tcl_SetObjResult(interp, Tcl_NewStringObj("cannot parse SVG image", -1));
        Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "PARSE_ERROR", NULL);
        goto error;
    }
    ckfree(inputCopy);
    return nsvgImage;

error:
    if (inputCopy != NULL) {
        ckfree(inputCopy);
    }
    return NULL;
}

/*
 *----------------------------------------------------------------------
 *
 * RasterizeSVG --
 *
 *  This function is called to rasterize the given nsvgImage and
 *  fill the imageHandle with data.
 *
 * Results:
 *  A standard TCL completion code. If TCL_ERROR is returned then an error
 *  message is left in the interp's result.
 *
 *
 * Side effects:
 *  On error the given nsvgImage will be deleted.
 *
 *----------------------------------------------------------------------
 */

static int
RasterizeSVG(
    Tcl_Interp *interp,
    Tk_PhotoHandle imageHandle,
    NSVGimage *nsvgImage,
    int destX, int destY,
    int width, int height,
    int srcX, int srcY,
    RastOpts *ropts)
{
    int w, h, c;
    NSVGrasterizer *rast;
    unsigned char *imgData;
    Tk_PhotoImageBlock svgblock;
    double scale;
    (void)srcX;
    (void)srcY;

    scale = GetScaleFromParameters(nsvgImage->width, nsvgImage->height, ropts, &w, &h);

    rast = nsvgCreateRasterizer();
    if (rast == NULL) {
        Tcl_SetObjResult(interp, Tcl_NewStringObj("cannot initialize rasterizer", -1));
        Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "RASTERIZER_ERROR", NULL);
        goto cleanAST;
    }
    imgData = (unsigned char *)attemptckalloc(w * h *4);
    if (imgData == NULL) {
        Tcl_SetObjResult(interp, Tcl_NewStringObj("cannot alloc image buffer", -1));
        Tcl_SetErrorCode(interp, "TK", "IMAGE", "SVG", "OUT_OF_MEMORY", NULL);
        goto cleanRAST;
    }
    nsvgRasterize(rast, nsvgImage, 0, 0, (float) scale, imgData, w, h, w * 4);
    /* transfer the data to a photo block */
    svgblock.pixelPtr = imgData;
    svgblock.width = w;
    svgblock.height = h;
    svgblock.pitch = w * 4;
    svgblock.pixelSize = 4;
    for (c = 0; c <= 3; c++) {
        svgblock.offset[c] = c;
    }
    if (Tk_PhotoExpand(interp, imageHandle, destX + width, destY + height) != TCL_OK) {
        goto cleanRAST;
    }
    if (Tk_PhotoPutBlock(interp, imageHandle, &svgblock, destX, destY,
                         width, height, TK_PHOTO_COMPOSITE_SET) != TCL_OK) {
        goto cleanimg;
    }
    ckfree(imgData);
    nsvgDeleteRasterizer(rast);
    nsvgDelete(nsvgImage);
    return TCL_OK;

cleanimg:
    ckfree(imgData);

cleanRAST:
    nsvgDeleteRasterizer(rast);

cleanAST:
    nsvgDelete(nsvgImage);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * GetScaleFromParameters --
 *
 *  Get the scale value from the already parsed parameters -scale,
 *  -scaletoheight and -scaletowidth.
 *
 *  The image width and height is also returned.
 *
 * Results:
 *  The evaluated or configured scale value, or 0.0 on failure
 *
 * Side effects:
 *  heightPtr and widthPtr are set to height and width of the image.
 *
 *----------------------------------------------------------------------
 */

static double
GetScaleFromParameters(
    float svgWidth,
    float svgHeight,
    RastOpts *ropts,
    int *widthPtr,
    int *heightPtr)
{
    double scale;
    int width, height;

    if ((svgWidth == 0.0) || (svgHeight == 0.0)) {
        width = height = 0;
        scale = 1.0;
    } else if (ropts->scaleToHeight > 0) {
        /*
         * Fixed height
         */
        height = ropts->scaleToHeight;
        scale = height / svgHeight;
        width = (int) ceil(svgWidth * scale);
    } else if (ropts->scaleToWidth > 0) {
        /*
         * Fixed width
         */
        width = ropts->scaleToWidth;
        scale = width / svgWidth;
        height = (int) ceil(svgHeight * scale);
    } else {
        /*
         * Scale factor
         */
        scale = ropts->scale;
        width = (int) ceil(svgWidth * scale);
        height = (int) ceil(svgHeight * scale);
    }

    *heightPtr = height;
    *widthPtr = width;
    return scale;
}

int DLLEXPORT
Tksvg_Init(Tcl_Interp *interp)
{
    if (interp == NULL) {
        return TCL_ERROR;
    }
#ifdef USE_TCL_STUBS
    if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
	return TCL_ERROR;
    }
#else
    if (Tcl_PkgRequire(interp, "Tcl", TCL_VERSION, 0) == NULL) {
	return TCL_ERROR;
    }
#endif
#ifdef USE_TK_STUBS
    if (Tk_InitStubs(interp, TCL_VERSION, 0) == NULL) {
	return TCL_ERROR;
    }
#else
    if (Tcl_PkgRequire(interp, "Tk", TK_VERSION, 0) == NULL) {
	return TCL_ERROR;
    }
#endif
    Tk_CreatePhotoImageFormat(&tkImgFmtSVGnano);
    Tcl_PkgProvide(interp, PACKAGE_NAME, PACKAGE_VERSION);
    return TCL_OK;
}