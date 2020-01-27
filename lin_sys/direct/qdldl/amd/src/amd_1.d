/* ========================================================================= */
/* === AMD_1 =============================================================== */
/* ========================================================================= */

/* ------------------------------------------------------------------------- */
/* AMD, Copyright (c) Timothy A. Davis,					     */
/* Patrick R. Amestoy, and Iain S. Duff.  See ../README.txt for License.     */
/* email: DrTimothyAldenDavis@gmail.com                                      */
/* ------------------------------------------------------------------------- */

/* AMD_1: Construct A+A' for a sparse matrix A and perform the AMD ordering.
 *
 * The n-by-n sparse matrix A can be unsymmetric.  It is stored in MATLAB-style
 * compressed-column form, with sorted row indices in each column, and no
 * duplicate entries.  Diagonal entries may be present, but they are ignored.
 * Row indices of column j of A are stored in Ai [Ap [j] ... Ap [j+1]-1].
 * Ap [0] must be zero, and nz = Ap [n] is the number of entries in A.  The
 * size of the matrix, n, must be greater than or equal to zero.
 *
 * This routine must be preceded by a call to AMD_aat, which computes the
 * number of entries in each row/column in A+A', excluding the diagonal.
 * Len [j], on input, is the number of entries in row/column j of A+A'.  This
 * routine constructs the matrix A+A' and then calls AMD_2.  No error checking
 * is performed (this was done in AMD_valid).
 */

module amd_1;

nothrow @nogc extern(C):

import glob_opts; // for c_float
import amd_internal;
import amd;
import amd_valid;
import amd_2;

void AMD_1
(
    Int n,		/* n > 0 */
    const Int * Ap,	/* input of size n+1, not modified */
    const Int * Ai,	/* input of size nz = Ap [n], not modified */
    Int * P,		/* size n output permutation */
    Int * Pinv,	/* size n output inverse permutation */
    Int * Len,	/* size n input, undefined on output */
    Int slen,		/* slen >= sum (Len [0..n-1]) + 7n,
			 * ideally slen = 1.2 * sum (Len) + 8n */
    Int * S,		/* size slen workspace */
    c_float * Control,	/* input array of size AMD_CONTROL */
    c_float * Info /* output array of size AMD_INFO */
)
{
    Int i;
	Int j;
	Int k;
	Int p;
	Int pfree;
	Int iwlen;
	Int pj;
	Int p1;
	Int p2;
	Int pj2;
	Int *Iw;
	Int *Pe;
	Int *Nv;
	Int *Head;
	Int *Elen;
	Int *Degree;
	Int *s;
	Int *W;
	Int *Sp;
	Int *Tp;

    /* --------------------------------------------------------------------- */
    /* construct the matrix for AMD_2 */
    /* --------------------------------------------------------------------- */

    ASSERT (n > 0) ;

    iwlen = slen - 6*n ;
    s = S ;
    Pe = s ;	    s += n ;
    Nv = s ;	    s += n ;
    Head = s ;	    s += n ;
    Elen = s ;	    s += n ;
    Degree = s ;    s += n ;
    W = s ;	    s += n ;
    Iw = s ;	    s += iwlen ;

    ASSERT (AMD_valid (n, n, Ap, Ai) == AMD_OK) ;

    /* construct the pointers for A+A' */
    Sp = Nv ;			/* use Nv and W as workspace for Sp and Tp [ */
    Tp = W ;
    pfree = 0 ;
    for (j = 0 ; j < n ; j++)
    {
	Pe [j] = pfree ;
	Sp [j] = pfree ;
	pfree += Len [j] ;
    }

    /* Note that this restriction on iwlen is slightly more restrictive than
     * what is strictly required in AMD_2.  AMD_2 can operate with no elbow
     * room at all, but it will be very slow.  For better performance, at
     * least size-n elbow room is enforced. */
    ASSERT (iwlen >= pfree + n) ;

version(NDEBUG){}
else {
    for (p = 0 ; p < iwlen ; p++) Iw [p] = EMPTY ;
} // !NDEBUG

    for (k = 0 ; k < n ; k++)
    {
	//AMD_DEBUG1 (("Construct row/column k= "ID" of A+A'\n", k))  ;  // todo
	p1 = Ap [k] ;
	p2 = Ap [k+1] ;

	/* construct A+A' */
	for (p = p1 ; p < p2 ; )
	{
	    /* scan the upper triangular part of A */
	    j = Ai [p] ;
	    ASSERT (j >= 0 && j < n) ;
	    if (j < k)
	    {
		/* entry A (j,k) in the strictly upper triangular part */
		ASSERT (Sp [j] < (j == n-1 ? pfree : Pe [j+1])) ;
		ASSERT (Sp [k] < (k == n-1 ? pfree : Pe [k+1])) ;
		Iw [Sp [j]++] = k ;
		Iw [Sp [k]++] = j ;
		p++ ;
	    }
	    else if (j == k)
	    {
		/* skip the diagonal */
		p++ ;
		break ;
	    }
	    else /* j > k */
	    {
		/* first entry below the diagonal */
		break ;
	    }
	    /* scan lower triangular part of A, in column j until reaching
	     * row k.  Start where last scan left off. */
	    ASSERT (Ap [j] <= Tp [j] && Tp [j] <= Ap [j+1]) ;
	    pj2 = Ap [j+1] ;
	    for (pj = Tp [j] ; pj < pj2 ; )
	    {
		i = Ai [pj] ;
		ASSERT (i >= 0 && i < n) ;
		if (i < k)
		{
		    /* A (i,j) is only in the lower part, not in upper */
		    ASSERT (Sp [i] < (i == n-1 ? pfree : Pe [i+1])) ;
		    ASSERT (Sp [j] < (j == n-1 ? pfree : Pe [j+1])) ;
		    Iw [Sp [i]++] = j ;
		    Iw [Sp [j]++] = i ;
		    pj++ ;
		}
		else if (i == k)
		{
		    /* entry A (k,j) in lower part and A (j,k) in upper */
		    pj++ ;
		    break ;
		}
		else /* i > k */
		{
		    /* consider this entry later, when k advances to i */
		    break ;
		}
	    }
	    Tp [j] = pj ;
	}
	Tp [k] = p ;
    }

    /* clean up, for remaining mismatched entries */
    for (j = 0 ; j < n ; j++)
    {
	for (pj = Tp [j] ; pj < Ap [j+1] ; pj++)
	{
	    i = Ai [pj] ;
	    ASSERT (i >= 0 && i < n) ;
	    /* A (i,j) is only in the lower part, not in upper */
	    ASSERT (Sp [i] < (i == n-1 ? pfree : Pe [i+1])) ;
	    ASSERT (Sp [j] < (j == n-1 ? pfree : Pe [j+1])) ;
	    Iw [Sp [i]++] = j ;
	    Iw [Sp [j]++] = i ;
	}
    }

version(NDEBUG){}
else {
    for (j = 0 ; j < n-1 ; j++) ASSERT (Sp [j] == Pe [j+1]) ;
    ASSERT (Sp [n-1] == pfree) ;
} // !NDEBUG

    /* Tp and Sp no longer needed ] */

    /* --------------------------------------------------------------------- */
    /* order the matrix */
    /* --------------------------------------------------------------------- */

    AMD_2 (n, Pe, Iw, Len, iwlen, pfree,
	Nv, Pinv, P, Head, Elen, Degree, W, Control, Info) ;
}