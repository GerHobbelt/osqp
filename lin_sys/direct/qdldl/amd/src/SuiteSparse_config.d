/* ========================================================================== */
/* === SuiteSparse_config =================================================== */
/* ========================================================================== */

/* Configuration file for SuiteSparse: a Suite of Sparse matrix packages
 * (AMD, COLAMD, CCOLAMD, CAMD, CHOLMOD, UMFPACK, CXSparse, and others).
 *
 * SuiteSparse_config.h provides the definition of the long integer.  On most
 * systems, a C program can be compiled in LP64 mode, in which long's and
 * pointers are both 64-bits, and int's are 32-bits.  Windows 64, however, uses
 * the LLP64 model, in which int's and long's are 32-bits, and long long's and
 * pointers are 64-bits.
 *
 * SuiteSparse packages that include long integer versions are
 * intended for the LP64 mode.  However, as a workaround for Windows 64
 * (and perhaps other systems), the long integer can be redefined.
 *
 * If _WIN64 is defined, then the __int64 type is used instead of long.
 *
 * The long integer can also be defined at compile time.  For example, this
 * could be added to SuiteSparse_config.mk:
 *
 * CFLAGS = -O -D'SuiteSparse_long=long long' \
 *  -D'SuiteSparse_long_max=9223372036854775801' -D'SuiteSparse_long_idd="lld"'
 *
 * This file defines SuiteSparse_long as either long (on all but _WIN64) or
 * __int64 on Windows 64.  The intent is that a SuiteSparse_long is always a
 * 64-bit integer in a 64-bit code.  ptrdiff_t might be a better choice than
 * long; it is always the same size as a pointer.
 *
 * This file also defines the SUITESPARSE_VERSION and related definitions.
 *
 * Copyright (c) 2012, Timothy A. Davis.  No licensing restrictions apply
 * to this file or to the SuiteSparse_config directory.
 * Author: Timothy A. Davis.
 */


/* SuiteSparse configuration : memory manager and printf functions. */

/* Copyright (c) 2013, Timothy A. Davis.  No licensing restrictions
 * apply to this file or to the SuiteSparse_config directory.
 * Author: Timothy A. Davis.
 */

module SuiteSparse_config;

nothrow @nogc extern(C):

// Include OSQP Global options for memory management
import glob_opts;

version (EMBEDDED){
  import osqp_configure; // for c_malloc and others
}

import core.stdc.math;
import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.limits;
//#ifndef NPRINT
//#include <stdio.h>
//#endif

version(MATLAB){
    //#include "mex.h"
    //#include "matrix.h"
    import mex;
    import matrix;
}

// todo: How do i check ifndef NULL ?
//#ifndef NULL
//#define NULL ((void *) 0)
//enum void * NULL = (cast(void *) 0);
//#endif

/* ========================================================================== */
/* === SuiteSparse_long ===================================================== */
/* ========================================================================== */

alias SuiteSparse_long = long;
enum long SuiteSparse_long_max = LONG_MAX;
enum string SuiteSparse_long_idd = "ld";

// todo: review it
//#define SuiteSparse_long_id "%" SuiteSparse_long_idd



/* ========================================================================== */
/* === SuiteSparse_config parameters and functions ========================== */
/* ========================================================================== */

/* SuiteSparse-wide parameters are placed in this struct.  It is meant to be
   an extern, globally-accessible struct.  It is not meant to be updated
   frequently by multiple threads.  Rather, if an application needs to modify
   SuiteSparse_config, it should do it once at the beginning of the application,
   before multiple threads are launched.

   The intent of these function pointers is that they not be used in your
   application directly, except to assign them to the desired user-provided
   functions.  Rather, you should use the
 */

alias malloc_func_t = void* function(size_t);
alias realloc_func_t = void* function(void*, size_t);
alias free_func_t = void function(void*);
alias printf_func_t = int function(const char*, ...);
alias hypot_func_t = c_float function(c_float, c_float);
alias divcomplex_func_t = int function(c_float, c_float, c_float, c_float, c_float*, c_float*);

struct SuiteSparse_config_struct
{
    malloc_func_t malloc_func;      // pointer to malloc
    realloc_func_t realloc_func;    // pointer to realloc
    free_func_t free_func;          // pointer to free             
    printf_func_t printf_func;      // pointer to printf
    hypot_func_t hypot_func;        // pointer to hypot
    divcomplex_func_t divcomplex_func;
};

//extern struct SuiteSparse_config_struct SuiteSparse_config ;

/* OSQP: disabling this timing code */
//#define NTIMER

/* determine which timer to use, if any */
/*#ifndef NTIMER
#ifdef _POSIX_C_SOURCE
#if    _POSIX_C_SOURCE >= 199309L
#define SUITESPARSE_TIMER_ENABLED
#endif
#endif
#endif
*/

/* SuiteSparse printf macro */
/*#define SUITESPARSE_PRINTF(params) \
{ \
    if (SuiteSparse_config.printf_func != NULL) \
    { \
        (void) (SuiteSparse_config.printf_func) params ; \
    } \
}*/
alias SUITESPARSE_PRINTF = c_print;

/* ========================================================================== */
/* === SuiteSparse version ================================================== */
/* ========================================================================== */

/* SuiteSparse is not a package itself, but a collection of packages, some of
 * which must be used together (UMFPACK requires AMD, CHOLMOD requires AMD,
 * COLAMD, CAMD, and CCOLAMD, etc).  A version number is provided here for the
 * collection itself.  The versions of packages within each version of
 * SuiteSparse are meant to work together.  Combining one package from one
 * version of SuiteSparse, with another package from another version of
 * SuiteSparse, may or may not work.
 *
 * SuiteSparse contains the following packages:
 *
 *  SuiteSparse_config version 4.5.3 (version always the same as SuiteSparse)
 *  AMD             version 2.4.6
 *  BTF             version 1.2.6
 *  CAMD            version 2.4.6
 *  CCOLAMD         version 2.9.6
 *  CHOLMOD         version 3.0.11
 *  COLAMD          version 2.9.6
 *  CSparse         version 3.1.9
 *  CXSparse        version 3.1.9
 *  GPUQREngine     version 1.0.5
 *  KLU             version 1.3.8
 *  LDL             version 2.2.6
 *  RBio            version 2.2.6
 *  SPQR            version 2.0.7
 *  SuiteSparse_GPURuntime  version 1.0.5
 *  UMFPACK         version 5.7.6
 *  MATLAB_Tools    various packages & M-files
 *  xerbla          version 1.0.3
 *
 * Other package dependencies:
 *  BLAS            required by CHOLMOD and UMFPACK
 *  LAPACK          required by CHOLMOD
 *  METIS 5.1.0     required by CHOLMOD (optional) and KLU (optional)
 *  CUBLAS, CUDART  NVIDIA libraries required by CHOLMOD and SPQR when
 *                  they are compiled with GPU acceleration.
 */


/* Versions prior to 4.2.0 do not have the above function.  The following
   code fragment will work with any version of SuiteSparse:

   #ifdef SUITESPARSE_HAS_VERSION_FUNCTION
   v = SuiteSparse_version (NULL) ;
   #else
   v = SUITESPARSE_VERSION ;
   #endif
*/
//#define SUITESPARSE_HAS_VERSION_FUNCTION

enum string SUITESPARSE_DATE = "May 4, 2016";
//#define SUITESPARSE_VER_CODE(main,sub) ((main) * 1000 + (sub))
c_int SUITESPARSE_VER_CODE(c_int main, c_int sub) {return (main) * 1000 + (sub);}
enum c_int SUITESPARSE_MAIN_VERSION = 4;
enum c_int SUITESPARSE_SUB_VERSION = 5;
enum c_int SUITESPARSE_SUBSUB_VERSION = 3;
//#define SUITESPARSE_VERSION SUITESPARSE_VER_CODE(SUITESPARSE_MAIN_VERSION,SUITESPARSE_SUB_VERSION)
enum c_int SUITESPARSE_VERSION = SUITESPARSE_VER_CODE(SUITESPARSE_MAIN_VERSION,SUITESPARSE_SUB_VERSION);


/* -------------------------------------------------------------------------- */
/* SuiteSparse_config : a global extern struct */
/* -------------------------------------------------------------------------- */

/* The SuiteSparse_config struct is available to all SuiteSparse functions and
    to all applications that use those functions.  It must be modified with
    care, particularly in a multithreaded context.  Normally, the application
    will initialize this object once, via SuiteSparse_start, possibily followed
    by application-specific modifications if the applications wants to use
    alternative memory manager functions.

    The user can redefine these global pointers at run-time to change the
    memory manager and printf function used by SuiteSparse.

    If -DNMALLOC is defined at compile-time, then no memory-manager is
    specified.  You must define them at run-time, after calling
    SuiteSparse_start.

    If -DPRINT is defined a compile time, then printf is disabled, and
    SuiteSparse will not use printf.
 */

version(PRINTING){
    SuiteSparse_config_struct SuiteSparse_config =
    {
        // Memory allocation from glob_opts.h in OSQP
        &c_malloc, &c_realloc, &c_free, 
        
        &c_print,

        &SuiteSparse_hypot,
        &SuiteSparse_divcomplex
    };
} else {
    SuiteSparse_config_struct SuiteSparse_config =
    {
        // Memory allocation from glob_opts.h in OSQP
        &c_malloc, &c_realloc, &c_free,
        null,
        &SuiteSparse_hypot,
        &SuiteSparse_divcomplex        
    };
}

/* -------------------------------------------------------------------------- */
/* SuiteSparse_malloc: malloc wrapper */
/* -------------------------------------------------------------------------- */

void *SuiteSparse_malloc    /* pointer to allocated block of memory */
(
    size_t nitems,          /* number of items to malloc */
    size_t size_of_item     /* sizeof each item */
)
{
    void *p ;
    size_t size ;
    if (nitems < 1) nitems = 1 ;
    if (size_of_item < 1) size_of_item = 1 ;
    size = nitems * size_of_item  ;

    if (size != (cast(c_float) nitems) * size_of_item)
    {
        /* size_t overflow */
        //p = NULL ;
        p = null;
    }
    else
    {
        p = cast(void *)(SuiteSparse_config.malloc_func(size));
        //p = cast(void *) c_malloc(size) ; // todo
    }
    return (p) ;
}



/* -------------------------------------------------------------------------- */
/* SuiteSparse_realloc: realloc wrapper */
/* -------------------------------------------------------------------------- */

/* If p is non-NULL on input, it points to a previously allocated object of
   size nitems_old * size_of_item.  The object is reallocated to be of size
   nitems_new * size_of_item.  If p is NULL on input, then a new object of that
   size is allocated.  On success, a pointer to the new object is returned,
   and ok is returned as 1.  If the allocation fails, ok is set to 0 and a
   pointer to the old (unmodified) object is returned.
 */

void *SuiteSparse_realloc   /* pointer to reallocated block of memory, or
                               to original block if the realloc failed. */
(
    size_t nitems_new,      /* new number of items in the object */
    size_t nitems_old,      /* old number of items in the object */
    size_t size_of_item,    /* sizeof each item */
    void *p,                /* old object to reallocate */
    int *ok                 /* 1 if successful, 0 otherwise */
)
{
    size_t size ;
    if (nitems_old < 1) nitems_old = 1 ;
    if (nitems_new < 1) nitems_new = 1 ;
    if (size_of_item < 1) size_of_item = 1 ;
    size = nitems_new * size_of_item  ;

    if (size != (cast(c_float) nitems_new) * size_of_item)
    {
        /* size_t overflow */
        (*ok) = 0 ;
    }
    else if (p == null) // todo : NULL
    {
        /* a fresh object is being allocated */
        p = SuiteSparse_malloc (nitems_new, size_of_item) ;
        (*ok) = (p != null) ; // todo : NULL
    }
    else if (nitems_old == nitems_new)
    {
        /* the object does not change; do nothing */
        (*ok) = 1 ;
    }
    else
    {
        /* change the size of the object from nitems_old to nitems_new */
        void *pnew ;
        // pnew = (void *) (SuiteSparse_config.realloc_func) (p, size) ;
        pnew = cast(void *) c_realloc (p, size) ;
        if (pnew == null)// todo : NULL
        {
            if (nitems_new < nitems_old)
            {
                /* the attempt to reduce the size of the block failed, but
                   the old block is unchanged.  So pretend to succeed. */
                (*ok) = 1 ;
            }
            else
            {
                /* out of memory */
                (*ok) = 0 ;
            }
        }
        else
        {
            /* success */
            p = pnew ;
            (*ok) = 1 ;
        }
    }
    return (p) ;
}

/* -------------------------------------------------------------------------- */
/* SuiteSparse_free: free wrapper */
/* -------------------------------------------------------------------------- */

void *SuiteSparse_free      /* always returns NULL */
(
    void *p                 /* block to free */
)
{
    if (p)
    {
        //cast(SuiteSparse_config.free_func) p ;
        c_free(p) ;  // todo : i had to get rid of SuiteSparse_config variable in D
        // because of error
        // function core.stdc.stdlib.malloc(ulong size) is not callable using argument types () ../lin_sys/direct/qdldl/amd/src/SuiteSparse_config.d(266):   missing argument for parameter #1: ulong size
    }
    return (null) ;
}


/* -------------------------------------------------------------------------- */
/* SuiteSparse_tic: return current wall clock time */
/* -------------------------------------------------------------------------- */

/* Returns the number of seconds (tic [0]) and nanoseconds (tic [1]) since some
 * unspecified but fixed time in the past.  If no timer is installed, zero is
 * returned.  A scalar c_float precision value for 'tic' could be used, but this
 * might cause loss of precision because clock_getttime returns the time from
 * some distant time in the past.  Thus, an array of size 2 is used.
 *
 * The timer is enabled by default.  To disable the timer, compile with
 * -DNTIMER.  If enabled on a POSIX C 1993 system, the timer requires linking
 * with the -lrt library.
 *
 * example:
 *
 *      c_float tic [2], r, s, t ;
 *      SuiteSparse_tic (tic) ;     // start the timer
 *      // do some work A
 *      t = SuiteSparse_toc (tic) ; // t is time for work A, in seconds
 *      // do some work B
 *      s = SuiteSparse_toc (tic) ; // s is time for work A and B, in seconds
 *      SuiteSparse_tic (tic) ;     // restart the timer
 *      // do some work C
 *      r = SuiteSparse_toc (tic) ; // s is time for work C, in seconds
 *
 * A c_float array of size 2 is used so that this routine can be more easily
 * ported to non-POSIX systems.  The caller does not rely on the POSIX
 * <time.h> include file.
 */
/*
#ifdef SUITESPARSE_TIMER_ENABLED

#include <time.h>

void SuiteSparse_tic
(
    c_float tic [2]      // output, contents undefined on input
)
{
    // POSIX C 1993 timer, requires -librt
    struct timespec t ;
    clock_gettime (CLOCK_MONOTONIC, &t) ;
    tic [0] = (c_float) (t.tv_sec) ;
    tic [1] = (c_float) (t.tv_nsec) ;
}

#else
*/

void SuiteSparse_tic
(
    c_float [2] tic      /* output, contents undefined on input */
)
{
    /* no timer installed */
    tic [0] = 0 ;
    tic [1] = 0 ;
}

//#endif


/* -------------------------------------------------------------------------- */
/* SuiteSparse_toc: return time since last tic */
/* -------------------------------------------------------------------------- */

/* Assuming SuiteSparse_tic is accurate to the nanosecond, this function is
 * accurate down to the nanosecond for 2^53 nanoseconds since the last call to
 * SuiteSparse_tic, which is sufficient for SuiteSparse (about 104 days).  If
 * additional accuracy is required, the caller can use two calls to
 * SuiteSparse_tic and do the calculations differently.
 */

c_float SuiteSparse_toc  /* returns time in seconds since last tic */
(
    c_float [2] tic  /* input, not modified from last call to SuiteSparse_tic */
)
{
    c_float [2]toc ;
    SuiteSparse_tic (toc) ;
    return ((toc [0] - tic [0]) + 1e-9 * (toc [1] - tic [1])) ;
}


/* -------------------------------------------------------------------------- */
/* SuiteSparse_time: return current wallclock time in seconds */
/* -------------------------------------------------------------------------- */

/* This function might not be accurate down to the nanosecond. */

c_float SuiteSparse_time  /* returns current wall clock time in seconds */
(
    //void
)
{
    c_float [2]toc ;
    SuiteSparse_tic (toc) ;
    return (toc [0] + 1e-9 * toc [1]) ;
}


/* -------------------------------------------------------------------------- */
/* SuiteSparse_version: return the current version of SuiteSparse */
/* -------------------------------------------------------------------------- */

int SuiteSparse_version
(
    int [3] _version
)
{
    if (_version != cast(int[])null)
    {
        _version [0] = SUITESPARSE_MAIN_VERSION ;
        _version [1] = SUITESPARSE_SUB_VERSION ;
        _version [2] = SUITESPARSE_SUBSUB_VERSION ;
    }
    return (SUITESPARSE_VERSION) ;
}

/* -------------------------------------------------------------------------- */
/* SuiteSparse_hypot */
/* -------------------------------------------------------------------------- */

/* There is an equivalent routine called hypot in <math.h>, which conforms
 * to ANSI C99.  However, SuiteSparse does not assume that ANSI C99 is
 * available.  You can use the ANSI C99 hypot routine with:
 *
 *      #include <math.h>
 *i     SuiteSparse_config.hypot_func = hypot ;
 *
 * Default value of the SuiteSparse_config.hypot_func pointer is
 * SuiteSparse_hypot, defined below.
 *
 * s = hypot (x,y) computes s = sqrt (x*x + y*y) but does so more accurately.
 * The NaN cases for the c_float relops x >= y and x+y == x are safely ignored.
 *
 * Source: Algorithm 312, "Absolute value and square root of a complex number,"
 * P. Friedland, Comm. ACM, vol 10, no 10, October 1967, page 665.
 */

c_float SuiteSparse_hypot (c_float x, c_float y)
{
    c_float s, r ;
    x = fabs (x) ;
    y = fabs (y) ;
    if (x >= y)
    {
        if (x + y == x)
        {
            s = x ;
        }
        else
        {
            r = y / x ;
            s = x * sqrt (1.0 + r*r) ;
        }
    }
    else
    {
        if (y + x == y)
        {
            s = y ;
        }
        else
        {
            r = x / y ;
            s = y * sqrt (1.0 + r*r) ;
        }
    }
    return (s) ;
}

/* -------------------------------------------------------------------------- */
/* SuiteSparse_divcomplex */
/* -------------------------------------------------------------------------- */

/* c = a/b where c, a, and b are complex.  The real and imaginary parts are
 * passed as separate arguments to this routine.  The NaN case is ignored
 * for the c_float relop br >= bi.  Returns 1 if the denominator is zero,
 * 0 otherwise.
 *
 * This uses ACM Algo 116, by R. L. Smith, 1962, which tries to avoid
 * underflow and overflow.
 *
 * c can be the same variable as a or b.
 *
 * Default value of the SuiteSparse_config.divcomplex_func pointer is
 * SuiteSparse_divcomplex.
 */

int SuiteSparse_divcomplex
(
    c_float ar, c_float ai,       /* real and imaginary parts of a */
    c_float br, c_float bi,       /* real and imaginary parts of b */
    c_float *cr, c_float *ci      /* real and imaginary parts of c */
)
{
    c_float tr, ti, r, den ;
    if (fabs (br) >= fabs (bi))
    {
        r = bi / br ;
        den = br + r * bi ;
        tr = (ar + ai * r) / den ;
        ti = (ai - ar * r) / den ;
    }
    else
    {
        r = br / bi ;
        den = r * br + bi ;
        tr = (ar * r + ai) / den ;
        ti = (ai * r - ar) / den ;
    }
    *cr = tr ;
    *ci = ti ;
    return (den == 0.) ;
}
