# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

proc ticklecharts::critHList {args} {
    # Replace huddle::list
    #
    # Returns huddle list
    return [critHuddleTypeList $args]
}

proc ticklecharts::critJsonDump {huddle {offset "  "} {newline "\n"} {begin ""}} {
    # Replace huddle::jsondump
    #
    # Returns JSON
    return [critHuddleDump $huddle [list $offset $newline $begin]]
}

# Gets all types huddle tags (boolean, null, string...)
# huddle package should be loaded.
#
# Note : If a huddle type is added, it will not be supported, 
# additional changes are expected
#
foreach {key value} [array get ::huddle::types tagOfType*] {
    lappend ht [format {"%s"} $value]
    lappend cht [format {{"%s","%s"}} $value $::huddle::types(isContainer:$value)]
}

set LENHTYPE   [llength $ht]
set HTYPE      [format {{%s}} [join $ht ", "]]
set CONTAINERH [format {{%s}} [join $cht ", "]]

# load critcl...
package require critcl

# Tcl version
#
critcl::tcl 8.6

eval [string map [list \
        "%LENHTYPE%"   $LENHTYPE \
        "%HTYPE%"      $HTYPE \
        "%CONTAINERH%" $CONTAINERH \
    ] {
        critcl::ccode {
            #include <stdio.h>
            #include <string.h>
            #include <stdlib.h>

            const char *huddletype[%LENHTYPE%]    = %HTYPE%;
            const char *hcontainer[%LENHTYPE%][2] = %CONTAINERH%;
            const char *hmap[8][2]                = {{"\n","\\n"}, {"\t","\\t"}, {"\r","\\r"}, {"\b","\\b"}, {"\f","\\f"}, {"\\","\\\\"}, {"\"","\\\""}, {"/","\\/"}};
            int        huddleTLen = %LENHTYPE%;

            Tcl_Obj* huddleTypeCallbackStripC      (Tcl_Interp* interp, Tcl_Obj* headobj, Tcl_Obj* srcobj);
            Tcl_Obj* huddleTypeCallbackGetSubNodeC (Tcl_Interp* interp, Tcl_Obj* headobj, Tcl_Obj* srcobj, Tcl_Obj* pathobj);
            Tcl_Obj* huddleStripNodeC              (Tcl_Interp* interp, Tcl_Obj* node);
            Tcl_Obj* huddleFindNodeC               (Tcl_Interp* interp, Tcl_Obj* node, Tcl_Obj* path);
            Tcl_Obj* huddleArgToNodeC              (Tcl_Interp* interp, Tcl_Obj* srcObj);
            Tcl_Obj* huddleUnwrapC                 (Tcl_Interp* interp, Tcl_Obj* huddle_object);
            int      isHuddleC                     (Tcl_Interp* interp, Tcl_Obj* huddle_object);
            /*
            *----------------------------------------------------------------------
            * replaceWord --
            * source : https://www.geeksforgeeks.org/c-program-replace-word-text-another-given-word/
            *----------------------------------------------------------------------
            */
            char* replaceWord(const char* s, const char* oldW, const char* newW) {
                char* result;
                int i, cnt = 0;
                int newWlen = strlen(newW);
                int oldWlen = strlen(oldW);
            
                // Counting the number of times old word
                // occur in the string
                for (i = 0; s[i] != '\0'; i++) {
                    if (strstr(&s[i], oldW) == &s[i]) {
                        cnt++;
            
                        // Jumping to index after the old word.
                        i += oldWlen - 1;
                    }
                }
            
                // Making new string of enough length
                result = (char*)malloc(i + cnt * (newWlen - oldWlen) + 1);
            
                i = 0;
                while (*s) {
                    // compare the substring with the result
                    if (strstr(s, oldW) == s) {
                        strcpy(&result[i], newW);
                        i += newWlen;
                        s += oldWlen;
                    } else {
                        result[i++] = *s++;
                    }
                }
            
                result[i] = '\0';
                return result;
            }
            /*
            *----------------------------------------------------------------------
            * mapWord --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* mapWord (Tcl_Obj* strobj) {

                char* str = Tcl_GetString(strobj);
                char* result = NULL;

                for (int i = 0; i < 8; ++i) {
                    result = replaceWord(str, hmap[i][0], hmap[i][1]);
                    str = result;
                }

                return Tcl_NewStringObj(result, -1);

            }
            /*
            *----------------------------------------------------------------------
            * huddleTypeCallbackStripC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleTypeCallbackStripC (Tcl_Interp* interp, Tcl_Obj* headobj, Tcl_Obj* srcobj) {

                int count;
                Tcl_Obj **elements;
                Tcl_Obj *resObj = Tcl_NewListObj (0,NULL);

                const char* head = Tcl_GetString(headobj);

                if (strcmp(head, "D") == 0) {

                    fprintf(stderr, "error dict Callback strip not supported...\n");
                    exit(EXIT_FAILURE);

                } else if (strcmp(head, "L") == 0) {

                    if (Tcl_ListObjGetElements(interp, srcobj, &count, &elements) != TCL_OK) {
                        fprintf(stderr, "error(huddleTypeCallbackStripC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                        exit(EXIT_FAILURE);
                    }

                    for (int i = 0; i < count; ++i) {
                        Tcl_ListObjAppendElement(interp, resObj, huddleStripNodeC(interp, elements[i]));
                    }

                } else {
                    fprintf(stderr, "Callback Strip not supported...\n");
                    exit(EXIT_FAILURE);
                }
                
                return resObj;
            }
            /*
            *----------------------------------------------------------------------
            * huddleTypeCallbackGetSubNodeC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleTypeCallbackGetSubNodeC (Tcl_Interp* interp, Tcl_Obj* headobj, Tcl_Obj* srcobj, Tcl_Obj* pathobj) {

                int count;
                int rc;
                Tcl_Obj **elements;
                Tcl_Obj* index_obj;

                const char* head = Tcl_GetString(headobj);

                if (strcmp(head, "D") == 0) {

                    if (Tcl_DictObjGet(interp, srcobj, pathobj, &index_obj) != TCL_OK) {
                        fprintf(stderr, "error get value from dict...\n");
                        exit(EXIT_FAILURE);
                    }

                } else if (strcmp(head, "L") == 0) {

                    if (Tcl_ListObjGetElements(interp, srcobj, &count, &elements) != TCL_OK) {
                        fprintf(stderr, "error(huddleTypeCallbackGetSubNodeC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                        exit(EXIT_FAILURE);
                    }

                    if (Tcl_GetIntFromObj(interp, pathobj, &rc) != TCL_OK) {
                        fprintf(stderr, "error(huddleTypeCallbackGetSubNodeC): Not possible to get integer from pathobj...\n");
                        exit(EXIT_FAILURE);
                    }

                    Tcl_ListObjIndex(interp, srcobj, rc, &index_obj);

                } else {
                    fprintf(stderr, "Callback SubNode not supported...\n");
                    exit(EXIT_FAILURE);
                }

                return index_obj;

            }
            /*
            *----------------------------------------------------------------------
            * infoTypeExistsC --
            *----------------------------------------------------------------------
            */
            int infoTypeExistsC (Tcl_Obj* objtype) {

                const char* type = Tcl_GetString(objtype);

                for (int i = 0; i < huddleTLen; ++i) {
                    if (strcmp(type, huddletype[i]) == 0) {
                        return 1;
                    }
                }

                return 0;
            }
            /*
            *----------------------------------------------------------------------
            * isContainerC --
            *----------------------------------------------------------------------
            */
            int isContainerC (Tcl_Obj* objtype) {

                const char* src = Tcl_GetString(objtype);

                for (int i = 0; i < huddleTLen; ++i) {
                    if (strcmp(src, hcontainer[i][0]) == 0) {
                        if (strcmp(hcontainer[i][1], "yes") == 0) {
                            return 1;
                        } else {
                            return 0;
                        }
                    }
                }

                return 0;
            }
            /*
            *----------------------------------------------------------------------
            * isHuddleC --
            *----------------------------------------------------------------------
            */
            int isHuddleC(Tcl_Interp* interp, Tcl_Obj* huddle_object) {

                int count, result;
                Tcl_Obj **elements;
                
                if (Tcl_ListObjGetElements(interp, huddle_object, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(isHuddleC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                // if count == 0 Segmentation fault... for Tcl_GetString()
                if (count == 0) {return 0;}

                const char* h = Tcl_GetString(elements[0]);
                result = strcmp(h, "HUDDLE");

                if (result != 0 || count != 2) {
                    return 0;
                }

                Tcl_Obj* index_obj = Tcl_NewObj();

                if (Tcl_ListObjIndex(interp, elements[1], 0, &index_obj) != TCL_OK) {
                    fprintf(stderr, "error(isHuddleC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                return infoTypeExistsC(index_obj);
            }
            /*
            *----------------------------------------------------------------------
            * huddleUnwrapC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleUnwrapC (Tcl_Interp* interp, Tcl_Obj* huddle_object) {

                int count;
                Tcl_Obj **elements;

                if (Tcl_ListObjGetElements(interp, huddle_object, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(huddleUnwrapC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                return elements[1];
            }
            /*
            *----------------------------------------------------------------------
            * huddleStripNodeC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleStripNodeC (Tcl_Interp* interp, Tcl_Obj* node) {

                int count;
                Tcl_Obj **elements;
                Tcl_Obj* obj;

                if (Tcl_ListObjGetElements(interp, node, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(huddleStripNodeC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                // head = elements[0]
                // src  = elements[1]

                if (infoTypeExistsC(elements[0]) == 0) {
                    fprintf(stderr, "Type doesn't exists...\n");
                    exit(EXIT_FAILURE);
                }

                if (isContainerC(elements[0]) == 0) {
                    // not a container
                    obj = elements[1];
                } else {
                    obj = huddleTypeCallbackStripC(interp, elements[0], elements[1]);
                }

                return obj;

            }
            /*
            *----------------------------------------------------------------------
            * huddleWrapC
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleWrapC (Tcl_Interp* interp, Tcl_Obj* node) {

                Tcl_Obj *resObj = Tcl_NewListObj (0,NULL);

                Tcl_ListObjAppendElement (interp, resObj, Tcl_NewStringObj("HUDDLE", -1));
                Tcl_ListObjAppendElement (interp, resObj, node);

                return resObj;

            }
            /*
            *----------------------------------------------------------------------
            * huddleRetrieveHuddleC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleRetrieveHuddleC (Tcl_Interp* interp, Tcl_Obj* huddle_object, Tcl_Obj* path, int stripped) {

                Tcl_Obj* node;
                Tcl_Obj* targetnode;
                Tcl_Obj* obj;

                if (isHuddleC(interp, huddle_object) == 0) {
                    fprintf(stderr, "huddle_object is not Huddle...\n");
                    exit(EXIT_FAILURE);
                }

                // unwrap huddle_object
                node = huddleUnwrapC(interp, huddle_object);
                targetnode = huddleFindNodeC(interp, node, path);

                if (stripped == 1) {
                    obj = huddleStripNodeC(interp, targetnode);
                } else {
                    obj = huddleWrapC(interp, targetnode);
                }

                return obj;

            }
            /*
            *----------------------------------------------------------------------
            * huddleFindNodeC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleFindNodeC(Tcl_Interp* interp, Tcl_Obj* node, Tcl_Obj* path) {

                int count;
                Tcl_Obj **elements;
                Tcl_Obj **pathelements;
                Tcl_Obj* obj;

                Tcl_ListObjGetElements(interp, path, &count, &pathelements);

                if (count == 0) {
                    obj = node;
                } else {
                    Tcl_ListObjGetElements(interp, node, &count, &elements);
                    obj = huddleTypeCallbackGetSubNodeC(interp, elements[0], elements[1], pathelements[0]);
                }

                return obj;
                
            }
            /*
            *----------------------------------------------------------------------
            * huddleGetC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleGetC (Tcl_Interp* interp, Tcl_Obj* huddle_object, Tcl_Obj* obj) {

                return huddleRetrieveHuddleC(interp, huddle_object, obj, 0);
            }
            /*
            *----------------------------------------------------------------------
            * huddleGetStrippedC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleGetStrippedC (Tcl_Interp* interp,Tcl_Obj* huddle_object) {

                Tcl_Obj* obj = Tcl_NewObj();
                
                return huddleRetrieveHuddleC(interp, huddle_object, obj, 1);
            }
            /*
            *----------------------------------------------------------------------
            * huddleTypeC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleTypeC (Tcl_Interp* interp, Tcl_Obj* huddle_object) {

                Tcl_Obj* node;
                int count;
                Tcl_Obj **elements;

                if (isHuddleC(interp, huddle_object) == 0) {
                    fprintf(stderr, "huddle_object is not Huddle...\n");
                    exit(EXIT_FAILURE);
                }

                node = huddleUnwrapC(interp, huddle_object);

                if (Tcl_ListObjGetElements(interp, node, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(huddleTypeC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                return elements[0];
            }
            /*
            *----------------------------------------------------------------------
            * huddleLlengthC --
            *----------------------------------------------------------------------
            */
            int huddleLlengthC (Tcl_Interp* interp, Tcl_Obj* huddle_object) {

                Tcl_Obj* node;
                int count;
                Tcl_Obj **elements;
                Tcl_Obj **elementsrc;

                node = huddleUnwrapC(interp, huddle_object);

                if (Tcl_ListObjGetElements(interp, node, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(huddleLlengthC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                if (Tcl_ListObjGetElements(interp, elements[1], &count, &elementsrc) != TCL_OK) {
                    fprintf(stderr, "error(huddleLlengthC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }        

                return count;

            }
            /*
            *----------------------------------------------------------------------
            * huddleGetSrcC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleGetSrcC (Tcl_Interp* interp, Tcl_Obj* huddle_object) {

                Tcl_Obj* node;
                int count;
                Tcl_Obj **elements;

                node = huddleUnwrapC(interp, huddle_object);

                if (Tcl_ListObjGetElements(interp, node, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(huddleGetSrcC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                return elements[1];
            }
            /*
            *----------------------------------------------------------------------
            * huddleDictKeysC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleDictKeysC (Tcl_Interp* interp, Tcl_Obj* huddle_object) {

                Tcl_Obj* node;
                int count;
                Tcl_Obj **elements;
                Tcl_Obj *dict = Tcl_NewDictObj();

                node = huddleGetSrcC(interp, huddle_object);

                if (Tcl_ListObjGetElements(interp, node, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(huddleDictKeysC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                for (int i = 0; i < count; i++) {
                    if (i % 2 == 0) {
                        Tcl_DictObjPut (interp, dict, elements[i], elements[i+1]);
                    }
                }
            
                return dict;
            }
            /*
            *----------------------------------------------------------------------
            * huddleJoinListC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleJoinListC (Tcl_Interp* interp, Tcl_Obj* huddle_object, Tcl_Obj* nlof) {

                Tcl_Obj* node;
                int count;
                Tcl_Obj **elements;
                Tcl_Obj *joinObjPtr;
                Tcl_Obj *resObjPtr;

                if (Tcl_ListObjGetElements(interp, huddle_object, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(huddleJoinListC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                if (count == 1) {
                    return elements[0];
                }

                joinObjPtr = Tcl_NewStringObj(",", 1);
                Tcl_AppendObjToObj(joinObjPtr, nlof);

                resObjPtr = Tcl_NewObj();

                for (int i = 0; i < count; i++) {
                    if (i > 0) {
                        Tcl_AppendObjToObj(resObjPtr, joinObjPtr);
                    }
                    Tcl_AppendObjToObj(resObjPtr, elements[i]);
                }
                
                return resObjPtr;
            }
            /*
            *----------------------------------------------------------------------
            * huddleArgToNodeC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleArgToNodeC (Tcl_Interp* interp, Tcl_Obj* srcObj) {

                Tcl_Obj* defaultTag = Tcl_NewObj();
                Tcl_Obj* s = Tcl_NewStringObj("s", 1);

                if (isHuddleC(interp, srcObj)) {
                    defaultTag = huddleUnwrapC(interp, srcObj);
                } else {
                    Tcl_ListObjAppendElement(interp, defaultTag, s);
                    Tcl_ListObjAppendElement(interp, defaultTag, srcObj);
                }

                return defaultTag;    
            }
            /*
            *----------------------------------------------------------------------
            * huddleJsonDumpC --
            *----------------------------------------------------------------------
            */
            Tcl_Obj* huddleJsonDumpC (Tcl_Interp* interp, Tcl_Obj* huddle_object, Tcl_Obj* huddle_format) {

                Tcl_Obj* dataobj = Tcl_NewObj();
                Tcl_Obj* nextoff = Tcl_NewObj();
                Tcl_Obj* subobject;
                Tcl_Obj **elements;
                int count;
                int len = 0;

                // huddle format...
                if (Tcl_ListObjGetElements(interp, huddle_format, &count, &elements) != TCL_OK) {
                    fprintf(stderr, "error(huddleJsonDumpC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                    exit(EXIT_FAILURE);
                }

                const char *offset = Tcl_GetStringFromObj(elements[0], &len);
                char *sp = " ";

                if (len == 0) {
                    sp = "";
                }

                // nextoff > $begin$offset
                Tcl_AppendObjToObj(nextoff, elements[2]);
                Tcl_AppendObjToObj(nextoff, elements[0]);

                const char *type = Tcl_GetString(huddleTypeC(interp, huddle_object));

                if (!strcmp(type, "b")) {

                    // boolean
                    return huddleGetStrippedC(interp, huddle_object);

                } else if (strcmp(type, "num") == 0) {

                    // number
                    return huddleGetStrippedC(interp, huddle_object);

                } else if (strcmp(type, "s") == 0) {

                    // string
                    Tcl_Obj* q = Tcl_NewStringObj("\"", 1);
                    Tcl_Obj* hstripped = huddleGetStrippedC(interp, huddle_object);

                    Tcl_AppendObjToObj(dataobj, q);
                    Tcl_AppendObjToObj(dataobj, mapWord(hstripped));
                    Tcl_AppendObjToObj(dataobj, q);

                    return dataobj;

                } else if (!strcmp(type, "null")) {

                    // null
                    return Tcl_ObjPrintf("null");

                } else if (!strcmp(type, "L")) {

                    // list
                    int len = huddleLlengthC(interp, huddle_object);
                    Tcl_Obj *innerObj  = Tcl_NewListObj (0,NULL);
                    Tcl_Obj *formatObj = Tcl_NewListObj (0,NULL);

                    // offset newline nextoff
                    Tcl_ListObjAppendElement(interp, formatObj, elements[0]);
                    Tcl_ListObjAppendElement(interp, formatObj, elements[1]);
                    Tcl_ListObjAppendElement(interp, formatObj, nextoff);

                    for (int i = 0; i < len; ++i) {
                        subobject = huddleGetC(interp, huddle_object, Tcl_NewIntObj(i));
                        // recursive JsonDump
                        dataobj = huddleJsonDumpC(interp, subobject, formatObj);
                        Tcl_ListObjAppendElement(interp, innerObj, dataobj);
                    }

                    int llen;

                    if (Tcl_ListObjLength(interp, innerObj, &llen) != TCL_OK) {
                        fprintf(stderr, "error(huddleJsonDumpC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                        exit(EXIT_FAILURE);
                    }

                    if (llen == 1) {
                        Tcl_Obj* index_obj = Tcl_NewObj();
                        Tcl_ListObjIndex(interp, innerObj, 0, &index_obj);
                        return Tcl_ObjPrintf("[%s]", Tcl_GetString(index_obj));
                    }

                    // nlof > "$newline$nextoff"
                    Tcl_Obj* nlof    = Tcl_NewObj();
                    Tcl_AppendObjToObj(nlof, elements[1]);
                    Tcl_AppendObjToObj(nlof, nextoff);

                    // [$nlof
                    Tcl_Obj* bracketnlof = Tcl_NewObj();
                    Tcl_AppendObjToObj(bracketnlof, Tcl_NewStringObj("[", 1));
                    Tcl_AppendObjToObj(bracketnlof, nlof);

                    // $newline$begin]
                    Tcl_Obj* newlinebeginbracket = Tcl_NewObj();
                    Tcl_AppendObjToObj(newlinebeginbracket, elements[1]);
                    Tcl_AppendObjToObj(newlinebeginbracket, elements[2]);
                    Tcl_AppendObjToObj(newlinebeginbracket, Tcl_NewStringObj("]", 1));

                    Tcl_Obj *joinList;
                    joinList = huddleJoinListC(interp, innerObj, nlof);

                    Tcl_Obj* newlist = Tcl_NewObj();
                    Tcl_AppendObjToObj(newlist, bracketnlof);
                    Tcl_AppendObjToObj(newlist, joinList);
                    Tcl_AppendObjToObj(newlist, newlinebeginbracket);

                    return newlist;

                } else if (!strcmp(type, "D")) {

                    // dict
                    Tcl_Obj *dictObj = huddleDictKeysC(interp, huddle_object);
                    Tcl_DictSearch search;
                    Tcl_Obj *key, *value;
                    int done;

                    if (Tcl_DictObjFirst(interp, dictObj, &search, &key, &value, &done) != TCL_OK) {
                        fprintf(stderr, "error dict...\n");
                        exit(EXIT_FAILURE);
                    }

                    Tcl_Obj *formatObj = Tcl_NewListObj (0,NULL);
                    Tcl_Obj *innerObj  = Tcl_NewListObj (0,NULL);

                    // offset newline nextoff
                    Tcl_ListObjAppendElement(interp, formatObj, elements[0]);
                    Tcl_ListObjAppendElement(interp, formatObj, elements[1]);
                    Tcl_ListObjAppendElement(interp, formatObj, nextoff);

                    Tcl_Obj* qm = Tcl_NewStringObj("\"", 1);
                    Tcl_Obj* c  = Tcl_NewStringObj(":", 1);

                    for (; !done ; Tcl_DictObjNext(&search, &key, &value, &done)) {

                        Tcl_Obj* keylistObj = Tcl_NewObj();

                        subobject = huddleGetC(interp, huddle_object, key);
                        // recursive JsonDump
                        dataobj = huddleJsonDumpC(interp, subobject, formatObj);

                        Tcl_AppendObjToObj(keylistObj, qm);
                        Tcl_AppendObjToObj(keylistObj, Tcl_NewStringObj(Tcl_GetString(key), -1));
                        Tcl_AppendObjToObj(keylistObj, qm);
                        Tcl_AppendObjToObj(keylistObj, c);
                        Tcl_AppendObjToObj(keylistObj, Tcl_NewStringObj(sp, strlen(sp)));
                        Tcl_AppendObjToObj(keylistObj, dataobj);
                        Tcl_ListObjAppendElement(interp, innerObj, keylistObj);
                    }

                    Tcl_DictObjDone(&search);

                    int llen;

                    if (Tcl_ListObjLength(interp, innerObj, &llen) != TCL_OK) {
                        fprintf(stderr, "error(huddleJsonDumpC): '%s'\n", Tcl_GetString(Tcl_GetObjResult(interp)));
                        exit(EXIT_FAILURE);
                    }

                    if (llen == 1) {
                        return innerObj;
                    }

                    // nlof
                    Tcl_Obj* nlof    = Tcl_NewObj();
                    Tcl_AppendObjToObj(nlof, elements[1]);
                    Tcl_AppendObjToObj(nlof, nextoff);

                    // {$nlof
                    Tcl_Obj* curlyBnlof = Tcl_NewObj();
                    Tcl_AppendObjToObj(curlyBnlof, Tcl_NewStringObj("{", 1));
                    Tcl_AppendObjToObj(curlyBnlof, nlof);

                    // $newline$begin}
                    Tcl_Obj* newlinebegincurlyB = Tcl_NewObj();
                    Tcl_AppendObjToObj(newlinebegincurlyB, elements[1]);
                    Tcl_AppendObjToObj(newlinebegincurlyB, elements[2]);
                    Tcl_AppendObjToObj(newlinebegincurlyB, Tcl_NewStringObj("}", 1));

                    Tcl_Obj *joinList;
                    joinList = huddleJoinListC(interp, innerObj, nlof);

                    Tcl_Obj* newlist = Tcl_NewObj();
                    Tcl_AppendObjToObj(newlist, curlyBnlof);
                    Tcl_AppendObjToObj(newlist, joinList);
                    Tcl_AppendObjToObj(newlist, newlinebegincurlyB);

                    return newlist;

                } else if (!strcmp(type, "jsf")) {

                    Tcl_Obj* index_obj       = Tcl_NewObj();
                    Tcl_Obj* index_subobj    = Tcl_NewObj();
                    Tcl_Obj* index_subsubobj = Tcl_NewObj();
                    Tcl_ListObjIndex(interp, huddle_object, 1, &index_obj);
                    Tcl_ListObjIndex(interp, index_obj,     1, &index_subobj);
                    Tcl_ListObjIndex(interp, index_subobj,  0, &index_subsubobj);

                    return index_subsubobj;

                } else {
                    fprintf(stderr, "Type not supported...'%s'\n", type);
                    exit(EXIT_FAILURE);
                }
            }
        }
}]

critcl::cproc critHuddleDump {Tcl_Interp* interp Tcl_Obj* huddle Tcl_Obj* format} ok {
    Tcl_Obj* json;

    json = huddleJsonDumpC(interp, huddle, format);
    Tcl_SetObjResult(interp, json);

    return TCL_OK;
}


critcl::cproc critIsHuddle {Tcl_Interp* interp Tcl_Obj* huddle} ok {

    int result = isHuddleC(interp, huddle);

    Tcl_SetObjResult(interp, Tcl_NewIntObj(result));

    return TCL_OK;
}

critcl::cproc critRetrieveHuddle {Tcl_Interp* interp Tcl_Obj* huddle_object Tcl_Obj* path int stripped} ok {

    Tcl_Obj* result = huddleRetrieveHuddleC(interp, huddle_object, path, stripped);
    Tcl_SetObjResult(interp, result);

    return TCL_OK;

}

critcl::cproc critHuddleListMap {Tcl_Interp* interp Tcl_Obj* data} ok {

    Tcl_Obj **elements, **sub_elements, **sub_list;
    int count, subcount;
    double d;

    if (Tcl_ListObjGetElements(interp, data, &count, &elements) != TCL_OK) {
        Tcl_SetObjResult(interp, Tcl_ObjPrintf("error(critHuddleListMap): '%s'", Tcl_GetString(Tcl_GetObjResult(interp))));
        return TCL_ERROR;
    }

    if (Tcl_ListObjGetElements(interp, elements[0], &count, &sub_elements) != TCL_OK) {
        Tcl_SetObjResult(interp, Tcl_ObjPrintf("error(critHuddleListMap): '%s'", Tcl_GetString(Tcl_GetObjResult(interp))));
        return TCL_ERROR;
    }

    Tcl_Obj *dataObj = Tcl_NewListObj (0,NULL);
    Tcl_Obj* s       = Tcl_NewStringObj("s", 1);
    Tcl_Obj* l       = Tcl_NewStringObj("L", 1);
    Tcl_Obj* n       = Tcl_NewStringObj("num", 3);
    Tcl_Obj* null    = Tcl_NewStringObj("null", 4);

    for (int i = 0; i < count; ++i) {
        Tcl_Obj *innerObj = Tcl_NewListObj (0,NULL);
        Tcl_Obj* lTag     = Tcl_NewObj();
       
        Tcl_ListObjGetElements(interp, sub_elements[i], &subcount, &sub_list);

        for (int j = 0; j < subcount; j++) {
            Tcl_Obj* dataTag = Tcl_NewObj();

            if (Tcl_GetDoubleFromObj(interp, sub_list[j], &d) == TCL_OK) {
                Tcl_ListObjAppendElement(interp, dataTag, n);
                Tcl_ListObjAppendElement(interp, dataTag, sub_list[j]); 
            } else if (!strcmp(Tcl_GetString(sub_list[j]), "null")) {
                Tcl_ListObjAppendElement(interp, dataTag, null);
            } else {
                Tcl_ListObjAppendElement(interp, dataTag, s);
                Tcl_ListObjAppendElement(interp, dataTag, sub_list[j]); 
            }

            Tcl_ListObjAppendElement(interp, innerObj, dataTag);

        }

        Tcl_ListObjAppendElement(interp, lTag, l);
        Tcl_ListObjAppendElement(interp, lTag, innerObj);
        Tcl_ListObjAppendElement(interp, dataObj, lTag);
    }

    Tcl_SetObjResult(interp, dataObj);

    return TCL_OK;
}

critcl::cproc critHuddleListInsert {Tcl_Interp* interp Tcl_Obj* data} ok {

    Tcl_Obj **elements, **sub_elements, **sub_list;
    int count;
    double d;

    if (Tcl_ListObjGetElements(interp, data, &count, &elements) != TCL_OK) {
        Tcl_SetObjResult(interp, Tcl_ObjPrintf("error(critHuddleListInsert): '%s'", Tcl_GetString(Tcl_GetObjResult(interp))));
        return TCL_ERROR;
    }

    if (Tcl_ListObjGetElements(interp, elements[0], &count, &sub_list) != TCL_OK) {
        Tcl_SetObjResult(interp, Tcl_ObjPrintf("error(critHuddleListInsert): '%s'", Tcl_GetString(Tcl_GetObjResult(interp))));
        return TCL_ERROR;
    }

    if (Tcl_ListObjGetElements(interp, sub_list[0], &count, &sub_elements) != TCL_OK) {
        Tcl_SetObjResult(interp, Tcl_ObjPrintf("error(critHuddleListInsert): '%s'", Tcl_GetString(Tcl_GetObjResult(interp))));
        return TCL_ERROR;
    }

    Tcl_Obj *dataObj = Tcl_NewListObj (0,NULL);
    Tcl_Obj* s       = Tcl_NewStringObj("s", 1);
    Tcl_Obj* n       = Tcl_NewStringObj("num", 3);
    Tcl_Obj* null    = Tcl_NewStringObj("null", 4);

    for (int i = 0; i < count; ++i) {
        Tcl_Obj* dataTag = Tcl_NewObj(); 

        if (Tcl_GetDoubleFromObj(interp, sub_elements[i], &d) == TCL_OK) {
            Tcl_ListObjAppendElement(interp, dataTag, n);
            Tcl_ListObjAppendElement(interp, dataTag, sub_elements[i]);
        } else if (!strcmp(Tcl_GetString(sub_elements[i]), "null")) {
            Tcl_ListObjAppendElement(interp, dataTag, null);
        } else {
            Tcl_ListObjAppendElement(interp, dataTag, s);
            Tcl_ListObjAppendElement(interp, dataTag, sub_elements[i]); 
        }

        Tcl_ListObjAppendElement(interp, dataObj, dataTag);
    }
    
    Tcl_SetObjResult(interp, dataObj);

    return TCL_OK;
}

critcl::cproc critHuddleTypeList {Tcl_Interp* interp Tcl_Obj* data} ok {

    Tcl_Obj **elements, **sub_elements;
    int count;

    if (Tcl_ListObjGetElements(interp, data, &count, &elements) != TCL_OK) {
        Tcl_SetObjResult(interp, Tcl_ObjPrintf("error(critHuddleTypeList): '%s'", Tcl_GetString(Tcl_GetObjResult(interp))));
        return TCL_ERROR;
    }

    Tcl_Obj *dataObj  = Tcl_NewListObj (0,NULL);

    for (int i = 0; i < count; ++i) {
        Tcl_ListObjAppendElement(interp, dataObj, huddleArgToNodeC(interp, elements[i]));
    }

    Tcl_Obj* listTag = Tcl_NewObj();
    Tcl_Obj* l       = Tcl_NewStringObj("L", 1);

    Tcl_ListObjAppendElement(interp, listTag, l);
    Tcl_ListObjAppendElement(interp, listTag, dataObj);

    Tcl_Obj* wrap = huddleWrapC(interp, listTag);

    Tcl_SetObjResult(interp, wrap);

    return TCL_OK;

}

critcl::load ; # force compilation...