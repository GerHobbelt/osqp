module lib_handler;

nothrow @nogc extern(C):

import glob_opts;
//#include <ctype.h> // Needed for tolower functions

import constants;
import util;

version(Windows){
//#include <windows.h>
// todo
alias soHandle_t = HINSTANCE;
} else {
import core.stdc.ctype;
import core.sys.posix.dlfcn;

alias soHandle_t = void *;
}

version(Windows)
{
    enum string SHAREDLIBEXT = "dll";
} else {
    version(OSX){
        enum string SHAREDLIBEXT = "dylib";
    } else {
    enum string SHAREDLIBEXT = "so";
    }
}

enum OSQP_NULL = null;

soHandle_t lh_load_lib(const char *libName) {
    soHandle_t h = OSQP_NULL;

    if (!libName) {
        version(PRINTING){
        c_eprint("ERROR in %s: no library name given\n", __FUNCTION__.ptr);
        }
        return OSQP_NULL;
    }

version(Windows){
    h = LoadLibrary (libName);
    if (!h) {
        version(PRINTING){
        c_eprint("ERROR in %s: Windows error while loading dynamic library %s, error = %d\n",
                __FUNCTION__.ptr, libName, cast(int)GetLastError());
        }
    }
} else {
    h = dlopen (libName, RTLD_LAZY);
    if (!h) {
        version(PRINTING){
        c_eprint("ERROR in %s: Error while loading dynamic library %s: %s\n", __FUNCTION__.ptr, libName, dlerror());
        }
    }
}

    return h;
} /* lh_load_lib */


c_int lh_unload_lib (soHandle_t h) {
    c_int rc = 1;

version (Windows){
    rc = FreeLibrary (h);
    rc = ! rc;
} else {
    rc = dlclose (h);
}

    return rc;
} /* LSL_unLoadLib */


version (Windows){
    alias symtype = FARPROC;
} else {
    //typedef void* symtype;
    alias symtype = void*;
}
/** Loads a symbol from a dynamically linked library.
 * This function is not defined in the header to allow a workaround for the problem that dlsym returns an object instead of a function pointer.
 * However, Windows also needs special care.
 *
 * The method does six attempts to load the symbol. Next to its given name, it also tries variations of lower case and upper case form and with an extra underscore.
 * @param h Handle of dynamically linked library.
 * @param symName Name of the symbol to load.
 * @return A pointer to the symbol, or OSQP_NULL if not found.
 */
symtype lh_load_sym (soHandle_t h, char *symName) {
    symtype s;
    char *from;
    char *to;
    char *tripSym;
    char* err;
    char [257] lcbuf;
    char [257]ucbuf;
    char [257]ocbuf;
    size_t symLen;
    int trip;

    s = OSQP_NULL;
    err = OSQP_NULL;

    /* search in this order:
     *  1. original
     *  2. lower_
     *  3. upper_
     *  4. original_
     *  5. lower
     *  6. upper
     */

    symLen = 0;
    for (trip = 1;  trip <= 6;  trip++) {
        switch (trip) {
        case 1:                             /* original */
            tripSym = cast(char*)symName;
            break;
        case 2:                             /* lower_ */
            for (from = cast(char*)symName, to = cast(char*)lcbuf;  *from;  from++, to++) {
                *to = cast(char)tolower(*from); // todo : may cause data loss
            }
            symLen = from - symName;
            *to++ = '_';
            *to = '\0';
            tripSym = cast(char*)lcbuf;
            break;
        case 3:                             /* upper_ */
            for (from = cast(char*)symName, to = cast(char*)ucbuf;  *from;  from++, to++) {
                *to = cast(char)toupper(*from);
            }
            *to++ = '_';
            *to = '\0';
            tripSym = cast(char*)ucbuf;
            break;
        case 4:                             /* original_ */
            c_strcpy(cast(char*)ocbuf, symName);
            ocbuf[symLen] = '_';
            ocbuf[symLen+1] = '\0';
            tripSym = cast(char*)ocbuf;
            break;
        case 5:                             /* lower */
            lcbuf[symLen] = '\0';
            tripSym = cast(char*)lcbuf;
            break;
        case 6:                             /* upper */
            ucbuf[symLen] = '\0';
            tripSym = cast(char*)ucbuf;
            break;
        default:
            tripSym = cast(char*)symName;
        } /* end switch */
version(Windows){
        s = GetProcAddress (h, tripSym);
        if (s) {
            return s;
        } else {
            version(PRINTING){
            c_eprint("ERROR in %s: Cannot find symbol %s in dynamic library, error = %d\n", __FUNCTION__.ptr, 
                    symName, cast(int)GetLastError());
            }
        }
} else {
        s = dlsym (h, tripSym);
        err = dlerror();  /* we have only one chance; a successive call to dlerror() returns OSQP_NULL */
        if (err) {
            version(PRINTING){
            c_eprint("ERROR in %s: Cannot find symbol %s in dynamic library, error = %s\n", __FUNCTION__.ptr, 
                    symName, err);
            }
        } else {
            return s;
        }
}
    } /* end loop over symbol name variations */

    return OSQP_NULL;
} /* lh_load_sym */
