/* ========================================================================= */
/* === amd_internal.h ====================================================== */
/* ========================================================================= */

/* ------------------------------------------------------------------------- */
/* AMD, Copyright (c) Timothy A. Davis,                                      */
/* Patrick R. Amestoy, and Iain S. Duff.  See ../README.txt for License.     */
/* email: DrTimothyAldenDavis@gmail.com                                      */
/* ------------------------------------------------------------------------- */

/* This file is for internal use in AMD itself, and does not normally need to
 * be included in user code (it is included in UMFPACK, however).   All others
 * should use amd.h instead.
 */

/* ========================================================================= */
/* === NDEBUG ============================================================== */
/* ========================================================================= */

/*
 * Turning on debugging takes some work (see below).   If you do not edit this
 * file, then debugging is always turned off, regardless of whether or not
 * -DNDEBUG is specified in your compiler options.
 *
 * If AMD is being compiled as a mexFunction, then MATLAB is defined,
 * and mxAssert is used instead of assert.  If debugging is not enabled, no
 * MATLAB include files or functions are used.  Thus, the AMD library libamd.a
 * can be safely used in either a stand-alone C program or in another
 * mexFunction, without any change.
 */

/*
    AMD will be exceedingly slow when running in debug mode.  The next three
    lines ensure that debugging is turned off.
*/
//#define NDEBUG

/*
    To enable debugging, uncomment the following line:
#undef NDEBUG
*/

nothrow @nogc extern(C):

import glob_opts;
import SuiteSparse_config;
import amd_postorder;
import amd_preprocess;
import amd_aat;
import amd_valid;
import amd_1;
import amd_2;

/* ------------------------------------------------------------------------- */
/* ANSI include files */
/* ------------------------------------------------------------------------- */

import core.stdc.stdlib;  // size_t, malloc, free, realloc, and calloc
import core.stdc.stdarg;

//#if !defined(NPRINT) || !defined(NDEBUG)
version (NPRINT){}
else {
/* from stdio.h:  printf.  Not included if NPRINT is defined at compile time.
 * fopen and fscanf are used when debugging. */
import core.stdc.stdio;
}

version (NDEBUG){}
else {
/* from stdio.h:  printf.  Not included if NPRINT is defined at compile time.
 * fopen and fscanf are used when debugging. */
import core.stdc.stdio;
}

/* from limits.h:  INT_MAX and LONG_MAX */
import core.stdc.limits;

/* from math.h: sqrt */
import core.stdc.math;

/* ------------------------------------------------------------------------- */
/* MATLAB include files (only if being used in or via MATLAB) */
/* ------------------------------------------------------------------------- */

version(MATLAB){
//#include "matrix.h"
//#include "mex.h"
import matrix;
import meh;
}

/* ------------------------------------------------------------------------- */
/* basic definitions */
/* ------------------------------------------------------------------------- */
/*
#ifdef FLIP
#undef FLIP
#endif

#ifdef MAX
#undef MAX
#endif

#ifdef MIN
#undef MIN
#endif

#ifdef EMPTY
#undef EMPTY
#endif

#ifdef GLOBAL
#undef GLOBAL
#endif

#ifdef PRIVATE
#undef PRIVATE
#endif
*/
/* FLIP is a "negation about -1", and is used to mark an integer i that is
 * normally non-negative.  FLIP (EMPTY) is EMPTY.  FLIP of a number > EMPTY
 * is negative, and FLIP of a number < EMTPY is positive.  FLIP (FLIP (i)) = i
 * for all integers i.  UNFLIP (i) is >= EMPTY. */
enum c_int EMPTY = -1;

//#define FLIP(i) (-(i)-2)
//#define UNFLIP(i) ((i < EMPTY) ? FLIP (i) : (i))
// todo  test it
c_int FLIP(c_int i) {return (-(i)-2);}
c_int UNFLIP(c_int i) {return ((i < EMPTY) ? FLIP (i) : (i));}

/* for integer MAX/MIN, or for c_floats when we don't care how NaN's behave: */
//#define MAX(a,b) (((a) > (b)) ? (a) : (b))
//#define MIN(a,b) (((a) < (b)) ? (a) : (b))
auto MAX(T)(auto ref T a, auto ref T b) {return (((a) > (b)) ? (a) : (b));}
auto MIN(T)(auto ref T a, auto ref T b) {return (((a) < (b)) ? (a) : (b));}

/* logical expression of p implies q: */
//#define IMPLIES(p,q) (!(p) || (q))
bool IMPLIES(T1, T2)(auto ref T1 p, auto ref T2 q) { return (!(p) || (q));}

/* Note that the IBM RS 6000 xlc predefines TRUE and FALSE in <types.h>. */
/* The Compaq Alpha also predefines TRUE and FALSE. */
/*
#ifdef TRUE
#undef TRUE
#endif
#ifdef FALSE
#undef FALSE
#endif
*/
enum c_int TRUE = 1;
enum c_int FALSE = 0;
//#define PRIVATE static
// todo : check it
//alias PRIVATE = static
//#define GLOBAL
//#define EMPTY (-1)
//enum c_int EMPTY = -1;

/* Note that Linux's gcc 2.96 defines NULL as ((void *) 0), but other */
/* compilers (even gcc 2.95.2 on Solaris) define NULL as 0 or (0).  We */
/* need to use the ANSI standard value of 0. */
/*
#ifdef NULL
#undef NULL
#endif
*/
auto NULL = null;

/* largest value of size_t */
/*
#ifndef SIZE_T_MAX
#ifdef SIZE_MAX
// C99 only 
#define SIZE_T_MAX SIZE_MAX
#else
#define SIZE_T_MAX ((size_t) (-1))
#endif
#endif
*/
enum c_int SIZE_T_MAX = (cast(size_t) (-1));


version(NDEBUG){
    void AMD_debug_init ( string s ) {};
    void AMD_dump
    (
        Int n,
        Int *Pe ,
        Int *Iw,
        Int *Len,
        Int iwlen,
        Int pfree,
        Int *Nv,
        Int *Next,
        Int *Last,
        Int *Head,
        Int *Elen,
        Int *Degree,
        Int *W,
        Int nel
    ) {};
}
else {
    //void AMD_debug_init ( char *s ) ;
    void AMD_debug_init ( string s ) ;

    void AMD_dump
    (
        Int n,
        Int *Pe ,
        Int *Iw,
        Int *Len,
        Int iwlen,
        Int pfree,
        Int *Nv,
        Int *Next,
        Int *Last,
        Int *Head,
        Int *Elen,
        Int *Degree,
        Int *W,
        Int nel
    );
}
/* ------------------------------------------------------------------------- */
/* integer type for AMD: int or SuiteSparse_long */
/* ------------------------------------------------------------------------- */

import amd;

//#if defined (DLONG) || defined (ZLONG)
version(DLONG){
    alias Int = SuiteSparse_long;
    alias UInt = ulong;
    alias ID = SuiteSparse_long_idd;
    alias Int_MAX = SuiteSparse_long_max;
/*    alias amd_l_order = AMD_order;
    alias amd_l_defaults = AMD_defaults;
    alias amd_l_control = AMD_control;
    alias amd_l_info = AMD_info;
    alias amd_l1 = AMD_1;
    alias amd_l2 = AMD_2;
    alias amd_l_valid = AMD_valid;
    alias amd_l_aat = AMD_aat;
    alias amd_l_postorder = AMD_postorder;
    alias amd_l_post_tree = AMD_post_tree;
    alias amd_l_dump = AMD_dump;
    alias amd_l_debug = AMD_debug;
    alias amd_l_debug_init = AMD_debug_init;
    alias amd_l_preprocess = AMD_preprocess;*/
}
else {
    version(ZLONG){
        alias Int = SuiteSparse_long;
        alias UInt = ulong;
        alias ID = SuiteSparse_long_idd;
        alias Int_MAX = SuiteSparse_long_max;
    /*    alias AMD_order = amd_l_order;
        alias AMD_defaults = amd_l_defaults;
        alias amd_l_control = AMD_control;
        alias amd_l_info = AMD_info;
        alias amd_l1 = AMD_1;
        alias amd_l2 = AMD_2;
        alias amd_l_valid = AMD_valid;
        alias amd_l_aat = AMD_aat;
        alias amd_l_postorder = AMD_postorder;
        alias amd_l_post_tree = AMD_post_tree;
        alias amd_l_dump = AMD_dump;
        alias amd_l_debug = AMD_debug;
        alias amd_l_debug_init = AMD_debug_init;
        alias amd_l_preprocess = AMD_preprocess;*/
    }
    else {
        alias Int = int;
        alias UInt = uint;
        enum string ID = "%d";        
        alias Int_MAX = INT_MAX;
        
    /*    alias amd_order = AMD_order;
        alias amd_defaults = AMD_defaults;
        alias amd_control = AMD_control;
        alias amd_info = AMD_info;
        alias amd_1 = AMD_1;
        alias amd_2 = AMD_2;
        alias amd_valid = AMD_valid;
        alias amd_aat = AMD_aat;
        alias amd_postorder = AMD_postorder;
        alias amd_post_tree = AMD_post_tree;
        alias amd_dump = AMD_dump;
        alias amd_debug = AMD_debug;
        alias amd_debug_init = AMD_debug_init;
        alias amd_preprocess = AMD_preprocess;*/
    }
}

/* ------------------------------------------------------------------------- */
/* debugging definitions */
/* ------------------------------------------------------------------------- */

version (NDEBUG){
/* no debugging */
//#define ASSERT(expression)
//#define AMD_DEBUG0(params)
//#define AMD_DEBUG1(params)
//#define AMD_DEBUG2(params)
//#define AMD_DEBUG3(params)
//#define AMD_DEBUG4(params)

void ASSERT(T)(auto ref T expression) {}
void AMD_DEBUG0(T)(auto ref T params, ...) {}
void AMD_DEBUG1(T)(auto ref T params, ...) {}
void AMD_DEBUG2(T)(auto ref T params, ...) {}
void AMD_DEBUG3(T)(auto ref T params, ...) {}
void AMD_DEBUG4(T)(auto ref T params, ...) {}
//__gshared Int AMD_debug = 0;
}
else 
{
    /* from assert.h:  assert macro */
    // todo : maybe no need special import for assert
    //#include <assert.h>
    //import core.sync.exception;
    //import core.stdcpp.exception;    

    //#ifndef EXTERN
    //#define EXTERN extern
    //#endif

    //EXTERN Int AMD_debug ;
    //__gshared Int AMD_debug = 3; // todo : AMD_debug declared nowhere in C code

    //#ifdef ASSERT
    //#undef ASSERT
    //#endif

    /* Use mxAssert if AMD is compiled into a mexFunction */
    version(MATLAB){
        //#define ASSERT(expression) (mxAssert ((expression), ""))
        void ASSERT(T)(T expression) { mxAssert((expression), ""); }
    }else {
        //#define ASSERT(expression) (assert (expression))
        void ASSERT(T)(T expression) { assert(expression); }
    }

    //#define AMD_DEBUG0(params) { SUITESPARSE_PRINTF (params) ; }
    //#define AMD_DEBUG1(params) { if (AMD_debug >= 1) SUITESPARSE_PRINTF (params) ; }
    //#define AMD_DEBUG2(params) { if (AMD_debug >= 2) SUITESPARSE_PRINTF (params) ; }
    //#define AMD_DEBUG3(params) { if (AMD_debug >= 3) SUITESPARSE_PRINTF (params) ; }
    //#define AMD_DEBUG4(params) { if (AMD_debug >= 4) SUITESPARSE_PRINTF (params) ; }
    void AMD_DEBUG0(T)(auto ref T params, ...) { SUITESPARSE_PRINTF (params); }
    // todo : AMD_debug declared nowhere in C code
    void AMD_DEBUG1(T)(auto ref T params, ...) { /*if (AMD_debug >= 1)*/ SUITESPARSE_PRINTF (params); }
    void AMD_DEBUG2(T)(auto ref T params, ...) { /*if (AMD_debug >= 2) */SUITESPARSE_PRINTF (params); }
    void AMD_DEBUG3(T)(auto ref T params, ...) { /*if (AMD_debug >= 3)*/ SUITESPARSE_PRINTF (params); }
    void AMD_DEBUG4(T)(auto ref T params, ...) { /*if (AMD_debug >= 4) */SUITESPARSE_PRINTF (params); }

} // !NDEBUG
