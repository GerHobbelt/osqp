/* ========================================================================= */
/* === AMD_order =========================================================== */
/* ========================================================================= */

/* ------------------------------------------------------------------------- */
/* AMD, Copyright (c) Timothy A. Davis,					     */
/* Patrick R. Amestoy, and Iain S. Duff.  See ../README.txt for License.     */
/* email: DrTimothyAldenDavis@gmail.com                                      */
/* ------------------------------------------------------------------------- */

/* User-callable AMD minimum degree ordering routine.  See amd.h for
 * documentation.
 */

module amd_order;

nothrow @nogc extern(C):

import glob_opts;
import amd_internal;
import amd;
import amd_1;
import amd_valid;
import amd_preprocess;
import amd_aat;
import SuiteSparse_config;

/* ========================================================================= */
/* === AMD_order =========================================================== */
/* ========================================================================= */

version (DLONG){
    SuiteSparse_long AMD_order
    (
        SuiteSparse_long n,
        const SuiteSparse_long * Ap,
        const SuiteSparse_long * Ai,
        SuiteSparse_long * P,
        c_float * Control,
        c_float * Info
    )
    {
        Int *Len;
        Int *S;
        Int nz;
        Int i;
        Int *Pinv;
        Int info;
        Int status;
        Int *Rp;
        Int *Ri;
        Int *Cp;
        Int *Ci;
        Int ok;
        size_t nzaat;
        size_t slen;
        c_float mem = 0 ;

    version(NDEBUG){}
    else {
        AMD_debug_init ("amd") ;
    }

        /* clear the Info array, if it exists */
        info = Info != cast(c_float *) NULL ;
        if (info)
        {
        for (i = 0 ; i < AMD_INFO ; i++)
        {
            Info [i] = EMPTY ;
        }
        Info [AMD_N] = n ;
        Info [AMD_STATUS] = AMD_OK ;
        }

        /* make sure inputs exist and n is >= 0 */
        if (Ai == cast(Int *) NULL || Ap == cast(Int *) NULL || P == cast(Int *) NULL || n < 0)
        {
        if (info) Info [AMD_STATUS] = AMD_INVALID ;
        return (AMD_INVALID) ;	    /* arguments are invalid */
        }

        if (n == 0)
        {
        return (AMD_OK) ;	    /* n is 0 so there's nothing to do */
        }

        nz = Ap [n] ;
        if (info)
        {
        Info [AMD_NZ] = nz ;
        }
        if (nz < 0)
        {
        if (info) Info [AMD_STATUS] = AMD_INVALID ;
        return (AMD_INVALID) ;
        }

        /* check if n or nz will cause size_t overflow */
        if ((cast(size_t) n) >= SIZE_T_MAX /  (Int.sizeof)
        || (cast(size_t) nz) >= SIZE_T_MAX / (Int.sizeof))
        {
        if (info) Info [AMD_STATUS] = AMD_OUT_OF_MEMORY ;
        return (AMD_OUT_OF_MEMORY) ;	    /* problem too large */
        }

        /* check the input matrix:	AMD_OK, AMD_INVALID, or AMD_OK_BUT_JUMBLED */
        status = AMD_valid (n, n, Ap, Ai) ;

        if (status == AMD_INVALID)
        {
        if (info) Info [AMD_STATUS] = AMD_INVALID ;
        return (AMD_INVALID) ;	    /* matrix is invalid */
        }

        /* allocate two size-n integer workspaces */
        Len  = cast(Int*)SuiteSparse_malloc (n, (Int.sizeof)) ;
        Pinv = cast(Int*)SuiteSparse_malloc (n, (Int.sizeof)) ;
        mem += n ;
        mem += n ;
        if (!Len || !Pinv)
        {
        /* :: out of memory :: */
        SuiteSparse_free (Len) ;
        SuiteSparse_free (Pinv) ;
        if (info) Info [AMD_STATUS] = AMD_OUT_OF_MEMORY ;
        return (AMD_OUT_OF_MEMORY) ;
        }

        if (status == AMD_OK_BUT_JUMBLED)
        {
        /* sort the input matrix and remove duplicate entries */
        AMD_DEBUG1 (("Matrix is jumbled\n")) ;
        Rp = cast(Int*)SuiteSparse_malloc (n+1, (Int.sizeof)) ;
        Ri = cast(Int*)SuiteSparse_malloc (nz,  (Int.sizeof)) ;
        mem += (n+1) ;
        mem += MAX (nz,1) ;
        if (!Rp || !Ri)
        {
            /* :: out of memory :: */
            SuiteSparse_free (Rp) ;
            SuiteSparse_free (Ri) ;
            SuiteSparse_free (Len) ;
            SuiteSparse_free (Pinv) ;
            if (info) Info [AMD_STATUS] = AMD_OUT_OF_MEMORY ;
            return (AMD_OUT_OF_MEMORY) ;
        }
        /* use Len and Pinv as workspace to create R = A' */
        AMD_preprocess (n, Ap, Ai, Rp, Ri, Len, Pinv) ;
        Cp = Rp ;
        Ci = Ri ;
        }
        else
        {
        /* order the input matrix as-is.  No need to compute R = A' first */
        Rp = NULL ;
        Ri = NULL ;
        Cp = cast(Int *) Ap ;
        Ci = cast(Int *) Ai ;
        }

        /* --------------------------------------------------------------------- */
        /* determine the symmetry and count off-diagonal nonzeros in A+A' */
        /* --------------------------------------------------------------------- */

        nzaat = AMD_aat (n, Cp, Ci, Len, P, Info) ;
        AMD_DEBUG1 ("nzaat: %g\n", cast(c_float) nzaat) ;
        ASSERT ((MAX (nz-n, 0) <= nzaat) && (nzaat <= 2 * cast(size_t) nz)) ;

        /* --------------------------------------------------------------------- */
        /* allocate workspace for matrix, elbow room, and 6 size-n vectors */
        /* --------------------------------------------------------------------- */

        S = NULL ;
        slen = nzaat ;			/* space for matrix */
        ok = ((slen + nzaat/5) >= slen) ;	/* check for size_t overflow */
        slen += nzaat/5 ;			/* add elbow room */
        for (i = 0 ; ok && i < 7 ; i++)
        {
        ok = ((slen + n) > slen) ;	/* check for size_t overflow */
        slen += n ;			/* size-n elbow room, 6 size-n work */
        }
        mem += slen ;
        ok = ok && (slen < SIZE_T_MAX / (Int.sizeof)) ; /* check for overflow */
        ok = ok && (slen < Int_MAX) ;	/* S[i] for Int i must be OK */
        if (ok)
        {
        S = cast(Int*)SuiteSparse_malloc (slen, (Int.sizeof)) ;
        }
        AMD_DEBUG1 ("slen %g\n", cast(c_float) slen) ;
        if (!S)
        {
        /* :: out of memory :: (or problem too large) */
        SuiteSparse_free (Rp) ;
        SuiteSparse_free (Ri) ;
        SuiteSparse_free (Len) ;
        SuiteSparse_free (Pinv) ;
        if (info) Info [AMD_STATUS] = AMD_OUT_OF_MEMORY ;
        return (AMD_OUT_OF_MEMORY) ;
        }
        if (info)
        {
        /* memory usage, in bytes. */
        Info [AMD_MEMORY] = mem * (Int.sizeof) ;
        }

        /* --------------------------------------------------------------------- */
        /* order the matrix */
        /* --------------------------------------------------------------------- */

        AMD_1 (n, Cp, Ci, P, Pinv, Len, cast(Int)slen, S, Control, Info) ;

        /* --------------------------------------------------------------------- */
        /* free the workspace */
        /* --------------------------------------------------------------------- */

        SuiteSparse_free (Rp) ;
        SuiteSparse_free (Ri) ;
        SuiteSparse_free (Len) ;
        SuiteSparse_free (Pinv) ;
        SuiteSparse_free (S) ;
        if (info) Info [AMD_STATUS] = status ;
        return (status) ;	    /* successful ordering */
    }
}
else {
    int AMD_order                  /* returns AMD_OK, AMD_OK_BUT_JUMBLED,
                                * AMD_INVALID, or AMD_OUT_OF_MEMORY */
    (
        int n,                     /* A is n-by-n.  n must be >= 0. */
        const int * Ap,          /* column pointers for A, of size n+1 */
        const int * Ai,          /* row indices of A, of size nz = Ap [n] */
        int * P,                 /* output permutation, of size n */
        c_float * Control,        /* input Control settings, of size AMD_CONTROL */
        c_float * Info            /* output Info statistics, of size AMD_INFO */
    )
    {
        Int *Len;
        Int *S;
        Int nz;
        Int i;
        Int *Pinv;
        Int info;
        Int status;
        Int *Rp;
        Int *Ri;
        Int *Cp;
        Int *Ci;
        Int ok;
        size_t nzaat;
        size_t slen;
        c_float mem = 0 ;

    version(NDEBUG){}
    else {
        AMD_debug_init ("amd") ;
    }

        /* clear the Info array, if it exists */
        info = Info != cast(c_float *) NULL ;
        if (info)
        {
        for (i = 0 ; i < AMD_INFO ; i++)
        {
            Info [i] = EMPTY ;
        }
        Info [AMD_N] = n ;
        Info [AMD_STATUS] = AMD_OK ;
        }

        /* make sure inputs exist and n is >= 0 */
        if (Ai == cast(Int *) NULL || Ap == cast(Int *) NULL || P == cast(Int *) NULL || n < 0)
        {
        if (info) Info [AMD_STATUS] = AMD_INVALID ;
        return (AMD_INVALID) ;	    /* arguments are invalid */
        }

        if (n == 0)
        {
        return (AMD_OK) ;	    /* n is 0 so there's nothing to do */
        }

        nz = Ap [n] ;
        if (info)
        {
        Info [AMD_NZ] = nz ;
        }
        if (nz < 0)
        {
        if (info) Info [AMD_STATUS] = AMD_INVALID ;
        return (AMD_INVALID) ;
        }

        /* check if n or nz will cause size_t overflow */
        if ((cast(size_t) n) >= SIZE_T_MAX /  (Int.sizeof)
        || (cast(size_t) nz) >= SIZE_T_MAX / (Int.sizeof))
        {
        if (info) Info [AMD_STATUS] = AMD_OUT_OF_MEMORY ;
        return (AMD_OUT_OF_MEMORY) ;	    /* problem too large */
        }

        /* check the input matrix:	AMD_OK, AMD_INVALID, or AMD_OK_BUT_JUMBLED */
        status = AMD_valid (n, n, Ap, Ai) ;

        if (status == AMD_INVALID)
        {
        if (info) Info [AMD_STATUS] = AMD_INVALID ;
        return (AMD_INVALID) ;	    /* matrix is invalid */
        }

        /* allocate two size-n integer workspaces */
        Len  = cast(Int*)SuiteSparse_malloc (n, (Int.sizeof)) ;
        Pinv = cast(Int*)SuiteSparse_malloc (n, (Int.sizeof)) ;
        mem += n ;
        mem += n ;
        if (!Len || !Pinv)
        {
        /* :: out of memory :: */
        SuiteSparse_free (Len) ;
        SuiteSparse_free (Pinv) ;
        if (info) Info [AMD_STATUS] = AMD_OUT_OF_MEMORY ;
        return (AMD_OUT_OF_MEMORY) ;
        }

        if (status == AMD_OK_BUT_JUMBLED)
        {
        /* sort the input matrix and remove duplicate entries */
        AMD_DEBUG1 (("Matrix is jumbled\n")) ;
        Rp = cast(Int*)SuiteSparse_malloc (n+1, (Int.sizeof)) ;
        Ri = cast(Int*)SuiteSparse_malloc (nz,  (Int.sizeof)) ;
        mem += (n+1) ;
        mem += MAX (nz,1) ;
        if (!Rp || !Ri)
        {
            /* :: out of memory :: */
            SuiteSparse_free (Rp) ;
            SuiteSparse_free (Ri) ;
            SuiteSparse_free (Len) ;
            SuiteSparse_free (Pinv) ;
            if (info) Info [AMD_STATUS] = AMD_OUT_OF_MEMORY ;
            return (AMD_OUT_OF_MEMORY) ;
        }
        /* use Len and Pinv as workspace to create R = A' */
        AMD_preprocess (n, Ap, Ai, Rp, Ri, Len, Pinv) ;
        Cp = Rp ;
        Ci = Ri ;
        }
        else
        {
        /* order the input matrix as-is.  No need to compute R = A' first */
        Rp = NULL ;
        Ri = NULL ;
        Cp = cast(Int *) Ap ;
        Ci = cast(Int *) Ai ;
        }

        /* --------------------------------------------------------------------- */
        /* determine the symmetry and count off-diagonal nonzeros in A+A' */
        /* --------------------------------------------------------------------- */

        nzaat = AMD_aat (n, Cp, Ci, Len, P, Info) ;
        AMD_DEBUG1 ("nzaat: %g\n", cast(c_float) nzaat) ;
        ASSERT ((MAX (nz-n, 0) <= nzaat) && (nzaat <= 2 * cast(size_t) nz)) ;

        /* --------------------------------------------------------------------- */
        /* allocate workspace for matrix, elbow room, and 6 size-n vectors */
        /* --------------------------------------------------------------------- */

        S = NULL ;
        slen = nzaat ;			/* space for matrix */
        ok = ((slen + nzaat/5) >= slen) ;	/* check for size_t overflow */
        slen += nzaat/5 ;			/* add elbow room */
        for (i = 0 ; ok && i < 7 ; i++)
        {
        ok = ((slen + n) > slen) ;	/* check for size_t overflow */
        slen += n ;			/* size-n elbow room, 6 size-n work */
        }
        mem += slen ;
        ok = ok && (slen < SIZE_T_MAX / (Int.sizeof)) ; /* check for overflow */
        ok = ok && (slen < Int_MAX) ;	/* S[i] for Int i must be OK */
        if (ok)
        {
        S = cast(Int*)SuiteSparse_malloc (slen, (Int.sizeof)) ;
        }
        AMD_DEBUG1 ("slen %g\n", cast(c_float) slen) ;
        if (!S)
        {
        /* :: out of memory :: (or problem too large) */
        SuiteSparse_free (Rp) ;
        SuiteSparse_free (Ri) ;
        SuiteSparse_free (Len) ;
        SuiteSparse_free (Pinv) ;
        if (info) Info [AMD_STATUS] = AMD_OUT_OF_MEMORY ;
        return (AMD_OUT_OF_MEMORY) ;
        }
        if (info)
        {
        /* memory usage, in bytes. */
        Info [AMD_MEMORY] = mem * (Int.sizeof) ;
        }

        /* --------------------------------------------------------------------- */
        /* order the matrix */
        /* --------------------------------------------------------------------- */

        AMD_1 (n, Cp, Ci, P, Pinv, Len, cast(Int)slen, S, Control, Info) ;

        /* --------------------------------------------------------------------- */
        /* free the workspace */
        /* --------------------------------------------------------------------- */

        SuiteSparse_free (Rp) ;
        SuiteSparse_free (Ri) ;
        SuiteSparse_free (Len) ;
        SuiteSparse_free (Pinv) ;
        SuiteSparse_free (S) ;
        if (info) Info [AMD_STATUS] = status ;
        return (status) ;	    /* successful ordering */
    }
} // DLONG

